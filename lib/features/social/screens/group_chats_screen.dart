import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_mess.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';

class GroupChatsScreen extends StatefulWidget {
  final String accessToken;
  final bool showFooterNav;
  const GroupChatsScreen(
      {super.key, required this.accessToken, this.showFooterNav = true});

  @override
  State<GroupChatsScreen> createState() => _GroupChatsScreenState();
}

class _GroupChatsScreenState extends State<GroupChatsScreen> {
  final Map<String, String> _previewCache = {};
  final Map<String, int> _timeCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupChatController>().loadGroups();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _reloadGroups() async {
    await context.read<GroupChatController>().loadGroups();
  }

  int? _normalizedTs(dynamic ts) {
    if (ts == null) return null;
    int? v;
    if (ts is num) v = ts.toInt();
    if (ts is String) v = int.tryParse(ts);
    if (v == null || v <= 0) return null;
    if (v > 2000000000) return v ~/ 1000;
    return v;
  }

  String _formatTime(dynamic ts) {
    final sec = _normalizedTs(ts);
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

  Future<void> _ensureLatestPreview(
      Map<String, dynamic> g, GroupChatController ctrl) async {
    final groupId = (g['group_id'] ?? g['id'] ?? '').toString();
    if (groupId.isEmpty) return;
    if (_previewCache.containsKey(groupId)) return;
    _previewCache[groupId] = '';

    try {
      final msgs = await ctrl.repo.fetchMessages(groupId, limit: 1);
      if (msgs.isNotEmpty) {
        final m = msgs.last;
        String txt = (m['display_text'] ?? '').toString().trim();
        if (txt.isEmpty) {
          txt = pickWoWonderText(m);
        }
        int? ts;
        final rawTime = m['time'] ?? m['time_text'] ?? m['timestamp'];
        if (rawTime is num) ts = rawTime.toInt();
        if (rawTime is String) ts = int.tryParse(rawTime);

        if (!mounted) return;
        setState(() {
          _previewCache[groupId] = txt;
          if (ts != null) _timeCache[groupId] = ts;
        });
      }
    } catch (_) {

    }
  }

  String _previewText(Map<String, dynamic> g) {
    final sender = (g['last_sender_name'] ?? g['last_sender'] ?? '').toString();
    final lm = g['last_message'];
    Map<String, dynamic>? lastMap;
    if (lm is Map<String, dynamic>) {
      lastMap = Map<String, dynamic>.from(lm);
    } else if (lm is List && lm.isNotEmpty && lm.first is Map) {
      lastMap = Map<String, dynamic>.from(lm.first as Map);
    }

    if (lastMap != null) {
      String txt = (lastMap['display_text'] ?? '').toString().trim();
      if (txt.isEmpty) {
        // try text/message fields
        txt = (lastMap['text'] ??
                lastMap['message'] ??
                lastMap['textDecoded'] ??
                '')
            .toString()
            .trim();
      }
      if (txt.isEmpty) {
        txt = pickWoWonderText(lastMap);
      }
      if (txt.isNotEmpty) {
        return sender.isNotEmpty ? '$sender: $txt' : txt;
      }
    }

    final text = g['last_message_text'] ??
        g['last_text'] ??
        g['text'] ??
        g['last_message'] ??
        g['last_msg'] ??
        '';
    if (text is String && text.trim().isNotEmpty) {
      final t = text.replaceAll('\n', ' ').trim();
      return sender.isNotEmpty ? '$sender: $t' : t;
    }

    final type = (g['last_message_type'] ?? g['type_two'] ?? '').toString();
    String tag = '';
    switch (type) {
      case 'image':
        tag = '[Image]';
        break;
      case 'video':
        tag = '[Video]';
        break;
      case 'voice':
      case 'audio':
        tag = '[Voice]';
        break;
      case 'file':
        tag = '[File]';
        break;
      default:
        if (type.isNotEmpty) tag = '[$type]';
    }
    if (tag.isNotEmpty) {
      return sender.isNotEmpty ? '$sender: $tag' : tag;
    }

    return getTranslated('no_messages_yet', context) ?? 'Bat dau doan chat';
  }

  int _lastTsFor(Map<String, dynamic> g) {
    final gid = (g['group_id'] ?? g['id'] ?? '').toString();
    final cached = _timeCache[gid];
    if (cached != null) return _normalizedTs(cached) ?? 0;
    final fields = [
      g['last_time'],
      g['time'],
      g['last_message_time'],
      g['last_msg_time']
    ];
    for (final f in fields) {
      final n = _normalizedTs(f);
      if (n != null && n > 0) return n;
    }
    return 0;
  }

  void _sortGroups(List<Map<String, dynamic>> groups) {
    groups.sort((a, b) => _lastTsFor(b).compareTo(_lastTsFor(a)));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Text(
          getTranslated('group_chat', context) ?? 'Group chat',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(getTranslated('add', context) ?? 'Add'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () async {
                final success = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateGroupScreen(accessToken: widget.accessToken),
                  ),
                );
                if (!mounted) return;
                if (success == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getTranslated('group_created_success', context) ?? 'Created'),
                    ),
                  );
                  await _reloadGroups();
                }
              },
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Consumer<GroupChatController>(
              builder: (context, ctrl, _) {
                if (ctrl.groupsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                var groups = List<Map<String, dynamic>>.from(ctrl.groups);
                _sortGroups(groups);

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
                      _ensureLatestPreview(g, ctrl);
                      final groupId =
                          (g['group_id'] ?? g['id'] ?? '').toString();
                      final groupName =
                          (g['group_name'] ?? g['name'] ?? 'Không tên')
                              .toString();
                      final avatar =
                          (g['avatar'] ?? g['image'] ?? '').toString();
                      final time = _formatTime(
                        _timeCache[groupId] ??
                            g['last_time'] ??
                            g['time'] ??
                            g['last_message_time'],
                      );
                      final cachedText = _previewCache[groupId] ?? '';
                      final preview =
                          cachedText.isNotEmpty ? cachedText : _previewText(g);
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

      bottomNavigationBar: widget.showFooterNav
          ? Consumer<GroupChatController>(
              builder: (context, ctrl, _) {
                final totalGroupUnread =
                    ctrl.groups.fold<int>(0, (sum, g) => sum + _unread(g));

                return SocialTabsBottomNav(
                  currentIndex: 2,
                  accessToken: widget.accessToken,
                  chatBadgeCount: 0,
                  groupBadgeCount: totalGroupUnread,
                  onTap: (i) {
                    if (i == 2) return;

                    if (i == 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FriendsListScreen(
                              accessToken: widget.accessToken),
                        ),
                      );
                      return;
                    }

                    if (i == 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PageMessagesScreen(
                              accessToken: widget.accessToken),
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Chưa gắn điều hướng cho Menu')),
                    );
                  },
                );
              },
            )
          : null,
    );
  }
}

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
    final initial =
        title.isNotEmpty ? title.characters.first.toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

class SocialTabsBottomNav extends StatelessWidget {
  final int currentIndex;
  final String accessToken;
  final int chatBadgeCount;
  final int groupBadgeCount;
  final ValueChanged<int> onTap;

  const SocialTabsBottomNav({
    super.key,
    required this.currentIndex,
    required this.accessToken,
    required this.chatBadgeCount,
    required this.groupBadgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final bool isIOSPlatform = !kIsWeb && Platform.isIOS;

    if (isIOSPlatform) {
      Widget iconWithBadge(IconData icon, int badge) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 24),
            if (badge > 0)
              Positioned(
                right: -10,
                top: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      }

      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        activeColor: cs.primary,
        items: [
          BottomNavigationBarItem(
            icon: iconWithBadge(CupertinoIcons.chat_bubble_2, chatBadgeCount),
            activeIcon: iconWithBadge(
                CupertinoIcons.chat_bubble_2_fill, chatBadgeCount),
            label: getTranslated('chat_section', context) ?? 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.flag),
            activeIcon: Icon(CupertinoIcons.flag_fill),
            label: 'Pages',
          ),
          BottomNavigationBarItem(
            icon: iconWithBadge(CupertinoIcons.person_3, groupBadgeCount),
            activeIcon:
                iconWithBadge(CupertinoIcons.person_3_fill, groupBadgeCount),
            label: getTranslated('group_chat', context) ?? 'Group',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.line_horizontal_3),
            activeIcon: const Icon(CupertinoIcons.line_horizontal_3),
            label: getTranslated('menu', context) ?? 'Menu',
          ),
        ],
      );
    }

    // Android/Web: moving circle như DashBoardScreen
    final androidItems = <_AndroidNavItem>[
      _AndroidNavItem(
        icon: Icons.chat_bubble_outline,
        label: getTranslated('chat_section', context) ?? 'Chat',
        badgeCount: chatBadgeCount,
      ),
      const _AndroidNavItem(icon: Icons.flag_outlined, label: 'Pages'),
      _AndroidNavItem(
        icon: Icons.groups_outlined,
        label: getTranslated('group_chat', context) ?? 'Group',
        badgeCount: groupBadgeCount,
      ),
      _AndroidNavItem(
        icon: Icons.menu,
        label: getTranslated('menu', context) ?? 'Menu',
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: 8 + bottomInset),
      child: AndroidMovingCircleBottomBar(
        items: androidItems,
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
}

class _AndroidNavItem {
  final IconData icon;
  final String label;
  final int badgeCount;

  const _AndroidNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

class AndroidMovingCircleBottomBar extends StatelessWidget {
  final List<_AndroidNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AndroidMovingCircleBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color barColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8EBF0);
    final Color scaffoldBg = theme.scaffoldBackgroundColor;

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double barWidth = constraints.maxWidth;
            final double itemWidth = barWidth / items.length;

            const double circleSize = 70;
            const double circleBottom = 40;

            final double circleCenterX = itemWidth * (currentIndex + 0.5);
            final double circleLeft = circleCenterX - circleSize / 2;

            return SizedBox(
              height: 110,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 76,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: List.generate(
                          items.length,
                          (index) => Expanded(
                            child: _AndroidNavItemWidget(
                              item: items[index],
                              selected: index == currentIndex,
                              onTap: () => onTap(index),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 230),
                    curve: Curves.easeOutCubic,
                    left: circleLeft,
                    bottom: circleBottom,
                    child: Container(
                      height: circleSize,
                      width: circleSize,
                      decoration: BoxDecoration(
                        color: scaffoldBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            items[currentIndex].icon,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AndroidNavItemWidget extends StatelessWidget {
  final _AndroidNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _AndroidNavItemWidget({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color iconColor =
        selected ? cs.primary : cs.onSurface.withOpacity(0.7);
    final FontWeight labelWeight = selected ? FontWeight.w600 : FontWeight.w400;

    Widget iconArea;
    if (selected) {
      iconArea = const SizedBox(height: 16);
    } else {
      iconArea = Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(item.icon, size: 24, color: iconColor),
          if (item.badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    item.badgeCount > 9 ? '9+' : item.badgeCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconArea,
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11.5,
                fontWeight: labelWeight,
                color: cs.onSurface.withOpacity(selected ? 0.95 : 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
