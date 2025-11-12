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

  // ✅ Dùng router để né lỗi .php.php
  static const String endpointPath = '/api/';

  WebRTCGroupSignalingRepositoryImpl({
    required this.baseUrl,
    required this.serverKey,
    required this.getAccessToken,
    this.requestTimeout = const Duration(seconds: 15),
  }) {
    _endpointUri = Uri.parse('$baseUrl$endpointPath');
    if (kDebugMode) {
      debugPrint('[SIGNALING] INIT endpoint=$_endpointUri (router mode)');
    }
  }

  late Uri _endpointUri;

  String _maskKey(String key) {
    if (key.length < 10) return key;
    return '${key.substring(0, 5)}...${key.substring(key.length - 5)}';
  }

  Future<Map<String, dynamic>> _post(
    Map<String, String> fields, {
    bool allow204 = false,
  }) async {
    final token = await getAccessToken();
    final body = <String, String>{
      'type': 'webrtc_group', // 🔑 quan trọng cho router
      'server_key': serverKey.trim(),
      if (token != null && token.isNotEmpty) 'access_token': token,
      ...fields,
    };

    final act = body['action'];
    final keyMasked = _maskKey(serverKey.trim());
    if (kDebugMode) {
      debugPrint(
          '[SIGNALING] POST $_endpointUri | action=$act | server_key(${serverKey.length})=$keyMasked');
    }

    try {
      final resp = await http.post(_endpointUri, body: body).timeout(
            requestTimeout,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      final status = resp.statusCode;
      final txt = resp.body;
      if (kDebugMode) {
        debugPrint(
            '[SIGNALING] RESP $status ${txt.length > 700 ? txt.substring(0, 700) + "..." : txt}');
      }

      if (status < 200 || status >= 300) {
        throw GroupSignalingException(status, 'HTTP $status', txt);
      }

      if (txt.isEmpty) {
        if (allow204) return {'api_status': 204};
        throw GroupSignalingException(status, 'Empty body');
      }

      final json = jsonDecode(txt);
      if (json is! Map) {
        throw GroupSignalingException(status, 'Invalid JSON', txt);
      }

      return Map<String, dynamic>.from(json);
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
    return (json['peers'] as List?)
            ?.map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList() ??
        [];
  }

  @override
  Future<List<int>> peers({required int callId}) async {
    final json = await _post({'action': 'peers', 'call_id': '$callId'});
    return (json['peers'] as List?)
            ?.map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList() ??
        [];
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
    final items = (json['items'] as List?)
            ?.map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
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
  Future<Map<String, dynamic>?> inbox({required String groupId}) async {
    final json =
        await _post({'action': 'inbox', 'group_id': groupId}, allow204: true);
    if (json['api_status'] == 204) return null;
    return Map<String, dynamic>.from(json['call'] ?? {});
  }
}
