class PageChatThread {
  final String pageId;
  final String userId;
  final String ownerId;
  final String peerName;
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
        list.firstWhere((e) => e.trim().isNotEmpty && e.trim() != 'null', orElse: () => '');

    Map<String, dynamic> _pickLastMsg(dynamic raw) {
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is List && raw.isNotEmpty) {
        final last = raw.last;
        if (last is Map) return Map<String, dynamic>.from(last);
        if (raw.first is Map) return Map<String, dynamic>.from(raw.first);
      }
      return <String, dynamic>{};
    }

    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(_s(v)) ?? 0;
    }

    String _inferTypeFromUrlOrName(String s) {
      final v = s.toLowerCase();
      if (v.contains('.jpg') || v.contains('.jpeg') || v.contains('.png') || v.contains('.webp') || v.contains('.gif')) return 'image';
      if (v.contains('.mp4') || v.contains('.mov') || v.contains('.mkv') || v.contains('.webm')) return 'video';
      if (v.contains('.mp3') || v.contains('.aac') || v.contains('.m4a') || v.contains('.wav') || v.contains('.ogg')) return 'audio';
      if (v.contains('.pdf') || v.contains('.doc') || v.contains('.docx') || v.contains('.xls') || v.contains('.xlsx') || v.contains('.zip') || v.contains('.rar')) return 'file';
      return '';
    }

    String _tagFromType(String type) {
      switch (type) {
        case 'image':
        case 'photo':
        case 'gif':
          return '[Image]';
        case 'video':
          return '[Video]';
        case 'voice':
        case 'audio':
          return '[Voice]';
        case 'file':
        case 'document':
          return '[File]';
        case 'sticker':
          return '[Sticker]';
        default:
          return type.isNotEmpty ? '[$type]' : '';
      }
    }

    final Map<String, dynamic> lastMsg = _pickLastMsg(json['last_message']);
    final Map<String, dynamic> rootUserData = _m(json['user_data']);
    final Map<String, dynamic> lastUserData = _m(lastMsg['user_data']);

    final bool isMyPage = json['is_page_onwer'] == 1 || json['is_page_onwer'] == true;

    final String pageId = _s(json['page_id']);
    final String pageTitle = _s(json['name']);
    final String pageName = _s(json['page_name']);

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
        final n = _firstNonEmpty([_s(lastUserData['name']), _s(lastUserData['username'])]);
        if (n.isNotEmpty) return n;
      }
      if (id == fromId) {
        final n = _firstNonEmpty([_s(lastMsg['from_name']), _s(lastMsg['from_username'])]);
        if (n.isNotEmpty) return n;
      }
      if (id == toId) {
        final n = _firstNonEmpty([_s(lastMsg['to_name']), _s(lastMsg['to_username'])]);
        if (n.isNotEmpty) return n;
      }
      if (_s(rootUserData['user_id']) == id) {
        final n = _firstNonEmpty([_s(rootUserData['name']), _s(rootUserData['username'])]);
        if (n.isNotEmpty) return n;
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

    String lastMessageText = _firstNonEmpty([
      _s(lastMsg['display_text']),
      _s(lastMsg['text']),
      _s(lastMsg['message']),
      _s(lastMsg['textDecoded']),
    ]);

    String lastType = _firstNonEmpty([
      _s(lastMsg['type_two']),
      _s(lastMsg['message_type']),
      _s(lastMsg['type']),
      _s(lastMsg['media_type']),
    ]).toLowerCase();

    if (lastType.isEmpty) {
      final fileLike = _firstNonEmpty([
        _s(lastMsg['media']),
        _s(lastMsg['file']),
        _s(lastMsg['media_file']),
        _s(lastMsg['mediaFile']),
        _s(lastMsg['mediaFileName']),
        _s(lastMsg['mediaFileUrl']),
      ]);
      lastType = _inferTypeFromUrlOrName(fileLike);
    }

    if (lastMessageText.isEmpty) {
      lastMessageText = _tagFromType(lastType);
    }

    final bool lastFromOwner = ownerId.isNotEmpty && fromId == ownerId;
    final int seen = _asInt(lastMsg['seen']);
    final bool isUnreadCustomerMsg = !lastFromOwner && seen == 0;

    return PageChatThread(
      pageId: pageId,
      userId: peerId,
      ownerId: ownerId,
      peerName: peerName.isNotEmpty ? peerName : peerId,
      peerAvatar: peerAvatar,
      pageName: pageName,
      pageTitle: pageTitle,
      isMyPage: isMyPage,
      lastMessage: lastMessageText,
      lastMessageTime: _firstNonEmpty([_s(lastMsg['date_time']), _s(lastMsg['time']), _s(lastMsg['timestamp'])]),
      unreadCount: isUnreadCustomerMsg ? 1 : 0,
      avatar: peerAvatar.isNotEmpty ? peerAvatar : _s(json['avatar']),
      lastMessageType: lastType,
    );
  }
}