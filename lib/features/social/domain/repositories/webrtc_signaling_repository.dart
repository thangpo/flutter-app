import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ice_candidate_lite.dart';

class CreateCallResult {
  final int callId;
  final String status; // ringing | answered | declined | ended
  final String mediaType; // audio | video
  CreateCallResult({
    required this.callId,
    required this.status,
    required this.mediaType,
  });
}

class PollResult {
  final String? callStatus; // ringing | answered | declined | ended
  final String? mediaType; // audio | video
  final String? sdpOffer; // raw SDP
  final String? sdpAnswer; // raw SDP
  final List<IceCandidateLite> iceCandidates;

  PollResult({
    this.callStatus,
    this.mediaType,
    this.sdpOffer,
    this.sdpAnswer,
    this.iceCandidates = const [],
  });
}

class WebRTCSignalingRepository {
  WebRTCSignalingRepository({
    String? baseUrl,
    String? serverKey,
    this.accessTokenKey = 'socialAccessToken',
    http.Client? client,
    this.enableLogging = true,
  })  : baseUrl =
            (baseUrl ?? AppConstants.baseUrl).replaceAll(RegExp(r'/$'), ''),
        serverKey = serverKey ?? _defaultServerKey,
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final bool enableLogging;

  /// Mặc định dùng server_key WoWonder, có thể truyền qua constructor
  static const String _defaultServerKey =
      'f6e69c898ddd643154c9bd4b152555842e26a868-d195c100005dddb9f1a30a67a5ae42d4-19845955';
  final String serverKey;

  final String accessTokenKey;
  static const String _logName = 'WebRTCSignaling';

  void _log(String message, {Object? error, StackTrace? stack}) {
    if (!enableLogging) return;
    developer.log(message, name: _logName, error: error, stackTrace: stack);
  }

  /// Nếu server chưa có route `/api/webrtc`, có thể đổi endpoint ở đây.
  String get _endpoint => '$baseUrl/api-v2.php';

  Future<String> _getAccessToken() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(accessTokenKey);
    if (token == null || token.isEmpty) {
      throw Exception(
        'Không có access_token mạng xã hội trong SharedPreferences ($accessTokenKey).',
      );
    }
    return token;
  }

  Future<Map<String, dynamic>> _multipartPost(
    Map<String, String> fields,
  ) async {
    final uri = Uri.parse(_endpoint);
    final req = http.MultipartRequest('POST', uri);

    req.fields['server_key'] = serverKey;
    req.fields['access_token'] = await _getAccessToken();

    // báo cho PHP biết đây là router webrtc
    req.fields['type'] = 'webrtc';

    // xác định sub_type (create, offer, answer, ...)
    final subType = fields['type'];
    fields.remove('type');
    req.fields['sub_type'] = subType ?? '';

    req.fields.addAll(fields);
    _log('POST $_endpoint subType=$subType fields=${req.fields.keys.toList()}');

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      final msg =
          'WebRTC API ${subType ?? '?'} failed (HTTP ${res.statusCode}): ${res.body}';
      _log(msg);
      throw Exception(msg);
    }
    final Map<String, dynamic> json = jsonDecode(res.body);
    final apiStatus = json['api_status'];
    if (apiStatus == '400' || apiStatus == 400 || apiStatus == '404') {
      final err = json['errors']?['error_text'] ??
          json['error'] ??
          json['error_message'] ??
          'Unknown error';
      final msg = 'WebRTC API ${subType ?? '?'} error: $err';
      _log(msg);
      throw Exception(msg);
    }
    _log(
        'WebRTC API ${subType ?? '?'} ok api_status=$apiStatus keys=${json.keys.toList()}');
    return json;
  }

  // ------------------------
  // Public APIs
  // ------------------------

  Future<CreateCallResult> create({
    required int recipientId,
    required String mediaType, // 'audio' | 'video'
  }) async {
    _log('create(recipient=$recipientId, mediaType=$mediaType)');
    final json = await _multipartPost({
      'type': 'create',
      'recipient_id': recipientId.toString(),
      'media_type': (mediaType == 'video') ? 'video' : 'audio',
    });

    final id = int.tryParse('${json['call_id'] ?? 0}') ?? 0;
    if (id <= 0) {
      throw Exception(
          'Create call không trả về call_id hợp lệ: ${jsonEncode(json)}');
    }
    final status = (json['status'] ?? 'ringing').toString();
    final mtype = (json['media_type'] ?? mediaType).toString();
    _log('create -> callId=$id status=$status mediaType=$mtype');
    return CreateCallResult(callId: id, status: status, mediaType: mtype);
  }

  Future<void> offer({required int callId, required String sdp}) async {
    _log('offer(callId=$callId, sdpLen=${sdp.length})');
    await _multipartPost({
      'type': 'offer',
      'call_id': '$callId',
      'sdp': sdp,
    });
  }

  Future<void> answer({required int callId, required String sdp}) async {
    _log('answer(callId=$callId, sdpLen=${sdp.length})');
    await _multipartPost({
      'type': 'answer',
      'call_id': '$callId',
      'sdp': sdp,
    });
  }

  Future<void> candidate({
    required int callId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    _log(
        'candidate(callId=$callId, mid=${sdpMid ?? '-'}, mline=${sdpMLineIndex ?? '-'}, len=${candidate.length})');
    final fields = <String, String>{
      'type': 'candidate',
      'call_id': '$callId',
      'candidate': candidate,
    };
    if (sdpMid != null) fields['sdp_mid'] = sdpMid;
    if (sdpMLineIndex != null) fields['sdp_mline_index'] = '$sdpMLineIndex';

    await _multipartPost(fields);
  }

  Future<PollResult> poll({required int callId}) async {
    _log('poll(callId=$callId)');
    final json = await _multipartPost({
      'type': 'poll',
      'call_id': '$callId',
    });

    String? callStatus;
    String? mediaType;
    String? sdpOffer;
    String? sdpAnswer;
    final List<IceCandidateLite> ice = [];

    if (json['call_status'] != null && '${json['call_status']}'.isNotEmpty) {
      callStatus = '${json['call_status']}';
    }
    if (json['media_type'] != null && '${json['media_type']}'.isNotEmpty) {
      mediaType = '${json['media_type']}' == 'video' ? 'video' : 'audio';
    }

    final o = json['sdp_offer'];
    if (o is Map && o['sdp'] != null && '${o['sdp']}'.isNotEmpty) {
      sdpOffer = '${o['sdp']}';
    }
    final a = json['sdp_answer'];
    if (a is Map && a['sdp'] != null && '${a['sdp']}'.isNotEmpty) {
      sdpAnswer = '${a['sdp']}';
    }

    final cands = json['ice_candidates'];
    if (cands is List) {
      for (final c in cands) {
        if (c is Map &&
            c['candidate'] != null &&
            '${c['candidate']}'.isNotEmpty) {
          ice.add(IceCandidateLite.fromJson(
            c.map((k, v) => MapEntry('$k', v)),
          ));
        }
      }
    }

    _log(
        'poll -> status=$callStatus media=$mediaType offer=${sdpOffer != null} answer=${sdpAnswer != null} ice=${ice.length}');

    return PollResult(
      callStatus: callStatus,
      mediaType: mediaType,
      sdpOffer: sdpOffer,
      sdpAnswer: sdpAnswer,
      iceCandidates: ice,
    );
  }

  /// action: 'answer' | 'decline' | 'end'
  Future<String> action({required int callId, required String action}) async {
    _log('action(callId=$callId, action=$action)');
    final json = await _multipartPost({
      'type': 'action',
      'call_id': '$callId',
      'action': action,
    });
    final status = (json['status'] ?? '').toString();
    _log('action -> status=$status');
    return status.isEmpty ? 'ended' : status;
  }
}
