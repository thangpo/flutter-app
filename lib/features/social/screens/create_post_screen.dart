import 'dart:async';
import 'dart:io';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/live_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/social_feeling_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/social_feeling_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/post_background_presets.dart';

class SocialCreatePostScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;
  final String? groupTitle;

  const SocialCreatePostScreen({
    super.key,
    this.groupId,
    this.groupName,
    this.groupTitle,
  });

  @override
  State<SocialCreatePostScreen> createState() => _SocialCreatePostScreenState();
}

class _SocialCreatePostScreenState extends State<SocialCreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<XFile> _images = <XFile>[];
  XFile? _video;

  int _privacy = 0;
  bool _submitting = false;

  final ImagePicker _picker = ImagePicker();
  final FocusNode _textFocusNode = FocusNode();
  Timer? _mentionDebounce;
  List<SocialUser> _mentionSuggestions = <SocialUser>[];
  bool _mentionLoading = false;
  bool _mentionPromptVisible = false;
  int _mentionStartIndex = -1;
  String _currentMentionQuery = '';
  String? _selectedFeelingType;
  String? _selectedFeelingValue;
  String? _selectedLocation;
  String? _selectedBackgroundId;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChanged);
    _textFocusNode.addListener(_handleTextFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = context.read<SocialController>();
      sc.loadCurrentUser();
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChanged);
    _mentionDebounce?.cancel();
    _textFocusNode.removeListener(_handleTextFocusChange);
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onPickMedia() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    final bool? pickVideo = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(getTranslated('add_photo', ctx) ?? 'Add photo'),
                onTap: () => Navigator.of(ctx).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: Text(getTranslated('add_video', ctx) ?? 'Add video'),
                onTap: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || pickVideo == null) return;
    if (pickVideo) {
      await _pickVideo();
    } else {
      await _pickImages();
    }
  }

  Future<void> _pickImages() async {
    if (_hasBackground) {
      showCustomSnackBar(
        getTranslated('background_color_only_text', context) ??
            'Background posts can only contain text',
        context,
        isError: true,
      );
      return;
    }
    if (_video != null) {
      showCustomSnackBar(
        getTranslated('remove_video_before_adding_images', context) ??
            'Remove the video before adding images',
        context,
        isError: true,
      );
      return;
    }
    final List<XFile> selected = await _picker.pickMultiImage(
      imageQuality: 85,
    );
    if (!mounted || selected.isEmpty) return;
    setState(() {
      _images.addAll(selected);
    });
  }

  Future<void> _pickVideo() async {
    if (_hasBackground) {
      showCustomSnackBar(
        getTranslated('background_color_only_text', context) ??
            'Background posts can only contain text',
        context,
        isError: true,
      );
      return;
    }
    if (_images.isNotEmpty) {
      showCustomSnackBar(
        getTranslated('remove_images_before_adding_video', context) ??
            'Remove images before adding a video',
        context,
        isError: true,
      );
      return;
    }
    final XFile? file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (!mounted || file == null) return;
    setState(() {
      _video = file;
    });
  }

  void _removeImage(int index) {
    if (_submitting) return;
    setState(() {
      _images.removeAt(index);
    });
  }

  void _removeVideo() {
    if (_submitting) return;
    setState(() {
      _video = null;
    });
  }

  void _clearFeelingSelection() {
    if (_submitting) return;
    if (!SocialFeelingHelper.hasSelection(
      _selectedFeelingType,
      _selectedFeelingValue,
    )) {
      return;
    }
    setState(() {
      _selectedFeelingType = null;
      _selectedFeelingValue = null;
    });
  }

  Future<void> _startLiveVideo() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);
    try {
      final SocialController sc = context.read<SocialController>();
      final String? accessToken = sc.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        showCustomSnackBar(
          'Unable to start live stream: missing access token.',
          context,
          isError: true,
        );
        return;
      }

      final int provisionalUid =
          DateTime.now().millisecondsSinceEpoch.remainder(1000000);

      final Map<String, dynamic> session =
          await sc.createLiveSession(broadcasterUid: provisionalUid);

      if (!mounted) return;

      final Map<String, dynamic>? postData =
          session['post_data'] as Map<String, dynamic>?;

      final String? streamName =
          (session['stream_name'] ?? postData?['stream_name'])?.toString();

      if (streamName == null || streamName.isEmpty) {
        showCustomSnackBar(
          'Live API did not return a stream name.',
          context,
          isError: true,
        );
        return;
      }

      final String? token = session['token']?.toString();
      final String? postId = postData?['post_id']?.toString();
      final int broadcasterUid =
          int.tryParse(session['uid']?.toString() ?? '') ?? provisionalUid;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveScreen(
            streamName: streamName,
            accessToken: accessToken,
            broadcasterUid: broadcasterUid,
            initialToken: token,
            postId: postId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar('Failed to start live: $e', context, isError: true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _clearBackgroundSelection() {
    if (_submitting || !_hasBackground) return;
    setState(() {
      _selectedBackgroundId = null;
    });
  }

  Future<void> _openLocationInput() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    final TextEditingController controller =
        TextEditingController(text: _selectedLocation ?? '');
    final ThemeData theme = Theme.of(context);
    final String title =
        getTranslated('select_location', context) ?? 'Select location';
    final String hint = getTranslated('add_the_location_correctly', context) ??
        'Enter the location';
    final String cancel = getTranslated('cancel', context) ?? 'Cancel';
    final String save =
        getTranslated('save_location', context) ?? 'Save location';

    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setModalState) {
              final String trimmed = controller.text.trim();
              final bool canSave = trimmed.isNotEmpty;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: hint,
                      prefixIcon: const Icon(Icons.place_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                    onSubmitted: (_) {
                      final String value = controller.text.trim();
                      if (value.isEmpty) return;
                      Navigator.of(ctx).pop(value);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(cancel),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: canSave
                            ? () =>
                                Navigator.of(ctx).pop(controller.text.trim())
                            : null,
                        child: Text(save),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    if (result == null) return;
    final String trimmed = result.trim();
    setState(() {
      _selectedLocation = trimmed.isEmpty ? null : trimmed;
    });
  }

  void _clearSelectedLocation() {
    if (_submitting || !_hasLocation) return;
    setState(() {
      _selectedLocation = null;
    });
  }

  Future<void> _openBackgroundPicker() async {
    if (_images.isNotEmpty || _video != null) {
      showCustomSnackBar(
        getTranslated('background_color_only_text', context) ??
            'Background posts can only contain text',
        context,
        isError: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final TextEditingController controller =
        TextEditingController(text: _textController.text);
    String selectedId = _selectedBackgroundId ??
        (PostBackgroundPresets.presets.isNotEmpty
            ? PostBackgroundPresets.presets.first.id
            : '1');
    final _BackgroundPickerResult? result =
        await showModalBottomSheet<_BackgroundPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setModalState) {
              final ThemeData theme = Theme.of(ctx);
              final PostBackgroundPreset preset =
                  PostBackgroundPresets.findById(selectedId) ??
                      PostBackgroundPresets.presets.first;
              final bool canSave = controller.text.trim().isNotEmpty;
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            getTranslated('select_background_color', context) ??
                                'Select background',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_hasBackground)
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(
                              _BackgroundPickerResult(
                                null,
                                controller.text.trim(),
                              ),
                            ),
                            child: Text(
                              getTranslated('remove_background', context) ??
                                  'Remove',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        gradient: preset.gradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: 5,
                        minLines: 3,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: preset.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: preset.textColor,
                        decoration: InputDecoration(
                          hintText: getTranslated(
                                'post_background_hint',
                                context,
                              ) ??
                              'Share something...',
                          hintStyle: TextStyle(
                            color: preset.textColor.withOpacity(.7),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: PostBackgroundPresets.presets
                          .map(
                            (PostBackgroundPreset option) => GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedId = option.id;
                                });
                              },
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  gradient: option.gradient,
                                  borderRadius: BorderRadius.circular(16),
                                  border: selectedId == option.id
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 3,
                                        )
                                      : null,
                                ),
                                child: selectedId == option.id
                                    ? Icon(
                                        Icons.check,
                                        color: option.textColor,
                                      )
                                    : null,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                              getTranslated('cancel', context) ?? 'Cancel'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: canSave
                              ? () => Navigator.of(ctx).pop(
                                    _BackgroundPickerResult(
                                      selectedId,
                                      controller.text.trim(),
                                    ),
                                  )
                              : null,
                          child: Text(
                            getTranslated('apply_background', context) ??
                                'Apply',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    if (result == null) return;
    setState(() {
      _selectedBackgroundId = result.backgroundId;
      final String trimmed = result.text.trim();
      _textController
        ..text = trimmed
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: trimmed.length),
        );
    });
  }

  bool get _hasContent {
    final bool hasFeeling = SocialFeelingHelper.hasSelection(
      _selectedFeelingType,
      _selectedFeelingValue,
    );
    return _textController.text.trim().isNotEmpty ||
        _images.isNotEmpty ||
        _video != null ||
        hasFeeling ||
        _hasLocation;
  }

  bool get _hasLocation =>
      _selectedLocation != null && _selectedLocation!.trim().isNotEmpty;
  bool get _hasBackground => _selectedBackgroundId != null;
  PostBackgroundPreset? get _backgroundPreset =>
      PostBackgroundPresets.findById(_selectedBackgroundId);

  bool get _shouldShowMentionSuggestions =>
      _mentionStartIndex >= 0 &&
      _textFocusNode.hasFocus &&
      (_mentionLoading ||
          _mentionSuggestions.isNotEmpty ||
          _mentionPromptVisible);

  Future<void> _submit() async {
    if (!_hasContent || _submitting) {
      showCustomSnackBar(
        getTranslated('post_content_required', context) ??
            'Please add something to your post',
        context,
        isError: true,
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final SocialController sc = context.read<SocialController>();

      final SocialPost? created = await sc.createPost(
        text: _textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : null,
        imagePaths:
            _video == null ? _images.map((XFile f) => f.path).toList() : null,
        videoPath: _video?.path,
        privacy: _privacy,
        feelingType: _selectedFeelingType,
        feelingValue: _selectedFeelingValue?.trim(),
        groupId: widget.groupId,
        postMap: _selectedLocation?.trim(),
        backgroundColorId: _selectedBackgroundId,
      );
      if (mounted && created != null) {
        Navigator.of(context).pop<SocialPost>(created);
      }
    } catch (_) {
      // Errors are surfaced via showCustomSnackBar inside controller if any.
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ProfileModel? profile =
        context.watch<ProfileController>().userInfoModel;
    final social = context.watch<SocialController>();
    final socialUser = social.currentUser;
    final List<_PrivacyOption> privacyChoices = _buildPrivacyOptions(context);
    final _PrivacyOption selectedPrivacy = privacyChoices.firstWhere(
      (opt) => opt.value == _privacy,
      orElse: () => privacyChoices.first,
    );

    final List<_ComposeAction> actions = [
      _ComposeAction(
        icon: Icons.photo_library_outlined,
        color: Colors.green,
        label: getTranslated('photos_videos', context) ?? 'Photos/Videos',
        onTap: _onPickMedia,
      ),
      _ComposeAction(
        icon: Icons.person_add_alt_1_outlined,
        color: Colors.lightBlue,
        label: getTranslated('tag_people', context) ?? 'Tag people',
        onTap: _openMentionSuggestions,
      ),
      _ComposeAction(
        icon: Icons.emoji_emotions_outlined,
        color: Colors.orange,
        label:
            getTranslated('feelings_activity', context) ?? 'Feeling/Activity',
        onTap: _openFeelingPicker,
      ),
      _ComposeAction(
        icon: Icons.place_outlined,
        color: Colors.redAccent,
        label: getTranslated('check_in', context) ?? 'Check in',
        onTap: _openLocationInput,
      ),
      _ComposeAction(
        icon: Icons.videocam_outlined,
        color: Colors.purple,
        label: getTranslated('live_video', context) ?? 'Live video',
        onTap: _startLiveVideo,
      ),
      _ComposeAction(
        icon: Icons.format_color_fill_outlined,
        color: Colors.teal,
        label: getTranslated('background_color', context) ?? 'Background color',
        onTap: _openBackgroundPicker,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _submitting
              ? null
              : () {
                  Navigator.of(context).maybePop();
                },
        ),
        title: Text(getTranslated('create_post', context) ?? 'Create post'),
        actions: [
          TextButton(
            onPressed: _submitting || !_hasContent ? null : _submit,
            child: _submitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(getTranslated('post_action', context) ?? 'Post'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComposerHeader(
                      socialUser,
                      profile,
                      privacyChoices,
                      selectedPrivacy,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(theme),
                    if (SocialFeelingHelper.hasSelection(
                      _selectedFeelingType,
                      _selectedFeelingValue,
                    )) ...[
                      const SizedBox(height: 12),
                      _buildSelectedFeeling(theme),
                    ],
                    if (_hasLocation) ...[
                      const SizedBox(height: 12),
                      _buildSelectedLocation(theme),
                    ],
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildImagesPreview(theme),
                    ],
                    if (_video != null) ...[
                      const SizedBox(height: 16),
                      _buildVideoPreview(theme),
                    ],
                  ],
                ),
              ),
            ),
            _buildActionsList(actions, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerHeader(
    SocialUser? user,
    ProfileModel? profile,
    List<_PrivacyOption> options,
    _PrivacyOption selectedPrivacy,
    ThemeData theme,
  ) {
    final ColorScheme cs = theme.colorScheme;
    final String? avatarUrl = () {
      final candidates = [
        user?.avatarUrl?.trim(),
        profile?.imageFullUrl?.path?.trim(),
        profile?.image?.trim(),
      ];
      for (final value in candidates) {
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }();
    final String? postingGroupName = () {
      if (widget.groupId == null) return null;
      final List<String?> candidates = <String?>[
        widget.groupTitle?.trim(),
        widget.groupName?.trim(),
      ];
      for (final String? value in candidates) {
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: cs.surfaceVariant,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Icon(Icons.person, color: cs.onSurface.withOpacity(.6))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName(user, profile),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (postingGroupName != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_2_outlined, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        postingGroupName,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: .75),
                              fontWeight: FontWeight.w600,
                            ) ??
                            TextStyle(
                              color: cs.onSurface.withValues(alpha: .75),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              _buildPrivacyControl(options, selectedPrivacy, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyControl(
    List<_PrivacyOption> options,
    _PrivacyOption selectedPrivacy,
    ThemeData theme,
  ) {
    final ColorScheme cs = theme.colorScheme;
    return PopupMenuButton<int>(
      initialValue: selectedPrivacy.value,
      onSelected: (int value) {
        setState(() {
          _privacy = value;
        });
      },
      itemBuilder: (BuildContext context) {
        return options
            .map(
              (opt) => PopupMenuItem<int>(
                value: opt.value,
                child: Row(
                  children: [
                    Icon(opt.icon, size: 18, color: cs.onSurface),
                    const SizedBox(width: 8),
                    Text(opt.label),
                  ],
                ),
              ),
            )
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedPrivacy.icon,
              size: 16,
              color: cs.onSurface.withOpacity(.75),
            ),
            const SizedBox(width: 6),
            Text(
              selectedPrivacy.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(.8),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: cs.onSurface.withOpacity(.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(ThemeData theme) {
    final PostBackgroundPreset? preset = _backgroundPreset;
    final InputBorder border = InputBorder.none;
    if (preset != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: preset.gradient,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              textAlign: TextAlign.center,
              maxLines: null,
              decoration: InputDecoration(
                border: border,
                hintText: getTranslated('post_background_hint', context) ??
                    'Share something...',
                hintStyle: theme.textTheme.titleLarge?.copyWith(
                  color: preset.textColor.withOpacity(.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                color: preset.textColor,
                fontWeight: FontWeight.w700,
              ),
              cursorColor: preset.textColor,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          if (_shouldShowMentionSuggestions) _buildMentionSuggestions(theme),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _submitting ? null : _clearBackgroundSelection,
              icon: const Icon(Icons.close),
              label: Text(
                getTranslated('remove_background', context) ??
                    'Remove background',
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _textController,
          focusNode: _textFocusNode,
          maxLines: null,
          minLines: 5,
          decoration: InputDecoration(
            hintText: getTranslated('whats_on_your_mind', context) ??
                "What's on your mind?",
            border: InputBorder.none,
          ),
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
        ),
        if (_shouldShowMentionSuggestions) _buildMentionSuggestions(theme),
      ],
    );
  }

  Widget _buildSelectedFeeling(ThemeData theme) {
    final String type = _selectedFeelingType!;
    final String value = _selectedFeelingValue!;
    final ColorScheme cs = theme.colorScheme;
    final String? emoji =
        SocialFeelingHelper.emojiForValue(type, _selectedFeelingValue);
    final IconData icon = SocialFeelingHelper.iconForType(type);
    final String label = SocialFeelingHelper.buildLabel(
      context,
      type,
      value,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (emoji != null)
            Text(
              emoji,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
            )
          else
            Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: getTranslated('remove', context) ?? 'Remove',
            onPressed: _submitting ? null : _clearFeelingSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedLocation(ThemeData theme) {
    final ColorScheme cs = theme.colorScheme;
    final String location = _selectedLocation ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.place, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              location,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: getTranslated('remove', context) ?? 'Remove',
            onPressed: _submitting ? null : _clearSelectedLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildImagesPreview(ThemeData theme) {
    final ColorScheme cs = theme.colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List<Widget>.generate(_images.length, (int index) {
        final XFile file = _images[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(file.path),
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => _removeImage(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(.8),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: cs.onSurface),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoPreview(ThemeData theme) {
    final ColorScheme cs = theme.colorScheme;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam,
                      size: 40, color: cs.onSurface.withOpacity(.7)),
                  const SizedBox(height: 8),
                  Text(
                    getTranslated('selected_video', context) ??
                        'Selected video',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: _removeVideo,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.close, size: 18, color: cs.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList(List<_ComposeAction> actions, ThemeData theme) {
    final ColorScheme cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((action) {
          return InkWell(
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: action.color.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(action.icon, color: action.color),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    action.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_PrivacyOption> _buildPrivacyOptions(BuildContext ctx) {
    return [
      _PrivacyOption(
        value: 0,
        label: getTranslated('privacy_public', ctx) ?? 'Public',
        icon: Icons.public,
      ),
      _PrivacyOption(
        value: 1,
        label: getTranslated('privacy_friends', ctx) ?? 'Friends',
        icon: Icons.people,
      ),
      _PrivacyOption(
        value: 2,
        label: getTranslated('privacy_only_me', ctx) ?? 'Only me',
        icon: Icons.lock,
      ),
    ];
  }

  Future<void> _openFeelingPicker() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    final _FeelingPickerResult? result =
        await showModalBottomSheet<_FeelingPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return _FeelingPickerSheet(
          initialType: _selectedFeelingType,
          initialValue: _selectedFeelingValue,
        );
      },
    );
    if (!mounted || result == null) return;
    if (result.cleared) {
      setState(() {
        _selectedFeelingType = null;
        _selectedFeelingValue = null;
      });
      return;
    }
    final String? type = result.type;
    final String? value = result.value;
    if (!SocialFeelingHelper.hasSelection(type, value)) {
      return;
    }
    setState(() {
      _selectedFeelingType = type;
      _selectedFeelingValue = value!.trim();
    });
  }

  void _showComingSoon(String featureKey) {
    final String feature = getTranslated(featureKey, context) ?? featureKey;
    final String template = getTranslated('feature_in_development', context) ??
        '"{feature}" is being developed';
    final String message = template.replaceAll('{feature}', feature);
    showCustomSnackBar(message, context, isError: false);
  }

  void _openMentionSuggestions() {
    FocusScope.of(context).requestFocus(_textFocusNode);
    final TextSelection selection = _textController.selection;
    final String text = _textController.text;
    int cursor;
    if (!selection.isValid) {
      cursor = text.length;
    } else if (selection.isCollapsed) {
      cursor = selection.baseOffset;
    } else {
      cursor = selection.extentOffset;
    }
    cursor = cursor.clamp(0, text.length);

    final bool hasAtBefore =
        cursor > 0 && text.substring(cursor - 1, cursor) == '@';
    if (!hasAtBefore) {
      final bool needsSpace =
          cursor > 0 && text.substring(cursor - 1, cursor).trim().isNotEmpty;
      final String insertion = '${needsSpace ? ' ' : ''}@';
      final String updated = text.replaceRange(cursor, cursor, insertion);
      final int newCursor = cursor + insertion.length;
      _textController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    }
    setState(() {
      _mentionPromptVisible = true;
    });
  }

  void _handleTextFocusChange() {
    if (!_textFocusNode.hasFocus) {
      _resetMentionTracking();
    }
  }

  void _handleTextChanged() {
    if (!mounted) return;
    final TextSelection selection = _textController.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      _resetMentionTracking();
      return;
    }
    final int cursor = selection.baseOffset;
    if (cursor <= 0 || cursor > _textController.text.length) {
      _resetMentionTracking();
      return;
    }
    final _MentionToken? token =
        _resolveMentionToken(_textController.text, cursor);
    if (token == null) {
      _resetMentionTracking();
      return;
    }
    final String query = token.query;
    final bool queryChanged = query != _currentMentionQuery;
    _mentionStartIndex = token.start;
    if (!queryChanged) {
      if (query.isEmpty && !_mentionPromptVisible && mounted) {
        setState(() {
          _mentionPromptVisible = true;
        });
      }
      return;
    }
    _currentMentionQuery = query;
    _mentionDebounce?.cancel();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _mentionPromptVisible = true;
          _mentionSuggestions = const <SocialUser>[];
          _mentionLoading = false;
        });
      }
      return;
    }
    setState(() {
      _mentionPromptVisible = false;
      _mentionLoading = true;
      _mentionSuggestions = const <SocialUser>[];
    });
    _mentionDebounce = Timer(const Duration(milliseconds: 250), () {
      _fetchMentionSuggestions(query);
    });
  }

  Future<void> _fetchMentionSuggestions(String query) async {
    final String currentQuery = query;
    final SocialController controller = context.read<SocialController>();
    try {
      final List<SocialUser> results =
          await controller.searchMentionUsers(keyword: currentQuery, limit: 8);
      if (!mounted) return;
      if (_currentMentionQuery != currentQuery) return;
      setState(() {
        _mentionPromptVisible = false;
        _mentionSuggestions = results;
        _mentionLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_currentMentionQuery != currentQuery) return;
      setState(() {
        _mentionPromptVisible = true;
        _mentionSuggestions = const <SocialUser>[];
        _mentionLoading = false;
      });
    }
  }

  void _resetMentionTracking() {
    final bool hasState = _mentionStartIndex != -1 ||
        _mentionSuggestions.isNotEmpty ||
        _mentionLoading ||
        _currentMentionQuery.isNotEmpty;
    if (!hasState) return;
    _mentionDebounce?.cancel();
    if (!mounted) {
      _mentionSuggestions = const <SocialUser>[];
      _mentionLoading = false;
      _mentionStartIndex = -1;
      _currentMentionQuery = '';
      _mentionPromptVisible = false;
      return;
    }
    setState(() {
      _mentionSuggestions = const <SocialUser>[];
      _mentionLoading = false;
      _mentionStartIndex = -1;
      _currentMentionQuery = '';
      _mentionPromptVisible = false;
    });
  }

  _MentionToken? _resolveMentionToken(String text, int cursor) {
    final int safeCursor = cursor.clamp(0, text.length);
    int index = safeCursor - 1;
    while (index >= 0) {
      final String char = text[index];
      if (char == '@') {
        final bool validPrefix =
            index == 0 || !_isUsernameChar(text[index - 1]);
        if (!validPrefix) {
          return null;
        }
        final String query = text.substring(index + 1, safeCursor);
        if (_isValidMentionQuery(query)) {
          return _MentionToken(start: index, query: query);
        }
        return null;
      }
      if (!_isUsernameChar(char)) {
        break;
      }
      index--;
    }
    return null;
  }

  bool _isUsernameChar(String char) {
    if (char.isEmpty) return false;
    final int code = char.codeUnitAt(0);
    if (code >= 48 && code <= 57) return true; // 0-9
    if (code >= 65 && code <= 90) return true; // A-Z
    if (code >= 97 && code <= 122) return true; // a-z
    return char == '_' || char == '.';
  }

  bool _isValidMentionQuery(String query) {
    if (query.isEmpty) return true;
    final RegExp pattern = RegExp(r'^[A-Za-z0-9_.]+$');
    return pattern.hasMatch(query);
  }

  void _handleMentionTap(SocialUser user) {
    final String? username = user.userName?.trim();
    if (username == null || username.isEmpty) return;
    final String text = _textController.text;
    final int start = _mentionStartIndex.clamp(0, text.length);
    final int cursor =
        _textController.selection.baseOffset.clamp(0, text.length);
    if (cursor < start) return;
    final String before = text.substring(0, start);
    final String after = text.substring(cursor);
    final String mentionText = '@$username';
    final String insertion = '$mentionText ';
    final String updated = '$before$insertion$after';
    final int newCursor = (before + insertion).length;
    _textController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _resetMentionTracking();
    FocusScope.of(context).requestFocus(_textFocusNode);
  }

  Widget _buildMentionSuggestions(ThemeData theme) {
    final ColorScheme cs = theme.colorScheme;
    final List<SocialUser> suggestions = _mentionSuggestions;
    final bool showPrompt =
        _mentionPromptVisible && !_mentionLoading && suggestions.isEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: _mentionLoading && suggestions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
              ),
            )
          : showPrompt
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    getTranslated('start_typing_to_tag', context) ??
                        'Start typing to tag someone…',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              : suggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        getTranslated('no_results_found', context) ??
                            'No matches found',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        final SocialUser user = suggestions[index];
                        final String? avatar = user.avatarUrl;
                        final String displayName =
                            user.displayName?.trim().isNotEmpty == true
                                ? user.displayName!.trim()
                                : (user.userName?.trim().isNotEmpty == true
                                    ? user.userName!.trim()
                                    : user.id);
                        final String? username = user.userName?.trim();
                        return ListTile(
                          dense: true,
                          onTap: () => _handleMentionTap(user),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: cs.surfaceVariant,
                            backgroundImage:
                                (avatar != null && avatar.isNotEmpty)
                                    ? NetworkImage(avatar)
                                    : null,
                            child: (avatar == null || avatar.isEmpty)
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : '?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: (username != null && username.isNotEmpty)
                              ? Text(
                                  '@$username',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                )
                              : null,
                        );
                      },
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 0.6,
                        color: cs.outline.withOpacity(.1),
                      ),
                      itemCount: suggestions.length,
                    ),
    );
  }

  String _displayName(SocialUser? user, ProfileModel? profile) {
    final String? socialName = user?.displayName?.trim();
    if (socialName != null && socialName.isNotEmpty) {
      return socialName;
    }
    final String? socialUsername = user?.userName?.trim();
    if (socialUsername != null && socialUsername.isNotEmpty) {
      return socialUsername;
    }
    if (profile != null) {
      final String first = profile.fName?.trim() ?? '';
      final String last = profile.lName?.trim() ?? '';
      final String combined =
          [first, last].where((part) => part.isNotEmpty).join(' ').trim();
      if (combined.isNotEmpty) return combined;
      final String name = profile.name?.trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    return getTranslated('social_user_placeholder', context) ?? 'User';
  }
}

class _FeelingPickerResult {
  final String? type;
  final String? value;
  final bool cleared;

  const _FeelingPickerResult._({
    required this.type,
    required this.value,
    required this.cleared,
  });

  const _FeelingPickerResult.selection({
    required String type,
    required String value,
  }) : this._(type: type, value: value, cleared: false);

  const _FeelingPickerResult.cleared()
      : this._(type: null, value: null, cleared: true);
}

class _FeelingPickerSheet extends StatefulWidget {
  final String? initialType;
  final String? initialValue;

  const _FeelingPickerSheet({
    required this.initialType,
    required this.initialValue,
  });

  @override
  State<_FeelingPickerSheet> createState() => _FeelingPickerSheetState();
}

class _FeelingPickerSheetState extends State<_FeelingPickerSheet> {
  late String _currentType;
  String? _selectedFeeling;
  late final TextEditingController _textController;
  final FocusNode _textFocusNode = FocusNode();

  bool get _isTextCategory => _currentType != SocialFeelingType.feelings;

  @override
  void initState() {
    super.initState();
    final String? initialType = widget.initialType;
    final String? initialValue = widget.initialValue;
    _currentType = SocialFeelingType.contains(initialType)
        ? initialType!
        : SocialFeelingType.feelings;
    _selectedFeeling =
        _currentType == SocialFeelingType.feelings ? initialValue : null;
    _textController = TextEditingController(
      text: _isTextCategory ? (initialValue ?? '') : '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  String? get _currentValue {
    if (_currentType == SocialFeelingType.feelings) {
      return _selectedFeeling;
    }
    return _textController.text.trim();
  }

  bool get _canSubmit {
    final String? value = _currentValue;
    return value != null && value.trim().isNotEmpty;
  }

  void _selectCategory(String type) {
    if (_currentType == type) return;
    setState(() {
      _currentType = type;
      if (_currentType == SocialFeelingType.feelings) {
        _selectedFeeling = widget.initialType == SocialFeelingType.feelings
            ? widget.initialValue
            : null;
        _textController.clear();
      } else {
        _selectedFeeling = null;
        final bool restorePrevious =
            widget.initialType == type && widget.initialValue != null;
        _textController.text =
            restorePrevious ? widget.initialValue!.trim() : '';
      }
    });
    if (_currentType == SocialFeelingType.feelings) {
      _textFocusNode.unfocus();
    } else {
      FocusScope.of(context).requestFocus(_textFocusNode);
    }
  }

  void _selectFeeling(String value) {
    setState(() {
      _selectedFeeling = value;
    });
  }

  void _submit() {
    final String? value = _currentValue;
    if (value == null || value.isEmpty) return;
    Navigator.of(context).pop(
      _FeelingPickerResult.selection(
        type: _currentType,
        value: value.trim(),
      ),
    );
  }

  void _clearSelection() {
    Navigator.of(context).pop(const _FeelingPickerResult.cleared());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    final bool showClear = SocialFeelingHelper.hasSelection(
        widget.initialType, widget.initialValue);

    final List<Widget> categoryChips =
        socialFeelingCategories.map((SocialFeelingCategoryOption option) {
      final bool selected = option.type == _currentType;
      final String label =
          getTranslated(option.labelKey, context) ?? option.defaultLabel;
      return ChoiceChip(
        avatar: Icon(option.icon, size: 18),
        label: Text(label),
        selected: selected,
        onSelected: (_) => _selectCategory(option.type),
      );
    }).toList();

    final Widget valueInput = _currentType == SocialFeelingType.feelings
        ? _buildFeelingsWrap(theme)
        : _buildTextCategoryField(theme);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withOpacity(.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                getTranslated('feeling_picker_title', context) ??
                    'How are you feeling?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoryChips,
              ),
              const SizedBox(height: 20),
              valueInput,
              const SizedBox(height: 24),
              Row(
                children: [
                  if (showClear)
                    TextButton(
                      onPressed: _clearSelection,
                      child: Text(
                        getTranslated('remove', context) ?? 'Remove',
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(getTranslated('cancel', context) ?? 'Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: Text(getTranslated('done', context) ?? 'Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeelingsWrap(ThemeData theme) {
    final ColorScheme cs = theme.colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: socialFeelingOptions.map((SocialFeelingOption option) {
        final bool selected = option.value == _selectedFeeling;
        final String? emoji =
            SocialFeelingConstants.emojiForFeeling(option.value);
        return ChoiceChip(
          avatar: emoji != null
              ? Text(
                  emoji,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                )
              : const Icon(Icons.emoji_emotions_outlined, size: 18),
          label: Text(option.label),
          selected: selected,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          selectedColor: cs.primary.withOpacity(.15),
          onSelected: (_) => _selectFeeling(option.value),
        );
      }).toList(),
    );
  }

  Widget _buildTextCategoryField(ThemeData theme) {
    return TextField(
      controller: _textController,
      focusNode: _textFocusNode,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: getTranslated('feeling_picker_input_hint', context) ??
            'Describe it...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
    );
  }
}

class _PrivacyOption {
  final int value;
  final String label;
  final IconData icon;

  const _PrivacyOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class _ComposeAction {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ComposeAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
}

class _MentionToken {
  final int start;
  final String query;

  const _MentionToken({
    required this.start,
    required this.query,
  });
}

class _BackgroundPickerResult {
  final String? backgroundId;
  final String text;

  const _BackgroundPickerResult(this.backgroundId, this.text);
}
