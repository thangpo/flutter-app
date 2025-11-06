class IceCandidateLite {
  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  IceCandidateLite({
    required this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });

  factory IceCandidateLite.fromJson(Map<String, dynamic> j) {
    return IceCandidateLite(
      candidate: (j['candidate'] ?? '').toString(),
      sdpMid: j['sdp_mid']?.toString(),
      sdpMLineIndex: j['sdp_mline_index'] == null
          ? null
          : int.tryParse(j['sdp_mline_index'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'candidate': candidate,
        'sdp_mid': sdpMid,
        'sdp_mline_index': sdpMLineIndex,
      };
}
