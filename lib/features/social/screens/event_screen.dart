// lib/features/social/screens/event_screen.dart
import 'dart:ui'; // cho ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/event_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_event_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/event_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/edit_event_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<EventController>().getEvents();
    });
  }

  Future<void> _openFilterSheet() async {
    final ctrl = context.read<EventController>();
    final theme = Theme.of(context);
    final current = ctrl.currentFetch;

    final options = <String, String>{
      'events': getTranslated('browse_events', context) ?? 'Duyệt qua các sự kiện',
      'going': getTranslated('events_you_are_going_to', context) ?? 'Sự kiện sẽ diễn ra',
      'interested': getTranslated('events_you_are_interested_in', context) ?? 'Sự kiện đã quan tâm',
      'past': getTranslated('past_events', context) ?? 'Những sự kiện đã qua',
      'my_events': getTranslated('my_events', context) ?? 'Sự kiện của tôi',
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        getTranslated('filter_events', context) ?? 'Lọc sự kiện',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...options.entries.map((e) {
                        final isSelected = e.key == current;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: isSelected
                              ? Icon(
                            Icons.check_circle,
                            color: theme.primaryColor,
                            size: 20,
                          )
                              : null,
                          onTap: () => Navigator.of(ctx).pop(e.key),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && selected != current) {
      await ctrl.getEvents(fetch: selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final tEvents = getTranslated('events', context) ?? 'Sự kiện';
    final tNoEvents = getTranslated('no_events_found', context) ?? 'Chưa có sự kiện nào';
    final eventCtrl = context.watch<EventController>();

    // CẤU TRÚC LẠI SCAFFOLD HOÀN TOÀN
    return Scaffold(
      // Đặt background động ra ngoài, không cần Stack nữa
      body: Stack(
        children: [
          _buildDecorativeBackground(isDarkMode),

          // CustomScrollView bây giờ là con trực tiếp của body (thông qua LiquidPullToRefresh)
          // Nó sẽ tự động có kích thước full màn hình và cuộn được.
          LiquidPullToRefresh(
            onRefresh: eventCtrl.refresh,
            color: theme.primaryColor,
            backgroundColor: theme.cardColor,
            showChildOpacityTransition: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(), // Thêm hiệu ứng nảy khi kéo
              slivers: [
                // AppBar được đặt bên trong CustomScrollView để có hiệu ứng ẩn/hiện khi cuộn
                SliverAppBar(
                  title: Text(tEvents, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
                  pinned: true, // Ghim AppBar ở trên cùng
                  floating: true, // Hiển thị lại ngay khi cuộn lên
                ),

                // Header chứa các nút Filter và Add
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HeaderDelegate(
                    child: _buildHeader(context),
                  ),
                ),

                // Nội dung chính
                if (eventCtrl.loading && eventCtrl.events.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (eventCtrl.events.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false, // Giữ nguyên fix này
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(tNoEvents, style: TextStyle(color: theme.hintColor)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final e = eventCtrl.events[index];
                          return GestureDetector(
                            onTap: () {
                              if (e.id == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(eventId: e.id!),
                                ),
                              );
                            },
                            child: _EventCard(event: e),
                          );
                        },
                        childCount: eventCtrl.events.length,
                      ),
                    ),
                  ),

                // Thêm một khoảng đệm an toàn ở cuối để không bị che bởi thanh điều hướng
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.bottom),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nền trang trí giống hệt Create/Edit Screen
  Widget _buildDecorativeBackground(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.black : const Color(0xFFF2F5F9),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDarkMode ? Colors.purple.shade900 : Colors.blue.shade200).withOpacity(0.5),
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
                // SỬA MÀU NỀN: Đổi từ purple sang một màu xanh
                color: (isDarkMode ? Colors.teal.shade900 : Colors.cyan.shade200).withOpacity(0.5),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final glassColor = isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6);
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glassColor.withOpacity(0.8),
                glassColor.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Text(
                getTranslated('suggested_for_you', context) ?? 'Gợi ý cho bạn',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              _RoundIconButton(
                icon: Icons.tune_rounded,
                onTap: _openFilterSheet,
              ),
              const SizedBox(width: 8),
              _RoundIconButton(
                icon: Icons.add,
                filled: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Delegate để ghim header khi cuộn
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _HeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: child,
    );
  }

  @override
  double get maxExtent => 64.0;

  @override
  double get minExtent => 64.0;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}


/// Nút tròn dùng cho search + add trên header
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final buttonColor = filled
        ? theme.primaryColor
        : (isDarkMode ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.5));
    final iconColor = filled ? Colors.white : (isDarkMode ? Colors.white : Colors.black87);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SocialEvent event;

  const _EventCard({required this.event});

  static bool _isDatePast(String? endDateStr) {
    if (endDateStr == null || endDateStr.isEmpty || endDateStr == '0000-00-00') {
      return false;
    }
    try {
      final date = DateTime.tryParse(endDateStr);
      if (date == null) return false;
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      return endOfDay.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = event.name ?? '';
    final coverUrl = event.cover;

    final socialCtrl = context.read<SocialController>();
    final currentUserId = socialCtrl.currentUser?.id?.toString();
    final posterId = event.posterId?.toString();
    final bool isOwner =
    (currentUserId != null && posterId != null && posterId == currentUserId);

    final currentFetch = context.read<EventController>().currentFetch;
    final bool isPast = event.isPast == true ||
        currentFetch == 'past' ||
        _isDatePast(event.endDate);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // LỚP 1: ẢNH NỀN
          Positioned.fill(
            child: coverUrl != null && coverUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: theme.primaryColor.withOpacity(0.1)),
              placeholder: (context, url) => Container(color: theme.cardColor),
            )
                : Container(
              color: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.event,
                  color: theme.primaryColor.withOpacity(0.5), size: 40),
            ),
          ),

          // LỚP 2: LỚP PHỦ GRADIENT TỐI
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // LỚP 3: NỘI DUNG VĂN BẢN VÀ NÚT BẤM
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 10),

                // CÁC NÚT HÀNH ĐỘNG
                if (isOwner)
                  _ActionButton(
                    label: getTranslated('edit', context) ?? 'Chỉnh sửa',
                    isPrimary: true,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditEventScreen(event: event)),
                      );
                      if (result == true && context.mounted) {
                        await context.read<EventController>().refresh();
                      }
                    },
                  )
                else if (isPast)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            getTranslated('event_ended', context) ?? 'Đã kết thúc',
                            style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: (currentFetch == 'going' || event.isGoing)
                              ? getTranslated('going_state', context) ?? 'Đã tham gia'
                              : getTranslated('join', context) ?? 'Tham gia',
                          isPrimary: !(event.isGoing),
                          onTap: () => context
                              .read<EventController>()
                              .toggleEventGoing(event.id!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => context
                            .read<EventController>()
                            .toggleInterestEvent(event.id!),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: event.isInterested
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            event.isInterested ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 20,
                            color: event.isInterested
                                ? theme.primaryColor
                                : Colors.white,
                          ),
                        ),
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
}

/// Widget con cho các nút hành động
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isPrimary ? theme.primaryColor : Colors.black.withOpacity(0.3);
    final textColor = Colors.white;

    return SizedBox(
      height: 36,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18), // Bo tròn thành viên thuốc
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
