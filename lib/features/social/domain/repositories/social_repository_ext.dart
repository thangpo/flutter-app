// social_repository_ext.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_repository.dart';

extension SocialRepositoryToken on SocialRepository {
  String? readAccessToken() {
    // dùng field public `sharedPreferences` đã có sẵn trong repo
    return sharedPreferences.getString(AppConstants.socialAccessToken);
  }
}
