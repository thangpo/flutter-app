import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_page_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chats_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/chat_preview_helper.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';

class PageMessagesScreen extends StatefulWidget {
  final String accessToken;
  final bool showFooterNav;

  const PageMessagesScreen(
      {super.key, required this.accessToken, this.showFooterNav = true});

  @override
  State<PageMessagesScreen> createState() => _PageMessagesScreenState();
}

class _PageMessagesScreenState extends State<PageMessagesScreen> {
  int _tabIndex = 0;

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
    super.dispose();
  }

  int _normalizedTimestamp(int ts) {
    if (ts <= 0) return 0;
    return ts > 2000000000 ? (ts ~/ 1000) : ts;
  }

  int _pageTimestamp(PageChatThread t) {
    final raw = t.lastMessageTime.trim();
    if (raw.isEmpty) return 0;

    final numeric = int.tryParse(raw);
    if (numeric != null) return _normalizedTimestamp(numeric);

    try {
      final dt = DateTime.parse(raw);
      return dt.millisecondsSinceEpoch ~/ 1000;
    } catch (_) {}

    final parts = raw.split(':');
    if (parts.length == 2) {
      final now = DateTime.now();
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return DateTime(now.year, now.month, now.day, h, m)
            .millisecondsSinceEpoch ~/
            1000;
      }
    }
    return 0;
  }

  String _formatTimestampLabel(int ts) {
    if (ts <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);
    String two(int n) => n.toString().padLeft(2, '0');

    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return '${two(dt.hour)}:${two(dt.minute)}';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final sameYear = dt.year == now.year;
    return '${two(dt.day)}/${two(dt.month)}${sameYear ? '' : '/${dt.year}'}';
  }

  String _pagePreview(PageChatThread t, BuildContext context) {
    final rawText = t.lastMessage.trim();
    final type = (t.lastMessageType ?? '').toString().toLowerCase().trim();

    // 1) Nếu có text -> normalize như bình thường
    if (rawText.isNotEmpty) {
      final normalized = normalizeChatPreview(rawText, context).trim();

      // Có trường hợp text là HTML/placeholder bị helper strip sạch => fallback theo raw/type
      if (normalized.isNotEmpty) return normalized;
    }

    // 2) Fallback theo type (nếu có)
    String tag = _tagFromType(type);

    // 3) Nếu type cũng rỗng -> đoán từ rawText (kể cả rawText rỗng thì vẫn thử)
    tag = tag.isNotEmpty ? tag : _tagFromRaw(rawText);

    // 4) Nếu vẫn không đoán được -> message trống
    if (tag.isEmpty) {
      return getTranslated('no_messages_yet', context) ?? 'Bắt đầu đoạn chat';
    }

    return normalizeChatPreview(tag, context);
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

  String _tagFromRaw(String raw) {
    final s = raw.toLowerCase();

    if (s.contains('<img') || s.contains('upload/photos') || s.contains('.jpg') || s.contains('.jpeg') || s.contains('.png') || s.contains('.webp') || s.contains('.gif')) {
      return '[Image]';
    }
    if (s.contains('upload/videos') || s.contains('.mp4') || s.contains('.mov') || s.contains('.mkv') || s.contains('.webm')) {
      return '[Video]';
    }
    if (s.contains('upload/audio') || s.contains('upload/voice') || s.contains('.mp3') || s.contains('.aac') || s.contains('.m4a') || s.contains('.wav') || s.contains('.ogg')) {
      return '[Voice]';
    }
    if (s.contains('upload/files') || s.contains('.pdf') || s.contains('.doc') || s.contains('.docx') || s.contains('.xls') || s.contains('.xlsx') || s.contains('.zip') || s.contains('.rar')) {
      return '[File]';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final pageCtrl = context.watch<SocialPageController>();
    final List<PageChatThread> threads = pageCtrl.pageChatList;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SegmentedTabs(
                  index: _tabIndex,
                  labels: [
                    getTranslated('all', context) ?? 'All',
                    getTranslated('my_pages', context) ?? 'My Pages',
                  ],
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
              ],
            ),
          ),

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

                        if (_tabIndex == 1 && !item.isMyPage) {
                          return const SizedBox.shrink();
                        }

                        final bool isOwner = item.isMyPage;
                        final String displayName = isOwner
                            ? (item.peerName.isNotEmpty
                                ? item.peerName
                                : item.pageTitle)
                            : item.pageTitle;
                        final String subtitle = isOwner
                            ? '(${item.pageName})'
                            : '@${item.pageName}';
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
                        final ts = _pageTimestamp(item);
                        final timeLabel = _formatTimestampLabel(ts);
                        final preview = _pagePreview(item, context);

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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: Colors.transparent,
                            child: Row(
                              children: [
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
                                                fontWeight: item.unreadCount > 0
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            timeLabel.isNotEmpty ? timeLabel : item.lastMessageTime,
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
                                        preview.isNotEmpty ? preview : item.lastMessage,
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

      bottomNavigationBar: widget.showFooterNav
          ? Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 8 + bottomInset,
              ),
              child: _GroupFooterNav(
                currentIndex: 1,
                chatBadgeCount: 0,
                showNotifDot: false,
                onTap: (i) {
                  if (i == 1) return;

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
                        builder: (_) => DashboardChatScreen(
                          accessToken: widget.accessToken,
                          initialIndex: 2,
                        ),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        getTranslated('navigation_not_implemented', context) ??
                            'Chưa gắn điều hướng cho tab $i',
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFEDEDED);
    final border = isDark ? Colors.white12 : Colors.black12;
    final active = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final activeText = isDark ? Colors.white : Colors.black87;
    final inactiveText = isDark ? Colors.white70 : Colors.black54;

    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;
        final itemW = w / labels.length;

        return Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: itemW * index,
                top: 0,
                bottom: 0,
                width: itemW,
                child: Container(
                  decoration: BoxDecoration(
                    color: active,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final selected = i == index;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? activeText : inactiveText,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    return const SizedBox.shrink();
  }
}

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
              label: getTranslated('chat_section', context) ?? 'Đoạn chat',
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
              label: getTranslated('group_chat', context) ?? 'Nhóm chat',
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