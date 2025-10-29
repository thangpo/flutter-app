import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';
import 'group_chat_screen.dart';

class GroupChatsScreen extends StatefulWidget {
  final String accessToken;
  const GroupChatsScreen({super.key, required this.accessToken});

  @override
  State<GroupChatsScreen> createState() => _GroupChatsScreenState();
}

class _GroupChatsScreenState extends State<GroupChatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<GroupChatController>();
      ctrl.loadGroups(widget.accessToken);
    });
  }

  Future<void> _refreshGroups() async {
    await context.read<GroupChatController>().loadGroups(widget.accessToken);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nhóm Chat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: Consumer<GroupChatController>(
        builder: (context, ctrl, _) {
          if (ctrl.groupsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ctrl.groups.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshGroups,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Chưa có nhóm nào.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshGroups,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: ctrl.groups.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: cs.outlineVariant.withOpacity(.4),
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final g = ctrl.groups[index];
                final avatar = g['avatar'] ?? '';
                final name = g['group_name'] ?? 'Nhóm không tên';
                final lastMsg = g['last_message'] ?? '';
                final time = g['time_text'] ?? '';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          accessToken: widget.accessToken,
                          groupId: g['group_id'].toString(),
                          groupName: name,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage:
                              avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          backgroundColor: cs.surfaceVariant,
                          child: avatar.isEmpty
                              ? const Icon(Icons.groups, size: 24)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lastMsg.isNotEmpty
                                    ? lastMsg
                                    : 'Chưa có tin nhắn',
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(.7),
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(.6),
                          ),
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
    );
  }
}
