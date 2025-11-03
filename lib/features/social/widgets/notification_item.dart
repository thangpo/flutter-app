// lib/features/social/widgets/notification_item.dart
import 'dart:convert';

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
    final bgColor = n.seen == "0" ? const Color(0xFFE8F0FE) : Colors.white;
    final t = (_drag / _revealMax).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onHDragUpdate,
      onHorizontalDragEnd: _onHDragEnd,
      onTap: _handleTap, // 👈 điều hướng nằm ở đây (trong widget con)
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
                            content: Text(msg ?? 'Đã xoá thông báo'),
                            backgroundColor: Colors.redAccent,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 3),
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
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          _iconByType(n.type),
                          color: _colorByType(n.type),
                          size: 14,
                        ),
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
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
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
                            TextSpan(text: _messageByType(n)),
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
                    decoration: const BoxDecoration(
                      color: Colors.blue,
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
    debugPrint('[NOTI] id=${n.id}, post_id=${n.postId}, story_id=${n.storyId}, type=${n.type}, url=${n.url}');

    // 🟣 1️⃣ Story trước
    if (n.type == 'viewed_story' ||
        (n.storyId != null && n.storyId!.isNotEmpty && n.storyId != '0')) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SocialStoryViewerScreen(
            stories: [
              SocialStory(
                id: n.storyId ?? '',
                userId: n.notifierId,
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
        n.type == 'shared_your_post') {
      if (n.postId != '0' && n.postId.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SocialPostDetailScreen(
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

    // 🟢 3️⃣ Mặc định: mở profile
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
  static String _messageByType(SocialNotification n) {
    final url = n.url;
    final isStory = (n.storyId != null && n.storyId != '0') ||
        url.contains('story=true') ||
        n.text.toLowerCase() == 'story';

    switch (n.type) {
      case 'reaction':
        return isStory
            ? "đã thả cảm xúc vào story của bạn."
            : "đã thả cảm xúc vào bài viết của bạn.";
      case 'comment':
        return "đã bình luận vào bài viết của bạn.";
      case 'shared_your_post':
        return "đã chia sẻ bài viết của bạn.";
      case 'following':
        return "đã bắt đầu theo dõi bạn.";
      case 'viewed_story':
        return "đã xem story của bạn.";
      case 'comment_reply':
        return "đã trả lời bình luận của bạn.";
      default:
        return "đã tương tác với bạn.";
    }
  }


  static IconData _iconByType(String type) {
    switch (type) {
      case 'reaction':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'shared_your_post':
        return Icons.share;
      case 'following':
        return Icons.person_add;
      case 'viewed_story':
        return Icons.visibility;
      case 'comment_reply':
        return Icons.reply;
      default:
        return Icons.notifications;
    }
  }

  static Color _colorByType(String type) {
    switch (type) {
      case 'reaction':
        return Colors.redAccent;
      case 'comment':
        return Colors.blueAccent;
      case 'shared_your_post':
        return Colors.green;
      case 'following':
        return Colors.orange;
      case 'viewed_story':
        return Colors.purple;
      case 'comment_reply':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  // URL parsers cho WoWonder
  // ex: https://.../post/325&ref=57 → 325
  int? _extractPostId(String url) {
    try {
      final m = RegExp(r'/post/(\d+)').firstMatch(url);
      return m != null ? int.tryParse(m.group(1)!) : null;
    } catch (_) {
      return null;
    }
  }

  // lấy query param từ url (ví dụ story_id)
  String? _extractQuery(String url, String key) {
    try {
      final u = Uri.parse(url);
      return u.queryParameters[key];
    } catch (_) {
      return null;
    }
  }
}

// ===================== PLACEHOLDER Post Detail =====================
class _PostDetailPlaceholder extends StatelessWidget {
  final int postId;
  const _PostDetailPlaceholder({required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bài viết #$postId')),
      body: Center(
        child: Text('TODO: hiển thị chi tiết bài viết ID = $postId'),
      ),
    );
  }
}
