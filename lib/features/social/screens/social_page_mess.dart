import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chats_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_page_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

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
      context.read<SocialPageController>().startPageChatListPolling();
    });
  }

  @override
  void dispose() {
    context.read<SocialPageController>().stopPageChatListPolling();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

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
        title: Text(
          getTranslated('pages', context) ?? 'Trang',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Header + search + tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary.withOpacity(.15), cs.surfaceVariant],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chat_bubble_outline, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTranslated('page_messages', context) ??
                                  'Tin nhắn Page',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              getTranslated(
                                  'page_messages_subtitle', context) ??
                                  'Theo dõi hội thoại khách hàng và Page của bạn',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText:
                    getTranslated('search_page_conversation', context) ??
                        'Tìm kiếm hội thoại hoặc tên Page',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniTabChip(
                      label: getTranslated('all', context) ?? 'Tất cả',
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    _MiniTabChip(
                      label:
                      getTranslated('my_pages', context) ?? 'Page của tôi',
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: threads.length,
                itemBuilder: (_, index) {
                  final item = threads[index];

                  // TAB FILTER
                  if (_tabIndex == 1 && !item.isMyPage) {
                    return const SizedBox.shrink();
                  }

                  final bool isOwner = item.isMyPage;
                  final String displayName = isOwner
                      ? (item.peerName.isNotEmpty
                      ? item.peerName
                      : item.pageTitle)
                      : item.pageTitle;
                  final String subtitle =
                  isOwner ? '(${item.pageName})' : '@${item.pageName}';
                  final String avatarUrl =
                  isOwner && item.peerAvatar.isNotEmpty
                      ? item.peerAvatar
                      : item.avatar;
                  final String avatarFallback = displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?';

                  final String chatTitle = item.isMyPage
                      ? (item.peerName.isNotEmpty
                      ? item.peerName
                      : item.pageTitle)
                      : item.pageTitle;
                  final String chatAvatar =
                  item.isMyPage && item.peerAvatar.isNotEmpty
                      ? item.peerAvatar
                      : item.avatar;

                  return InkWell(
                    onTap: () {
                      final recipientId =
                      item.isMyPage ? item.userId : item.ownerId;

                      context
                          .read<SocialPageController>()
                          .markPageThreadRead(
                        item.pageId,
                        peerId: recipientId,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PageChatScreen(
                            pageId: int.parse(item.pageId),
                            recipientId: recipientId,
                            pageTitle: chatTitle,
                            pageAvatar: chatAvatar,
                            pageSubtitle: subtitle,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          // AVATAR
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant
                                    .withOpacity(.3),
                                child: avatarUrl.isEmpty
                                    ? Text(
                                  avatarFallback,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(width: 14),

                          // INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight:
                                          item.unreadCount > 0
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      item.lastMessageTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(.6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(.7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.lastMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: item.unreadCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: item.unreadCount > 0
                                        ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
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

      // FOOTER NAV
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 8 + bottomInset,
        ),
        child: _GroupFooterNav(
          currentIndex: 1, // màn Page messages
          chatBadgeCount: 0,
          showNotifDot: false,
          onTap: (i) {
            if (i == 1) return; // đang ở tab Pages rồi

            if (i == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FriendsListScreen(accessToken: widget.accessToken),
                ),
              );
              return;
            }

            if (i == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GroupChatsScreen(accessToken: widget.accessToken),
                ),
              );
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  getTranslated(
                      'navigation_not_implemented', context) ??
                      'Chưa gắn điều hướng cho tab $i',
                ),
              ),
            );
          },
        ),
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
    return const SizedBox.shrink(); // unused
  }
}

/// =====================
/// Footer Nav
/// =====================
class _GroupFooterNav extends StatelessWidget {
  final int currentIndex;
  final int chatBadgeCount;
  final bool showNotifDot;
  final ValueChanged<int> onTap;

  const _GroupFooterNav({
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
          borderRadius: BorderRadius.circular(999),
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
                        child: _Badge(text: (badge!).toString()),
                      ),
                    if (dot)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: _Dot(color: Colors.red),
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
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.5),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            item(
              index: 0,
              icon: Icons.chat_bubble,
              label:
              getTranslated('chat_section', context) ?? 'Đoạn chat',
              badge: chatBadgeCount,
            ),
            item(
              index: 1,
              icon: Icons.flag_outlined,
              label: getTranslated('pages', context) ?? 'Pages',
            ),
            item(
              index: 2,
              icon: Icons.groups,
              label:
              getTranslated('group_chat', context) ?? 'Nhóm chat',
              dot: showNotifDot,
            ),
            item(
              index: 3,
              icon: Icons.menu,
              label: getTranslated('menu', context) ?? 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
