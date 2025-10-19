import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_sixvalley_ecommerce/di_container.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class SocialPostDetailScreen extends StatefulWidget {
  final SocialPost post;
  const SocialPostDetailScreen({super.key, required this.post});

  @override
  State<SocialPostDetailScreen> createState() => _SocialPostDetailScreenState();
}

class _SocialPostDetailScreenState extends State<SocialPostDetailScreen> {
  bool _showInput = true;
  late Future<SocialPost?> _postFuture;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _sendingComment = false;
  String? _commentImagePath;
  String? _commentAudioPath;
  SocialComment? _replyingTo;

  final List<SocialComment> _comments = [];
  bool _loadingComments = false;
  bool _hasMore = true;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    final svc = sl<SocialServiceInterface>();
    _postFuture = svc.getPostById(postId: widget.post.id);
    _loadMoreComments();
  }

  Future<void> _refreshAll() async {
    final svc = sl<SocialServiceInterface>();
    setState(() {
      _postFuture = svc.getPostById(postId: widget.post.id);
      _comments.clear();
      _hasMore = true;
    });
    await _loadMoreComments();
  }

  Future<void> _loadMoreComments() async {
    if (_loadingComments || !_hasMore) return;
    _loadingComments = true;
    try {
      final svc = sl<SocialServiceInterface>();
      final list = await svc.getPostComments(
        postId: widget.post.id,
        limit: _pageSize,
        offset: _comments.length,
      );
      if (list.isEmpty || list.length < _pageSize) _hasMore = false;
      final existing = _comments.map((e) => e.id).toSet();
      setState(() {
        _comments.addAll(list.where((e) => !existing.contains(e.id)));
      });
    } finally {
      _loadingComments = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAll,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                    _loadMoreComments();
                  }
                  return false;
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _showInput = false);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<SocialPost?>(
                          future: _postFuture,
                          builder: (context, snap) {
                            final post = snap.data ?? p;
                            final ctrl = context.watch<SocialController>();
                            final idx =
                                ctrl.posts.indexWhere((e) => e.id == post.id);
                            final effective =
                                idx != -1 ? ctrl.posts[idx] : post;
                            final myReaction = effective.myReaction;
                            final reactionCount = effective.reactionCount;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          (post.userAvatar != null &&
                                                  post.userAvatar!.isNotEmpty)
                                              ? NetworkImage(post.userAvatar!)
                                              : null,
                                      child: (post.userAvatar == null ||
                                              post.userAvatar!.isEmpty)
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.userName ?? 'Người dùng',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          if ((post.timeText ?? '').isNotEmpty)
                                            Text(
                                              post.timeText!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      color: onSurface
                                                          .withOpacity(.6)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if ((post.text ?? '').isNotEmpty)
                                  const SizedBox(height: 4),
                                if ((post.text ?? '').isNotEmpty)
                                  Html(data: post.text!),
                                const SizedBox(height: 8),
                                _DetailMedia(post: post),
                                if (post.hasProduct)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _ProductBlock(
                                      title: post.productTitle,
                                      images: post.productImages ?? const [],
                                      price: post.productPrice,
                                      currency: post.productCurrency,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: Builder(
                                          builder: (itemCtx) => InkWell(
                                            onTap: () {
                                              final was = myReaction;
                                              final now =
                                                  (was == 'Like') ? '' : 'Like';
                                              final target = idx != -1
                                                  ? ctrl.posts[idx]
                                                  : post;
                                              itemCtx
                                                  .read<SocialController>()
                                                  .reactOnPost(target, now);
                                            },
                                            onLongPress: () {
                                              final overlayBox =
                                                  Overlay.of(itemCtx)
                                                          .context
                                                          .findRenderObject()
                                                      as RenderBox;
                                              final box =
                                                  itemCtx.findRenderObject()
                                                      as RenderBox?;
                                              final Offset centerGlobal =
                                                  (box != null)
                                                      ? box.localToGlobal(
                                                          box.size.center(
                                                              Offset.zero),
                                                          ancestor: overlayBox)
                                                      : overlayBox.size
                                                          .center(Offset.zero);
                                              _showReactionsOverlay(
                                                itemCtx,
                                                centerGlobal,
                                                onSelect: (val) {
                                                  final target = idx != -1
                                                      ? ctrl.posts[idx]
                                                      : post;
                                                  itemCtx
                                                      .read<SocialController>()
                                                      .reactOnPost(target, val);
                                                },
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  _reactionIcon(myReaction),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    reactionCount.toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      _PostAction(
                                        icon: Icons.mode_comment_outlined,
                                        label: 'Bình luận',
                                        onTap: () {
                                          setState(() => _showInput = true);
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (mounted) {
                                              FocusScope.of(context)
                                                  .requestFocus(_commentFocus);
                                            }
                                          });
                                        },
                                      ),
                                      const _PostAction(
                                          icon: Icons.share_outlined,
                                          label: 'Chia sẻ'),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Divider(color: onSurface.withOpacity(.12)),
                        const SizedBox(height: 8),
                        Text(
                          'Bình luận (${_comments.length}${_hasMore ? '+' : ''})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            if (_comments.isEmpty && _loadingComments) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (_comments.isEmpty) {
                              return Text(
                                'Chưa có bình luận',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: onSurface.withOpacity(.7)),
                              );
                            }
                            final svc = sl<SocialServiceInterface>();
                            return Column(
                              children: [
                                for (final c in _comments)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage:
                                              (c.userAvatar != null &&
                                                      c.userAvatar!.isNotEmpty)
                                                  ? NetworkImage(c.userAvatar!)
                                                  : null,
                                          child: (c.userAvatar == null ||
                                                  c.userAvatar!.isEmpty)
                                              ? const Icon(Icons.person,
                                                  size: 16)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      c.userName ??
                                                          'Người dùng',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                    ),
                                                  ),
                                                  if ((c.timeText ?? '')
                                                      .isNotEmpty)
                                                    Text(
                                                      _formatTimeText(
                                                          c.timeText),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                              color: onSurface
                                                                  .withOpacity(
                                                                      .6)),
                                                    ),
                                                ],
                                              ),
                                              if ((c.text ?? '').isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(c.text!),
                                                ),
                                              if ((c.imageUrl ?? '').isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 6),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: CachedNetworkImage(
                                                      imageUrl: c.imageUrl!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              if ((c.audioUrl ?? '').isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 6),
                                                  child: _AudioPlayerBox(
                                                    url: c.audioUrl!,
                                                    autoplay: false,
                                                  ),
                                                ),
                                              _RepliesLazy(
                                                comment: c,
                                                service: svc,
                                                onRequestReply: (target) {
                                                  setState(() {
                                                    _replyingTo = target;
                                                    _showInput = true;
                                                  });
                                                  FocusScope.of(context)
                                                      .requestFocus(
                                                          _commentFocus);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_loadingComments) ...[
                                  const SizedBox(height: 8),
                                  const Center(
                                      child: CircularProgressIndicator()),
                                ] else if (_hasMore) ...[
                                  const SizedBox(height: 8),
                                  Center(
                                    child: TextButton(
                                      onPressed: _loadMoreComments,
                                      child: const Text('Tải thêm bình luận'),
                                    ),
                                  )
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ===== FIXED: nhánh nhập bình luận, đúng cấu trúc child =====
          _showInput
              ? SafeArea(
                  top: false,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: onSurface.withOpacity(.1)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_replyingTo != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Đang trả lời \'${_replyingTo!.userName ?? ''}\'',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _replyingTo = null),
                                  child: const Text('Hủy'),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                focusNode: _commentFocus,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập bình luận...',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Attach image',
                              onPressed: () async {
                                final img = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 80);
                                if (img != null)
                                  setState(() => _commentImagePath = img.path);
                              },
                              icon: const Icon(Icons.image_outlined),
                            ),
                            IconButton(
                              tooltip: 'Attach audio',
                              onPressed: () async {
                                final res = await FilePicker.platform
                                    .pickFiles(type: FileType.audio);
                                if (res != null && res.files.isNotEmpty) {
                                  setState(() =>
                                      _commentAudioPath = res.files.first.path);
                                }
                              },
                              icon: const Icon(Icons.audiotrack_outlined),
                            ),
                            IconButton(
                              tooltip: 'Gửi',
                              onPressed: _sendingComment
                                  ? null
                                  : () async {
                                      final txt =
                                          _commentController.text.trim();
                                      if (txt.isEmpty &&
                                          _commentImagePath == null &&
                                          _commentAudioPath == null) return;
                                      setState(() => _sendingComment = true);
                                      try {
                                        final svc =
                                            sl<SocialServiceInterface>();
                                        if (_replyingTo == null) {
                                          await svc.createComment(
                                            postId: widget.post.id,
                                            text: txt,
                                            imagePath: _commentImagePath,
                                            audioPath: _commentAudioPath,
                                          );
                                        } else {
                                          await svc.createReply(
                                            commentId: _replyingTo!.id,
                                            text: txt,
                                            imagePath: _commentImagePath,
                                          );
                                        }
                                        _commentController.clear();
                                        setState(() {
                                          _commentImagePath = null;
                                          _commentAudioPath = null;
                                          _replyingTo = null;
                                        });
                                        await _refreshAll();
                                      } catch (e) {
                                        showCustomSnackBar(
                                            e.toString(), context,
                                            isError: true);
                                      } finally {
                                        if (mounted)
                                          setState(
                                              () => _sendingComment = false);
                                      }
                                    },
                              icon: const Icon(Icons.send),
                            ),
                            IconButton(
                              tooltip: 'Ẩn ô nhập',
                              onPressed: () =>
                                  setState(() => _showInput = false),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        if (_commentImagePath != null ||
                            (_commentAudioPath != null && _replyingTo == null))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (_commentImagePath != null)
                                  InputChip(
                                    label: const Text('Ảnh đính kèm'),
                                    onDeleted: () => setState(
                                        () => _commentImagePath = null),
                                  ),
                                if (_commentAudioPath != null &&
                                    _replyingTo == null)
                                  InputChip(
                                    label: const Text('Âm thanh đính kèm'),
                                    onDeleted: () => setState(
                                        () => _commentAudioPath = null),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showInput = true;
                            _replyingTo = null;
                          });
                          FocusScope.of(context).requestFocus(_commentFocus);
                        },
                        icon: const Icon(Icons.mode_comment_outlined),
                        label: const Text('Viết bình luận'),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PostAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: onSurface.withOpacity(.8)),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailMedia extends StatelessWidget {
  final SocialPost post;
  const _DetailMedia({required this.post});

  @override
  Widget build(BuildContext context) {
    if ((post.videoUrl ?? '').isNotEmpty) {
      return _VideoPlayerBox(url: post.videoUrl!);
    }
    if ((post.audioUrl ?? '').isNotEmpty && post.imageUrls.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ImagesCarousel(urls: post.imageUrls),
          const SizedBox(height: 8),
          _AudioPlayerBox(
              url: post.audioUrl!, autoplay: true, title: post.fileName),
        ],
      );
    }
    if ((post.audioUrl ?? '').isNotEmpty) {
      return _AudioPlayerBox(
          url: post.audioUrl!, autoplay: false, title: post.fileName);
    }
    final imgs = post.imageUrls;
    if (imgs.isEmpty) return const SizedBox.shrink();
    if (imgs.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imgs.first,
          fit: BoxFit.cover,
        ),
      );
    }
    return _ImagesCarousel(urls: imgs);
  }
}

class _ProductBlock extends StatelessWidget {
  final String? title;
  final List<String> images;
  final double? price;
  final String? currency;
  const _ProductBlock(
      {this.title, required this.images, this.price, this.currency});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onSurface.withOpacity(.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: (images.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: images.first,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, size: 28),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((title ?? '').isNotEmpty)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 6),
                if (price != null)
                  Text(
                    currency == null
                        ? '${price!.toStringAsFixed(2)}'
                        : '${price!.toStringAsFixed(2)} $currency',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionSummary extends StatelessWidget {
  final String myReaction;
  final int count;
  const _ReactionSummary({required this.myReaction, required this.count});

  String _reactionAsset(String r) {
    switch (r) {
      case 'Love':
        return 'assets/images/reactions/love.png';
      case 'HaHa':
        return 'assets/images/reactions/haha.png';
      case 'Wow':
        return 'assets/images/reactions/wow.png';
      case 'Sad':
        return 'assets/images/reactions/sad.png';
      case 'Angry':
        return 'assets/images/reactions/angry.png';
      case 'Like':
        return 'assets/images/reactions/like.png';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (myReaction.isEmpty) {
      return Row(
        children: [
          Icon(Icons.thumb_up_outlined,
              size: 18, color: onSurface.withOpacity(.6)),
          const SizedBox(width: 6),
          Text('$count'),
        ],
      );
    }
    final asset = _reactionAsset(myReaction);
    if (asset.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.thumb_up, size: 18),
          const SizedBox(width: 6),
          Text('$count'),
        ],
      );
    }
    return Row(
      children: [
        Image.asset(asset, width: 18, height: 18),
        const SizedBox(width: 6),
        Text('$count'),
      ],
    );
  }
}

class _ImagesCarousel extends StatefulWidget {
  final List<String> urls;
  const _ImagesCarousel({required this.urls});
  @override
  State<_ImagesCarousel> createState() => _ImagesCarouselState();
}

class _ImagesCarouselState extends State<_ImagesCarousel> {
  final PageController _pc = PageController();
  int _index = 0;
  double? _aspect;

  @override
  void initState() {
    super.initState();
    _resolveAspect();
  }

  void _resolveAspect() {
    if (widget.urls.isEmpty) return;
    final provider = CachedNetworkImageProvider(widget.urls.first);
    final stream = provider.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (w > 0 && h > 0) {
        setState(() => _aspect = w / h);
      }
    }));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect ?? 1.0;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: aspect,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.urls.length,
              itemBuilder: (ctx, i) => CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.urls.length; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RepliesLazy extends StatefulWidget {
  final SocialComment comment;
  final SocialServiceInterface service;
  final void Function(SocialComment) onRequestReply;
  const _RepliesLazy(
      {required this.comment,
      required this.service,
      required this.onRequestReply});

  @override
  State<_RepliesLazy> createState() => _RepliesLazyState();
}

class _RepliesLazyState extends State<_RepliesLazy> {
  bool _expanded = false;
  bool _loading = false;
  List<SocialComment> _replies = const [];
  // Giữ lại các biến cũ để tránh lỗi biên dịch trong khối UI đã vô hiệu hóa
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final list =
          await widget.service.getCommentReplies(commentId: widget.comment.id);
      setState(() {
        _replies = list;
        _expanded = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (!_expanded) {
      if ((widget.comment.repliesCount ?? 0) == 0) {
        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => widget.onRequestReply(widget.comment),
            child: Text(
              'Trả lời',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: onSurface.withOpacity(.6)),
            ),
          ),
        );
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _load,
              child: Text(
                'Xem phản hồi (${widget.comment.repliesCount ?? 0})',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: onSurface.withOpacity(.6)),
              ),
            ),
            TextButton(
              onPressed: () => widget.onRequestReply(widget.comment),
              child: Text(
                'Trả lời',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: onSurface.withOpacity(.6)),
              ),
            ),
          ],
        ),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        for (final r in _replies)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage:
                      (r.userAvatar != null && r.userAvatar!.isNotEmpty)
                          ? NetworkImage(r.userAvatar!)
                          : null,
                  child: (r.userAvatar == null || r.userAvatar!.isEmpty)
                      ? const Icon(Icons.person, size: 14)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.userName ?? 'Người dùng',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if ((r.timeText ?? '').isNotEmpty)
                            Text(
                              _formatTimeText(r.timeText),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: onSurface.withOpacity(.6)),
                            ),
                        ],
                      ),
                      if ((r.text ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(r.text!),
                        ),
                      if ((r.imageUrl ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: r.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if ((r.audioUrl ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _AudioPlayerBox(
                            url: r.audioUrl!,
                            autoplay: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        if (false)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: const InputDecoration(
                    hintText: 'Viết phản hồi...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Gửi',
                onPressed: _sending
                    ? null
                    : () async {
                        final txt = _replyController.text.trim();
                        if (txt.isEmpty) return;
                        setState(() => _sending = true);
                        try {
                          await widget.service.createReply(
                              commentId: widget.comment.id, text: txt);
                          _replyController.clear();
                          await _load();
                        } catch (e) {
                          showCustomSnackBar(e.toString(), context,
                              isError: true);
                        } finally {
                          if (mounted) setState(() => _sending = false);
                        }
                      },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
      ],
    );
  }
}

class _VideoPlayerBox extends StatefulWidget {
  final String url;
  const _VideoPlayerBox({required this.url});
  @override
  State<_VideoPlayerBox> createState() => _VideoPlayerBoxState();
}

class _VideoPlayerBoxState extends State<_VideoPlayerBox> {
  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Container(
        alignment: Alignment.center,
        color: Colors.black12,
        height: 200,
        child: const CircularProgressIndicator(),
      );
    }
    final ar = _controller.value.aspectRatio == 0
        ? 16 / 9
        : _controller.value.aspectRatio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: ar,
          child: VideoPlayer(_controller),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Builder(
                builder: (context) {
                  final totalMs = _controller.value.duration.inMilliseconds;
                  final posMs = _controller.value.position.inMilliseconds;
                  final maxVal = totalMs <= 0 ? 1.0 : totalMs.toDouble();
                  final curVal =
                      (posMs.clamp(0, totalMs <= 0 ? 1 : totalMs)).toDouble();
                  return Slider(
                    min: 0,
                    max: maxVal,
                    value: curVal,
                    onChanged: (v) async {
                      await _controller
                          .seekTo(Duration(milliseconds: v.toInt()));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

typedef _OnReactionSelect = void Function(String);

void _showReactionsOverlay(
  BuildContext context,
  Offset globalPos, {
  required _OnReactionSelect onSelect,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(builder: (_) {
    final RenderBox overlayBox =
        overlay.context.findRenderObject() as RenderBox;
    final Offset local = overlayBox.globalToLocal(globalPos);

    const double popupWidth = 300;
    const double popupHeight = 56;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(onTap: () => entry.remove()),
        ),
        Positioned(
          left: (local.dx - popupWidth / 2)
              .clamp(8.0, overlayBox.size.width - popupWidth - 8.0),
          top: (local.dy - popupHeight - 12)
              .clamp(8.0, overlayBox.size.height - popupHeight - 8.0),
          width: popupWidth,
          height: popupHeight,
          child: _ReactionBar(
            onPick: (v) {
              onSelect(v);
              entry.remove();
            },
          ),
        ),
      ],
    );
  });

  overlay.insert(entry);
}

class _ReactionBar extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _ReactionBar({required this.onPick});

  @override
  Widget build(BuildContext context) {
    const items = ['Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'];
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items.map((e) {
              return GestureDetector(
                onTap: () => onPick(e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _reactionIcon(e, size: 28),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

Widget _reactionIcon(String r, {double size = 22}) {
  final String path = _reactionPngPath(r);
  return Image.asset(
    path,
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
  );
}

String _reactionPngPath(String r) {
  switch (r) {
    case 'Love':
      return 'assets/images/reactions/love.png';
    case 'HaHa':
      return 'assets/images/reactions/haha.png';
    case 'Wow':
      return 'assets/images/reactions/wow.png';
    case 'Sad':
      return 'assets/images/reactions/sad.png';
    case 'Angry':
      return 'assets/images/reactions/angry.png';
    case 'Like':
      return 'assets/images/reactions/like.png';
    default:
      return 'assets/images/reactions/like_outline.png';
  }
}

String _formatTimeText(String? raw) {
  if (raw == null) return '';
  final s = raw.trim();
  if (s.isEmpty) return '';
  final intVal = int.tryParse(s);
  if (intVal == null) {
    return s;
  }
  int ms;
  if (intVal >= 1000000000000) {
    ms = intVal;
  } else if (intVal >= 1000000000) {
    ms = intVal * 1000;
  } else {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    ms = nowMs - (intVal * 1000);
  }
  final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
  final now = DateTime.now();
  Duration diff = now.difference(dt);
  if (diff.isNegative) diff = -diff;

  if (diff.inSeconds < 60) return 'vài giây trước';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
  return '${(diff.inDays / 365).floor()} năm trước';
}

class _AudioPlayerBox extends StatefulWidget {
  final String url;
  final bool autoplay;
  final String? title;
  const _AudioPlayerBox({required this.url, this.autoplay = false, this.title});
  @override
  State<_AudioPlayerBox> createState() => _AudioPlayerBoxState();
}

class _AudioPlayerBoxState extends State<_AudioPlayerBox> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _dur = const Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((d) => setState(() => _pos = d));
    _player.onDurationChanged.listen((d) => setState(() => _dur = d));
    if (widget.autoplay) {
      _player.play(UrlSource(widget.url));
      _playing = true;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(_playing
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill),
              onPressed: () async {
                if (_playing) {
                  await _player.pause();
                } else {
                  await _player.play(UrlSource(widget.url));
                }
                setState(() => _playing = !_playing);
              },
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final totalMs = _dur.inMilliseconds;
                  final posMs = _pos.inMilliseconds;
                  final maxVal = totalMs <= 0 ? 1.0 : totalMs.toDouble();
                  final curVal =
                      (posMs.clamp(0, totalMs <= 0 ? 1 : totalMs)).toDouble();
                  return Slider(
                    min: 0,
                    max: maxVal,
                    value: curVal,
                    onChanged: (v) async {
                      await _player.seek(Duration(milliseconds: v.toInt()));
                    },
                  );
                },
              ),
            ),
          ],
        ),
        if ((widget.title ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(widget.title!),
          ),
      ],
    );
  }
}
