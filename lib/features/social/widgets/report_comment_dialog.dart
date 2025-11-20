import 'package:flutter/material.dart';

import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/di_container.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

/// Helper dùng chung để report comment / reply
Future<void> showReportCommentDialog({
  required BuildContext context,
  required SocialComment comment,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        getTranslated('report_comment', ctx) ?? 'Report comment',
      ),
      content: Text(
        getTranslated('report_comment_confirm', ctx) ??
            'Are you sure you want to report this comment?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(getTranslated('cancel', ctx) ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(getTranslated('report', ctx) ?? 'Report'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final svc = sl<SocialServiceInterface>();
    await svc.reportComment(commentId: comment.id);

    if (!context.mounted) return;
    showCustomSnackBar(
      getTranslated('comment_reported', context) ??
          'Comment has been reported.',
      context,
      isError: false,
    );
  } catch (e) {
    if (!context.mounted) return;
    showCustomSnackBar(e.toString(), context, isError: true);
  }
}
