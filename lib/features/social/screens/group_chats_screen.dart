import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';

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
      context
          .read<GroupChatController>()
          .loadGroups(); // ⬅️ không truyền tham số
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadGroups() async {
    await context
        .read<GroupChatController>()
        .loadGroups(); // ⬅️ không truyền tham số
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
    final isMedia = (g['last_message_type'] ?? g['type_two'] ?? '') == 'media';
    if (isMedia) return '${sender.isNotEmpty ? "$sender: " : ""}[Ảnh/Video]';
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đoạn chat'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tạo nhóm chat',
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
                  const SnackBar(content: Text('Tạo nhóm thành công')),
                );
                await _reloadGroups(); // ⬅️ reload sau khi tạo
              }
            },
          ),
        ],
      ),
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
                hintText: 'Tìm kiếm nhóm',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(.4),
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
                  return const Center(child: Text('Chưa tham gia nhóm nào'));
                }

                return RefreshIndicator(
                  onRefresh: _reloadGroups, // ⬅️ không truyền tham số
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
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

                      return InkWell(
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: avatar.isNotEmpty
                                    ? NetworkImage(avatar)
                                    : null,
                                backgroundColor: cs.surfaceVariant,
                                child: avatar.isEmpty
                                    ? Text(
                                        groupName.isNotEmpty
                                            ? groupName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // Name + preview
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            groupName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: unread > 0
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (time.isNotEmpty)
                                          Text(
                                            time,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color:
                                                  cs.onSurface.withOpacity(.6),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: unread > 0
                                            ? cs.onSurface
                                            : cs.onSurface.withOpacity(.7),
                                        fontWeight: unread > 0
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Badge + mute
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: TextStyle(
                                          color: cs.onPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  if (muted) ...[
                                    const SizedBox(height: 8),
                                    Icon(Icons.notifications_off_rounded,
                                        size: 18,
                                        color: cs.onSurface.withOpacity(.6)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
