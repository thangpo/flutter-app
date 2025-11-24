// lib/features/social/screens/event_detail_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/event_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/edit_event_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final SocialEvent? initialEvent;

  const EventDetailScreen({
    Key? key,
    required this.eventId,
    this.initialEvent,
  }) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<SocialEvent?> _future;
  SocialEvent? _titleEvent;

  @override
  void initState() {
    super.initState();
    _titleEvent = widget.initialEvent;
    _future = context.read<EventController>().fetchEventById(widget.eventId);
  }

  /// Build URL sự kiện theo id (dạng show-event/id)
  String _buildEventUrl(SocialEvent event) {
    final id = event.id?.toString() ?? widget.eventId;
    if (id.isEmpty) return AppConstants.socialBaseUrl;
    final base = AppConstants.socialBaseUrl;
    if (base.endsWith('/')) {
      return '${base}show-event/$id';
    }
    return '$base/show-event/$id';
  }

  /// Bottom sheet chia sẻ: share lên profile + copy link
  Future<void> _showShareSheet(SocialEvent event) async {
    final theme = Theme.of(context);

    // build đúng link detail như web
    final String eventId = (event.id ?? widget.eventId).toString();
    final String link = '${AppConstants.socialBaseUrl}/events/$eventId/';

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.post_add_outlined),
                title: const Text('Chia sẻ lên trang cá nhân'),
                subtitle: const Text('Link sự kiện sẽ được sao chép'),
                onTap: () async {
                  // 1) copy link
                  await Clipboard.setData(ClipboardData(text: link));

                  // 2) đóng bottom sheet
                  Navigator.of(ctx).pop();

                  // 3) mở màn tạo bài viết bình thường (không sửa code gốc)
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SocialCreatePostScreen(),
                    ),
                  );

                  // 4) thông báo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã sao chép liên kết sự kiện, hãy dán vào bài viết mới.',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Sao chép liên kết'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép liên kết sự kiện'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_titleEvent?.name ?? 'Sự kiện'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_titleEvent != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final ev = _titleEvent;
                if (ev != null) {
                  _showShareSheet(ev); // 👈 gọi hàm mới
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<SocialEvent?>(
        future: _future,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final event = snapshot.data ?? widget.initialEvent;

          if (event != null &&
              (_titleEvent == null ||
                  _titleEvent!.id != event.id ||
                  _titleEvent!.name != event.name)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _titleEvent = event;
              });
            });
          }

          if (event == null && isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (event == null) {
            return const Center(child: Text('Không tìm thấy sự kiện'));
          }

          return _buildBody(context, event, isLoading);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SocialEvent event, bool isLoading) {
    final theme = Theme.of(context);

    final socialCtrl = context.read<SocialController>();
    final currentUserId = socialCtrl.currentUser?.id?.toString();
    final posterId = event.posterId?.toString();
    final bool isOwner = (event.isOwner == true) ||
        (currentUserId != null &&
            posterId != null &&
            posterId == currentUserId);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(event, isOwner),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${event.startDate ?? ''} - ${event.endDate ?? ''}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDateRow(event),
                const SizedBox(height: 16),
                _buildStatsCard(event, theme),
                const SizedBox(height: 16),
                if (!isOwner) _buildActionButtons(context, event, isOwner),
                const SizedBox(height: 24),
                Text(
                  'Mô tả',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (event.user != null) ...[
                  Text(
                    'Người tổ chức',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage:
                        NetworkImage(event.user!.avatar ?? ''),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        event.user!.name ?? event.user!.username ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                if (isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(SocialEvent event, bool isOwner) {
    final theme = Theme.of(context);
    final coverUrl = event.cover;

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: coverUrl != null && coverUrl.isNotEmpty
                ? Image.network(
              coverUrl,
              fit: BoxFit.cover,
            )
                : Container(color: theme.primaryColor.withOpacity(0.2)),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        event.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (isOwner)
                  Row(
                    children: [
                      _OwnerActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Chỉnh sửa sự kiện',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditEventScreen(event: event),
                            ),
                          );
                          if (result == true && mounted) {
                            setState(() {
                              _future = context
                                  .read<EventController>()
                                  .fetchEventById(widget.eventId);
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      _OwnerActionButton(
                        icon: Icons.delete_outline,
                        label: 'Xóa bỏ',
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xóa sự kiện'),
                              content: const Text(
                                  'Sau khi xóa không thể khôi phục!'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final ctrl = context.read<EventController>();
                          final id =
                              event.id?.toString() ?? widget.eventId;
                          final ok = await ctrl.deleteEvent(id);

                          if (!mounted) return;

                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa sự kiện'),
                              ),
                            );
                            Navigator.pop(context, true);
                          } else {
                            final msg = ctrl.error ??
                                'Xóa sự kiện thất bại, vui lòng thử lại.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(SocialEvent event) {
    String dayStart = '';
    String monthStart = '';
    String dayEnd = '';
    String monthEnd = '';

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    if (event.startDate != null) {
      final parts = event.startDate!.split('-');
      if (parts.length >= 2) {
        dayStart = parts[0];
        final m = int.tryParse(parts[1]) ?? 1;
        monthStart = months[(m - 1).clamp(0, 11)];
      }
    }
    if (event.endDate != null) {
      final parts = event.endDate!.split('-');
      if (parts.length >= 2) {
        dayEnd = parts[0];
        final m = int.tryParse(parts[1]) ?? 1;
        monthEnd = months[(m - 1).clamp(0, 11)];
      }
    }

    final startFull =
    '${event.startDate ?? ''} - ${event.startTime ?? ''}'.trim();
    final endFull =
    '${event.endDate ?? ''} - ${event.endTime ?? ''}'.trim();

    return Row(
      children: [
        Expanded(
          child: _DateCard(
            day: dayStart,
            month: monthStart,
            title: 'NGÀY BẮT ĐẦU',
            value: startFull,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateCard(
            day: dayEnd,
            month: monthEnd,
            title: 'NGÀY CUỐI',
            value: endFull,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(SocialEvent event, ThemeData theme) {
    final goingText = event.isGoing ? 'Bạn sẽ đi' : '0 Đi mọi người';
    final interestedText =
    event.isInterested ? 'Bạn quan tâm' : '0 Những người quan tâm';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatRow(
            icon: Icons.emoji_people_outlined,
            text: goingText,
          ),
          const SizedBox(height: 8),
          _StatRow(
            icon: Icons.favorite_border,
            text: interestedText,
          ),
          const SizedBox(height: 8),
          _StatRow(
            icon: Icons.place_outlined,
            text: event.location ?? '',
          ),
          const SizedBox(height: 12),
          if ((event.description ?? '').isNotEmpty)
            Text(
              event.description!,
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, SocialEvent event, bool isOwner) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor:
              theme.primaryColor.withOpacity(isOwner ? 0.4 : 0.95),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: isOwner
                ? null
                : () async {
              final ok = await context
                  .read<EventController>()
                  .toggleInterestEvent(event.id!);
              if (ok && mounted) {
                setState(() {
                  event.isInterested = !event.isInterested;
                });
              }
            },
            child: Text(
              isOwner
                  ? 'Sự kiện của tôi'
                  : (event.isInterested ? 'Đã quan tâm' : 'Quan tâm'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor:
              theme.primaryColor.withOpacity(isOwner ? 0.4 : 0.95),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: isOwner
                ? null
                : () async {
              final ok = await context
                  .read<EventController>()
                  .toggleEventGoing(event.id!);
              if (ok && mounted) {
                setState(() {
                  event.isGoing = !event.isGoing;
                });
              }
            },
            child: Text(
              isOwner
                  ? 'Chỉnh sửa'
                  : (event.isGoing ? 'Đã tham gia' : 'Tham gia'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ================== WIDGET PHỤ ==================

class _DateCard extends StatelessWidget {
  final String day;
  final String month;
  final String title;
  final String value;

  const _DateCard({
    required this.day,
    required this.month,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _OwnerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OwnerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: Colors.white.withOpacity(0.15),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
