import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// MXH
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_notifications_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isBackButtonExist;
  const NotificationsScreen({
    super.key,
    this.isBackButtonExist = true,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialNotificationsController>().getNotifications();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socialCtrl = context.watch<SocialNotificationsController>();
    // ✅ đảm bảo không lỗi build sớm
    _tabController ??= TabController(length: 2, vsync: this);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        automaticallyImplyLeading: widget.isBackButtonExist,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mạng xã hội'),
                  const SizedBox(width: 6),
                  if (socialCtrl.notifications.any((n) => n.seen == "0"))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${socialCtrl.notifications.where((n) => n.seen == "0").length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: 'Shop'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 🟦 Tab 1: MXH
          RefreshIndicator(
            onRefresh: socialCtrl.refresh,
            child: socialCtrl.loading
                ? const Center(child: CircularProgressIndicator())
                : (socialCtrl.notifications.isEmpty
                ? const Center(child: Text('Không có thông báo MXH'))
                : ListView.builder(
              itemCount: socialCtrl.notifications.length,
              itemBuilder: (context, index) {
                final n = socialCtrl.notifications[index];
                return NotificationItem(
                  key: ValueKey(n.id),
                  n: n,
                );
              },
            )),
          ),

          // 🛒 Tab 2: Shop — chỉ hiển thị text tĩnh
          const Center(
            child: Text(
              'Không có thông báo Shop',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
