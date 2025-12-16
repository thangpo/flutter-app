import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/social_controller.dart';
import '../screens/create_story_screen.dart';
import '../../profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class CreateStoryTile extends StatelessWidget {
  final double size;
  const CreateStoryTile({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final social = context.watch<SocialController>();
    final profileCtrl = context.watch<ProfileController>();
    final user = social.currentUser;
    final fallback = profileCtrl.userInfoModel;

    final String? avatar = () {
      final candidates = [
        user?.avatarUrl?.trim(),
        fallback?.imageFullUrl?.toString().trim(),
        fallback?.image?.trim(),
      ];
      for (final v in candidates) {
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }();

    void openCreateStory() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SocialCreateStoryScreen(),
          fullscreenDialog: true,
        ),
      );
    }

    return GestureDetector(
      onTap: openCreateStory,
      child: SizedBox(
        width: size + 10,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: size / 2,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage:
                  avatar != null ? CachedNetworkImageProvider(avatar) : null,
                  child: avatar == null
                      ? Icon(Icons.person,
                      color: cs.onSurface.withOpacity(.6))
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              getTranslated('create_story', context) ?? 'Story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}