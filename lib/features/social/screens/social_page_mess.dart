import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chats_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_page_screen.dart';


class PageMessagesScreen extends StatefulWidget {
  final String accessToken;

  const PageMessagesScreen({super.key, required this.accessToken});

  @override
  State<PageMessagesScreen> createState() => _PageMessagesScreenState();
}

class _PageMessagesScreenState extends State<PageMessagesScreen> {
  int _tabIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SocialPageController>().loadPageChatList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final pageCtrl = context.watch<SocialPageController>();
    final List<PageChatThread> origin = pageCtrl.pageChatList;

    // SEARCH
    final List<PageChatThread> threads = origin.where((item) {
      if (_searchCtrl.text.isEmpty) return true;
      final q = _searchCtrl.text.toLowerCase();
      return item.pageTitle.toLowerCase().contains(q) ||
          item.pageName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 0,
        title: const Text(
          'Trang',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // SEARCH BOX
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm hội thoại hoặc tên Page',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // HEADER + TABS
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(Icons.flag, size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tin nhắn Page',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'Quản lý tin nhắn khách hàng cho các Page của bạn',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _MiniTabChip(
                      label: 'Tất cả tin nhắn',
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    _MiniTabChip(
                      label: 'Page của tôi',
                      selected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                  ],
                )
              ],
            ),
          ),

          // LIST
          Expanded(
            child: pageCtrl.loadingPageChatList
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: () => pageCtrl.refreshPageChatList(),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: threads.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(.5),
                ),
                itemBuilder: (_, index) {
                  final item = threads[index];
                  final bool isOwner = item.isMyPage;
                  final String displayName = isOwner
                      ? (item.peerName.isNotEmpty ? item.peerName : item.pageTitle)
                      : item.pageTitle;
                  final String subtitle =
                      isOwner ? '(${item.pageName})' : '@${item.pageName}';
                  final String avatarUrl = isOwner && item.peerAvatar.isNotEmpty
                      ? item.peerAvatar
                      : item.avatar;
                  final String avatarFallback =
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

                  // TAB FILTER
                  if (_tabIndex == 1 && !item.isMyPage) {
                    return const SizedBox.shrink();
                  }

                  return InkWell(
                    onTap: () {
                      final recipientId =
                          item.isMyPage ? item.userId : item.ownerId;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PageChatScreen(
                            pageId: int.parse(item.pageId),
                            recipientId: recipientId,
                            pageTitle: item.pageTitle,
                            pageAvatar: item.avatar,
                          ),
                        ),
                      );
                    },

                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          // AVATAR
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                backgroundColor: cs.surfaceVariant,
                                child: avatarUrl.isEmpty
                                    ? Text(
                                        avatarFallback,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              if (item.isMyPage)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                            ],
                          ),

                          const SizedBox(width: 10),

                          // INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // NAME + TIME
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.lastMessageTime,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurface.withOpacity(.6),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 3),

                                // USERNAME
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withOpacity(.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 3),

                                // LAST MESSAGE + BADGE
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: cs.onSurface.withOpacity(.75),
                                        ),
                                      ),
                                    ),
                                    if (item.unreadCount > 0)
                                      const SizedBox(width: 8),
                                    if (item.unreadCount > 0)
                                      _UnreadBadge(count: item.unreadCount),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _PageMessengerFooter(
        currentIndex: 1,
        chatBadgeCount: 0,
        showNotifDot: false,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FriendsListScreen(accessToken: widget.accessToken),
              ),
            );
          } else if (i == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GroupChatsScreen(accessToken: widget.accessToken),
              ),
            );
          }
        },
      ),
    );
  }
}

/* -------------------------------------------------------------
   COMPONENTS
------------------------------------------------------------- */

class _MiniTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: .7,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PageMessengerFooter extends StatelessWidget {
  final int currentIndex;
  final int chatBadgeCount;
  final bool showNotifDot;
  final ValueChanged<int> onTap;

  const _PageMessengerFooter({
    required this.currentIndex,
    required this.chatBadgeCount,
    required this.showNotifDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget item({
      required int index,
      required IconData icon,
      required String label,
      int? badge,
      bool dot = false,
    }) {
      final bool active = currentIndex == index;
      final Color iconColor = active ? Colors.blue : Colors.grey.shade700;
      final Color textColor = active ? Colors.blue : Colors.grey.shade700;

      return Expanded(
        child: InkWell(
          onTap: () => onTap(index),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 24, color: iconColor),
                    if ((badge ?? 0) > 0)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (dot)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: const CircleAvatar(radius: 4, backgroundColor: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: cs.outlineVariant, width: .5),
          ),
        ),
        child: Row(
          children: [
            item(index: 0, icon: Icons.chat_bubble, label: 'Chat', badge: chatBadgeCount),
            item(index: 1, icon: Icons.video_collection, label: 'Stories'),
            item(index: 2, icon: Icons.groups, label: 'Group Chat', dot: showNotifDot),
            item(index: 3, icon: Icons.menu, label: 'Menu'),
          ],
        ),
      ),
    );
  }
}
