// lib/features/social/domain/repositories/webrtc_group_signaling_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GroupSignalingException implements Exception {
  final int status;
  final String message;
  final dynamic raw;
  GroupSignalingException(this.status, this.message, [this.raw]);
  @override
  String toString() => 'GroupSignalingException($status): $message';
}

abstract class GroupWebRTCSignalingRepository {
  Future<Map<String, dynamic>> create({
    required String groupId,
    required String media,
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
    String? sdpMLineIndex,
  });
  Future<List<Map<String, dynamic>>> poll({required int callId});
  Future<void> leave({required int callId});
  Future<void> end({required int callId});
  Future<Map<String, dynamic>?> inbox({required String groupId});
}

class WebRTCGroupSignalingRepositoryImpl
    implements GroupWebRTCSignalingRepository {
  final String baseUrl;
  final String serverKey;
  final Future<String?> Function() getAccessToken;
  final Duration requestTimeout;
  final http.Client? _client; // optional DI

  // Router mode để né /webrtc_group.php trực tiếp
  static const String _endpointPath = '/api/';

  late final Uri _endpointUri;

  WebRTCGroupSignalingRepositoryImpl({
    required this.baseUrl,
    required this.serverKey,
    required this.getAccessToken,
    this.requestTimeout = const Duration(seconds: 15),
    http.Client? client,
  }) : _client = client {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _endpointUri = Uri.parse('$root$_endpointPath');
    if (kDebugMode) {
      debugPrint('[SIGNALING] INIT endpoint=$_endpointUri (router mode)');
    }
  }

  String _maskKey(String key) {
    if (key.length < 10) return key;
    return '${key.substring(0, 5)}...${key.substring(key.length - 5)}';
  }

  Never _throwApiError(Map<String, dynamic> j, int httpCode) {
    final api = j['api_status'];
    final err = j['error'] ??
        (j['errors'] is Map ? (j['errors']['error_text'] ?? '') : '') ??
        'Unknown error';
    throw GroupSignalingException(httpCode, 'api_status=$api: $err', j);
  }

  void _ensureOk(Map<String, dynamic> j,
      {bool allow204 = false, int http = 200}) {
    final st = j['api_status'];
    if (st == 200) return;
    if (allow204 && st == 204) return;
    _throwApiError(j, http);
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  List<int> _parsePeers(dynamic v) {
    if (v is List) {
      return v
          .map((e) => _asInt(e) ?? 0)
          .where((e) => e > 0)
          .toList(growable: false);
    }
    return const <int>[];
  }

  List<Map<String, dynamic>> _parseEvents(dynamic v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> _post(
    Map<String, String> fields, {
    bool allow204 = false,
  }) async {
    final token = await getAccessToken();
    final body = <String, String>{
      'type': 'webrtc_group', // bắt buộc cho router
      'server_key': serverKey.trim(),
      if (token != null && token.isNotEmpty) 'access_token': token,
      if (token != null && token.isNotEmpty)
        's': token, // nhiều nhánh server chỉ đọc 's'
      ...fields,
    };

    final act = body['action'];
    final keyMasked = _maskKey(serverKey.trim());
    if (kDebugMode) {
      debugPrint(
          '[SIGNALING] POST $_endpointUri | action=$act | server_key(${serverKey.length})=$keyMasked');
    }

    try {
      final client = _client ?? http.Client();
      final resp = await client
          .post(
            _endpointUri,
            headers: {
              'Accept': 'application/json',
              // Content-Type để http tự set urlencoded
            },
            body: body,
          )
          .timeout(
            requestTimeout,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      final status = resp.statusCode;
      final txt = resp.body;
      if (kDebugMode) {
        debugPrint(
          '[SIGNALING] RESP $status ${txt.length > 1200 ? txt.substring(0, 1200) + "..." : txt}',
        );
      }

      if (status < 200 || status >= 300) {
        throw GroupSignalingException(status, 'HTTP $status', txt);
      }

      if (txt.isEmpty) {
        if (allow204) return {'api_status': 204};
        throw GroupSignalingException(status, 'Empty body');
      }

      final decoded = jsonDecode(txt);
      if (decoded is! Map) {
        throw GroupSignalingException(status, 'Invalid JSON', txt);
      }
      final json = Map<String, dynamic>.from(decoded);

      // WoWonder thường trả api_status trong body
      _ensureOk(json, allow204: allow204, http: status);

      return json;
    } catch (e) {
      if (e is GroupSignalingException) rethrow;
      throw GroupSignalingException(0, 'Network/Timeout error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> create({
    required String groupId,
    required String media,
    List<int>? participants,
  }) async {
    final json = await _post({
      'action': 'create',
      'group_id': groupId,
      'media': media == 'video' ? 'video' : 'audio',
      if (participants != null && participants.isNotEmpty)
        'participants': participants.join(','),
    });
    return json;
  }

  @override
  Future<List<int>> join({required int callId}) async {
    final json = await _post({'action': 'join', 'call_id': '$callId'});
    // peers có thể nằm trực tiếp hoặc dưới data.peers
    final peers = _parsePeers(json['peers'] ?? json['data']?['peers']);
    return peers;
  }

  @override
  Future<List<int>> peers({required int callId}) async {
    final json = await _post({'action': 'peers', 'call_id': '$callId'});
    final peers = _parsePeers(json['peers'] ?? json['data']?['peers']);
    return peers;
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
    String? sdpMLineIndex,
  }) async {
    await _post({
      'action': 'candidate',
      'call_id': '$callId',
      'to_id': '$toUserId',
      'candidate': candidate,
      if (sdpMid != null) 'sdpMid': sdpMid,
      if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> poll({required int callId}) async {
    final json = await _post({'action': 'poll', 'call_id': '$callId'});
    // server có thể trả items, events, hoặc data.items
    final list = json['items'] ??
        json['events'] ??
        json['data']?['items'] ??
        json['data']?['events'];
    return _parseEvents(list);
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
  Future<Map<String, dynamic>?> inbox({required String groupId}) async {
    final json =
        await _post({'action': 'inbox', 'group_id': groupId}, allow204: true);
    if (json['api_status'] == 204) return null;
    // call có thể ở call hoặc data.call
    final call = (json['call'] ?? json['data']?['call']);
    if (call is Map) return Map<String, dynamic>.from(call);
    return null;
  }
}
