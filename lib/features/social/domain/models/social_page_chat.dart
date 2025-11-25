class PageChatThread {
  final String pageId; // Page id
  final String userId; // Customer/peer id
  final String ownerId; // Page owner id
  final String peerName; // Customer display name
  final String peerAvatar;
  final String pageName;
  final String pageTitle;
  final bool isMyPage;

  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  final String avatar;
  final String lastMessageType;

  PageChatThread({
    required this.pageId,
    required this.userId,
    required this.ownerId,
    required this.peerName,
    required this.peerAvatar,
    required this.pageName,
    required this.pageTitle,
    required this.isMyPage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.avatar,
    required this.lastMessageType,
  });

  PageChatThread copyWith({
    String? pageId,
    String? userId,
    String? ownerId,
    String? peerName,
    String? peerAvatar,
    String? pageName,
    String? pageTitle,
    bool? isMyPage,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    String? avatar,
    String? lastMessageType,
  }) {
    return PageChatThread(
      pageId: pageId ?? this.pageId,
      userId: userId ?? this.userId,
      ownerId: ownerId ?? this.ownerId,
      peerName: peerName ?? this.peerName,
      peerAvatar: peerAvatar ?? this.peerAvatar,
      pageName: pageName ?? this.pageName,
      pageTitle: pageTitle ?? this.pageTitle,
      isMyPage: isMyPage ?? this.isMyPage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      avatar: avatar ?? this.avatar,
      lastMessageType: lastMessageType ?? this.lastMessageType,
    );
  }

  factory PageChatThread.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> lastMsg =
        (json['last_message'] ?? const <String, dynamic>{})
            as Map<String, dynamic>;

    // owner/page ids
    final String ownerId = [
      lastMsg['owner_id'],
      lastMsg['page_owner_id'],
      json['page_owner_id'],
      json['owner_id'],
      json['page_user_id'],
      json['user_id'],
    ]
        .map((e) => (e ?? '').toString())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');

    final String pageId = (json['page_id'] ?? '').toString();
    final String pageTitle = (json['name'] ?? '').toString();
    final String pageName = (json['page_name'] ?? '').toString();

    final String fromId = (lastMsg['from_id'] ?? '').toString();
    final String toId = (lastMsg['to_id'] ?? '').toString();
    final bool fromIsOwner =
        ownerId.isNotEmpty && fromId.isNotEmpty && fromId == ownerId;
    final bool toIsOwner =
        ownerId.isNotEmpty && toId.isNotEmpty && toId == ownerId;

    // Decide peerId as "other side" (customer)
    String peerId = '';
    if (fromIsOwner && toId.isNotEmpty) {
      peerId = toId;
    } else if (toIsOwner && fromId.isNotEmpty) {
      peerId = fromId;
    } else if (!fromIsOwner && fromId.isNotEmpty) {
      peerId = fromId;
    } else if (!toIsOwner && toId.isNotEmpty) {
      peerId = toId;
    }

    Map<String, dynamic> _toMap(dynamic src) =>
        src is Map<String, dynamic> ? Map<String, dynamic>.from(src) : <String, dynamic>{};

    String _pickName(String id) {
      if (id.isEmpty) return '';
      if (id == fromId) {
        final n = (lastMsg['from_name'] ?? lastMsg['from_username'] ?? '').toString();
        if (n.isNotEmpty) return n;
      }
      if (id == toId) {
        final n = (lastMsg['to_name'] ?? lastMsg['to_username'] ?? '').toString();
        if (n.isNotEmpty) return n;
      }
      for (final candidate in [json['user_data'], lastMsg['user_data']]) {
        final m = _toMap(candidate);
        if ((m['user_id'] ?? '').toString() == id) {
          final n = (m['name'] ?? m['username'] ?? '').toString();
          if (n.isNotEmpty) return n;
        }
      }
      return '';
    }

    String _pickAvatar(String id) {
      if (id.isEmpty) return '';
      if (id == fromId) {
        final a = (lastMsg['from_avatar'] ?? '').toString();
        if (a.isNotEmpty) return a;
      }
      if (id == toId) {
        final a = (lastMsg['to_avatar'] ?? '').toString();
        if (a.isNotEmpty) return a;
      }
      for (final candidate in [json['user_data'], lastMsg['user_data']]) {
        final m = _toMap(candidate);
        if ((m['user_id'] ?? '').toString() == id) {
          final a = (m['avatar'] ?? '').toString();
          if (a.isNotEmpty) return a;
        }
      }
      return '';
    }

    final String peerName = _pickName(peerId);
    final String peerAvatar = _pickAvatar(peerId);

    return PageChatThread(
      pageId: pageId,
      userId: peerId,
      ownerId: ownerId,
      peerName: peerName.isNotEmpty ? peerName : peerId,
      peerAvatar: peerAvatar,
      pageName: pageName,
      pageTitle: pageTitle,
      isMyPage: json['is_page_onwer'] == 1 || json['is_page_onwer'] == true,
      lastMessage: lastMsg['text']?.toString() ?? '',
      lastMessageTime: lastMsg['date_time']?.toString() ?? '',
      unreadCount: (lastMsg['seen']?.toString() == "0") ? 1 : 0,
      avatar: peerAvatar.isNotEmpty ? peerAvatar : (json['avatar']?.toString() ?? ''),
      lastMessageType: lastMsg['type']?.toString() ?? '',
    );
  }
}
