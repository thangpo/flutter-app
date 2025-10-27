import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class SocialFriendsService {
  /// POST multipart (form-data) – WoWonder thường yêu cầu như Postman của bạn
  static Future<Map<String, dynamic>?> _postMultipart(
    String path,
    Map<String, String> fields, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('${AppConstants.socialBaseUrl}$path')
        .replace(queryParameters: query);
    final req = http.MultipartRequest('POST', uri);
    fields.forEach((k, v) => req.fields[k] = v);

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      try {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  /// Gọi /api/get-friends với type=followers,following
  /// - Nếu truyền userId == null sẽ không thêm field đó (tuỳ site có thể vẫn trả kết quả “me”)
  /// - Đồng thời thêm access_token vào QUERY (như bạn test Postman) để tránh site nào bắt buộc query
  static Future<List<Map<String, dynamic>>> getFollowersAndFollowing({
    required String accessToken,
    String? userId,
    int limit = 200,
  }) async {
    final fields = <String, String>{
      'server_key': AppConstants.socialServerKey,
      'type': 'followers,following',
      'limit': '$limit',
    };
    if (userId != null && userId.isNotEmpty) {
      fields['user_id'] = userId;
    }

    final data = await _postMultipart(
      AppConstants.socialGetFriendsUri,
      fields,
      query: {'access_token': accessToken},
    );

    if (data == null || !(data['api_status'] == 200 || data['status'] == 200)) {
      // debug
      // print('get-friends failed: $data');
      return <Map<String, dynamic>>[];
    }

    // Cấu trúc thường gặp: { api_status:200, data:{ following:[], followers:[] } }
    // Một số bản có thể dùng keys khác; handle mềm dẻo.
    final root = (data['data'] ?? data) as Map<String, dynamic>;

    List flw(Map<String, dynamic> r, String key) {
      final v = r[key];
      if (v is List) return v;
      if (v is Map && v['data'] is List) return v['data'];
      return const [];
    }

    final List following = flw(root, 'following');
    final List followers = flw(root, 'followers');

    // Hợp nhất + loại trùng theo user_id/id
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addAll(List list) {
      for (final e in list) {
        if (e is Map) {
          final id = (e['user_id'] ?? e['id'] ?? '').toString();
          if (id.isEmpty) continue;
          if (seen.add(id)) merged.add(Map<String, dynamic>.from(e));
        }
      }
    }

    addAll(followers);
    addAll(following);

    // debug
    // print('friends merged count: ${merged.length}');
    return merged;
  }
}
