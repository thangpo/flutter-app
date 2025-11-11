// lib/features/social/domain/repositories/webrtc_group_signaling_repository.dart
//
// Signaling cho Group Call (P2P full-mesh) map 1-1 với
// /_social/api/webrtc_group.php  (action = create|join|peers|offer|answer|candidate|poll|leave|end|inbox)
//
// LƯU Ý:
// - Có thêm method inbox(groupId) để client trong màn chat tự phát hiện call đang 'ringing/ongoing'.
// - endpointPath auto-normalize: '/api', '/api/' -> '/api/webrtc_group.php'.
// - _post supports allowedStatuses (vd: inbox chấp nhận 200 & 204).

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Hợp đồng signaling cho gọi nhóm (full-mesh)
abstract class GroupWebRTCSignalingRepository {
  /// Tạo call nhóm. Có thể truyền danh sách người mời (userId)
  Future<Map<String, dynamic>> create({
    required String groupId,
    required String media, // 'audio' | 'video'
    List<int>? participants,
  });

  /// Đánh dấu tham gia call, trả về danh sách peer userId đang online (trừ mình).
  Future<List<int>> join({required int callId});

  /// Lấy danh sách peers đang online.
  Future<List<int>> peers({required int callId});

  /// Gửi SDP offer (from mình -> toUserId).
  Future<void> offer({
    required int callId,
    required int toUserId,
    required String sdp,
  });

  /// Gửi SDP answer (from mình -> toUserId).
  Future<void> answer({
    required int callId,
    required int toUserId,
    required String sdp,
  });

  /// Gửi ICE candidate (from mình -> toUserId).
  Future<void> candidate({
    required int callId,
    required int toUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  });

  /// Poll nhận các tín hiệu (offer/answer/candidate) gửi cho mình.
  Future<List<Map<String, dynamic>>> poll({required int callId});

  /// Rời call (người thường).
  Future<void> leave({required int callId});

  /// Kết thúc call (creator).
  Future<void> end({required int callId});

  /// Back-compat với code cũ (action: 'end' | 'leave' | ...)
  Future<void> action({required int callId, required String action});

  /// (NEW) Kiểm tra trong group hiện có cuộc gọi 'ringing/ongoing' dành cho mình không.
  /// Có -> trả về object `call` từ server (gồm call_id, group_id, media, status, joined).
  /// Không có -> trả về null (api_status 204).
  Future<Map<String, dynamic>?> inbox({required String groupId});
}

/// Exception gom thông tin lỗi khi gọi signaling API
class GroupSignalingException implements Exception {
  final int? status;
  final String message;
  final dynamic raw;
  GroupSignalingException(this.message, {this.status, this.raw});

  @override
  String toString() => 'GroupSignalingException($status): $message';
}

/// Triển khai bằng http (x-www-form-urlencoded)
class WebRTCGroupSignalingRepositoryImpl
    implements GroupWebRTCSignalingRepository {
  final String baseUrl; // ví dụ: https://social.vnshop247.com
  final String serverKey;
  final Future<String?> Function() getAccessToken;
  final String endpointPath; // ví dụ: '/api/webrtc_group.php'
  final http.Client _client;

  WebRTCGroupSignalingRepositoryImpl({
    required this.baseUrl,
    required this.serverKey,
    required this.getAccessToken,
    this.endpointPath = '/api/webrtc_group.php',
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  Uri get _endpointUri {
    final ep = endpointPath.trim();
    if (ep.startsWith('http')) return Uri.parse(ep);

    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // Chuẩn hoá path:
    // - '/api' hoặc '/api/' => '/api/webrtc_group.php'
    // - nếu đã truyền '/api/webrtc_group.php' thì giữ nguyên
    String path = ep.startsWith('/') ? ep : '/$ep';
    if (path == '/api' || path == '/api/') {
      path = '/api/webrtc_group.php';
    }
    return Uri.parse('$base$path');
  }

  // =============== Public APIs ===============

  @override
  Future<Map<String, dynamic>> create({
    required String groupId,
    required String media,
    List<int>? participants,
  }) async {
    final body = <String, String>{
      'action': 'create',
      'group_id': groupId,
      'media': (media == 'video') ? 'video' : 'audio',
    };
    if (participants != null && participants.isNotEmpty) {
      body['participants'] = participants.join(',');
    }
    final res = await _post(body);
    return res;
  }

  @override
  Future<List<int>> join({required int callId}) async {
    final res = await _post({
      'action': 'join',
      'call_id': '$callId',
    });
    return _parsePeers(res['peers']);
  }

  @override
  Future<List<int>> peers({required int callId}) async {
    final res = await _post({
      'action': 'peers',
      'call_id': '$callId',
    });
    return _parsePeers(res['peers']);
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
    if (sdpMid != null) body['sdpMid'] = sdpMid;
    if (sdpMLineIndex != null) body['sdpMLineIndex'] = '$sdpMLineIndex';
    await _post(body);
  }

  @override
  Future<List<Map<String, dynamic>>> poll({required int callId}) async {
    final res = await _post({
      'action': 'poll',
      'call_id': '$callId',
    });
    final items = <Map<String, dynamic>>[];
    final raw = res['items'];
    if (raw is List) {
      for (final it in raw) {
        if (it is Map) items.add(Map<String, dynamic>.from(it));
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

  @override
  Future<Map<String, dynamic>?> inbox({required String groupId}) async {
    final res = await _post(
      {
        'action': 'inbox',
        'group_id': groupId,
      },
      allowedStatuses: const {200, 204},
    );

    final apiStatus = _asInt(res['api_status']) ?? 200;
    if (apiStatus == 204) return null;

    final call = res['call'];
    if (call is Map) {
      return Map<String, dynamic>.from(call);
    }
    return null;
  }

  // =============== Helpers ===============

  Future<Map<String, dynamic>> _post(
    Map<String, String> body, {
    Set<int> allowedStatuses = const {200},
  }) async {
    final token = await getAccessToken();
    final merged = <String, String>{
      'server_key': serverKey,
      if (token != null && token.isNotEmpty) 'access_token': token,
      if (token != null && token.isNotEmpty) 's': token,
      // 'type' không bắt buộc với endpoint trực tiếp, nhưng thêm cũng không sao
      'type': 'webrtc_group',
      ...body,
    };

    final uri = _endpointUri;
    print('[SIGNALING] POST $uri  bodyKeys=${merged.keys.toList()}');

    http.Response r = await _client.post(uri, body: merged);

    // Theo dõi redirect thủ công cho POST (301/302/307/308)
    if ([301, 302, 307, 308].contains(r.statusCode) &&
        r.headers['location'] != null) {
      final loc = r.headers['location']!;
      final redirectUri =
          Uri.parse(loc).isAbsolute ? Uri.parse(loc) : uri.resolve(loc);
      print('[SIGNALING] REDIRECT -> $redirectUri');
      r = await _client.post(redirectUri, body: merged);
    }

    final bodyStr = utf8.decode(r.bodyBytes);
    print(
        '[SIGNALING] RESP ${r.statusCode}: ${bodyStr.length > 400 ? bodyStr.substring(0, 400) + '…' : bodyStr}');

    Map<String, dynamic> json;
    try {
      json = jsonDecode(bodyStr) as Map<String, dynamic>;
    } catch (_) {
      // Một số trường hợp 204 không có body => giả JSON
      if (r.statusCode == 204 && allowedStatuses.contains(204)) {
        return {'api_status': 204};
      }
      throw GroupSignalingException(
        'Invalid JSON (HTTP ${r.statusCode}): ${bodyStr.length > 800 ? bodyStr.substring(0, 800) + "…" : bodyStr}',
        status: r.statusCode,
        raw: bodyStr,
      );
    }

    final apiStatus =
        int.tryParse('${json['api_status'] ?? r.statusCode}') ?? r.statusCode;

    if (!allowedStatuses.contains(apiStatus)) {
      String? msg;
      final err = json['errors'];
      if (json['error'] != null) {
        msg = '${json['error']}';
      } else if (json['message'] != null) {
        msg = '${json['message']}';
      } else if (err is Map &&
          (err['error_text'] != null || err['error'] != null)) {
        msg = '${err['error_text'] ?? err['error']}';
      }
      throw GroupSignalingException(
        msg ?? 'Unknown error',
        status: apiStatus,
        raw: json,
      );
    }

    return json;
  }

  List<int> _parsePeers(dynamic raw) {
    final peers = <int>[];
    if (raw is List) {
      for (final v in raw) {
        final id = _asInt(v);
        if (id != null) peers.add(id);
      }
    }
    return peers;
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
