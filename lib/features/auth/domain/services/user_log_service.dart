import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_log_data.dart';

class UserLogService {
  static const String _userLogKey = "user_log_data";

  Future<void> saveUserLogData(UserLogData user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userLogKey, jsonEncode(user.toJson()));
  }

  Future<UserLogData?> getUserLogData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userLogKey);
    if (data != null) {
      return UserLogData.fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<bool> hasUserLogData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userLogKey);
  }

  Future<void> clearUserLogData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userLogKey);
  }
}