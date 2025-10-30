import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_group_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SocialGroupFormScreen extends StatefulWidget {
  final SocialGroup? group;
  const SocialGroupFormScreen({super.key, this.group});

  bool get isEditing => group != null;

  @override
  State<SocialGroupFormScreen> createState() => _SocialGroupFormScreenState();
}

class _SocialGroupFormScreenState extends State<SocialGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupTitleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _aboutController = TextEditingController();
  String _privacyValue = '1';
  String _joinPrivacyValue = '1';
  final List<_CustomFieldEntry> _customFields = <_CustomFieldEntry>[];

  final ImagePicker _picker = ImagePicker();
  String? _avatarPath;
  String? _coverPath;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    if (group != null) {
      _groupNameController.text = group.name;
      _groupTitleController.text = group.title ?? group.name;
      _categoryController.text = group.category ?? '';
      _subCategoryController.text = group.subCategory ?? '';
      _aboutController.text = group.about ?? group.description ?? '';
      _privacyValue = _normalizePrivacyValue(group.privacy);
      _joinPrivacyValue = _normalizePrivacyValue(group.joinPrivacy);
      group.customFields.forEach((key, value) {
        _customFields.add(_CustomFieldEntry(
          keyController: TextEditingController(text: key),
          valueController: TextEditingController(
            text: value?.toString() ?? '',
          ),
        ));
      });
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupTitleController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _aboutController.dispose();
    for (final entry in _customFields) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() {
        _avatarPath = file.path;
      });
    }
  }

  Future<void> _pickCover() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() {
        _coverPath = file.path;
      });
    }
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(
        _CustomFieldEntry(
          keyController: TextEditingController(),
          valueController: TextEditingController(),
        ),
      );
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index).dispose();
    });
  }

  String _normalizePrivacyValue(String? raw) {
    if (raw == null) return '1';
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return '1';
    if (trimmed == '1' || trimmed == '2') return trimmed;
    final String lower = trimmed.toLowerCase();
    if (lower.contains('public') ||
        lower.contains('open') ||
        lower.contains('everyone') ||
        lower.contains('anyone')) {
      return '1';
    }
    if (lower.contains('private') ||
        lower.contains('closed') ||
        lower.contains('approve') ||
        lower.contains('request') ||
        lower.contains('admin')) {
      return '2';
    }
    return '1';
  }

  List<_SelectOption> _privacyOptions(BuildContext context) {
    return [
      _SelectOption(
        value: '1',
        label: getTranslated('group_privacy_public', context) ?? 'Public',
      ),
      _SelectOption(
        value: '2',
        label: getTranslated('group_privacy_private', context) ?? 'Private',
      ),
    ];
  }

  List<_SelectOption> _joinPrivacyOptions(
    BuildContext context, {
    required String privacyValue,
  }) {
    final List<_SelectOption> options = [
      _SelectOption(
        value: '1',
        label: getTranslated('join_privacy_auto', context) ??
            'Anyone can join',
      ),
    ];
    if (privacyValue == '2') {
      options.add(
        _SelectOption(
          value: '2',
          label: getTranslated('join_privacy_approval', context) ??
              'Admin approval required',
        ),
      );
    }
    return options;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();

    final controller = context.read<SocialGroupController>();
    final groupName = _groupNameController.text.trim();
    final groupTitle = _groupTitleController.text.trim();
    final category = _categoryController.text.trim();
    final about = _aboutController.text.trim();
    final subCategory = _subCategoryController.text.trim();
    final String privacy = _privacyValue;
    final String joinPrivacy = _joinPrivacyValue;

    final Map<String, dynamic> customFields = <String, dynamic>{};
    for (final entry in _customFields) {
      final key = entry.keyController.text.trim();
      final value = entry.valueController.text.trim();
      if (key.isEmpty || value.isEmpty) continue;
      customFields[key] = value;
    }

    setState(() {
      _submitting = true;
    });

    try {
      SocialGroup group;
      if (widget.isEditing) {
        group = await controller.updateGroup(
          groupId: widget.group!.id,
          groupTitle: groupTitle.isEmpty ? null : groupTitle,
          about: about.isEmpty ? null : about,
          category: category.isEmpty ? null : category,
          groupSubCategory: subCategory.isEmpty ? null : subCategory,
          customFields: customFields.isEmpty ? null : customFields,
          privacy: privacy,
          joinPrivacy: joinPrivacy,
          avatarPath: _avatarPath,
          coverPath: _coverPath,
        );
        _showSnackBar(
          getTranslated('group_updated_success', context) ??
              'Group updated successfully',
          isError: false,
        );
      } else {
        group = await controller.createGroup(
          groupName: groupName,
          groupTitle: groupTitle.isEmpty ? groupName : groupTitle,
          category: category.isEmpty ? 'general' : category,
          about: about.isEmpty ? null : about,
          groupSubCategory: subCategory.isEmpty ? null : subCategory,
          customFields: customFields.isEmpty ? null : customFields,
          privacy: privacy,
          joinPrivacy: joinPrivacy,
          avatarPath: _avatarPath,
          coverPath: _coverPath,
        );
        _showSnackBar(
          getTranslated('group_created_success', context) ??
              'Group created successfully',
          isError: false,
        );
      }
      if (mounted) Navigator.pop(context, group);
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.isEditing;
    final title = isEditing
        ? getTranslated('update_group', context) ?? 'Update group'
        : getTranslated('create_group', context) ?? 'Create group';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _MediaPickerTile(
                label: getTranslated('group_avatar', context) ?? 'Group avatar',
                onTap: _pickAvatar,
                filePath: _avatarPath,
                networkUrl: widget.group?.avatarUrl,
              ),
              const SizedBox(height: 12),
              _MediaPickerTile(
                label: getTranslated('group_cover', context) ?? 'Group cover',
                onTap: _pickCover,
                filePath: _coverPath,
                networkUrl: widget.group?.coverUrl,
                aspectRatio: 3 / 1,
              ),
              const SizedBox(height: 20),
              if (!isEditing)
                TextFormField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText:
                        getTranslated('group_name', context) ?? 'Group name',
                    helperText: getTranslated('group_name_hint', context) ??
                        'This will be used in the group URL.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return getTranslated('field_required', context) ??
                          'This field is required';
                    }
                    if (value.contains(' ')) {
                      return getTranslated('group_name_no_space', context) ??
                          'Please avoid spaces in the group name';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _groupTitleController,
                decoration: InputDecoration(
                  labelText:
                      getTranslated('group_title', context) ?? 'Group title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return getTranslated('field_required', context) ??
                        'This field is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText:
                      getTranslated('group_category', context) ?? 'Category',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subCategoryController,
                decoration: InputDecoration(
                  labelText: getTranslated('group_sub_category', context) ??
                      'Sub category',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aboutController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: getTranslated('group_about', context) ?? 'About',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _privacyValue,
                decoration: InputDecoration(
                  labelText:
                      getTranslated('group_privacy', context) ?? 'Privacy',
                ),
                items: _privacyOptions(context)
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _privacyValue = value;
                          if (_privacyValue == '1' &&
                              _joinPrivacyValue == '2') {
                            _joinPrivacyValue = '1';
                          }
                        });
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _joinPrivacyValue,
                decoration: InputDecoration(
                  labelText: getTranslated('group_join_privacy', context) ??
                      'Join privacy',
                ),
                items: _joinPrivacyOptions(context, privacyValue: _privacyValue)
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _joinPrivacyValue = value;
                          if (_joinPrivacyValue == '2') {
                            _privacyValue = '2';
                          }
                        });
                      },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated('custom_fields', context) ?? 'Custom fields',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _addCustomField,
                    icon: const Icon(Icons.add),
                    label: Text(getTranslated('add_custom_field', context) ??
                        'Add field'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_customFields.isEmpty)
                Text(
                  getTranslated('no_custom_fields', context) ??
                      'No custom fields yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(.7),
                  ),
                ),
              for (int i = 0; i < _customFields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _customFields[i].keyController,
                          decoration: InputDecoration(
                            labelText:
                                getTranslated('custom_field_key', context) ??
                                    'Key (fid_*)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _customFields[i].valueController,
                          decoration: InputDecoration(
                            labelText:
                                getTranslated('custom_field_value', context) ??
                                    'Value',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeCustomField(i),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  getTranslated('save_changes', context) ?? 'Save',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectOption {
  final String value;
  final String label;

  const _SelectOption({required this.value, required this.label});
}

class _CustomFieldEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _CustomFieldEntry({
    required this.keyController,
    required this.valueController,
  });

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _MediaPickerTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? filePath;
  final String? networkUrl;
  final double aspectRatio;

  const _MediaPickerTile({
    required this.label,
    required this.onTap,
    required this.filePath,
    required this.networkUrl,
    this.aspectRatio = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget? preview;
    if (filePath != null) {
      if (!kIsWeb) {
        preview = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.file(
              File(filePath!),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: CachedNetworkImage(
            imageUrl: networkUrl!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.image_outlined,
                size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getTranslated('tap_to_choose', context) ?? 'Tap to choose',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(.7),
                    ),
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 12),
                    preview,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
