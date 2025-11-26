// G:\flutter-app\lib\features\social\screens\friends_list_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_friends_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_friends_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_mess.dart';

// nhóm chat
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_group_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chats_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';

class FriendsListScreen extends StatefulWidget {
  final String accessToken;
  const FriendsListScreen({super.key, required this.accessToken});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final friendsCtrl =
      Get.put(SocialFriendsController(SocialFriendsRepository()));
  final _chatRepo = SocialChatRepository();
  final searchCtrl = TextEditingController();

  int _tabIndex = 0;
  int chatBadgeCount = 1;
  bool notifDot = true;

  // ✅ static: giữ lại dữ liệu ngay cả khi màn này bị dispose rồi tạo lại
  static final Map<String, int> _localLastActivity = {};
  final Map<String, String> _lastTextCache = {};
  final Map<String, int> _lastTimeCache = {};

  @override
  void initState() {
    super.initState();
    friendsCtrl.load(widget.accessToken, context: context);
  }

  Future<void> _onRefresh() async {
    await friendsCtrl.load(widget.accessToken, context: context);
  }

  /// So sánh để sort theo thời gian tin nhắn/hoạt động cuối (mới nhất lên trên)
  int _compareByLastMessage(SocialFriend a, SocialFriend b) {
    // ✅ lấy timestamp local nếu có (chỉ set khi thực sự có tin mới)
    final taLocal = _localLastActivity[a.id.toString()];
    final tbLocal = _localLastActivity[b.id.toString()];

    final ta = taLocal ?? a.lastMessageTime ?? 0;
    final tb = tbLocal ?? b.lastMessageTime ?? 0;

    if (ta == 0 && tb == 0) return 0;
    return tb.compareTo(ta); // m?i nh?t l�n tr�n
  }

  // Convert timestamp (s or ms) to seconds
  int? _normalizedTimestamp(int? ts) {
    if (ts == null || ts <= 0) return null;
    if (ts > 2000000000) {
      // looks like milliseconds
      return ts ~/ 1000;
    }
    return ts;
  }

  // Format time label for list items
  String _formatTimeLabel(SocialFriend u) {
    final ts = _normalizedTimestamp(
        _lastTimeCache[u.id] ?? u.lastMessageTime);
    if (ts != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      final now = DateTime.now();
      final diff = now.difference(dt);
      String two(int n) => n.toString().padLeft(2, '0');

      final sameDay =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      if (sameDay) {
        return '${two(dt.hour)}:${two(dt.minute)}';
      }
      if (diff.inDays < 7) {
        return '${diff.inDays}d';
      }
      final sameYear = dt.year == now.year;
      return '${two(dt.day)}/${two(dt.month)}${sameYear ? '' : '/${dt.year}'}';
    }

    final ls = (u.lastSeen ?? '').trim();
    return ls;
  }

  Future<void> _loadLatestIfMissing(SocialFriend u) async {
    if (_lastTextCache.containsKey(u.id)) return;
    _lastTextCache[u.id] = ''; // mark loading
    try {
      final msgs = await _chatRepo.getUserMessages(
        token: widget.accessToken,
        peerUserId: u.id.toString(),
        limit: 1,
      );
      if (msgs.isNotEmpty) {
        final m = msgs.last;
        String text = (m['display_text'] ?? '').toString().trim();
        if (text.isEmpty) {
          text = pickWoWonderText(m);
        }
        int? ts;
        final rawTime =
            m['time'] ?? m['time_text'] ?? m['timestamp'] ?? m['created_at'];
        if (rawTime is num) {
          ts = rawTime.toInt();
        } else if (rawTime is String) {
          ts = int.tryParse(rawTime);
        }
        if (!mounted) return;
        setState(() {
          _lastTextCache[u.id] = text;
          if (ts != null) {
            _lastTimeCache[u.id] = ts;
            _localLastActivity[u.id] = _normalizedTimestamp(ts) ?? ts;
          }
        });
      }
    } catch (_) {
      // ignore errors, fallback to existing data
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Images.logoWithNameImage,
              height: 35,
            ),
            // nếu muốn chừa MenuWidget cạnh logo thì bật đoạn dưới
            // const SizedBox(width: 8),
            // const MenuWidget(),
          ],
        ),
      ),
      floatingActionButton: null,

      /// ✅ Thanh tab bar dạng "floating capsule"
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 8 + bottomInset, // chừa chỗ cho thanh điều hướng hệ thống
        ),
        child: _MessengerFooter(
          currentIndex: _tabIndex,
          chatBadgeCount: chatBadgeCount,
          showNotifDot: notifDot,
          onTap: (i) {
            setState(() => _tabIndex = i);

            if (i == 1) {
              // 👈 Tab STORIES → mở màn Trang / Tin nhắn Page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PageMessagesScreen(accessToken: widget.accessToken),
                ),
              );
            } else if (i == 2) {
              // Group chat như cũ
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GroupChatsScreen(accessToken: widget.accessToken),
                ),
              );
            }
          },
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 ô tìm kiếm dạng pill
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: searchCtrl,
              onChanged: friendsCtrl.search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 👥 dải avatar ngang (story-style) + "Tạo tin" đầu tiên
          SizedBox(
            height: 106,
            child: Obx(() {
              final list = List<SocialFriend>.from(friendsCtrl.friends);
              list.sort(_compareByLastMessage);

              if (friendsCtrl.isLoading.value && list.isEmpty) {
                return const _AvatarStripSkeleton();
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: list.length + 1, // +1 cho Ã´ "Táº¡o tin"
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return const _CreateStoryTile();
                  }
                  final u = list[i - 1];
                  return _AvatarStoryTile(
                    name: u.name,
                    avatar: u.avatar,
                    online: u.isOnline,
                    onTap: () => _openChat(u),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 8),

          // 📜 danh sách đoạn chat
          Expanded(
            child: Obx(() {
              final list = List<SocialFriend>.from(friendsCtrl.filtered);
              list.sort(_compareByLastMessage);

              if (friendsCtrl.isLoading.value && list.isEmpty) {
                return const _MessengerSkeleton();
              }
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 36),
                          Center(
                            child: Text(
                              getTranslated('no_friends_yet', context)!,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final u = list[i];

                          // preview: ưu tiên tin nhắn (cache/fetch), fallback sang trạng thái khi không có
                          _loadLatestIfMissing(u);
                          final cachedText = _lastTextCache[u.id] ?? '';
                          final messagePreview =
                              (cachedText.isNotEmpty ? cachedText : (u.lastMessageText ?? ''))
                                  .trim();
                          final statusFallback = u.isOnline
                              ? getTranslated('active_now', context) ?? ''
                              : (u.lastSeen ?? '').trim();
                          final preview = messagePreview.isNotEmpty
                              ? messagePreview
                              : statusFallback;
                          final rawTime = _formatTimeLabel(u).trim();
                          final timeLabel = rawTime.isNotEmpty ? rawTime : ' ';

                          return InkWell(
                            onTap: () => _openChat(u),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _ChatAvatar(
                                    url: u.avatar,
                                    online: u.isOnline,
                                    label: u.name,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                u.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: cs.onSurface,
                                                  fontSize: 15.5,
                                                ),
                                              ),
                                            ),
                                            if (timeLabel.isNotEmpty)
                                              Text(
                                                timeLabel,
                                                style: TextStyle(
                                                  color: cs.onSurface
                                                      .withOpacity(.55),
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          preview.isEmpty ? ' ' : preview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: cs.onSurface.withOpacity(.7),
                                            fontSize: 13,
                                          ),
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
              );
            }),
          ),
        ],
      ),
    );
  }

  // ✅ chỉ update khi ChatScreen trả về true (thực sự có tin mới)
  void _openChat(SocialFriend u) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          accessToken: widget.accessToken,
          peerUserId: u.id.toString(),
          peerName: (u.name.isNotEmpty) ? u.name : 'User #${u.id}',
          peerAvatar: u.avatar,
        ),
      ),
    ).then((hasNewMessage) {
      if (hasNewMessage == true) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        setState(() {
          _localLastActivity[u.id.toString()] = now;
        });

        // optional: reload từ server để preview/time chuẩn dữ liệu backend
        friendsCtrl.load(widget.accessToken, context: context);
      }
    });
  }
}

/* ===== FOOTER (Messenger style – floating iOS-like) ===== */
class _MessengerFooter extends StatelessWidget {
  final int currentIndex;
  final int chatBadgeCount;
  final bool showNotifDot;
  final ValueChanged<int> onTap;

  const _MessengerFooter({
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
              label: getTranslated('chat_section', context)!,
              badge: chatBadgeCount,
            ),
            item(
              index: 1,
              icon: Icons.flag_outlined, 
              label: 'Pages',
            ),
            item(
              index: 2,
              icon: Icons.groups,
              label: getTranslated('group_chat', context)!,
              dot: showNotifDot,
            ),
            item(
              index: 3,
              icon: Icons.menu,
              label: getTranslated('menu', context)!,
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

/* ===== Avatar components & skeletons ===== */

class _CreateStoryTile extends StatelessWidget {
  const _CreateStoryTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cs.surfaceVariant,
                child: Icon(
                  Icons.add,
                  color: cs.onSurface.withOpacity(.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tạo tin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

class _AvatarStoryTile extends StatelessWidget {
  final String name;
  final String? avatar;
  final bool online;
  final VoidCallback? onTap;
  const _AvatarStoryTile({
    required this.name,
    required this.avatar,
    required this.online,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: (avatar != null && avatar!.isNotEmpty)
                      ? NetworkImage(avatar!)
                      : null,
                  child: (avatar == null || avatar!.isEmpty)
                      ? Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: online ? Colors.green : cs.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final String? url;
  final bool online;
  final String label;
  const _ChatAvatar({
    required this.url,
    required this.online,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: cs.surfaceVariant,
          backgroundImage:
              (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
          child: (url == null || url!.isEmpty)
              ? Text(
                  label.isNotEmpty ? label[0] : '?',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: online ? Colors.green : cs.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarStripSkeleton extends StatelessWidget {
  const _AvatarStripSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (_, __) => Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: cs.surfaceVariant),
          const SizedBox(height: 6),
          Container(width: 54, height: 10, color: cs.surfaceVariant),
        ],
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemCount: 8,
    );
  }
}

class _MessengerSkeleton extends StatelessWidget {
  const _MessengerSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(radius: 26, backgroundColor: cs.surfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, color: cs.surfaceVariant),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 220, color: cs.surfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
