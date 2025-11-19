// lib/features/social/widgets/add_to_family_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/constants/family_relationships.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

/// Lấy label đã dịch cho 1 typeId (ví dụ "1","2"...)
String _getFamilyLabel(BuildContext context, String typeId) {
  final tKey = kFamilyTypeTranslationKeys[typeId];
  final fallback = kFamilyTypeLabelsEn[typeId] ?? typeId;

  if (tKey == null) return fallback;
  return getTranslated(tKey, context) ?? fallback;
}

/// Hiển thị bottom sheet chọn quan hệ + gửi API add_to_family
Future<void> showAddToFamilySheet(
    BuildContext context,
    SocialUserProfile user,
    ) async {
  final theme = Theme.of(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      final media = MediaQuery.of(sheetCtx);
      final entries = kFamilyTypeLabelsEn.entries.toList();

      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              // sheet cao tối đa ~60% chiều cao màn
              maxHeight: media.size.height * 0.6,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // thanh kéo
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: theme.dividerColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    getTranslated('choose_relationship', context) ??
                        'Chọn mối quan hệ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // list chip cuộn được
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in entries)
                          InputChip(
                            label: Text(_getFamilyLabel(sheetCtx, e.key)),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                            onPressed: () async {
                              final sc =
                              sheetCtx.read<SocialController>();

                              final int userId =
                                  int.tryParse(user.id.toString()) ?? 0;
                              if (userId == 0) {
                                Navigator.of(sheetCtx).pop();
                                return;
                              }

                              final typeId = e.key; // "1","2",...

                              // đóng sheet trước
                              Navigator.of(sheetCtx).pop();

                              final ok = await sc.addToFamily(
                                userId,
                                typeId,
                              );

                              final label =
                              _getFamilyLabel(context, typeId);

                              if (!context.mounted) return;

                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      getTranslated(
                                          'family_request_sent',
                                          context) ??
                                          'Đã gửi lời mời thêm ${user.displayName} làm $label',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      getTranslated(
                                          'family_request_already_sent',
                                          context) ??
                                          'Bạn đã gửi lời mời gia đình cho người này rồi!',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
