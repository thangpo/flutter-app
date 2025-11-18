import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class EditPageScreen extends StatefulWidget {
  /// ID trang – BẮT BUỘC để gọi API
  final int pageId;

  /// @page_name hiện tại (slug)
  final String? initialPageName;

  /// @page_title hiện tại (tên hiển thị)
  final String? initialPageTitle;

  /// Mô tả hiện tại (nếu có)
  final String? initialDescription;

  /// Optional: chỉ để hiển thị text, không cho sửa
  final String? initialCategoryName;

  /// URL avatar hiện tại
  final String? initialAvatarUrl;

  /// URL cover hiện tại
  final String? initialCoverUrl;

  const EditPageScreen({
    super.key,
    required this.pageId,
    this.initialPageName,
    this.initialPageTitle,
    this.initialDescription,
    this.initialCategoryName,
    this.initialAvatarUrl,
    this.initialCoverUrl,
  });

  @override
  State<EditPageScreen> createState() => _EditPageScreenState();
}

class _EditPageScreenState extends State<EditPageScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _pageNameCtrl;
  late final TextEditingController _pageTitleCtrl;
  late final TextEditingController _pageDescriptionCtrl;

  File? _avatarFile;
  File? _coverFile;

  @override
  void initState() {
    super.initState();

    _pageNameCtrl = TextEditingController(text: widget.initialPageName ?? '');
    _pageTitleCtrl = TextEditingController(text: widget.initialPageTitle ?? '');
    _pageDescriptionCtrl =
        TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _pageNameCtrl.dispose();
    _pageTitleCtrl.dispose();
    _pageDescriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (picked != null && picked.files.single.path != null) {
      setState(() {
        _avatarFile = File(picked.files.single.path!);
      });
    }
  }

  Future<void> _pickCover() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (picked != null && picked.files.single.path != null) {
      setState(() {
        _coverFile = File(picked.files.single.path!);
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final String pageName = _pageNameCtrl.text.trim();
    final String pageTitle = _pageTitleCtrl.text.trim();
    final String desc = _pageDescriptionCtrl.text.trim();

    // payload đúng spec API, không có page_category
    final Map<String, dynamic> payload = <String, dynamic>{
      'page_id': widget.pageId.toString(), // REQUIRED
    };

    if (pageName.isNotEmpty) {
      payload['page_name'] = pageName;
    }
    if (pageTitle.isNotEmpty) {
      payload['page_title'] = pageTitle;
    }
    if (desc.isNotEmpty) {
      payload['page_description'] = desc;
    }
    if (_avatarFile != null) {
      payload['avatar'] = _avatarFile; // File – repo sẽ map sang FormData
    }
    if (_coverFile != null) {
      payload['cover'] = _coverFile;
    }

    // Trả payload cho tầng trên tự call API update-page
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated('edit_page', context) ?? 'Chỉnh sửa trang',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _onSubmit,
            child: Text(
              getTranslated('save', context) ?? 'Lưu',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ───────── AVATAR + COVER ─────────
              Text(
                getTranslated('page_images', context) ??
                    'Ảnh đại diện & ảnh bìa',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                              cs.primary.withValues(alpha: 0.1),
                              backgroundImage: _avatarFile != null
                                  ? FileImage(_avatarFile!)
                                  : (widget.initialAvatarUrl != null &&
                                  widget.initialAvatarUrl!.isNotEmpty)
                                  ? NetworkImage(
                                widget.initialAvatarUrl!,
                              ) as ImageProvider
                                  : null,
                              child: (_avatarFile == null &&
                                  (widget.initialAvatarUrl == null ||
                                      widget.initialAvatarUrl!.isEmpty))
                                  ? Icon(Icons.person, color: cs.primary)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          getTranslated('avatar', context) ?? 'Ảnh đại diện',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Cover
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickCover,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                image: _coverFile != null
                                    ? DecorationImage(
                                  image: FileImage(_coverFile!),
                                  fit: BoxFit.cover,
                                )
                                    : (widget.initialCoverUrl != null &&
                                    widget.initialCoverUrl!.isNotEmpty)
                                    ? DecorationImage(
                                  image: NetworkImage(
                                      widget.initialCoverUrl!),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: (_coverFile == null &&
                                  (widget.initialCoverUrl == null ||
                                      widget.initialCoverUrl!.isEmpty))
                                  ? Center(
                                child: Icon(
                                  Icons.photo,
                                  color:
                                  cs.onSurface.withValues(alpha: 0.4),
                                ),
                              )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getTranslated('cover_photo', context) ??
                                'Ảnh bìa',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // (Optional) chỉ hiển thị category hiện tại, không cho sửa
              if (widget.initialCategoryName != null &&
                  widget.initialCategoryName!.isNotEmpty) ...[
                Text(
                  getTranslated('page_category', context) ??
                      'Danh mục trang',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.initialCategoryName!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ───────── PAGE NAME (slug) ─────────
              Text(
                getTranslated('page_name', context) ??
                    'Tên người dùng của trang (page_name)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _pageNameCtrl,
                decoration: InputDecoration(
                  hintText: getTranslated('page_name_hint', context) ??
                      'Ví dụ: vnshop_official',
                  prefixText: '@',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                // Cho phép để trống (không update)
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return null;
                  final slugReg = RegExp(r'^[a-zA-Z0-9_.]+$');
                  if (!slugReg.hasMatch(v)) {
                    return getTranslated('page_name_invalid', context) ??
                        'Chỉ được chứa chữ, số, dấu chấm và gạch dưới.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ───────── PAGE TITLE ─────────
              Text(
                getTranslated('page_title', context) ?? 'Tên trang (page_title)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _pageTitleCtrl,
                decoration: InputDecoration(
                  hintText: getTranslated('page_title_hint', context) ??
                      'Ví dụ: VNSHOP VIETNAM',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return null;
                  if (v.length < 3) {
                    return getTranslated('page_title_too_short', context) ??
                        'Tên trang phải có ít nhất 3 ký tự.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ───────── PAGE DESCRIPTION ─────────
              Text(
                getTranslated('page_description', context) ?? 'Mô tả trang',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _pageDescriptionCtrl,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: getTranslated(
                      'page_description_hint', context) ??
                      'Giới thiệu ngắn về trang, nội dung, dịch vụ...',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
