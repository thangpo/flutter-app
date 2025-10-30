import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';

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
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _aboutCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _birthdayCtrl;

  // Dropdown
  String? _genderValue; // 'Nam' | 'Nữ' | 'Khác' | null

  // Preview local
  String? _avatarLocalPath;
  String? _coverLocalPath;

  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _displayNameCtrl = TextEditingController(text: p.displayName ?? '');
    _aboutCtrl       = TextEditingController(text: p.about ?? '');
    _addressCtrl     = TextEditingController(text: p.address ?? ''); // chỉ dùng address
    _websiteCtrl     = TextEditingController(text: p.website ?? '');
    _birthdayCtrl    = TextEditingController(text: _toUiDate(p.birthday));
    _genderValue     = _normalizeGender(p.genderText);
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _aboutCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _birthdayCtrl.dispose();
    super.dispose();
  }

  // Pickers (local only)
  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 90,
    );
    if (x == null) return;
    setState(() => _avatarLocalPath = x.path);
  }

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      imageQuality: 90,
    );
    if (x == null) return;
    setState(() => _coverLocalPath = x.path);
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

    final String? displayName = _nullIfEmpty(_displayNameCtrl.text);
    final String? about       = _nullIfEmpty(_aboutCtrl.text);
    final String? address     = _nullIfEmpty(_addressCtrl.text);
    final String? website     = _normalizeWebsite(_websiteCtrl.text.trim());
    final String? birthdayIso = _toIsoDate(_birthdayCtrl.text.trim());
    final String? genderText  = _genderValue;

    try {
      final controller = context.read<SocialController>();

      // Tạo bản sao profile với dữ liệu mới (đánh dấu file local bằng scheme file://)
      final edited = widget.profile.copyWith(
        displayName: displayName,
        about      : about,
        address    : address,
        website    : website,
        birthday   : birthdayIso,
        genderText : genderText,
        avatarUrl  : (_avatarLocalPath != null)
            ? 'file://$_avatarLocalPath'
            : widget.profile.avatarUrl,
        coverUrl   : (_coverLocalPath != null)
            ? 'file://$_coverLocalPath'
            : widget.profile.coverUrl,
      );

      // Gọi controller (non-null)
      final updatedProfile = await controller.updateDataUserFromEdit(edited);

      if (!mounted) return;

      // Trả result về parent
      widget.onSave(updatedProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===== Utils =====
  String _toUiDate(String? iso) {
    if (iso == null || iso.isEmpty || iso == '0000-00-00') return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String? _toIsoDate(String? ui) {
    if (ui == null || ui.isEmpty) return null;
    try {
      final p = ui.split('/');
      if (p.length != 3) return null;
      final d = int.parse(p[0]), m = int.parse(p[1]), y = int.parse(p[2]);
      final dt = DateTime(y, m, d);
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  String? _normalizeWebsite(String? url) {
    if (url == null || url.isEmpty) return null;
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return 'https://$u';
  }

  String? _normalizeGender(String? txt) {
    if (txt == null) return null;
    final s = txt.trim().toLowerCase();
    if (s == 'male' || s == 'm' || s.contains('nam')) return 'Nam';
    if (s == 'female' || s == 'f' || s.contains('nữ')) return 'Nữ';
    if (s.isEmpty) return null;
    return 'Khác';
  }

  bool _isHttp(String? s) =>
      s != null && (s.startsWith('http://') || s.startsWith('https://'));

  bool _isLocalFile(String? s) =>
      s != null && (s.startsWith('/') || s.startsWith('file://'));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor.withOpacity(.4);
    final p = widget.profile;

    final avatarPreview = _avatarLocalPath ?? p.avatarUrl;
    final coverPreview  = _coverLocalPath  ?? p.coverUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa trang cá nhân'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving ? null : () => Navigator.pop(context),
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
                : const Text('Lưu'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover + Avatar
              SizedBox(
                height: 210,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover
                    Positioned.fill(
                      child: InkWell(
                        onTap: _pickCover,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_isHttp(coverPreview))
                              Image.network(
                                coverPreview!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const _CoverPlaceholder(),
                                loadingBuilder: (c, child, p) =>
                                p == null ? child : const Center(child: CircularProgressIndicator()),
                              )
                            else if (_isLocalFile(coverPreview))
                              Image.file(
                                File(coverPreview!.replaceFirst('file://', '')),
                                fit: BoxFit.cover,
                              )
                            else
                              const _CoverPlaceholder(),
                            Container(
                              color: Colors.black26,
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.all(8),
                              child: const _CircleButton(
                                  icon: Icons.camera_alt_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Avatar
                    Positioned(
                      left: 16,
                      bottom: -40,
                      child: InkWell(
                        onTap: _pickAvatar,
                        borderRadius: BorderRadius.circular(60),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: Builder(
                                  builder: (_) {
                                    final src = avatarPreview;
                                    if (_isHttp(src)) {
                                      return Image.network(
                                        src!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                        const _AvatarPlaceholder(),
                                      );
                                    } else if (_isLocalFile(src)) {
                                      return Image.file(
                                        File(src!.replaceFirst('file://', '')),
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return const _AvatarPlaceholder();
                                  },
                                ),
                              ),
                            ),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black26,
                              ),
                            ),
                            const _CircleButton(
                                icon: Icons.camera_alt_outlined),
                          ],
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(height: 40),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------- Thông tin chính --------
              const _SectionHeader(title: 'Thông tin chính'),
              _LabeledField(
                label: 'Tên hiển thị *',
                controller: _displayNameCtrl,
                hint: 'VD: Nguyễn Văn A',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên hiển thị'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              _LabeledField(
                label: 'Giới thiệu',
                controller: _aboutCtrl,
                hint: 'Mô tả ngắn về bạn…',
                maxLines: 3,
              ),

              _SeparatorLine(color: dividerColor),

              // -------- Thông tin cá nhân --------
              const _SectionHeader(title: 'Thông tin cá nhân'),
              _DropdownField(
                label: 'Giới tính',
                value: _genderValue,
                items: const ['Nam', 'Nữ', 'Khác'],
                onChanged: (v) => setState(() => _genderValue = v),
              ),
              _DateField(
                label: 'Ngày sinh',
                controller: _birthdayCtrl,
                hint: 'dd/MM/yyyy',
                onPick: _pickBirthday,
              ),

              _SeparatorLine(color: dividerColor),

              // -------- Liên hệ --------
              const _SectionHeader(title: 'Liên hệ'),
              _LabeledField(
                label: 'Địa chỉ',
                controller: _addressCtrl,
                hint: 'VD: 123 Nguyễn Trãi, Thanh Xuân, Hà Nội',
                textInputAction: TextInputAction.next,
              ),
              _LabeledField(
                label: 'Website',
                controller: _websiteCtrl,
                hint: 'https://...',
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    DateTime init = DateTime(now.year - 20, now.month, now.day);
    final iso = _toIsoDate(_birthdayCtrl.text.trim());
    if (iso != null) {
      try {
        init = DateTime.parse(iso);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      _birthdayCtrl.text =
      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }
}

// ---------- UI pieces ----------
class _CircleButton extends StatelessWidget {
  final IconData icon;
  const _CircleButton({required this.icon});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white.withOpacity(.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(.2)
              : Colors.black.withOpacity(.06),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: isDark ? Colors.white : Colors.black87),
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
      child: const Icon(Icons.image, size: 60, color: Colors.white54),
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
      child: Icon(Icons.person, size: 36, color: theme.hintColor),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

class _SeparatorLine extends StatelessWidget {
  final Color color;
  const _SeparatorLine({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: color.withOpacity(.4),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.textInputAction,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(color: theme.hintColor),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor.withOpacity(.6),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: theme.colorScheme.primary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            ))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor.withOpacity(.6),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: theme.colorScheme.primary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final VoidCallback onPick;

  const _DateField({
    required this.label,
    required this.controller,
    required this.onPick,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onPick,
            child: AbsorbPointer(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint ?? 'dd/MM/yyyy',
                  hintStyle: TextStyle(color: theme.hintColor),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: const Icon(Icons.calendar_month),
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withOpacity(.6),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
