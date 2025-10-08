import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookLoginController with ChangeNotifier {
  Map? userData;
  late LoginResult result;
  final FacebookAuth facebookAuth = FacebookAuth.instance;

  Future<void> login() async {

    result = await facebookAuth.login();

    if (result.status == LoginStatus.success) {
      userData = await FacebookAuth.instance.getUserData(fields: 'name, email');
    }

    notifyListeners();
  }

}
