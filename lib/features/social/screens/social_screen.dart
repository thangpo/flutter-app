import 'package:flutter/material.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final posts = <_Post>[
      _Post(
        userName: 'Lò Văn Ninh',
        timeAgo: '3 ngày',
        text: 'đã cập nhật ảnh bìa của anh ấy.',
        imageUrl: 'https://picsum.photos/seed/flutter-social-1/800/450',
        isOnline: true,
      ),
      _Post(
        userName: 'Alice',
        timeAgo: '5h',
        text: 'Ảnh demo giao diện mới 📱',
        imageUrl: 'https://picsum.photos/seed/flutter-social-2/800/450',
        isOnline: false,
      ),
      _Post(
        userName: 'Bob',
        timeAgo: '1d',
        text:
        'Tip: nhớ bật caching cho danh sách để mượt hơn. Mình dùng AutomaticKeepAlive + PageStorageKey.',
        imageUrl: null,
        isOnline: false,
      ),
      _Post(
        userName: 'Xuân An',
        timeAgo: '5h',
        text: 'Ảnh demo giao diện mới 📱',
        imageUrl: 'https://picsum.photos/seed/flutter-social-2/800/450',
        isOnline: false,
      ),
    ];

    final stories = <_Story>[
      _Story(name: 'Tạo tin', isCreateStory: true),
      _Story(
          name: 'Lê Thị Thu Hà',
          imageUrl: 'https://picsum.photos/seed/story1/200/300'),
      _Story(
          name: 'Vũ Thị Bằng',
          imageUrl: 'https://picsum.photos/seed/story2/200/300'),
      _Story(name: 'Trọng', imageUrl: 'https://picsum.photos/seed/story3/200/300'),
    ];

    return Scaffold(
      // Dùng màu nền từ theme thay vì hard-code
      backgroundColor: cs.background,
      body: Column(
        children: [
          _FacebookHeader(), // header tự lấy màu từ theme bên trong

          Expanded(
            child: ListView(
              padding: EdgeBox.zero,
              children: [
                _WhatsOnYourMind(),

                const SizedBox(height: 8),

                _StoriesSection(stories: stories),

                const SizedBox(height: 8),

                ...posts.map((post) => _PostCard(post: post)),
              ],
            ),
          ),

          _BottomNavigation(),
        ],
      ),
    );
  }
}

class _FacebookHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      // surface cho thanh trên
      color: cs.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'facebook',
            style: TextStyle(
              color: onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              _HeaderIcon(icon: Icons.search),
              const SizedBox(width: 12),
              _HeaderIcon(icon: Icons.messenger_outline),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // elevated container theo surfaceVariant
        color: cs.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: onSurface.withOpacity(.9), size: 24),
    );
  }
}

class _WhatsOnYourMind extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.surfaceVariant,
            child: Icon(Icons.person, color: onSurface.withOpacity(.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bạn đang nghĩ gì?',
              style: TextStyle(
                color: onSurface.withOpacity(.7),
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: onSurface, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StoriesSection extends StatelessWidget {
  final List<_Story> stories;
  const _StoriesSection({required this.stories});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 200,
      color: cs.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        itemCount: stories.length,
        itemBuilder: (context, index) => _StoryCard(story: stories[index]),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final _Story story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceVariant,
      ),
      child: Stack(
        children: [
          if (!story.isCreateStory && story.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                story.imageUrl!,
                width: 110,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          if (story.isCreateStory)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 3),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cs.surfaceVariant,
                child: Icon(Icons.person, color: onSurface.withOpacity(.6), size: 20),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              story.name,
              style: TextStyle(
                color: onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.surfaceVariant,
                      child: Text(
                        post.userName.isNotEmpty ? post.userName[0] : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ),
                    if (post.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade400, // online dot
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            post.timeAgo,
                            style: TextStyle(
                              color: onSurface.withOpacity(.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.public,
                            size: 12,
                            color: onSurface.withOpacity(.6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: onSurface.withOpacity(.7)),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.close, color: onSurface.withOpacity(.7)),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Post Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              post.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: onSurface,
              ),
            ),
          ),

          // Post Image
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            Image.network(
              post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ],

          const SizedBox(height: 8),

          // Divider
          Divider(
            color: cs.outlineVariant,
            height: 1,
            thickness: 1,
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _PostAction(icon: Icons.thumb_up_outlined, label: 'Thích'),
                _PostAction(icon: Icons.mode_comment_outlined, label: 'Bình luận'),
                _PostAction(icon: Icons.share_outlined, label: 'Chia sẻ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PostAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: onSurface.withOpacity(.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withOpacity(.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        top: 4,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavItem(icon: Icons.home, label: 'Trang chủ', isActive: true),
          _NavItem(icon: Icons.ondemand_video_outlined, label: 'Reels'),
          _NavItem(icon: Icons.people_outline, label: 'Bạn bè'),
          _NavItem(icon: Icons.storefront_outlined, label: 'Marketplace'),
          _NavItem(icon: Icons.notifications_outlined, label: 'Thông báo', hasNotification: true),
          _NavItem(icon: Icons.menu, label: 'Menu'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool hasNotification;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? onSurface : onSurface.withOpacity(.6),
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? onSurface : onSurface.withOpacity(.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (hasNotification)
                Positioned(
                  top: -2,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Post {
  final String userName;
  final String timeAgo;
  final String text;
  final String? imageUrl;
  final bool isOnline;

  _Post({
    required this.userName,
    required this.timeAgo,
    required this.text,
    this.imageUrl,
    this.isOnline = false,
  });
}

class _Story {
  final String name;
  final String? imageUrl;
  final bool isCreateStory;

  _Story({
    required this.name,
    this.imageUrl,
    this.isCreateStory = false,
  });
}

// Small helper to avoid EdgeInsets.zero import everywhere
class EdgeBox {
  static const zero = EdgeInsets.zero;
}
