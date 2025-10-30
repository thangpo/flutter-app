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
      context.read<GroupChatController>().loadGroups();
    });
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
      ),
      body: Consumer<GroupChatController>(
        builder: (context, ctrl, _) {
          if (ctrl.groupsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = ctrl.groups;
          if (groups.isEmpty) {
            return const Center(
              child: Text('Chưa tham gia nhóm nào'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ctrl.loadGroups(),
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: cs.outlineVariant.withOpacity(.3),
              ),
              itemBuilder: (_, i) {
                 final group = ctrl.groups[i];
                final g = groups[i];
                final groupId = g['group_id']?.toString() ?? '';
                final groupName = g['group_name'] ?? 'Không tên';
                final avatar = g['avatar'] ?? '';

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    backgroundColor: cs.surfaceVariant,
                    child: avatar.isEmpty
                        ? Text(
                            groupName.isNotEmpty ? groupName[0] : '?',
                            style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  title: Text(
                    groupName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    g['time'] != null
                        ? 'Tạo lúc: ${g['time']}'
                        : 'Không rõ thời gian',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(.7),
                      fontSize: 13.5,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          groupId: group['group_id'].toString(),
                          groupName: group['group_name'],
                           // 🆕 thêm dòng này
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
    );
  }
}
