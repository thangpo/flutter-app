import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart'
    show SocialPostCard;
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  static const int _prefetchThreshold = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<SocialController>();
      if (controller.savedPosts.isEmpty &&
          (controller.accessToken?.isNotEmpty ?? false)) {
        controller.refreshSavedPosts();
      }
    });
  }

  Future<void> _handleRefresh(BuildContext context) {
    return context.read<SocialController>().refreshSavedPosts();
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        getTranslated('saved_posts', context) ?? 'Saved posts';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Consumer<SocialController>(
        builder: (context, controller, _) {
          final bool hasToken =
              (controller.accessToken?.isNotEmpty ?? false);
          if (!hasToken) {
            final String message =
                getTranslated('please_login_to_continue', context) ??
                    'Please sign in to continue.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final posts = controller.savedPosts;
          final bool isLoading = controller.loadingSavedPosts;
          final bool showLoadingItem =
              isLoading && posts.isNotEmpty && controller.hasMoreSavedPosts;

          if (isLoading && posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (posts.isEmpty) {
            final String emptyText =
                getTranslated('no_saved_posts', context) ??
                    getTranslated('no_data_found', context) ??
                    'No saved posts yet';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  emptyText,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _handleRefresh(context),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length + (showLoadingItem ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= posts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (controller.hasMoreSavedPosts &&
                    !controller.loadingSavedPosts &&
                    index >= posts.length - _prefetchThreshold) {
                  controller.loadMoreSavedPosts();
                }

                return SocialPostCard(post: posts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
