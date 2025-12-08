import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class CreatePageScreen extends StatefulWidget {
  const CreatePageScreen({super.key});

  @override
  State<CreatePageScreen> createState() => _CreatePageScreenState();
}

class _CreatePageScreenState extends State<CreatePageScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _pageNameCtrl = TextEditingController();
  final TextEditingController _pageTitleCtrl = TextEditingController();
  final TextEditingController _pageDescriptionCtrl = TextEditingController();

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // load categories lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pageCtrl = context.read<SocialPageController>();
      pageCtrl.loadArticleCategories();
    });
  }

  @override
  void dispose() {
    _pageNameCtrl.dispose();
    _pageTitleCtrl.dispose();
    _pageDescriptionCtrl.dispose();
    super.dispose();
  }

  String get _previewTitle {
    final t = _pageTitleCtrl.text.trim();
    return t.isEmpty ? 'Tên trang của bạn' : t;
  }

  String get _previewUsername {
    final t = _pageNameCtrl.text.trim();
    return t.isEmpty ? 'ten-nguoi-dung' : t;
  }

  String _previewCategoryName(BuildContext context) {
    final pageCtrl = context.read<SocialPageController>();
    final list = pageCtrl.articleCategories;
    final c = list.where((e) => e.id == _selectedCategoryId).toList();
    if (c.isEmpty) return '';
    return c.first.name;
  }

  Future<void> _onSubmit() async {
    final pageCtrl = context.read<SocialPageController>();

    // tránh double-click
    if (pageCtrl.creatingPage) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated('please_select_category', context) ??
                'Vui lòng chọn danh mục cho trang.',
          ),
        ),
      );
      return;
    }

    final String desc = _pageDescriptionCtrl.text.trim();

    final bool success = await pageCtrl.createPage(
      pageName: _pageNameCtrl.text.trim(),
      pageTitle: _pageTitleCtrl.text.trim(),
      categoryId: _selectedCategoryId!,
      description: desc.isEmpty ? null : desc,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated('create_page_success', context) ??
                'Tạo trang thành công.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final msg = pageCtrl.createPageError ??
          (getTranslated('failed_to_create_page', context) ??
              'Tạo trang thất bại.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  InputDecoration _inputDecoration(
      BuildContext context, {
        required String hintText,
        IconData? prefixIcon,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fillColor = theme.brightness == Brightness.dark
        ? cs.surfaceVariant.withOpacity(0.6)
        : cs.surfaceVariant;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: cs.outline.withOpacity(0.4),
        width: 1,
      ),
    );

    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      filled: true,
      fillColor: fillColor,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: cs.primary,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final pageCtrl = context.watch<SocialPageController>();
    final List<SocialArticleCategory> categories = pageCtrl.articleCategories;
    final bool loadingCategories = pageCtrl.loadingCategories;
    final String? categoryError = pageCtrl.categoriesError;
    final bool creating = pageCtrl.creatingPage;

    final String previewCategory = _previewCategoryName(context);

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.brightness == Brightness.dark
        ? cs.surface.withOpacity(0.9)
        : cs.surface;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scaffoldBg,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated('create_page', context) ?? 'Tạo trang',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          TextButton(
            onPressed: creating ? null : _onSubmit,
            child: creating
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              getTranslated('create_msg', context) ?? 'TẠO',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.primary,
                fontSize: 15,
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
              // ───────── PREVIEW CARD GIỐNG TRANG ─────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.25 : 0.06,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: cs.primary.withOpacity(0.12),
                      child: Icon(
                        Icons.flag_rounded,
                        color: cs.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _previewTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@$_previewUsername'
                                '${previewCategory.isNotEmpty ? ' • $previewCategory' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ───────── NHÃN SECTION 1 ─────────
              Text(
                'Thông tin cơ bản',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // ───────── CARD THÔNG TIN CƠ BẢN ─────────
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.16 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PAGE NAME
                    Text(
                      'Tên người dùng của trang',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _pageNameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Ví dụ: vnshop_official',
                        prefixIcon: Icons.alternate_email,
                      ),
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) {
                          return 'Vui lòng nhập tên người dùng.';
                        }
                        final slugReg = RegExp(r'^[a-zA-Z0-9_.]+$');
                        if (!slugReg.hasMatch(v)) {
                          return 'Chỉ được chứa chữ, số, dấu chấm và gạch dưới.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // PAGE TITLE
                    Text(
                      'Tên trang',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _pageTitleCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Ví dụ: VNSHOP VIETNAM',
                        prefixIcon: Icons.flag_outlined,
                      ),
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) {
                          return 'Vui lòng nhập tên trang.';
                        }
                        if (v.length < 3) {
                          return 'Tên trang phải có ít nhất 3 ký tự.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // PAGE CATEGORY
                    Text(
                      'Danh mục trang',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (loadingCategories && categories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else if (categoryError != null && categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          categoryError,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.error,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        items: categories
                            .map(
                              (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                            .toList(),
                        decoration: _inputDecoration(
                          context,
                          hintText: 'Chọn danh mục',
                          prefixIcon: Icons.category_outlined,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Vui lòng chọn danh mục.';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ───────── NHÃN SECTION 2 ─────────
              Text(
                'Mô tả trang',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // ───────── CARD MÔ TẢ ─────────
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.16 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _pageDescriptionCtrl,
                  maxLines: 4,
                  minLines: 3,
                  decoration: _inputDecoration(
                    context,
                    hintText:
                    'Giới thiệu ngắn về trang, nội dung, dịch vụ...',
                  ).copyWith(
                    prefixIcon: const Icon(Icons.description_outlined, size: 20),
                    alignLabelWithHint: true,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ───────── NÚT TẠO TRANG DƯỚI CÙNG ─────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: creating ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: creating
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    getTranslated('create_msg', context) ?? 'TẠO TRANG',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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