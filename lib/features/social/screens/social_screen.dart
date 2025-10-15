import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi refresh sau khi màn hình mount để chắc chắn lúc này đã có token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialController>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Column(
          children: [
            _FacebookHeader(),
            Expanded(
              child: Consumer<SocialController>(
                builder: (context, sc, _) {
                  if (sc.loading && sc.posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                    onRefresh: () => sc.refresh(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 200) {
                          sc.loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: sc.posts.length +
                            2, // +2: "Bạn đang nghĩ gì?" + "Stories"// +1 cho vùng "Bạn đang nghĩ gì?"
                        itemBuilder: (ctx, i) {
                          if (i == 0) return _WhatsOnYourMind();
                          if (i == 1) {
                            return Consumer<SocialController>(
                              builder: (context, sc2, __) {
                                final items = sc2.stories;
                                if (items.isEmpty)
                                  return const SizedBox.shrink();
                                return _StoriesSectionFromApi(stories: items);
                              },
                            );
                          }
                          final SocialPost p = sc.posts[i - 2];
                          return _PostCardFromApi(post: p);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
          Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? Images.logoWithNameSocialImageWhite
                : Images.logoWithNameSocialImage,
            height: 28,
            fit: BoxFit.contain,
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

class _StoriesSectionFromApi extends StatelessWidget {
  final List<SocialStory> stories;
  const _StoriesSectionFromApi({required this.stories});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 200,
      color: cs.surface,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // chỉ bắt event của scroll ngang
          if (n.metrics.axis == Axis.horizontal &&
              n.metrics.pixels >= n.metrics.maxScrollExtent - 100) {
            // gọi load thêm stories
            Provider.of<SocialController>(context, listen: false)
                .loadMoreStories();
          }
          return false;
        },
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          itemCount: stories.length,
          itemBuilder: (context, index) =>
              _StoryCardFromApi(story: stories[index]),
        ),
      ),
    );
  }
}

class _StoryCardFromApi extends StatelessWidget {
  final SocialStory story;
  const _StoryCardFromApi({required this.story});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final thumb = story.thumbUrl ?? story.mediaUrl;

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceVariant,
      ),
      child: Stack(
        children: [
          if (thumb != null && thumb.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumb,
                width: 110,
                height: 200,
                fit: BoxFit.cover,
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
                backgroundImage:
                    (story.userAvatar != null && story.userAvatar!.isNotEmpty)
                        ? NetworkImage(story.userAvatar!)
                        : null,
                child: (story.userAvatar == null || story.userAvatar!.isEmpty)
                    ? Icon(Icons.person,
                        color: onSurface.withOpacity(.6), size: 20)
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              story.userName ?? '',
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
                child: Icon(Icons.person,
                    color: onSurface.withOpacity(.6), size: 20),
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

class _PostCardFromApi extends StatelessWidget {
  final SocialPost post;
  const _PostCardFromApi({required this.post});

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
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage:
                      (post.userAvatar != null && post.userAvatar!.isNotEmpty)
                          ? NetworkImage(post.userAvatar!)
                          : null,
                  child: (post.userAvatar == null || post.userAvatar!.isEmpty)
                      ? Text(
                          (post.userName?.isNotEmpty ?? false)
                              ? post.userName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: onSurface),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName ?? '—',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: onSurface)),
                      Text(post.timeText ?? '',
                          style: TextStyle(
                              color: onSurface.withOpacity(.6), fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.more_horiz,
                        color: onSurface.withOpacity(.7)),
                    onPressed: () {}),
              ],
            ),
          ),

          if ((post.postType ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    post.postType == 'profile_picture'
                        ? Icons.person_outline
                        : post.postType == 'profile_cover_picture'
                            ? Icons.collections
                            : Icons.article_outlined,
                    size: 16,
                    color: onSurface.withOpacity(.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    post.postType == 'profile_picture'
                        ? 'đã cập nhật ảnh đại diện'
                        : post.postType == 'profile_cover_picture'
                            ? 'đã cập nhật ảnh bìa'
                            : post.postType!,
                    style: TextStyle(
                        color: onSurface.withOpacity(.7),
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Text
          if ((post.text ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.text!,
                style: TextStyle(fontSize: 15, height: 1.35, color: onSurface),
              ),
            ),

          // Media (ưu tiên multi)
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ImageGrid(urls: post.imageUrls),
          ] else if ((post.imageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _ImageGrid(urls: [post.imageUrl!]),
          ],

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _PostAction(icon: Icons.thumb_up_outlined, label: 'Thích'),
                _PostAction(
                    icon: Icons.mode_comment_outlined, label: 'Bình luận'),
                _PostAction(icon: Icons.share_outlined, label: 'Chia sẻ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> urls;
  const _ImageGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    // Ép kích thước tổng thể để con bên trong có ràng buộc (không bị MISSING size)
    final double aspect = urls.length == 1 ? (16 / 9) : (16 / 9); // có thể đổi 1.0 nếu muốn ô vuông
    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (urls.length == 1) {
      return _tile(urls[0]);
    } else if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _square(urls[0])),
          const SizedBox(width: 4),
          Expanded(child: _square(urls[1])),
        ],
      );
    } else if (urls.length == 3) {
      return Row(
        children: [
          Expanded(child: _square(urls[0])),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _square(urls[1])),
                const SizedBox(height: 4),
                Expanded(child: _square(urls[2])),
              ],
            ),
          ),
        ],
      );
    } else {
      // >= 4
      final remain = urls.length - 4;
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _square(urls[0])),
                const SizedBox(width: 4),
                Expanded(child: _square(urls[1])),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _square(urls[2])),
                const SizedBox(width: 4),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand, // BÂY GIỜ đã có ràng buộc từ Expanded cha
                    children: [
                      _square(urls[3]),
                      if (remain > 0)
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Text(
                            '+$remain',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Ảnh vuông dùng bên trong grid
  Widget _square(String u) => AspectRatio(
    aspectRatio: 1,
    child: _tile(u),
  );

  Widget _tile(String u) => Image.network(
    u,
    fit: BoxFit.cover,
    // tránh crash vì lỗi ảnh
    errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
  );
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
