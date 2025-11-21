class PageChatThread {
  final String pageId;    // ID of the Page
  final String userId;    // Peer ID (use as recipient_id when fetch/send)
  final String ownerId;   // Page owner ID
  final String peerName;  // Peer display name
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

  factory PageChatThread.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> lastMsg = json['last_message'] ?? {};
    final Map<String, dynamic> userData = lastMsg['user_data'] ?? {};
    final String ownerId = (json['user_id'] ?? '').toString();
    final String peerName =
        (userData['name'] ?? userData['username'] ?? '').toString();
    final String peerAvatar = (userData['avatar'] ?? '').toString();

    // Peer = the other end of the conversation (recipient_id to use).
    final String fromId = (lastMsg['from_id'] ?? '').toString();
    final String toId = (lastMsg['to_id'] ?? '').toString();
    final String userDataId = (userData['user_id'] ?? '').toString();

    String peerId = '';
    if (fromId.isNotEmpty && toId.isNotEmpty) {
      if (fromId == ownerId) {
        peerId = toId;
      } else if (toId == ownerId) {
        peerId = fromId;
      }
    }

    if (peerId.isEmpty && userDataId.isNotEmpty && userDataId != ownerId) {
      peerId = userDataId;
    }

    if (peerId.isEmpty) {
      peerId = fromId.isNotEmpty ? fromId : toId;
    }

    return PageChatThread(
      pageId: json['page_id']?.toString() ?? '',
      userId: peerId,
      ownerId: ownerId,
      peerName: peerName,
      peerAvatar: peerAvatar,
      pageName: json['page_name']?.toString() ?? '',
      pageTitle: json['name']?.toString() ?? '',
      isMyPage: json['is_page_onwer'] == 1 || json['is_page_onwer'] == true,
      lastMessage: lastMsg['text']?.toString() ?? '',
      lastMessageTime: lastMsg['date_time']?.toString() ?? '',
      unreadCount: (lastMsg['seen']?.toString() == "0") ? 1 : 0,
      avatar: json['avatar']?.toString() ?? '',
      lastMessageType: lastMsg['type']?.toString() ?? '',
    );
  }
}
