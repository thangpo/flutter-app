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

    // map fetch -> nhãn tiếng Việt
    const options = <String, String>{
      'events': 'Duyệt qua các sự kiện',
      'going': 'Sự kiện sẽ diễn ra', // hoặc "Đang tham gia"
      'invited': 'Được mời',
      'interested': 'Sự kiện quan tâm',
      'past': 'Những sự kiện đã qua',
      'my_events': 'Sự kiện của tôi',
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lọc sự kiện',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.entries.map((e) {
                  final isSelected = e.key == current;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.value),
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
    final tEvents = getTranslated('events', context) ?? 'Events';
    final tNoEvents =
        getTranslated('no_events_found', context) ?? 'No events yet';
    final tSuggested =
        getTranslated('suggested_events', context) ?? 'Suggested for you';

    final eventCtrl = context.watch<EventController>();

    final titleColor =
    isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.iconTheme.color,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER (vẫn giữ hiệu ứng kính mờ)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tEvents,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
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
              ),
            ),
            const SizedBox(height: 8),

            // List sự kiện
            Expanded(
              child: LiquidPullToRefresh(
                onRefresh: eventCtrl.refresh,
                color: theme.primaryColor,
                backgroundColor: theme.cardColor,
                showChildOpacityTransition: false,
                child: eventCtrl.loading
                    ? const Center(child: CircularProgressIndicator())
                    : (eventCtrl.events.isEmpty
                    ? Center(
                  child: Text(
                    tNoEvents,
                    style: TextStyle(color: theme.hintColor),
                  ),
                )
                    : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          tSuggested,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: eventCtrl.events.length,
                        itemBuilder: (context, index) {
                          final e = eventCtrl.events[index];
                          return GestureDetector(
                            onTap: () {
                              if (e.id == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(
                                      eventId: e.id!),
                                ),
                              );
                            },
                            child: _EventCard(event: e),
                          );
                        },
                      ),
                    ],
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: filled ? theme.primaryColor : Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : theme.iconTheme.color,
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SocialEvent event;

  const _EventCard({required this.event});

  // Tự check quá hạn theo endDate dạng dd-mm-yy hoặc dd-mm-yyyy
  static bool _isDatePast(String? endDateStr) {
    if (endDateStr == null ||
        endDateStr.isEmpty ||
        endDateStr == '0000-00-00') {
      return false;
    }
    try {
      final parts = endDateStr.split('-');
      if (parts.length < 3) return false;
      final day = int.tryParse(parts[0]) ?? 1;
      final month = int.tryParse(parts[1]) ?? 1;
      var year = int.tryParse(parts[2]) ?? DateTime.now().year;
      if (year < 100) {
        year += 2000;
      }
      final end = DateTime(year, month, day, 23, 59, 59);
      return end.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final name = event.name ?? '';
    final location = event.location ?? '';
    final dateRange = '${event.startDate ?? ''} - ${event.endDate ?? ''}';
    final coverUrl = event.cover;

    final socialCtrl = context.read<SocialController>();
    final currentUserId = socialCtrl.currentUser?.id?.toString();
    final posterId = event.posterId?.toString();

    final bool isOwner = (event.isOwner == true) ||
        (currentUserId != null &&
            posterId != null &&
            posterId == currentUserId);

    final currentFetch = context.read<EventController>().currentFetch;

    // ✅ XÁC ĐỊNH EVENT ĐÃ QUA HẠN
    final bool isPast =
        event.isPast == true || currentFetch == 'past' || _isDatePast(event.endDate);
    // ✅ ĐANG Ở TAB "Sự kiện sẽ diễn ra"
    final bool isInGoingTab = currentFetch == 'going';
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.25)
        : Colors.white.withOpacity(0.7);

    // màu chính cho "Chỉnh sửa" + "Tham gia"
    final Color primaryButtonColor = theme.primaryColor;
    // màu cho nút "Quan tâm"
    final Color interestBgColor = Colors.white;
    final Color interestTextColor = theme.primaryColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh nền
            Positioned.fill(
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.4),
                      theme.primaryColor.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.event,
                  color: theme.primaryColor,
                  size: 40,
                ),
              ),
            ),

            // Gradient tối
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),

            // Lớp kính + nội dung
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon trên
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),

                        // Nội dung + nút phía dưới
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black26, blurRadius: 4)
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateRange,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 🔽 LOGIC NÚT
                            if (isOwner)
                            // Chủ sự kiện: nút CHỈNH SỬA (cùng màu với Tham gia)
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    backgroundColor: primaryButtonColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditEventScreen(event: event),
                                      ),
                                    );
                                    if (result == true) {
                                      // reload list
                                      await context
                                          .read<EventController>()
                                          .refresh();
                                    }
                                  },
                                  child: Text(
                                    getTranslated('edit', context) ??
                                        'Chỉnh sửa',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              )
                            else if (isPast)
                            // ❗ SỰ KIỆN ĐÃ QUA -> chỉ Quan tâm (màu khác)
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    backgroundColor: interestBgColor,
                                    foregroundColor: interestTextColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    side: BorderSide(
                                      color: interestTextColor.withOpacity(0.9),
                                      width: 1.2,
                                    ),
                                  ),
                                  onPressed: () => context
                                      .read<EventController>()
                                      .toggleInterestEvent(event.id!),
                                  child: Text(
                                    event.isInterested
                                        ? 'Đã quan tâm'
                                        : 'Quan tâm',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              )
                            else
                            // Sự kiện chưa qua -> Quan tâm (màu phụ) + Tham gia (màu chính)
                              Row(
                                children: [
                                  // Quan tâm
                                  Expanded(
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        backgroundColor: interestBgColor,
                                        foregroundColor: interestTextColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(999),
                                        ),
                                        side: BorderSide(
                                          color: interestTextColor
                                              .withOpacity(0.9),
                                          width: 1.2,
                                        ),
                                      ),
                                      onPressed: () => context
                                          .read<EventController>()
                                          .toggleInterestEvent(event.id!),
                                      child: Text(
                                        event.isInterested
                                            ? 'Đã quan tâm'
                                            : 'Quan tâm',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Tham gia
                                  Expanded(
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        backgroundColor: primaryButtonColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(999),
                                        ),
                                      ),
                                      onPressed: () => context
                                          .read<EventController>()
                                          .toggleEventGoing(event.id!),
                                      child: Text(
                                        (isInGoingTab || event.isGoing)
                                            ? 'Đã tham gia'
                                            : 'Tham gia',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
