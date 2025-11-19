class PageMessage {
  final int id;
  final int fromId;
  final int toId;
  final int pageId;
  final String text;
  final String timeText;
  final bool isOwner;      // "onwer": 1
  final String position;   // "right" / "left"
  final String type;       // "right_text" ...

  const PageMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.pageId,
    required this.text,
    required this.timeText,
    required this.isOwner,
    required this.position,
    required this.type,
  });

  factory PageMessage.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      return s == '1' || s == 'true';
    }

    return PageMessage(
      id: _toInt(json['id']),
      fromId: _toInt(json['from_id']),
      toId: _toInt(json['to_id']),
      pageId: _toInt(json['page_id']),
      text: (json['text'] ?? '') as String,
      timeText: (json['time_text'] ?? '') as String,
      isOwner: _toBool(json['onwer']),
      position: (json['position'] ?? '') as String,
      type: (json['type'] ?? '') as String,
    );
  }

  static List<PageMessage> listFromJson(List<dynamic> data) {
    return data
        .map((e) => PageMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
