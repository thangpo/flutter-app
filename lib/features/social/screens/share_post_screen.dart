import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/shared_post_preview.dart';

class SharePostScreen extends StatefulWidget {
  final SocialPost post;
  const SharePostScreen({super.key, required this.post});

  @override
  State<SharePostScreen> createState() => _SharePostScreenState();
}

class _SharePostScreenState extends State<SharePostScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _submitting = false;

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final success = await context
        .read<SocialController>()
        .sharePost(widget.post, text: _textController.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title =
        getTranslated('share_post_title', context) ?? 'Share post';
    final String hint =
        getTranslated('share_post_hint', context) ?? 'Say something...';
    final String action =
        getTranslated('share_post_button', context) ?? 'Share';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _handleSubmit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(action),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _textController,
                maxLines: null,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                getTranslated('share_post_original_label', context) ??
                    'Original post',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SharedPostPreviewCard(post: widget.post),
            ],
          ),
        ),
      ),
    );
  }
}
