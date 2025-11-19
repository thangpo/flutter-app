import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/ads_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';

/// Utility helpers for converting ad payloads into story items so they can be
/// displayed seamlessly inside the story viewer.
class StoryAdsHelper {
  StoryAdsHelper._();

  /// Builds a [SocialStory] representation for the provided [ad].
  static SocialStory buildStory(AdsModel ad) {
    final String baseId =
        ad.id?.toString() ?? ad.mediaUrl ?? DateTime.now().millisecondsSinceEpoch.toString();
    final String storyId = 'ad_story_$baseId';
    final String itemId = 'ad_item_$baseId';
    final String? media = ad.mediaUrl;
    final bool isVideo = media != null && media.toLowerCase().endsWith('.mp4');

    final Map<String, dynamic> payload = <String, dynamic>{
      'id': ad.id,
      'name': ad.name,
      'headline': ad.headline,
      'description': ad.description,
      'url': ad.website,
      'media': ad.mediaUrl,
    };

    final SocialStoryItem adItem = SocialStoryItem(
      id: itemId,
      description: ad.description ?? ad.headline,
      mediaUrl: ad.mediaUrl,
      thumbUrl: ad.mediaUrl,
      isVideo: isVideo,
      userId: ad.userId,
      userData: <String, dynamic>{
        'name': ad.userName ?? ad.name,
        'avatar': ad.userAvatar ?? ad.mediaUrl,
      },
      postedAt: DateTime.now(),
    );

    return SocialStory(
      id: storyId,
      userId: 'ad_${baseId}',
      userName: ad.headline?.isNotEmpty == true
          ? ad.headline
          : (ad.name ?? 'Sponsored'),
      userAvatar: ad.userAvatar ?? ad.mediaUrl,
      thumbUrl: ad.mediaUrl,
      mediaUrl: ad.mediaUrl,
      items: <SocialStoryItem>[adItem],
      isAd: true,
      adPayload: payload,
    );
  }

  static List<SocialStory> buildStories(Iterable<AdsModel> ads) {
    return ads.map(buildStory).toList(growable: false);
  }
}
