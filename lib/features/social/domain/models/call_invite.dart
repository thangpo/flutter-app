class CallInvite {
  final int callId;
  final String media; // 'audio' | 'video'
  final int tsMs; // timestamp msec

  CallInvite({required this.callId, required this.media, required this.tsMs});

  static const String prefix = '__CALL_INVITE__';

  static String encode({required int callId, required String media}) {
    return '$prefix|$callId|$media|${DateTime.now().millisecondsSinceEpoch}';
    // ví dụ: __CALL_INVITE__|12|video|1730879999000
  }

  static CallInvite? tryParse(String? text) {
    if (text == null || !text.startsWith(prefix)) return null;
    final p = text.split('|');
    if (p.length < 4) return null;
    final id = int.tryParse(p[1]);
    final media = p[2];
    final ts = int.tryParse(p[3]) ?? 0;
    if (id == null) return null;
    return CallInvite(callId: id, media: media, tsMs: ts);
  }

  bool isExpired([int seconds = 45]) =>
      DateTime.now().millisecondsSinceEpoch - tsMs > seconds * 1000;
}
