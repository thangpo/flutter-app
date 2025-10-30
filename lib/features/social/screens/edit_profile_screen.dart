import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';

/// Màn hình chỉnh sửa thông tin cá nhân.
/// - Hiển thị cover, avatar
/// - Cho phép sửa các trường cơ bản
/// - Gọi onSave khi ấn Lưu
class EditProfileScreen extends StatefulWidget {
  final SocialUserProfile profile;
  final ValueChanged<SocialUserProfile> onSave;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _displayNameCtrl;
  late TextEditingController _aboutCtrl;
  late TextEditingController _workCtrl;
  late TextEditingController _educationCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _birthdayCtrl;
  late TextEditingController _genderCtrl;
  late TextEditingController _relationshipCtrl;

  String? _avatarUrlPreview;
  String? _coverUrlPreview;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final p = widget.profile;

    _displayNameCtrl    = TextEditingController(text: p.displayName ?? '');
    _aboutCtrl          = TextEditingController(text: p.about ?? '');
    _workCtrl           = TextEditingController(text: p.work ?? '');
    _educationCtrl      = TextEditingController(text: p.education ?? '');
    _cityCtrl           = TextEditingController(text: p.city ?? '');
    _countryCtrl        = TextEditingController(text: p.country ?? '');
    _websiteCtrl        = TextEditingController(text: p.website ?? '');
    _birthdayCtrl       = TextEditingController(text: p.birthday ?? '');
    _genderCtrl         = TextEditingController(text: p.genderText ?? '');
    _relationshipCtrl   = TextEditingController(text: p.relationshipStatus ?? '');

    _avatarUrlPreview   = p.avatarUrl;
    _coverUrlPreview    = p.coverUrl;
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _aboutCtrl.dispose();
    _workCtrl.dispose();
    _educationCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _websiteCtrl.dispose();
    _birthdayCtrl.dispose();
    _genderCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  void _pickCover() async {
    // TODO: mở image picker, upload tạm, cập nhật preview
    // final newUrl = await pickImageAndUpload();
    // setState(() { _coverUrlPreview = newUrl; });
  }

  void _pickAvatar() async {
    // TODO: mở image picker, upload tạm, cập nhật preview
    // final newUrl = await pickImageAndUpload();
    // setState(() { _avatarUrlPreview = newUrl; });
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });

    // tạo object mới
    final updated = widget.profile.copyWith(
      displayName: _displayNameCtrl.text.trim().isNotEmpty
          ? _displayNameCtrl.text.trim()
          : widget.profile.displayName,
      about: _aboutCtrl.text.trim(),
      work: _workCtrl.text.trim(),
      education: _educationCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      birthday: _birthdayCtrl.text.trim(),
      genderText: _genderCtrl.text.trim(),
      relationshipStatus: _relationshipCtrl.text.trim(),
      avatarUrl: _avatarUrlPreview ?? widget.profile.avatarUrl,
      coverUrl: _coverUrlPreview ?? widget.profile.coverUrl,
    );

    widget.onSave(updated);

    if (mounted) {
      setState(() {
        _saving = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor.withOpacity(.4);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa trang cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _handleSave,
            child: _saving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              'Lưu',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // COVER + AVATAR
            _CoverAndAvatarEditor(
              coverUrl: _coverUrlPreview,
              avatarUrl: _avatarUrlPreview,
              onTapCover: _pickCover,
              onTapAvatar: _pickAvatar,
            ),

            const SizedBox(height: 24),

            // THÔNG TIN CƠ BẢN
            _SectionHeader(
              title: 'Thông tin cơ bản',
              subtitle: 'Tên hiển thị và mô tả ngắn về bạn',
            ),
            _LabeledField(
              label: 'Tên hiển thị',
              controller: _displayNameCtrl,
              hint: 'VD: Nguyễn Văn A',
              textInputAction: TextInputAction.next,
            ),
            _LabeledField(
              label: 'Giới thiệu / About',
              controller: _aboutCtrl,
              hint: 'Mô tả ngắn về bạn, công việc, sở thích...',
              maxLines: 3,
            ),

            _SeparatorLine(color: dividerColor),

            // CÔNG VIỆC & HỌC VẤN
            _SectionHeader(
              title: 'Công việc & Học vấn',
              subtitle: 'Những gì bạn đang làm và đã học',
            ),
            _LabeledField(
              label: 'Công việc hiện tại',
              controller: _workCtrl,
              hint: 'VD: Kinh doanh online / Lập trình viên Flutter ...',
              textInputAction: TextInputAction.next,
              icon: Icons.work_outline,
            ),
            _LabeledField(
              label: 'Học vấn',
              controller: _educationCtrl,
              hint: 'VD: ĐH Thủy Lợi / Tự học...',
              textInputAction: TextInputAction.next,
              icon: Icons.school_outlined,
            ),

            _SeparatorLine(color: dividerColor),

            // LIÊN HỆ & ĐỊA CHỈ
            _SectionHeader(
              title: 'Liên hệ & Địa chỉ',
              subtitle: 'Nơi bạn đang sống và có thể liên hệ',
            ),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Thành phố',
                    controller: _cityCtrl,
                    hint: 'VD: Hà Nội',
                    textInputAction: TextInputAction.next,
                    icon: Icons.location_city_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Quốc gia',
                    controller: _countryCtrl,
                    hint: 'VD: Việt Nam',
                    textInputAction: TextInputAction.next,
                    icon: Icons.public,
                  ),
                ),
              ],
            ),
            _LabeledField(
              label: 'Website / Link cá nhân',
              controller: _websiteCtrl,
              hint: 'https://...',
              textInputAction: TextInputAction.next,
              icon: Icons.link,
              keyboardType: TextInputType.url,
            ),

            _SeparatorLine(color: dividerColor),

            // THÔNG TIN CÁ NHÂN
            _SectionHeader(
              title: 'Thông tin cá nhân',
              subtitle: 'Ngày sinh, giới tính, mối quan hệ',
            ),
            _LabeledField(
              label: 'Ngày sinh',
              controller: _birthdayCtrl,
              hint: 'VD: 01/01/2000',
              textInputAction: TextInputAction.next,
              icon: Icons.cake_outlined,
              readOnly: false,
            ),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Giới tính',
                    controller: _genderCtrl,
                    hint: 'Nam / Nữ / Khác...',
                    textInputAction: TextInputAction.next,
                    icon: Icons.wc_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Tình trạng mối quan hệ',
                    controller: _relationshipCtrl,
                    hint: 'Độc thân / Đang hẹn hò / ...',
                    textInputAction: TextInputAction.done,
                    icon: Icons.favorite_border,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// ==============================
/// Widget chọn / xem cover + avatar
/// ==============================
class _CoverAndAvatarEditor extends StatelessWidget {
  final String? coverUrl;
  final String? avatarUrl;
  final VoidCallback onTapCover;
  final VoidCallback onTapAvatar;

  const _CoverAndAvatarEditor({
    required this.coverUrl,
    required this.avatarUrl,
    required this.onTapCover,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // COVER (bìa)
          Positioned.fill(
            child: InkWell(
              onTap: onTapCover,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null && coverUrl!.isNotEmpty)
                    Image.network(
                      coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _CoverPlaceholder(),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    )
                  else
                    const _CoverPlaceholder(),

                  // lớp mờ + icon camera
                  Container(
                    color: Colors.black26,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.all(8),
                    child: const _CircleBgIcon(
                      icon: Icons.camera_alt_outlined,
                      tooltip: 'Đổi ảnh bìa',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AVATAR
          Positioned(
            left: 16,
            bottom: -40,
            child: InkWell(
              onTap: onTapAvatar,
              borderRadius: BorderRadius.circular(60),
              child: SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ảnh avatar + viền trắng + shadow
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const _AvatarPlaceholder(),
                        )
                            : const _AvatarPlaceholder(),
                      ),
                    ),

                    // lớp tối trong suốt phủ lên avatar (KHÔNG borderRadius)
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black26,
                      ),
                    ),

                    // icon camera nhỏ ở giữa
                    const _CircleBgIcon(
                      icon: Icons.camera_alt_outlined,
                      tooltip: 'Đổi ảnh đại diện',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // spacer để không bị cắt avatar
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(height: 40),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBgIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  const _CircleBgIcon({required this.icon, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          // LƯU Ý: KHÔNG dùng shape: BoxShape.circle ở đây,
          // vì mình đang bo tròn thủ công bằng borderRadius.
          color: isDark ? Colors.black87 : Colors.white.withOpacity(.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(.2)
                : Colors.black.withOpacity(.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image,
        size: 60,
        color: Colors.white54,
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.dividerColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: 36,
        color: theme.hintColor,
      ),
    );
  }
}

/// ==============================
/// Header nhỏ cho từng block form
/// ==============================
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    TextSpan(
                      text: subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: theme.hintColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==============================
/// Ô nhập có label
/// ==============================
class _LabeledField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final int maxLines;
  final IconData? icon;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.icon,
    this.readOnly = false,
    this.textInputAction,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // label
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          // field
          TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: icon != null
                  ? Icon(icon, size: 20, color: theme.hintColor)
                  : null,
              hintText: hint,
              hintStyle: TextStyle(
                color: theme.hintColor,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.dividerColor.withOpacity(.6),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==============================
/// Đường kẻ ngăn block
/// ==============================
class _SeparatorLine extends StatelessWidget {
  final Color color;
  const _SeparatorLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: color.withOpacity(.4),
    );
  }
}

extension _SocialUserProfileCopy on SocialUserProfile {
  /// helper copyWith vì model SocialUserProfile có thể chưa có sẵn copyWith
  SocialUserProfile copyWith({
    String? id,
    String? displayName,
    String? firstName,
    String? lastName,
    String? userName,
    String? avatarUrl,
    String? coverUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? friendsCount,
    bool? isVerified,
    String? about,
    String? work,
    String? education,
    String? city,
    String? country,
    String? website,
    String? birthday,
    String? relationshipStatus,
    String? genderText,
    String? lastSeenText,
    bool? isFollowing,
    bool? isFollowingMe,
  }) {
    return SocialUserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      friendsCount: friendsCount ?? this.friendsCount,
      isVerified: isVerified ?? this.isVerified,
      about: about ?? this.about,
      work: work ?? this.work,
      education: education ?? this.education,
      city: city ?? this.city,
      country: country ?? this.country,
      website: website ?? this.website,
      birthday: birthday ?? this.birthday,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      genderText: genderText ?? this.genderText,
      lastSeenText: lastSeenText ?? this.lastSeenText,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowingMe: isFollowingMe ?? this.isFollowingMe,
    );
  }
}
