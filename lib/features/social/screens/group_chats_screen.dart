import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/group_chat_controller.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_mess.dart';
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
      if (type == 'image') {
        tag = '[Ảnh]';
      } else if (type == 'video') {
        tag = '[Video]';
      } else if (type == 'voice' || type == 'audio') {
        tag = '[Voice]';
      } else if (type == 'file') {
        tag = '[Tệp]';
      } else {
        tag = '[Ảnh/Video]';
      }
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

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
          // 🔍 Search – cho giống FriendsListScreen
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _keyword = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: getTranslated('search_group', context),
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
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final g = groups[i];
                      final groupId =
                          (g['group_id'] ?? g['id'] ?? '').toString();
                      final groupName =
                          (g['group_name'] ?? g['name'] ?? 'Không tên')
                              .toString();
                      final avatar =
                          (g['avatar'] ?? g['image'] ?? '').toString();
                      final time = _formatTime(
                        g['last_time'] ?? g['time'] ?? g['last_message_time'],
                      );
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

      // === FOOTER NAV (floating iOS style) ===
      bottomNavigationBar: Consumer<GroupChatController>(
        builder: (context, ctrl, _) {
          final totalGroupUnread =
              ctrl.groups.fold<int>(0, (sum, g) => sum + _unread(g));

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 8 + bottomInset,
            ),
            child: _GroupFooterNav(
              currentIndex: 2, // Màn hình Nhóm Chat
              chatBadgeCount: 0, // có thể map từ màn Đoạn chat nếu cần
              showNotifDot: totalGroupUnread > 0,
              onTap: (i) {
                if (i == 2) return; // đang ở Nhóm Chat rồi

                if (i == 0) {
                  // Điều hướng về màn “Đoạn chat”
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FriendsListScreen(accessToken: widget.accessToken),
                    ),
                  );
                  return;
                }

                if (i == 1) {
                  // Điều hướng sang “Tin nhắn với pages”
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PageMessagesScreen(accessToken: widget.accessToken),
                    ),
                  );
                  return;
                }

                // TODO: gắn màn “Menu” (i == 3)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chưa gắn điều hướng cho tab $i')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// =====================
/// Group list item – đồng style với FriendsListScreen
/// =====================
class _GroupTile extends StatelessWidget {
  final ColorScheme cs;
  final String avatarUrl;
  final String title;
  final String subtitle;
  final String timeText;
  final int unread;
  final bool muted; // hiện tại không vẽ icon nữa, chỉ để dành nếu cần
  final bool online; // cũng không vẽ icon, giữ nếu sau này xài
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
    final initial =
        title.isNotEmpty ? title.characters.first.toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar giống _ChatAvatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          initial,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name + time
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
                            color: cs.onSurface,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(.5),
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle.isEmpty ? ' ' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread
                          ? cs.onSurface
                          : cs.onSurface.withOpacity(.7),
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================
/// Footer Nav (floating, iOS-like)
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
