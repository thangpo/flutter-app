import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/social_notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isBackButtonExist;
  const NotificationsScreen({super.key, this.isBackButtonExist = true});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<SocialNotificationsController>().getNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SocialNotificationsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        automaticallyImplyLeading: widget.isBackButtonExist,
        centerTitle: false,
      ),
      body: ctrl.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            if (ctrl.notifications.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 8, top: 6),
                child: Text("Mới",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ...ctrl.notifications.map((n) => _buildItem(n)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> n) {
    final notifier = n['notifier'] ?? {};
    final avatar = notifier['avatar'] ??
        'https://via.placeholder.com/60x60.png?text=No+Avatar';
    final name = notifier['name'] ?? 'Người dùng';
    final text = n['text'] ?? '';
    final type = n['type'] ?? '';
    final time = n['time_text'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage(avatar), radius: 25),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 15),
            children: [
              TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' '),
              TextSpan(text: text),
              TextSpan(
                text: text.isNotEmpty
                    ? text
                    : (type == 'added_you_to_group'
                    ? 'đã thêm bạn vào nhóm'
                    : (type == 'invited_you_to_the_group'
                    ? 'đã mời bạn vào nhóm'
                    : 'đã tương tác với bạn')),
              ),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(time,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.grey),
          onPressed: () async {
            final id = n['id'].toString();
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Xoá thông báo'),
                content: const Text('Bạn có chắc muốn xoá thông báo này không?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Huỷ')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xoá', style: TextStyle(color: Colors.red))),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              final controller = context.read<SocialNotificationsController>();
              final message = await controller.deleteNotification(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message ?? 'Không nhận được phản hồi từ server.'),
                    backgroundColor:
                    (message != null && message.contains('success')) ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },

        ),
        onTap: () {
          // TODO: điều hướng đến bài viết hoặc nhóm tương ứng
        },
      ),
    );
  }
}
