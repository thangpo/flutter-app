// lib/features/social/data/repositories/social_search_repository.dart
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_search_result.dart';

abstract class SocialSearchRepository {
  Future<List<SocialUser>> getRecentSearches({
    required String accessToken,
  });

  Future<SocialSearchResult> search({
    required String keyword,
    required String accessToken,
  });
}
