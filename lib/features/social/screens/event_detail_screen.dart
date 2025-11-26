// lib/features/social/screens/event_detail_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/event_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/edit_event_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
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

  @override
  void initState() {
    super.initState();
    _future = context.read<EventController>().fetchEventById(widget.eventId);
  }

  String _buildEventUrl(SocialEvent event) {
    final String id = (event.id ?? widget.eventId).toString();
    if (id.isEmpty) return AppConstants.socialBaseUrl;
    final String base = AppConstants.socialBaseUrl;
    final String normalizedBase =
    base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$normalizedBase/events/$id/';
  }

  Future<void> _showShareSheet(SocialEvent event) async {
    final String link = _buildEventUrl(event);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).cardColor.withOpacity(0.8),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.post_add_outlined),
                      title: Text(
                        getTranslated('share_on_profile', context) ??
                            'Chia sẻ lên trang cá nhân',
                      ),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SocialCreatePostScreen(attachedEvent: event),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(
                        getTranslated('copy_link', context) ?? 'Sao chép liên kết',
                      ),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              getTranslated('copied_event_link', context) ??
                                  'Đã sao chép liên kết sự kiện',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tEventNotFound =
        getTranslated('event_not_found', context) ?? 'Không tìm thấy sự kiện';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: FutureBuilder<SocialEvent?>(
          future: _future,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final event = snapshot.data ?? widget.initialEvent;

            if (event == null) {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(child: Text(tEventNotFound));
            }

            return _buildBody(context, event);
          },
        ),
      ),
    );
  }

  // === CẤU TRÚC BODY MỚI: Dùng Stack để chồng các lớp lên nhau ===
  Widget _buildBody(BuildContext context, SocialEvent event) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final socialCtrl = context.read<SocialController>();
    final currentUserId = socialCtrl.currentUser?.id?.toString();
    final posterId = event.posterId?.toString();
    final bool isOwner = (event.isOwner == true) ||
        (currentUserId != null &&
            posterId != null &&
            posterId == currentUserId);

    return Stack(
      children: [
        // Lớp 1: Background động đồng bộ với màn hình Create
        _buildDecorativeBackground(isDarkMode, event.cover),

        // Lớp 2: Nội dung cuộn được (thông tin chi tiết)
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Khoảng đệm trên cùng, đẩy nội dung xuống dưới khu vực header
              SizedBox(
                height: MediaQuery.of(context).padding.top + 180,
              ),
              // Thẻ thông tin chi tiết
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: _buildConsolidatedInfoCard(context, event, isDarkMode),
              ),
            ],
          ),
        ),

        // Lớp 3: Header nổi (chứa tên sự kiện và các nút)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildFloatingHeader(context, event, isOwner, isDarkMode),
        ),
      ],
    );
  }

  // === WIDGET MỚI: Đồng bộ background từ màn hình Create Event ===
  Widget _buildDecorativeBackground(bool isDarkMode, String? coverUrl) {
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    return Container(
      decoration: hasCover
          ? BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(coverUrl),
          fit: BoxFit.cover,
        ),
      )
          : BoxDecoration(
        color: isDarkMode ? Colors.black : const Color(0xFFF2F5F9),
      ),
      child: Stack(
        children: [
          if (!hasCover) ...[
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDarkMode
                      ? Colors.purple.shade900
                      : Colors.blue.shade200)
                      .withOpacity(0.5),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -150,
              child: Container(
                height: 400,
                width: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDarkMode
                      ? Colors.teal.shade900
                      : Colors.purple.shade200)
                      .withOpacity(0.5),
                ),
              ),
            ),
          ],
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.2)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === WIDGET MỚI: Header nổi ===
  Widget _buildFloatingHeader(
      BuildContext context, SocialEvent event, bool isOwner, bool isDarkMode) {
    final tNameEmpty =
        getTranslated('event_name_empty', context) ?? '(Chưa có tên)';

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.2),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hàng chứa nút Back và Share
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(color: Colors.white),
                  IconButton(
                    icon:
                    const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () => _showShareSheet(event),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tên sự kiện
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  event.name ?? tNameEmpty,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(blurRadius: 6, color: Colors.black87)
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Các nút hành động chính
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: isOwner
                    ? _buildOwnerActions(context, event)
                    : _buildGuestActions(context, event),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _getGlassmorphismDecoration(BuildContext context,
      {bool isDarkMode = false}) {
    final glassColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.8);

    return BoxDecoration(
      color: glassColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor, width: 1.5),
    );
  }

  // === Thẻ thông tin chi tiết ===
  Widget _buildConsolidatedInfoCard(
      BuildContext context, SocialEvent event, bool isDarkMode) {
    final tDescription =
        getTranslated('description', context) ?? 'Mô tả';
    final tDescEmpty =
        getTranslated('event_description_empty', context) ??
            '(Chưa có mô tả)';
    final tTimeStart = getTranslated('event_time_start', context) ?? 'Thời gian bắt đầu';
    final tTimeEnd =
        getTranslated('event_time_end', context) ?? 'Thời gian kết thúc';
    final tLocation =
        getTranslated('event_location', context) ?? 'Địa điểm';
    final tLocationEmpty =
        getTranslated('event_location_empty', context) ??
            'Chưa có địa điểm';
    final tOrganizer =
        getTranslated('organizer', context) ?? 'Người tổ chức';

    // Helper nhỏ để build chuỗi ngày giờ
    String _buildDateTime(String? date, String? time) {
      final d = (date ?? '').trim();
      final t = (time ?? '').trim();
      if (d.isEmpty && t.isEmpty) return '-';
      if (d.isEmpty) return t;
      if (t.isEmpty) return d;
      return '$d $t';
    }

    final startText =
    _buildDateTime(event.startDate, event.startTime);
    final endText = _buildDateTime(event.endDate, event.endTime);
    final desc = event.description ?? tDescEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration:
          _getGlassmorphismDecoration(context, isDarkMode: isDarkMode),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bắt đầu
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                title: tTimeStart,
                subtitle: startText,
              ),
              const SizedBox(height: 12),
              // Kết thúc
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                title: tTimeEnd,
                subtitle: endText,
              ),
              _buildDivider(),
              _InfoRow(
                icon: Icons.location_on_outlined,
                title: tLocation,
                subtitle: event.location ?? tLocationEmpty,
              ),
              _buildDivider(),
              Text(
                tDescription,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.6),
              ),
              if (event.user != null) ...[
                _buildDivider(),
                Text(
                  tOrganizer,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                      NetworkImage(event.user!.avatar ?? ''),
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.user!.name ?? event.user!.username ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- CÁC WIDGET HELPER VÀ HÀNH ĐỘNG ---
  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.5)),
  );

  Widget _buildGuestActions(BuildContext context, SocialEvent event) {
    final theme = Theme.of(context);
    final tJoined =
        getTranslated('event_joined', context) ?? 'Đã tham gia';
    final tJoin = getTranslated('event_join', context) ?? 'Tham gia';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(
              event.isGoing ? Icons.check_circle : Icons.add_circle_outline,
            ),
            label: Text(event.isGoing ? tJoined : tJoin),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: event.isGoing
                  ? Colors.green.shade600
                  : theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final ok = await context
                  .read<EventController>()
                  .toggleEventGoing(event.id!);
              if (!mounted || !ok) return;
              setState(() {
                event.isGoing = !event.isGoing;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: Icon(
            event.isInterested ? Icons.star : Icons.star_border,
            color: Colors.white,
          ),
          style: IconButton.styleFrom(
            backgroundColor:
            (event.isInterested ? Colors.amber.shade700 : Colors.white)
                .withOpacity(0.2),
            side: BorderSide(color: Colors.white.withOpacity(0.4)),
          ),
          iconSize: 24,
          onPressed: () async {
            final ok = await context
                .read<EventController>()
                .toggleInterestEvent(event.id!);
            if (!mounted || !ok) return;
            setState(() {
              event.isInterested = !event.isInterested;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOwnerActions(BuildContext context, SocialEvent event) {
    final tEdit = getTranslated('edit', context) ?? 'Chỉnh sửa';
    final tDelete = getTranslated('delete', context) ?? 'Xóa';
    final tDeleteTitle =
        getTranslated('delete_event_title', context) ?? 'Xóa sự kiện';
    final tDeleteConfirm =
        getTranslated('delete_event_confirm', context) ??
            'Bạn có chắc muốn xóa? Hành động này không thể hoàn tác.';
    final tCancel = getTranslated('cancel', context) ?? 'Hủy';
    final tDeleteSuccess =
        getTranslated('event_delete_success', context) ?? 'Đã xóa sự kiện';
    final tDeleteFailed =
        getTranslated('event_delete_failed', context) ??
            'Xóa sự kiện thất bại.';

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_outlined,
            label: tEdit,
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
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.delete_outline,
            label: tDelete,
            color: Colors.red.shade400,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(tDeleteTitle),
                  content: Text(tDeleteConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(tCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        tDelete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              final ctrl = context.read<EventController>();
              final id = event.id?.toString() ?? widget.eventId;
              final ok = await ctrl.deleteEvent(id);

              if (!mounted) return;

              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tDeleteSuccess)),
                );
                Navigator.pop(context, true);
              } else {
                final msg = ctrl.error ?? tDeleteFailed;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.primaryColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: (color ?? theme.primaryColor).withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
    );
  }
}
