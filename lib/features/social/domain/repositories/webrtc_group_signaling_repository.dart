// lib/features/social/domain/repositories/webrtc_group_signaling_repository.dart
//
// Group WebRTC signaling repository (P2P full-mesh):
// - create/join/peers
// - offer/answer/candidate
// - poll/leave/end
//
// Gửi qua router /api với:
//   server_key, access_token, s (token), type=webrtc_group, action=...
//
// LƯU Ý:
// - create() sẽ gửi "participants" dạng CSV "1,2,3" nếu có danh sách invitees
// - peers/join trả List<int>
// - poll trả List<Map> (mỗi item: {from_id,type,sdp,candidate,sdpMid,sdpMLineIndex,...})
//
// Log [SIGNALING] để tiện debug như 1-1.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract class GroupWebRTCSignalingRepository {
  Future<Map<String, dynamic>> create({
    required String groupId,
    required String media, // 'audio' | 'video'
    List<int>? participants,
  });

  Future<List<int>> join({required int callId});
  Future<List<int>> peers({required int callId});

  Future<void> offer({
    required int callId,
    required int toUserId,
    required String sdp,
  });

  Future<void> answer({
    required int callId,
    required int toUserId,
    required String sdp,
  });

  Future<void> candidate({
    required int callId,
    required int toUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  });

  Future<List<Map<String, dynamic>>> poll({required int callId});

  Future<void> leave({required int callId});
  Future<void> end({required int callId});

  /// Back-compat nếu đâu đó gọi kiểu action('end'|'leave'|...)
  Future<void> action({required int callId, required String action});
}

class WebRTCGroupSignalingRepositoryImpl
    implements GroupWebRTCSignalingRepository {
  final String baseUrl; // ví dụ: https://social.vnshop247.com
  final String serverKey;
  final Future<String?> Function() getAccessToken;

  /// Nên để '/api/' để đi qua router WoWonder (đã map type=webrtc_group).
  /// Nếu muốn gọi trực tiếp file PHP, có thể truyền '/api/v2/endpoints/webrtc_group.php'.
  final String endpointPath;
  final Duration timeout;
  final http.Client _client;

  WebRTCGroupSignalingRepositoryImpl({
    required this.baseUrl,
    required this.serverKey,
    required this.getAccessToken,
    this.endpointPath = '/api/', // <-- khớp với main.dart
    this.timeout = const Duration(seconds: 20),
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  Uri _endpointUri() {
    final left = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    String right = endpointPath;
    if (!right.startsWith('/')) right = '/$right';
    // đảm bảo nếu là router thì có dấu '/' kết
    if (right == '/api') right = '/api/';
    return Uri.parse('$left$right');
  }

  Future<Map<String, dynamic>> _post(Map<String, String> body) async {
    final url = _endpointUri();
    final token = (await getAccessToken()) ?? '';

    final full = <String, String>{
      'server_key': serverKey,
      // Gửi cả 2 khoá để tương thích nhiều router WoWonder
      if (token.isNotEmpty) 'access_token': token,
      if (token.isNotEmpty) 's': token,
      'type': 'webrtc_group',
      ...body,
    };

    if (kDebugMode) {
      debugPrint('[SIGNALING] POST $url  bodyKeys=${full.keys.toList()}');
    }

    http.Response resp;
    try {
      resp = await _client.post(url, body: full).timeout(timeout);
    } catch (e) {
      throw Exception('network_error: $e');
    }

    if (kDebugMode) {
      final bodyStr = utf8.decode(resp.bodyBytes);
      debugPrint(
          '[SIGNALING] RESP ${resp.statusCode}: ${bodyStr.length > 600 ? bodyStr.substring(0, 600) + '…' : bodyStr}');
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw Exception('invalid_response');
    }
    final apiStatus = data['api_status'];
    if ((apiStatus is int && apiStatus != 200) ||
        (apiStatus is String && apiStatus != '200')) {
      throw Exception(data['error'] ?? 'api_status=$apiStatus');
    }
    return data;
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  List<int> _toIntList(dynamic v) {
    final out = <int>[];
    if (v is List) {
      for (final e in v) {
        final i = _asInt(e);
        if (i != null) out.add(i);
      }
    }
    return out;
  }

  // ================== Public APIs ==================

  @override
  Future<Map<String, dynamic>> create({
    required String groupId,
    required String media,
    List<int>? participants,
  }) async {
    // CSV "1,2,3"
    final csv = (participants ?? <int>{}.toList())
        .where((e) => e > 0)
        .toSet()
        .join(',');

    final body = <String, String>{
      'action': 'create',
      'group_id': groupId,
      'media': (media == 'video') ? 'video' : 'audio',
    };
    if (csv.isNotEmpty) {
      body['participants'] = csv; // <-- để server bắn FCM cho máy B
    }

    final resp = await _post(body);
    return resp; // {api_status:200, call_id:..., status:'ringing', invited:[...]}
  }

  @override
  Future<List<int>> join({required int callId}) async {
    final resp = await _post({
      'action': 'join',
      'call_id': '$callId',
    });
    return _toIntList(resp['peers']);
  }

  @override
  Future<List<int>> peers({required int callId}) async {
    final resp = await _post({
      'action': 'peers',
      'call_id': '$callId',
    });
    return _toIntList(resp['peers']);
  }

  @override
  Future<void> offer({
    required int callId,
    required int toUserId,
    required String sdp,
  }) async {
    await _post({
      'action': 'offer',
      'call_id': '$callId',
      'to_id': '$toUserId',
      'sdp': sdp,
    });
  }

  @override
  Future<void> answer({
    required int callId,
    required int toUserId,
    required String sdp,
  }) async {
    await _post({
      'action': 'answer',
      'call_id': '$callId',
      'to_id': '$toUserId',
      'sdp': sdp,
    });
  }

  @override
  Future<void> candidate({
    required int callId,
    required int toUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    final body = <String, String>{
      'action': 'candidate',
      'call_id': '$callId',
      'to_id': '$toUserId',
      'candidate': candidate,
    };
    if (sdpMid != null && sdpMid.isNotEmpty) body['sdpMid'] = sdpMid;
    if (sdpMLineIndex != null) body['sdpMLineIndex'] = '$sdpMLineIndex';

    await _post(body);
  }

  @override
  Future<List<Map<String, dynamic>>> poll({required int callId}) async {
    final resp = await _post({
      'action': 'poll',
      'call_id': '$callId',
    });
    final items = <Map<String, dynamic>>[];
    final raw = resp['items'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(e.map((k, v) => MapEntry(k.toString(), v)));
        }
      }
    }
    return items;
  }

  @override
  Future<void> leave({required int callId}) async {
    await _post({
      'action': 'leave',
      'call_id': '$callId',
    });
  }

  @override
  Future<void> end({required int callId}) async {
    await _post({
      'action': 'end',
      'call_id': '$callId',
    });
  }

  @override
  Future<void> action({required int callId, required String action}) async {
    final a = action.toLowerCase().trim();
    if (a == 'end') return end(callId: callId);
    if (a == 'leave') return leave(callId: callId);
    await _post({
      'action': a,
      'call_id': '$callId',
    });
  }
}
