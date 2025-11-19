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
      // pop về SocialPagesScreen với kết quả true
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final pageCtrl = context.watch<SocialPageController>();
    final List<SocialArticleCategory> categories = pageCtrl.articleCategories;
    final bool loadingCategories = pageCtrl.loadingCategories;
    final String? categoryError = pageCtrl.categoriesError;
    final bool creating = pageCtrl.creatingPage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated('create_page', context) ?? 'Tạo trang',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: creating ? null : _onSubmit,
            child: creating
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              getTranslated('create_msg', context) ?? 'Tạo',
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
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) {
                    return getTranslated('page_name_required', context) ??
                        'Vui lòng nhập page_name.';
                  }
                  // slug đơn giản: chữ, số, dấu gạch dưới hoặc chấm
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
                  if (v.isEmpty) {
                    return getTranslated('page_title_required', context) ??
                        'Vui lòng nhập tên trang.';
                  }
                  if (v.length < 3) {
                    return getTranslated('page_title_too_short', context) ??
                        'Tên trang phải có ít nhất 3 ký tự.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ───────── PAGE CATEGORY ─────────
              Text(
                getTranslated('page_category', context) ?? 'Danh mục trang',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.8),
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
                  decoration: InputDecoration(
                    hintText: getTranslated('select_category', context) ??
                        'Chọn danh mục',
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
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return getTranslated(
                          'page_category_required', context) ??
                          'Vui lòng chọn danh mục.';
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
