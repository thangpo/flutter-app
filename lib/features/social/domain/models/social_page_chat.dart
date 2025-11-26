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
    String _s(dynamic v) => (v ?? '').toString();
    Map<String, dynamic> _m(dynamic src) =>
        src is Map ? Map<String, dynamic>.from(src as Map) : <String, dynamic>{};
    String _firstNonEmpty(Iterable<String> list) =>
        list.firstWhere((e) => e.isNotEmpty, orElse: () => '');

    final Map<String, dynamic> lastMsg = _m(json['last_message']);
    final Map<String, dynamic> rootUserData = _m(json['user_data']);
    final Map<String, dynamic> lastUserData = _m(lastMsg['user_data']);

    final bool isMyPage =
        json['is_page_onwer'] == 1 || json['is_page_onwer'] == true;

    final String pageId = _s(json['page_id']);
    final String pageTitle = _s(json['name']);
    final String pageName = _s(json['page_name']);

    // Owner of the page (WoWonder thường set user_id = owner)
    final String ownerId = _firstNonEmpty(<String>[
      _s(json['page_owner_id']),
      _s(json['owner_id']),
      _s(json['page_user_id']),
      _s(json['user_id']),
      _s(lastMsg['owner_id']),
      _s(lastMsg['page_owner_id']),
    ]);

    final String fromId = _s(lastMsg['from_id']);
    final String toId = _s(lastMsg['to_id']);

    // Determine peer (customer), avoiding owner/page ids
    String peerId = '';
    if (ownerId.isNotEmpty) {
      if (fromId == ownerId && toId.isNotEmpty) peerId = toId;
      if (toId == ownerId && fromId.isNotEmpty) peerId = fromId;
    }
    if (peerId.isEmpty) {
      peerId = _firstNonEmpty(<String>[
        _s(json['recipient_id']),
        _s(lastMsg['recipient_id']),
        _s(rootUserData['user_id']),
        _s(lastUserData['user_id']),
        fromId,
        toId,
      ].where((id) => id.isNotEmpty && id != ownerId && id != pageId));
    }

    String _pickName(String id) {
      if (id.isEmpty) return '';
      if (_s(lastUserData['user_id']) == id) {
        final n = _firstNonEmpty([
          _s(lastUserData['name']),
          _s(lastUserData['username']),
        ]);
        if (n.isNotEmpty && n != 'null') return n;
      }
      if (id == fromId) {
        final n = _firstNonEmpty([_s(lastMsg['from_name']), _s(lastMsg['from_username'])]);
        if (n.isNotEmpty && n != 'null') return n;
      }
      if (id == toId) {
        final n = _firstNonEmpty([_s(lastMsg['to_name']), _s(lastMsg['to_username'])]);
        if (n.isNotEmpty && n != 'null') return n;
      }
      if (_s(rootUserData['user_id']) == id) {
        final n = _firstNonEmpty([_s(rootUserData['name']), _s(rootUserData['username'])]);
        if (n.isNotEmpty && n != 'null') return n;
      }
      return '';
    }

    String _pickAvatar(String id) {
      if (id.isEmpty) return '';
      if (_s(lastUserData['user_id']) == id) {
        final a = _s(lastUserData['avatar']);
        if (a.isNotEmpty && a != 'null') return a;
      }
      if (id == fromId) {
        final a = _s(lastMsg['from_avatar']);
        if (a.isNotEmpty && a != 'null') return a;
      }
      if (id == toId) {
        final a = _s(lastMsg['to_avatar']);
        if (a.isNotEmpty && a != 'null') return a;
      }
      if (_s(rootUserData['user_id']) == id) {
        final a = _s(rootUserData['avatar']);
        if (a.isNotEmpty && a != 'null') return a;
      }
      return '';
    }

    final String peerName = _pickName(peerId);
    final String peerAvatar = _pickAvatar(peerId);

    final bool lastFromOwner = ownerId.isNotEmpty && fromId == ownerId;
    final bool isUnreadCustomerMsg =
        !lastFromOwner && _s(lastMsg['seen']) == '0';

    return PageChatThread(
      pageId: pageId,
      userId: peerId,
      ownerId: ownerId,
      peerName: peerName.isNotEmpty ? peerName : peerId,
      peerAvatar: peerAvatar,
      pageName: pageName,
      pageTitle: pageTitle,
      isMyPage: isMyPage,
      lastMessage: _s(lastMsg['text']),
      lastMessageTime: _s(lastMsg['date_time']),
      unreadCount: isUnreadCustomerMsg ? 1 : 0,
      avatar: peerAvatar.isNotEmpty ? peerAvatar : _s(json['avatar']),
      lastMessageType: _s(lastMsg['type']),
    );
  }
}
