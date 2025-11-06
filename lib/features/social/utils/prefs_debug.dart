import 'dart:developer' as dev;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> dumpPrefs({bool maskSensitive = true}) async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().toList()..sort();

  final data = <String, dynamic>{};
  for (final k in keys) {
    final v = prefs.get(k);
    if (maskSensitive && _looksSensitive(k)) {
      data[k] = _mask(v);
    } else {
      data[k] = v;
    }
  }

  final pretty = const JsonEncoder.withIndent('  ').convert(data);
  _logChunks('📦 SharedPreferences dump:\n$pretty');
}

bool _looksSensitive(String key) {
  final k = key.toLowerCase();
  return k.contains('token') ||
      k.contains('password') ||
      k.contains('secret') ||
      k.contains('key') ||
      k.contains('auth');
}

dynamic _mask(dynamic v) {
  if (v is String) {
    if (v.length <= 8) return '***';
    return '${v.substring(0, 4)}***${v.substring(v.length - 4)}';
  }
  if (v is List<String>) return v.map(_mask).toList();
  return '***';
}

void _logChunks(String s, {int chunk = 800}) {
  for (var i = 0; i < s.length; i += chunk) {
    dev.log(s.substring(i, (i + chunk).clamp(0, s.length)));
  }
}
