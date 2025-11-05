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

  bool get _hasContent {
    return _textController.text.trim().isNotEmpty ||
        _images.isNotEmpty ||
        _video != null;
  }

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
        groupId: widget.groupId,
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
        onTap: () => _showComingSoon('feelings_activity'),
      ),
      _ComposeAction(
        icon: Icons.place_outlined,
        color: Colors.redAccent,
        label: getTranslated('check_in', context) ?? 'Check in',
        onTap: () => _showComingSoon('check_in'),
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
        onTap: () => _showComingSoon('background_color'),
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
