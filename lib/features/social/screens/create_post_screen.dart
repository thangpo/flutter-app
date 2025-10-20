import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';

class SocialCreatePostScreen extends StatefulWidget {
  const SocialCreatePostScreen({super.key});

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
                title: const Text('Thêm ảnh'),
                onTap: () => Navigator.of(ctx).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Thêm video'),
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
        'Đã chọn video, hãy gỡ video trước khi thêm ảnh.',
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
        'Đã chọn ảnh, hãy gỡ ảnh trước khi thêm video.',
        context,
        isError: true,
      );
      return;
    }
    final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
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
        'Hãy viết gì đó hoặc thêm nội dung trước khi đăng.',
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
      );
      if (mounted && created != null) {
        Navigator.of(context).pop<SocialPost>(created);
      }
    } catch (_) {
      // Error already surfaced via showCustomSnackBar in controller.
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
    final _PrivacyOption selectedPrivacy = _privacyOptions.firstWhere(
      (opt) => opt.value == _privacy,
      orElse: () => _privacyOptions.first,
    );

    final List<_ComposeAction> actions = [
      _ComposeAction(
        icon: Icons.photo_library_outlined,
        color: Colors.green,
        label: 'Ảnh/video',
        onTap: _onPickMedia,
      ),
      _ComposeAction(
        icon: Icons.person_add_alt_1_outlined,
        color: Colors.lightBlue,
        label: 'Gắn thẻ người khác',
        onTap: () => _showComingSoon('Gắn thẻ người khác'),
      ),
      _ComposeAction(
        icon: Icons.emoji_emotions_outlined,
        color: Colors.orange,
        label: 'Cảm xúc/hoạt động',
        onTap: () => _showComingSoon('Cảm xúc/hoạt động'),
      ),
      _ComposeAction(
        icon: Icons.place_outlined,
        color: Colors.redAccent,
        label: 'Check in',
        onTap: () => _showComingSoon('Check in'),
      ),
      _ComposeAction(
        icon: Icons.videocam_outlined,
        color: Colors.purple,
        label: 'Video trực tiếp',
        onTap: () => _showComingSoon('Video trực tiếp'),
      ),
      _ComposeAction(
        icon: Icons.format_color_fill_outlined,
        color: Colors.teal,
        label: 'Màu nền',
        onTap: () => _showComingSoon('Màu nền'),
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
        title: const Text('Tạo bài viết'),
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
                : const Text('Đăng'),
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
                        socialUser, profile, selectedPrivacy, theme),
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
              const SizedBox(height: 6),
              _buildPrivacyControl(selectedPrivacy, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyControl(_PrivacyOption selectedPrivacy, ThemeData theme) {
    final ColorScheme cs = theme.colorScheme;
    return PopupMenuButton<int>(
      initialValue: selectedPrivacy.value,
      onSelected: (int value) {
        setState(() {
          _privacy = value;
        });
      },
      itemBuilder: (BuildContext context) {
        return _privacyOptions
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
      decoration: const InputDecoration(
        hintText: 'Bạn đang nghĩ gì?',
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
                    'Video đã chọn',
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

  void _showComingSoon(String feature) {
    showCustomSnackBar('$feature đang được phát triển.', context,
        isError: false);
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
    return 'Người dùng';
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

const List<_PrivacyOption> _privacyOptions = [
  _PrivacyOption(value: 0, label: 'Công khai', icon: Icons.public),
  _PrivacyOption(value: 1, label: 'Bạn bè', icon: Icons.people),
  _PrivacyOption(value: 2, label: 'Chỉ mình tôi', icon: Icons.lock),
];

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

