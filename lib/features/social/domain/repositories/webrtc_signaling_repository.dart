import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple HTTP repository for WoWonder WebRTC signaling.
/// baseUrl ví dụ: https://social.vnshop247.com/api/webrtc
class WebRTCSignalingRepository {
  final String baseUrl;
  final String accessToken;
  final String serverKey;

  WebRTCSignalingRepository({
    required this.baseUrl,
    required this.accessToken,
    required this.serverKey,
  });

  Future<Map<String, dynamic>> _post(Map<String, String> fields) async {
    final uri = Uri.parse('$baseUrl?access_token=$accessToken');
    final req = http.MultipartRequest('POST', uri);
    req.fields['server_key'] = serverKey;
    fields.forEach((k, v) => req.fields[k] = v);

    final res = await req.send();
    final body = await res.stream.bytesToString();

    Map<String, dynamic> data;
    try {
      data = json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Bad JSON: $body');
    }

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }
    final apiStatus = data['api_status'];
    if ((apiStatus is int && apiStatus != 200) ||
        (apiStatus is String && apiStatus != '200')) {
      throw Exception('API error: ${data['errors'] ?? data}');
    }
    return data;
  }

  Future<int> createCall({
    required int recipientId,
    String mediaType = 'audio', // 'audio' | 'video'
  }) async {
    final res = await _post({
      'type': 'create',
      'recipient_id': '$recipientId',
      'media_type': mediaType,
    });
    return (res['call_id'] as num).toInt();
  }

  Future<void> sendOffer({
    required int callId,
    required String sdp,
  }) async {
    await _post({'type': 'offer', 'call_id': '$callId', 'sdp': sdp});
  }

  Future<void> sendAnswer({
    required int callId,
    required String sdp,
  }) async {
    await _post({'type': 'answer', 'call_id': '$callId', 'sdp': sdp});
  }

  Future<void> sendCandidate({
    required int callId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    final fields = <String, String>{
      'type': 'candidate',
      'call_id': '$callId',
      'candidate': candidate,
    };
    if (sdpMid != null) fields['sdp_mid'] = sdpMid;
    if (sdpMLineIndex != null) fields['sdp_mline_index'] = '$sdpMLineIndex';
    await _post(fields);
  }

  Future<PollResult> poll({required int callId}) async {
    final res = await _post({'type': 'poll', 'call_id': '$callId'});
    return PollResult.fromJson(res);
  }

  /// action: 'answer' | 'decline' | 'end'
  Future<String> action({required int callId, required String action}) async {
    final res =
        await _post({'type': 'action', 'call_id': '$callId', 'action': action});
    return '${res['status']}';
  }
}

class PollResult {
  final String callStatus;
  final String mediaType;
  final String? sdpOffer;
  final String? sdpAnswer;
  final List<IceCandidatePayload> iceCandidates;

  PollResult({
    required this.callStatus,
    required this.mediaType,
    required this.sdpOffer,
    required this.sdpAnswer,
    required this.iceCandidates,
  });

  factory PollResult.fromJson(Map<String, dynamic> json) {
    String? readSdp(dynamic obj) {
      if (obj == null) return null;
      if (obj is Map<String, dynamic>) {
        final sdp = obj['sdp'];
        if (sdp is String) return sdp;
      }
      return null;
    }

    final cands = <IceCandidatePayload>[];
    final arr = json['ice_candidates'];
    if (arr is List) {
      for (final item in arr) {
        if (item is Map<String, dynamic>) {
          cands.add(IceCandidatePayload.fromJson(item));
        }
      }
    }

    return PollResult(
      callStatus: json['call_status']?.toString() ?? '',
      mediaType: json['media_type']?.toString() ?? 'audio',
      sdpOffer: readSdp(json['sdp_offer']),
      sdpAnswer: readSdp(json['sdp_answer']),
      iceCandidates: cands,
    );
  }
}

class IceCandidatePayload {
  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  IceCandidatePayload({
    required this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });

  factory IceCandidatePayload.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return IceCandidatePayload(
      candidate: json['candidate']?.toString() ?? '',
      sdpMid: json['sdp_mid']?.toString(),
      sdpMLineIndex: toInt(json['sdp_mline_index']),
    );
  }
}
