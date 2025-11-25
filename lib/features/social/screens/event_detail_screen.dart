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
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

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
                        getTranslated('copy_link', context) ??
                            'Sao chép liên kết',
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
    final tEventNotFound = getTranslated('event_not_found', context) ??
        'Không tìm thấy sự kiện';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const _AppBarButton(child: BackButton(color: Colors.white)),
          actions: [
            FutureBuilder<SocialEvent?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _AppBarButton(
                    child: IconButton(
                      icon: const Icon(Icons.share_outlined,
                          color: Colors.white),
                      onPressed: () => _showShareSheet(snapshot.data!),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: FutureBuilder<SocialEvent?>(
          future: _future,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final event = snapshot.data ?? widget.initialEvent;

            if (event == null && isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (event == null) {
              return Center(
                child: Text(tEventNotFound),
              );
            }

            return _buildBody(context, event);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SocialEvent event) {
    final socialCtrl = context.read<SocialController>();
    final currentUserId = socialCtrl.currentUser?.id?.toString();
    final posterId = event.posterId?.toString();
    final bool isOwner = (event.isOwner == true) ||
        (currentUserId != null &&
            posterId != null &&
            posterId == currentUserId);

    final tNameEmpty =
        getTranslated('event_name_empty', context) ?? '(Chưa có tên)';

    return Stack(
      children: [
        // Lớp 1: Ảnh bìa tràn viền
        Positioned.fill(child: _buildCover(event)),

        // Lớp 2: Sheet kéo lên
        DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Tên sự kiện
                    Text(
                      event.name ?? tNameEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Khu vực hành động + “thống kê”
                    _buildActionsAndStatsSection(context, event, isOwner),

                    const Divider(height: 40),

                    // Thời gian + địa điểm
                    _buildDetailsSection(context, event),

                    const Divider(height: 40),

                    // Mô tả
                    _buildDescriptionSection(context, event),

                    // Người tổ chức
                    if (event.user != null) ...[
                      const Divider(height: 40),
                      _buildOrganizerSection(context, event),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- WIDGET CON ---

  Widget _buildCover(SocialEvent event) {
    final coverUrl = event.cover;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.2),
        image: coverUrl != null && coverUrl.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(coverUrl),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsAndStatsSection(
      BuildContext context, SocialEvent event, bool isOwner) {
    final theme = Theme.of(context);

    final tGoing = getTranslated('going', context) ?? 'Sẽ đi';
    final tInterested =
        getTranslated('interested', context) ?? 'Quan tâm';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // “Thống kê” trạng thái của chính mình
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                // Dùng ✓ / – thay cho số, vì backend không trả count
                count: event.isGoing ? '✓' : '–',
                label: tGoing,
              ),
              Container(
                width: 1,
                height: 30,
                color: theme.dividerColor,
              ),
              _StatItem(
                count: event.isInterested ? '✓' : '–',
                label: tInterested,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nút hành động
          isOwner
              ? _buildOwnerActions(context, event)
              : _buildGuestActions(context, event),
        ],
      ),
    );
  }

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
              backgroundColor:
              event.isGoing ? Colors.green.shade600 : theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final ok = await context
                  .read<EventController>()
                  .toggleEventGoing(event.id!);

              if (!mounted) return;
              if (!ok) return;

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
          ),
          color: event.isInterested ? Colors.amber.shade700 : theme.hintColor,
          iconSize: 28,
          onPressed: () async {
            final ok = await context
                .read<EventController>()
                .toggleInterestEvent(event.id!);

            if (!mounted) return;
            if (!ok) return;

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
    final tDeleteConfirm = getTranslated('delete_event_confirm', context) ??
        'Bạn có chắc muốn xóa? Hành động này không thể hoàn tác.';
    final tCancel = getTranslated('cancel', context) ?? 'Hủy';
    final tDeleteSuccess =
        getTranslated('event_delete_success', context) ??
            'Đã xóa sự kiện';
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

  Widget _buildDetailsSection(BuildContext context, SocialEvent event) {
    final tTime = getTranslated('event_time', context) ?? 'Thời gian';
    final tLocation =
        getTranslated('event_location', context) ?? 'Địa điểm';
    final tLocationEmpty =
        getTranslated('event_location_empty', context) ??
            'Chưa có địa điểm';

    final timeText = event.timeText ??
        '${event.startDate ?? ''}${event.startTime != null ? ' ${event.startTime}' : ''}';

    return Column(
      children: [
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          title: tTime,
          subtitle: timeText,
        ),
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.location_on_outlined,
          title: tLocation,
          subtitle: event.location ?? tLocationEmpty,
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, SocialEvent event) {
    final tDescription =
        getTranslated('description', context) ?? 'Mô tả';
    final tDescEmpty =
        getTranslated('event_description_empty', context) ??
            '(Chưa có mô tả)';

    final desc = event.description ?? tDescEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).hintColor,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerSection(BuildContext context, SocialEvent event) {
    final tOrganizer =
        getTranslated('organizer', context) ?? 'Người tổ chức';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              backgroundImage: NetworkImage(event.user!.avatar ?? ''),
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
    );
  }
}

// --- HELPER WIDGETS ---

class _AppBarButton extends StatelessWidget {
  final Widget child;
  const _AppBarButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: child,
          ),
        ),
      ),
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
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
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
    final buttonColor = color ?? theme.primaryColor;
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: buttonColor.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}
