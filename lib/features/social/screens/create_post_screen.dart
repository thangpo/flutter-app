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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = context.read<SocialController>();
      sc.loadCurrentUser();
    });
  }

  @override
  void dispose() {
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

  bool get _hasContent {
    return _textController.text.trim().isNotEmpty ||
        _images.isNotEmpty ||
        _video != null;
  }

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
        onTap: () => _showComingSoon('tag_people'),
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
        onTap: () => _showComingSoon('live_video'),
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
                    Icon(Icons.groups_2_outlined,
                        size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        postingGroupName,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: .75),
                              fontWeight: FontWeight.w600,
                            ) ??
                            TextStyle(
                              color:
                                  cs.onSurface.withValues(alpha: .75),
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
    return TextField(
      controller: _textController,
      maxLines: null,
      minLines: 5,
      decoration: InputDecoration(
        hintText: getTranslated('whats_on_your_mind', context) ??
            "What's on your mind?",
        border: InputBorder.none,
      ),
      style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
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
