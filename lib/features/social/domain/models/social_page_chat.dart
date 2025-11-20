class PageChatThread {
  final String pageId;
  final String chatId;
  final String pageName;
  final String pageTitle;
  final bool isMyPage;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String avatar;

  // MUST HAVE to open chat
  final String recipientId;

  // Nice to have (UI hiển thị icon)
  final String lastMessageType;

  PageChatThread({
    required this.pageId,
    required this.chatId,
    required this.pageName,
    required this.pageTitle,
    required this.isMyPage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.avatar,
    required this.recipientId,
    required this.lastMessageType,
  });

  factory PageChatThread.fromJson(Map<String, dynamic> json) {
    final isMyPage = json['is_page_onwer'] == true || json['is_page_onwer'] == 1;
    final lastMsg = json['last_message'] ?? {};

    return PageChatThread(
      pageId: json['page_id']?.toString() ?? '',
      chatId: json['chat_id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',      // <-- thêm
      pageName: json['page_name'] ?? '',
      pageTitle: json['name'] ?? '',
      isMyPage: isMyPage,
      lastMessage: lastMsg['text'] ?? '',
      lastMessageTime: lastMsg['date_time'] ?? '',
      unreadCount: (lastMsg['seen'] == "0") ? 1 : 0,
      avatar: json['avatar'] ?? '',
      lastMessageType: lastMsg['type']?.toString() ?? '',        // <-- thêm
    );
  }
}
