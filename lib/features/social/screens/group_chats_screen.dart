import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';


class GroupChatsScreen extends StatefulWidget {
  final String accessToken;
  const GroupChatsScreen({super.key, required this.accessToken});

  @override
  State<GroupChatsScreen> createState() => _GroupChatsScreenState();
}

class _GroupChatsScreenState extends State<GroupChatsScreen> {
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupChatController>().loadGroups();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadGroups() async {
    await context.read<GroupChatController>().loadGroups();
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    final sec = int.tryParse(ts.toString());
    if (sec == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  String _previewText(Map<String, dynamic> g) {
    final text = g['last_message'] ??
        g['last_message_text'] ??
        g['last_text'] ??
        g['text'] ??
        '';
    final sender = g['last_sender_name'] ?? g['last_sender'] ?? '';
    final type = (g['last_message_type'] ?? g['type_two'] ?? '').toString();
    final isMedia = type == 'media' ||
        type == 'image' ||
        type == 'video' ||
        type == 'voice' ||
        type == 'audio' ||
        type == 'file';
    String tag = '';
    if (isMedia) {
      if (type == 'image')
        tag = '[Ảnh]';
      else if (type == 'video')
        tag = '[Video]';
      else if (type == 'voice' || type == 'audio')
        tag = '[Voice]';
      else if (type == 'file')
        tag = '[Tệp]';
      else
        tag = '[Ảnh/Video]';
    }
    if (isMedia) return '${sender.isNotEmpty ? "$sender: " : ""}$tag';
    if (text is String && text.isNotEmpty) {
      final t = text.replaceAll('\n', ' ').trim();
      return sender.isNotEmpty ? '$sender: $t' : t;
    }
    return 'Bắt đầu đoạn chat';
  }

  int _unread(Map<String, dynamic> g) {
    final raw = g['unread'] ?? g['unread_count'] ?? g['count_unread'] ?? 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  bool _isMuted(Map<String, dynamic> g) {
    final m = g['muted'] ?? g['is_muted'];
    if (m is bool) return m;
    if (m == null) return false;
    return m.toString() == '1' || m.toString().toLowerCase() == 'true';
  }

  bool _isOnline(Map<String, dynamic> g) {
    final v = g['is_online'] ?? g['online'] ?? g['active'];
    if (v is bool) return v;
    if (v == null) return false;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslated('group_chat', context)!),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: getTranslated('create_group_chat', context)!,
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              final success = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateGroupScreen(accessToken: widget.accessToken),
                ),
              );
              if (!mounted) return;
              if (success == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(getTranslated('group_created_success', context)!),
                  ),
                );
                await _reloadGroups();
              }
            },
          ),
        ],
      ),

      // === BODY ===
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _keyword = v.trim().toLowerCase()),
              decoration: InputDecoration(
                 hintText: getTranslated('search_group', context),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(.35),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: Consumer<GroupChatController>(
              builder: (context, ctrl, _) {
                if (ctrl.groupsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var groups = ctrl.groups;
                if (_keyword.isNotEmpty) {
                  groups = groups.where((g) {
                    final name = (g['group_name'] ?? g['name'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(_keyword);
                  }).toList();
                }

                if (groups.isEmpty) {
                  return Center(
                    child: Text(getTranslated('no_groups_joined', context)!),
                  );
                }


                return RefreshIndicator(
                  onRefresh: _reloadGroups,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 84, // lùi giống Messenger (avatar 56 + padding)
                      color: cs.outlineVariant.withOpacity(.3),
                    ),
                    itemBuilder: (_, i) {
                      final g = groups[i];
                      final groupId =
                          (g['group_id'] ?? g['id'] ?? '').toString();
                      final groupName =
                          (g['group_name'] ?? g['name'] ?? 'Không tên')
                              .toString();
                      final avatar =
                          (g['avatar'] ?? g['image'] ?? '').toString();
                      final time = _formatTime(g['last_time'] ??
                          g['time'] ??
                          g['last_message_time']);
                      final preview = _previewText(g);
                      final unread = _unread(g);
                      final muted = _isMuted(g);
                      final online = _isOnline(g);

                      return _GroupTile(
                        cs: cs,
                        avatarUrl: avatar,
                        title: groupName,
                        subtitle: preview,
                        timeText: time,
                        unread: unread,
                        muted: muted,
                        online: online,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupChatScreen(
                                groupId: groupId,
                                groupName: groupName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // === FOOTER NAV ===
      bottomNavigationBar: Consumer<GroupChatController>(
        builder: (context, ctrl, _) {
          final totalGroupUnread =
              ctrl.groups.fold<int>(0, (sum, g) => sum + _unread(g));

          return _FooterNav(
            currentIndex: 2, // Màn hình Nhóm Chat
            chatBadgeCount:
                0, // nếu có tổng unread của “Đoạn chat” thì set ở đây
            showNotifDot: totalGroupUnread > 0,
            onTap: (i) {
              if (i == 2) return; // đang ở Nhóm Chat rồi

              if (i == 0) {
                // Điều hướng về màn “Đoạn chat” (FriendsList)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FriendsListScreen(accessToken: widget.accessToken),
                  ),
                );
                return;
              }

              // TODO: gắn màn “Tin” (i == 1) và “Menu” (i == 3) theo router của bạn
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chưa gắn điều hướng cho tab $i')),
              );
            },
          );
        },
      ),

    );
  }
}

/// =====================
/// Messenger-like tile
/// =====================
class _GroupTile extends StatelessWidget {
  final ColorScheme cs;
  final String avatarUrl;
  final String title;
  final String subtitle;
  final String timeText;
  final int unread;
  final bool muted;
  final bool online;
  final VoidCallback onTap;

  const _GroupTile({
    required this.cs,
    required this.avatarUrl,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.unread,
    required this.muted,
    required this.online,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar with gradient ring & online dot
            _AvatarRing(
              size: 56,
              avatarUrl: avatarUrl,
              placeholderChar: title.isNotEmpty ? title[0].toUpperCase() : '?',
              showRing: hasUnread,
              online: online,
              cs: cs,
            ),
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name + time + mute
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                hasUnread ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cs.onSurface.withOpacity(.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (muted) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.notifications_off_rounded,
                            size: 16, color: cs.onSurface.withOpacity(.5)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // preview + unread dot
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: hasUnread
                                ? cs.onSurface
                                : cs.onSurface.withOpacity(.7),
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Unread badge (giống Messenger)
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final double size;
  final String avatarUrl;
  final String placeholderChar;
  final bool showRing;
  final bool online;
  final ColorScheme cs;

  const _AvatarRing({
    required this.size,
    required this.avatarUrl,
    required this.placeholderChar,
    required this.showRing,
    required this.online,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: size / 2 - (showRing ? 2 : 0),
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      backgroundColor: cs.surfaceVariant,
      child: avatarUrl.isEmpty
          ? Text(
              placeholderChar,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.38,
              ),
            )
          : null,
    );

    final avatarWithRing = showRing
        ? Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary,
                  cs.tertiary,
                ],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
              child: avatar,
            ),
          )
        : SizedBox(width: size, height: size, child: avatar);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWithRing,
        if (online)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// =====================
/// Footer Nav (custom)
/// =====================
class _FooterNav extends StatelessWidget {
  final int currentIndex;
  final int chatBadgeCount;
  final bool showNotifDot;
  final ValueChanged<int> onTap;

  const _FooterNav({
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
      int badge = 0,
      bool dot = false,
    }) {
      final active = currentIndex == index;
      final color = active ? cs.primary : cs.onSurface.withOpacity(.7);

      return Expanded(
        child: InkWell(
          onTap: () => onTap(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 24, color: color),
                    if (badge > 0)
                      Positioned(
                        right: -10,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge > 99 ? '99+' : '$badge',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (badge == 0 && dot)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: cs.primary, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border:
                Border(top: BorderSide(color: cs.outlineVariant, width: .5)),
          ),
          child: Row(
            children: [
              item(
                  index: 0,
                  icon: Icons.chat_bubble,
                  label: 'Đoạn chat',
                  badge: chatBadgeCount),
              item(index: 1, icon: Icons.video_collection, label: 'Tin'),
              item(
                  index: 2,
                  icon: Icons.groups,
                  label: 'Nhóm Chat',
                  dot: showNotifDot),
              item(index: 3, icon: Icons.menu, label: 'Menu'),
            ],
          ),
        ),
      ),
    );
  }
}
