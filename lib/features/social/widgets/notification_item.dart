// lib/features/social/widgets/notification_item.dart
import 'dart:convert';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/models/social_notification.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_notifications_controller.dart';
// dùng các màn hình/mode hiện có trong dự án
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_group_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_groups_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/event_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class NotificationItem extends StatefulWidget {
  final SocialNotification n;

  const NotificationItem({
    super.key,
    required this.n,
  });

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  // ----- swipe to reveal delete -----
  double _drag = 0.0;
  static const double _revealMax = -90;
  static const double _revealSnap = -60;

  static const double _touchSlop = 8.0; // ngưỡng để xem là drag
  double _dxAccum = 0.0;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant NotificationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.n.id != widget.n.id) {
      _drag = 0.0;
      _dxAccum = 0.0;
      _dragging = false;
    }
  }

  void _onHDragUpdate(DragUpdateDetails d) {
    _dxAccum += d.delta.dx.abs();
    if (!_dragging && _dxAccum >= _touchSlop) _dragging = true;
    if (_dragging) {
      setState(() {
        _drag += d.delta.dx;
        if (_drag > 0) _drag = 0;
        if (_drag < _revealMax) _drag = _revealMax;
      });
    }
  }

  void _onHDragEnd(DragEndDetails d) {
    if (_dragging) {
      setState(() => _drag = (_drag <= _revealSnap) ? _revealMax : 0.0);
    }
    _dxAccum = 0.0;
    _dragging = false;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = n.seen == "0"
        ? theme.primaryColor.withOpacity(0.08)
        : theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final secondary = theme.hintColor;
    final String tNotificationDeleted =
        getTranslated('notification_deleted', context) ??
            'Đã xoá thông báo';


    final t = (_drag / _revealMax).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onHDragUpdate,
      onHorizontalDragEnd: _onHDragEnd,
      onTap: _handleTap,
      // 👈 điều hướng nằm ở đây (trong widget con)
      child: Stack(
        children: [
          // --- nút XÓA ---
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: IgnorePointer(
                ignoring: t < 0.6,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: t,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkResponse(
                      radius: 28,
                      onTap: () async {
                        setState(() {
                          _drag = 0.0;
                          _dragging = false;
                          _dxAccum = 0.0;
                        });
                        final ctrl = Provider.of<SocialNotificationsController>(
                          context,
                          listen: false,
                        );
                        final msg = await ctrl.deleteNotification(widget.n.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg ?? tNotificationDeleted),
                            backgroundColor: theme.colorScheme.error,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- nội dung (trượt trái khi kéo) ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_drag, 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            margin: const EdgeInsets.symmetric(vertical: 0),
            color: bgColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // avatar + icon loại
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(n.avatar),
                      backgroundColor: theme.colorScheme.error,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardColor, width: 1.5),
                        ),
                        padding: const EdgeInsets.all(0),
                        child: (n.type == 'reaction')
                            ? igReactionBadge(n.type2,
                            badge: 18)
                            : Icon(_iconByType(n.type),
                            color: _colorByType(n.type), size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: textRegular.copyWith(
                            color: textColor,
                            fontSize: Dimensions.fontSizeDefault,
                            height: 1.3,
                          ),
                          children: [
                            if (n.name.isNotEmpty)
                              TextSpan(
                                text: n.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (n.name.isNotEmpty) const TextSpan(text: ' '),
                            TextSpan(text: _messageByType(context, n)),
                          ],
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.timeText,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                if (n.seen == "0")
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ tap → mở chi tiết ngay trong widget con ------------------
  Future<void> _handleTap() async {
    if (_dragging) return;
    if (_drag != 0) {
      setState(() => _drag = 0.0);
      return;
    }
    final n = widget.n;
    await context
        .read<SocialNotificationsController>()
        .getNotificationDetail(n.id);
    debugPrint('[NOTI] $n');

    // 🟣 1️⃣ Story trước
    if (n.type == 'viewed_story' ||
        (n.storyId != null && n.storyId!.isNotEmpty && n.storyId != '0')) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SocialStoryViewerScreen(
                stories: [
                  SocialStory(
                    id: n.storyId ?? '',
                    userId: n.recipientId,
                    userName: n.name ?? '',
                    userAvatar: n.avatar ?? '',
                    items: [
                      SocialStoryItem(
                        id: n.storyId ?? '',
                        mediaUrl: '',
                        description: '',
                      ),
                    ],
                  ),
                ],
              ),
        ),
      );
      return;
    }

    // 🔵 2️⃣ Post/comment/reaction/share
    if (n.type == 'comment' ||
        n.type == 'comment_reply' ||
        n.type == 'reaction' ||
        n.type == 'shared_your_post' ||
        n.type == 'comment_mention' ||
        n.type == 'post_mention'
    ) {
      if (n.postId != '0' && n.postId.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SocialPostDetailScreen(
                  post: SocialPost(
                    id: n.postId.toString(),
                    reactionCount: 0,
                    myReaction: '',
                  ),
                ),
          ),
        );
        return;
      }
    }
    // 🟠 3️⃣ Group invitation → mở chi tiết nhóm

    if (n.type == 'invited_you_to_the_group'
        || n.type=='joined_group'
        || n.type=='requested_to_join_group'
        || n.type=='accepted_join_request'
        || n.type=='group_admin'
    ) {
      final groupId = n.groupId;
      // 🧩 chỉ hợp lệ nếu khác rỗng & khác '0'
      if (groupId.isNotEmpty && groupId != '0') {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SocialGroupDetailScreen(
              groupId: groupId,
            ),
          ),
        );
        return;
      } else if (n.type == 'group_admin') {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SocialGroupsScreen(),
          ),
        );
        return;
      }
    }

    // 🟡 4️⃣ Event (sự kiện)
    if (n.type == 'interested_event' || n.type == 'going_event') {
      final eventId = n.eventId ?? '';
      if (eventId.isNotEmpty && eventId != '0') {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: eventId),
          ),
        );
        return;
      }
    }

    // 🟢 Mặc định: mở profile
    final String notifierId = n.notifierId ?? '';
    if (notifierId.isNotEmpty) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(targetUserId: notifierId),
        ),
      );
    }
  }

  // ------------------ helpers ------------------
  static String _messageByType(BuildContext context, SocialNotification n) {
    final url = n.url;
    final isStory = (n.storyId != null && n.storyId != '0') ||
        url.contains('story=true') ||
        n.text.toLowerCase() == 'story';

    switch (n.type) {
      case 'reaction':
        return isStory
            ? (getTranslated('notification_reacted_to_story', context) ??
                'đã thả cảm xúc vào story của bạn.')
            : (getTranslated('notification_reacted_to_post', context) ??
                'đã thả cảm xúc vào bài viết của bạn.');
      case 'comment':
        return getTranslated('notification_commented_on_post', context) ??
            'đã bình luận vào bài viết của bạn.';
      case 'comment_reply':
        return getTranslated('notification_replied_to_comment', context) ??
            'đã trả lời bình luận của bạn.';
      case 'comment_mention':
        return getTranslated('notification_mentioned_in_comment', context) ??
            'đã nhắc đến bạn trong một bình luận.';
      case 'shared_your_post':
        return getTranslated('notification_shared_post', context) ??
            'đã chia sẻ bài viết của bạn.';
      case 'post_mention':
        return getTranslated('notification_mentioned_in_post', context) ??
            'đã nhắc đến bạn trong một bài viết.';
      case 'visited_profile':
        return getTranslated('notification_visited_profile', context) ??
            'đã ghé thăm trang cá nhân của bạn.';
      case 'invited_you_to_the_group':
        return getTranslated('notification_invited_to_group', context) ??
            'đã mời bạn tham gia nhóm.';
      case 'joined_group':
        return getTranslated('notification_joined_your_group', context) ??
            'đã tham gia nhóm của bạn.';
      case 'requested_to_join_group':
        return getTranslated('notification_requested_to_join_group', context) ??
            'đã gửi yêu cầu tham gia nhóm.';
      case 'accepted_join_request':
        return getTranslated('notification_accepted_join_request', context) ??
            'đã chấp nhận yêu cầu tham gia nhóm của bạn.';
      case 'group_admin':
        return getTranslated('notification_set_group_admin', context) ??
            'đã đặt bạn làm quản trị viên nhóm.';
      case 'following':
        return getTranslated('notification_started_following', context) ??
            'đã bắt đầu theo dõi bạn.';
      case 'viewed_story':
        return getTranslated('notification_viewed_story', context) ??
            'đã xem story của bạn.';
      case 'poke':
        return getTranslated('notification_poked_you', context) ??
            'đã chọc bạn.';
      case 'added_u_as':
        return getTranslated('notification_sent_family_request', context) ??
            'đã gửi cho bạn lời mời gia đình.';
      case 'interested_event':
        return getTranslated('notification_interested_in_event', context) ??
            'đã quan tâm tới sự kiện của bạn.';
      case 'going_event':
        return getTranslated('notification_going_to_event', context) ??
            'đã đánh dấu sẽ tham gia sự kiện của bạn.';
      default:
        return getTranslated('notification_interacted', context) ??
            'đã tương tác với bạn.';
    }
  }

  // Badge reaction đẹp hơn, mềm mại hơn, màu giống Facebook/Instagram
  static Widget igReactionBadge(String? type2, {double badge = 28}) {
    final t = (type2 ?? '').trim();

    final asset = <String, String>{
      '1': 'assets/images/reactions/like.png',
      '2': 'assets/images/reactions/love.png',
      '3': 'assets/images/reactions/haha.png',
      '4': 'assets/images/reactions/wow.png',
      '5': 'assets/images/reactions/sad.png',
      '6': 'assets/images/reactions/angry.png',
    }[t] ?? 'assets/images/reactions/like.png';

    return Container(
      width: badge,
      height: badge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }




  static IconData _iconByType(String type, [String? type2]) {
    switch (type) {
      case 'reaction':
        return Icons.favorite_rounded; // ❤️ nhẹ nhàng hơn thumb_up
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'comment_reply':
        return Icons.reply_rounded;
      case 'comment_mention':
        return Icons.alternate_email_rounded;
      case 'shared_your_post':
        return Icons.share_rounded;
      case 'post_mention':
        return Icons.alternate_email_rounded;
      case 'visited_profile':
        return Icons.person_search_rounded;
      case 'invited_you_to_the_group':
        return Icons.group_add_rounded;
      case 'joined_group':
        return Icons.groups_rounded;
      case 'requested_to_join_group':
        return Icons.group_rounded;
      case 'accepted_join_request':
        return Icons.check_circle_rounded;
      case 'group_admin':
        return Icons.verified_rounded;
      case 'following':
        return Icons.person_add_alt_1_rounded;
      case 'viewed_story':
        return Icons.visibility_rounded;
        case 'poke':
      return Icons.touch_app_rounded;
      case 'added_u_as':
        return Icons.family_restroom;
      case 'interested_event':
        return Icons.event_available_rounded;
      case 'going_event':
        return Icons.event_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _colorByType(String type, [String? type2]) {
    switch (type) {
      case 'reaction': return const Color(0xFF1877F2); // Blue FB
      case 'comment': return const Color(0xFF3BAFDA); // Light teal
      case 'comment_reply': return const Color(0xFF845EC2); // Violet
      case 'comment_mention': return const Color(0xFF5C33F6); // Deep purple
      case 'shared_your_post': return const Color(0xFF34B233); // Green
      case 'post_mention': return const Color(0xFFAD3EF3); // Lilac
      case 'visited_profile': return const Color(0xFF0DCEDA); // Cyan
      case 'invited_you_to_the_group': return const Color(0xFFFF7A00); // Orange
      case 'joined_group': return const Color(0xFFFFA200); // Yellow-orange
      case 'requested_to_join_group': return const Color(0xFF5BC0EB); // Sky blue
      case 'accepted_join_request': return const Color(0xFF34B233); // Green
      case 'group_admin': return const Color(0xFF1877F2); // Blue check
      case 'following': return const Color(0xFFFB6B90); // Pink coral
      case 'viewed_story': return const Color(0xFFF94892); // Magenta
      case 'poke':
        return const Color(0xFF0A84FF);
      case 'added_u_as':
        return const Color(0xFFFFB020); // vàng cam nhẹ cho family
      case 'interested_event':
        return const Color(0xFFFFB020); // vàng cam nổi bật cho sự kiện
      case 'going_event':
        return const Color(0xFF34B233); // xanh lá
      default: return const Color(0xFFAAAAAA);
    }
  }


}


