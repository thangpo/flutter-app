import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class GroupWebRTCSignalingRepository {
  Future<Map<String, dynamic>> create({
    required String groupId,
    required String media, // 'audio' | 'video'
    List<int>? participants,
  });
  Future<List<int>> join({required int callId});
  Future<List<int>> peers({required int callId});
  Future<void> offer(
      {required int callId, required int toUserId, required String sdp});
  Future<void> answer(
      {required int callId, required int toUserId, required String sdp});
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
  Future<void> action({required int callId, required String action});
  Future<Map<String, dynamic>?> inbox({required String groupId});
}

class GroupSignalingException implements Exception {
  final int? status;
  final String message;
  final dynamic raw;
  GroupSignalingException(this.message, {this.status, this.raw});
  @override
  String toString() => 'GroupSignalingException($status): $message';
}

class WebRTCGroupSignalingRepositoryImpl
    implements GroupWebRTCSignalingRepository {
  final String baseUrl; // https://social.vnshop247.com
  final String serverKey;
  final Future<String?> Function() getAccessToken;

  /// Router mode: set '/api/'. (Đừng trỏ .php)
  final String endpointPath;
  final http.Client _client;

  WebRTCGroupSignalingRepositoryImpl({
    required this.baseUrl,
    required this.serverKey,
    required this.getAccessToken,
    this.endpointPath = '/api/', // <<<< DÙNG ROUTER
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  Uri get _endpointUri {
    final ep = endpointPath.trim();
    if (ep.startsWith('http')) return Uri.parse(ep);
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    String path = ep.startsWith('/') ? ep : '/$ep';
    if (path == '/api') path = '/api/';
    return Uri.parse('$base$path');
  }

  bool get _routerMode {
    final p = _endpointUri.path.toLowerCase();
    return !p.endsWith('.php'); // -> dùng .php => false => KHÔNG gửi 'type'
  }


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
    final res = await _post({'action': 'join', 'call_id': '$callId'});
    return _parsePeers(res['peers']);
  }

  @override
  Future<List<int>> peers({required int callId}) async {
    final res = await _post({'action': 'peers', 'call_id': '$callId'});
    return _parsePeers(res['peers']);
  }

  @override
  Future<void> offer(
      {required int callId, required int toUserId, required String sdp}) async {
    await _post({
      'action': 'offer',
      'call_id': '$callId',
      'to_id': '$toUserId',
      'sdp': sdp
    });
  }

  @override
  Future<void> answer(
      {required int callId, required int toUserId, required String sdp}) async {
    await _post({
      'action': 'answer',
      'call_id': '$callId',
      'to_id': '$toUserId',
      'sdp': sdp
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
    final res = await _post({'action': 'poll', 'call_id': '$callId'});
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
    await _post({'action': 'leave', 'call_id': '$callId'});
  }

  @override
  Future<void> end({required int callId}) async {
    await _post({'action': 'end', 'call_id': '$callId'});
  }

  @override
  Future<void> action({required int callId, required String action}) async {
    final a = action.toLowerCase().trim();
    if (a == 'end') return end(callId: callId);
    if (a == 'leave') return leave(callId: callId);
    await _post({'action': a, 'call_id': '$callId'});
  }

  @override
  Future<Map<String, dynamic>?> inbox({required String groupId}) async {
    final res = await _post({'action': 'inbox', 'group_id': groupId},
        allowedStatuses: const {200, 204});
    final apiStatus = _asInt(res['api_status']) ?? 200;
    if (apiStatus == 204) return null;
    final call = res['call'];
    if (call is Map) return Map<String, dynamic>.from(call);
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
      if (_routerMode) 'type': 'webrtc_group', // <<<< BẮT BUỘC khi dùng /api/
      ...body,
    };

    final uri = _endpointUri;
    print('[SIGNALING] POST $uri  bodyKeys=${merged.keys.toList()}');
    http.Response r = await _client.post(uri, body: merged);

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
      if (r.statusCode == 204 && allowedStatuses.contains(204))
        return {'api_status': 204};
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
      if (json['error'] != null)
        msg = '${json['error']}';
      else if (json['message'] != null)
        msg = '${json['message']}';
      else if (err is Map &&
          (err['error_text'] != null || err['error'] != null)) {
        msg = '${err['error_text'] ?? err['error']}';
      }
      throw GroupSignalingException(msg ?? 'Unknown error',
          status: apiStatus, raw: json);
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
