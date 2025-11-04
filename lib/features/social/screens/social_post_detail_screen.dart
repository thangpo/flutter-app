import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
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
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/share_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/shared_post_preview.dart';
import 'package:url_launcher/url_launcher.dart';

enum CommentSortOrder { newest, oldest }

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
  String? _commentImageUrl;
  String? _commentAudioPath;
  SocialComment? _replyingTo;
  final List<SocialComment> _comments = [];
  bool _loadingComments = false;
  bool _hasMore = true;
  final int _pageSize = 10;
  final Set<String> _commentReactionLoading = <String>{};
  CommentSortOrder _sortOrder = CommentSortOrder.newest;

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
        _sortComments();
      });
    } finally {
      _loadingComments = false;
    }
  }

  Future<void> _reactOnComment(SocialComment comment, String reaction) async {
    final idx = _comments.indexWhere((e) => e.id == comment.id);
    if (idx == -1) return;
    if (_commentReactionLoading.contains(comment.id)) return;
    final previous = _comments[idx];
    final was = previous.myReaction;
    final now = reaction;
    int delta = 0;
    if (was.isEmpty && now.isNotEmpty) {
      delta = 1;
    } else if (was.isNotEmpty && now.isEmpty) {
      delta = -1;
    }
    final optimistic = previous.copyWith(
      myReaction: now,
      reactionCount: (previous.reactionCount + delta).clamp(0, 1 << 31).toInt(),
    );
    setState(() {
      _comments[idx] = optimistic;
    });
    _commentReactionLoading.add(comment.id);
    try {
      final svc = sl<SocialServiceInterface>();
      await svc.reactToComment(commentId: comment.id, reaction: now);
    } catch (e) {
      setState(() {
        _comments[idx] = previous;
      });
      showCustomSnackBar(e.toString(), context, isError: true);
    } finally {
      _commentReactionLoading.remove(comment.id);
    }
  }

  Future<void> _handleSharePost(SocialPost post) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharePostScreen(post: post),
        fullscreenDialog: true,
      ),
    );
  }

  String _sharedSubtitleDetail(BuildContext context, SocialPost post) {
    final SocialPost? shared = post.sharedPost;
    if (shared == null) return '';
    final String owner =
        post.userName ?? (getTranslated('user', context) ?? 'User');
    final String original =
        shared.userName ?? (getTranslated('user', context) ?? 'User');
    final String verb =
        getTranslated('shared_post_from', context) ?? 'shared a post from';
    return '$owner $verb $original';
  }

  void _sortComments() {
    int comparison(SocialComment a, SocialComment b) {
      final DateTime? aTime = a.createdAt;
      final DateTime? bTime = b.createdAt;
      if (aTime != null && bTime != null) {
        final cmp = aTime.compareTo(bTime);
        if (cmp != 0) return cmp;
      } else if (aTime != null) {
        return -1;
      } else if (bTime != null) {
        return 1;
      }
      final int aId = int.tryParse(a.id) ?? 0;
      final int bId = int.tryParse(b.id) ?? 0;
      return aId.compareTo(bId);
    }

    final multiplier = _sortOrder == CommentSortOrder.newest ? -1 : 1;
    _comments.sort((a, b) => multiplier * comparison(a, b));
  }

  String _sortOrderLabel(BuildContext context, CommentSortOrder order) {
    switch (order) {
      case CommentSortOrder.newest:
        return getTranslated('latest', context) ?? 'Latest';
      case CommentSortOrder.oldest:
        return getTranslated('oldest', context) ?? 'Oldest';
    }
  }

  Future<void> _handleImageAttachment() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(getTranslated('pick_from_gallery', sheetCtx) ??
                  'Pick from gallery'),
              onTap: () => Navigator.of(sheetCtx).pop('photo'),
            ),
            ListTile(
              leading: const Icon(Icons.gif_box_outlined),
              title: Text(getTranslated('pick_gif_from_file', sheetCtx) ??
                  'Pick GIF from file'),
              onTap: () => Navigator.of(sheetCtx).pop('gif'),
            ),
            ListTile(
              leading: const Icon(Icons.link_outlined),
              title: Text(
                  getTranslated('paste_gif_url', sheetCtx) ?? 'Paste GIF URL'),
              onTap: () => Navigator.of(sheetCtx).pop('url'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'photo') {
      final img = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (!mounted || img == null) return;
      setState(() {
        _commentImagePath = img.path;
        _commentImageUrl = null;
      });
      return;
    }
    if (choice == 'gif') {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gif', 'webp', 'GIF', 'WEBP'],
      );
      if (!mounted || res == null || res.files.isEmpty) return;
      final file = res.files.first;
      if (file.path == null) return;
      setState(() {
        _commentImagePath = file.path;
        _commentImageUrl = null;
      });
      return;
    }
    if (choice == 'url') {
      final url = await _askGifUrl();
      if (!mounted || url == null || url.isEmpty) return;
      setState(() {
        _commentImageUrl = url;
        _commentImagePath = null;
      });
    }
  }

  Future<String?> _askGifUrl() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(getTranslated('enter_gif_url', ctx) ?? 'Enter GIF URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...gif'),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(getTranslated('cancel', ctx) ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(getTranslated('choose', ctx) ?? 'Choose'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final Color appBarColor = cs.surface;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 68, // 64–72 cho thoáng 2 dòng
        titleSpacing: 12,
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: FutureBuilder<SocialPost?>(
          future: _postFuture,
          builder: (ctx, snap) {
            final basePost = snap.data ?? p;
            final ctrl = ctx.watch<SocialController>();
            final SocialPost current =
                ctrl.findPostById(basePost.id) ?? basePost;
            final SocialPost displayPost = current.sharedPost != null
                ? current
                : (p.sharedPost != null ? p : current);
            final onSurface = Theme.of(ctx).colorScheme.onSurface;

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (displayPost.userAvatar != null &&
                          displayPost.userAvatar!.isNotEmpty)
                      ? NetworkImage(displayPost.userAvatar!)
                      : null,
                  child: (displayPost.userAvatar == null ||
                          displayPost.userAvatar!.isEmpty)
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayPost.userName ??
                            (getTranslated('user', ctx) ?? 'User'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if ((displayPost.timeText ?? '').isNotEmpty)
                        Text(
                          displayPost.timeText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: onSurface.withOpacity(.6),
                              ),
                        ),
                      if (displayPost.sharedPost != null)
                        Text(
                          _sharedSubtitleText(ctx, displayPost),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: onSurface.withOpacity(.75),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
                            final Color onSurface =
                                Theme.of(context).colorScheme.onSurface;
                            final SocialPost current =
                                ctrl.findPostById(post.id) ?? post;
                            final SocialPost displayPost =
                                current.sharedPost != null
                                    ? current
                                    : (p.sharedPost != null ? p : current);
                            final SocialPost? sharedPost =
                                displayPost.sharedPost ?? p.sharedPost;
                            final String? postText =
                                (current.text?.isNotEmpty ?? false)
                                    ? current.text
                                    : p.text;
                            final List<dynamic>? pollOptions =
                                (current.pollOptions?.isNotEmpty ?? false)
                                    ? current.pollOptions
                                    : p.pollOptions;
                            final bool hasPoll =
                                pollOptions != null && pollOptions.isNotEmpty;
                            final Widget? mediaContent = sharedPost != null
                                ? SharedPostPreviewCard(
                                    post: sharedPost!,
                                    compact: true,
                                    padding: const EdgeInsets.all(10),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SocialPostDetailScreen(
                                                  post: sharedPost!),
                                        ),
                                      );
                                    },
                                  )
                                : ((displayPost.videoUrl ?? '').isNotEmpty ||
                                        (displayPost.audioUrl ?? '')
                                            .isNotEmpty ||
                                        displayPost.imageUrls.isNotEmpty)
                                    ? _DetailMedia(post: displayPost)
                                    : null;
                            final myReaction = current.myReaction;
                            final bool isSharing = ctrl.isSharing(current.id);
                            final List<String> topReactions =
                                _topReactionLabels(current);
                            final int commentCount = current.commentCount;
                            final int shareCount = current.shareCount;
                            final int reactionCount = current.reactionCount;
                            final bool showReactions = reactionCount > 0;
                            final bool showComments = commentCount > 0;
                            final bool showShares = shareCount > 0;
                            final bool showStats =
                                showReactions || showComments || showShares;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((postText ?? '').isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Html(
                                      data: postText!,
                                      style: {
                                        'body': Style(
                                          color: onSurface,
                                          fontSize: FontSize(15),
                                          lineHeight: LineHeight(1.35),
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                        ),
                                      },
                                      onLinkTap: (url, _, __) async {
                                        if (url != null) {
                                          final uri = Uri.parse(url);
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (hasPoll) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (final opt in pollOptions!) ...[
                                          Text(opt['text']?.toString() ?? ''),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: (((double.tryParse(
                                                            (opt['percentage_num'] ??
                                                                    '0')
                                                                .toString()) ??
                                                        0.0) /
                                                    100.0))
                                                .clamp(0, 1),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (mediaContent != null) ...[
                                  mediaContent,
                                  const SizedBox(height: 12),
                                ],
                                if (displayPost.hasProduct)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _ProductBlock(
                                      title: displayPost.productTitle,
                                      images:
                                          displayPost.productImages ?? const [],
                                      price: displayPost.productPrice,
                                      currency: displayPost.productCurrency,
                                      description:
                                          displayPost.productDescription,
                                      productId: displayPost.ecommerceProductId,
                                      slug: displayPost.productSlug,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Builder(
                                          builder: (itemCtx) => InkWell(
                                            onTap: () {
                                              final was = myReaction;
                                              final now =
                                                  (was == 'Like') ? '' : 'Like';
                                              itemCtx
                                                  .read<SocialController>()
                                                  .reactOnPost(current, now);
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
                                                  itemCtx
                                                      .read<SocialController>()
                                                      .reactOnPost(
                                                          current, val);
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
                                                    _reactionActionLabel(
                                                        context, myReaction),
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
                                        label:
                                            getTranslated('comment', context) ??
                                                'Comment',
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
                                      _PostAction(
                                        icon: Icons.share_outlined,
                                        label:
                                            getTranslated('share', context) ??
                                                'Share',
                                        loading: isSharing,
                                        onTap: isSharing
                                            ? null
                                            : () => _handleSharePost(current),
                                      ),
                                    ],
                                  ),
                                ),
                                if (showStats)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        if (showReactions)
                                          Expanded(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (topReactions.isNotEmpty)
                                                  _ReactionIconStack(
                                                      labels: topReactions),
                                                if (topReactions.isNotEmpty)
                                                  const SizedBox(width: 6),
                                                Text(
                                                  _formatSocialCount(
                                                      reactionCount),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: onSurface
                                                            .withOpacity(.85),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          const Expanded(
                                              child: SizedBox.shrink()),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Wrap(
                                              spacing: 12,
                                              children: [
                                                // if (showComments)
                                                //   Text(
                                                //     '${_formatSocialCount(commentCount)} ${getTranslated("comments", context) ?? "comments"}',
                                                //     style: Theme.of(context)
                                                //         .textTheme
                                                //         .bodySmall
                                                //         ?.copyWith(
                                                //           color: onSurface
                                                //               .withOpacity(.7),
                                                //         ),
                                                //     overflow:
                                                //         TextOverflow.ellipsis,
                                                //   ),
                                                if (showShares)
                                                  Text(
                                                    '${_formatSocialCount(shareCount)} ${getTranslated("share_plural", context) ?? "shares"}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: onSurface
                                                              .withOpacity(.7),
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
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
                        Row(
                          children: [
                            PopupMenuButton<CommentSortOrder>(
                              tooltip: getTranslated('arrange', context) ??
                                  'Arrange',
                              onSelected: (value) {
                                if (_sortOrder != value) {
                                  setState(() {
                                    _sortOrder = value;
                                    _sortComments();
                                  });
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: CommentSortOrder.newest,
                                  child: Text(
                                      getTranslated('latest', context) ??
                                          'Latest'),
                                ),
                                PopupMenuItem(
                                  value: CommentSortOrder.oldest,
                                  child: Text(
                                      getTranslated('oldest', context) ??
                                          'Oldest'),
                                ),
                              ],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_sortOrderLabel(context, _sortOrder)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.sort, size: 18),
                                ],
                              ),
                            ),
                          ],
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
                                getTranslated('no_comments_yet', context) ??
                                    'No comments yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: onSurface.withOpacity(.7),
                                    ),
                              );
                            }
                            final svc = sl<SocialServiceInterface>();
                            final replyActionStyle = Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: onSurface.withOpacity(.6));
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
                                                          (getTranslated('user',
                                                                  context) ??
                                                              'User'),
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
                                                          context, c.timeText),
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
                                                  child: _CommentImagePreview(
                                                      url: c.imageUrl!),
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
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6),
                                                child: Row(
                                                  children: [
                                                    // TRÁI: Reply + số lượng reaction
                                                    Expanded(
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                _replyingTo = c;
                                                                _showInput =
                                                                    true;
                                                                _commentImagePath =
                                                                    null;
                                                                _commentImageUrl =
                                                                    null;
                                                                _commentAudioPath =
                                                                    null;
                                                              });
                                                              FocusScope.of(
                                                                      context)
                                                                  .requestFocus(
                                                                      _commentFocus);
                                                            },
                                                            child: Text(
                                                              getTranslated(
                                                                      'reply',
                                                                      context) ??
                                                                  'Reply',
                                                              style:
                                                                  replyActionStyle,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),

                                                          // 👉 ICON LIKE CỐ ĐỊNH + SỐ LƯỢNG
                                                          if (c.reactionCount >
                                                              0) ...[
                                                            const SizedBox(
                                                                width: 12),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                _reactionIcon(
                                                                    'Like',
                                                                    size: 18),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  _formatSocialCount(
                                                                      c.reactionCount),
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.copyWith(
                                                                        color: onSurface
                                                                            .withOpacity(.6),
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                    // PHẢI: nút Reaction (icon + nhãn), tap/long-press như cũ
                                                    Builder(
                                                      builder: (reactCtx) {
                                                        final reacted = c
                                                            .myReaction
                                                            .isNotEmpty;
                                                        final style =
                                                            Theme.of(context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: reacted
                                                                      ? Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .primary
                                                                      : onSurface
                                                                          .withOpacity(
                                                                              .6),
                                                                  fontWeight: reacted
                                                                      ? FontWeight
                                                                          .w600
                                                                      : null,
                                                                );

                                                        return GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap: () {
                                                            final next =
                                                                c.myReaction ==
                                                                        'Like'
                                                                    ? ''
                                                                    : 'Like';
                                                            _reactOnComment(
                                                                c, next);
                                                          },
                                                          onLongPress: () {
                                                            final overlay =
                                                                Overlay.of(
                                                                    reactCtx);
                                                            if (overlay == null)
                                                              return;
                                                            final overlayBox =
                                                                overlay.context
                                                                        .findRenderObject()
                                                                    as RenderBox;
                                                            final box = reactCtx
                                                                    .findRenderObject()
                                                                as RenderBox?;
                                                            final Offset centerGlobal = box !=
                                                                    null
                                                                ? box.localToGlobal(
                                                                    box.size.center(
                                                                        Offset
                                                                            .zero),
                                                                    ancestor:
                                                                        overlayBox)
                                                                : overlayBox
                                                                    .size
                                                                    .center(Offset
                                                                        .zero);

                                                            _showReactionsOverlay(
                                                              reactCtx,
                                                              centerGlobal,
                                                              onSelect: (val) =>
                                                                  _reactOnComment(
                                                                      c, val),
                                                            );
                                                          },
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              _reactionIcon(
                                                                  c.myReaction,
                                                                  size: 18),
                                                              const SizedBox(
                                                                  width: 6),
                                                              // Text(
                                                              //   // nhãn của nút reaction (giống postcard)
                                                              //   c.myReaction
                                                              //           .isNotEmpty
                                                              //       ? c
                                                              //           .myReaction
                                                              //       : (getTranslated(
                                                              //               'like',
                                                              //               context) ??
                                                              //           'Like'),
                                                              //   style: style,
                                                              // ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              _RepliesLazy(
                                                comment: c,
                                                service: svc,
                                                onRequestReply: (target) {
                                                  setState(() {
                                                    _replyingTo = target;
                                                    _showInput = true;
                                                    _commentImagePath = null;
                                                    _commentImageUrl = null;
                                                    _commentAudioPath = null;
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
                                      child: Text(
                                        getTranslated('load_more_comments',
                                                context) ??
                                            'Load more comments',
                                      ),
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
          // ==== input bình luận ====
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
                                    '${getTranslated('reply', context) ?? 'Reply'} '
                                    '"${_replyingTo!.userName ?? (getTranslated('user', context) ?? 'User')}"',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _replyingTo = null),
                                  child: Text(
                                      getTranslated('cancel', context) ??
                                          'Cancel'),
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
                                decoration: InputDecoration(
                                  hintText:
                                      getTranslated('enter_comment', context) ??
                                          'Enter comment',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip:
                                  getTranslated('image', context) ?? 'Image',
                              onPressed: _handleImageAttachment,
                              icon: const Icon(Icons.image_outlined),
                            ),
                            IconButton(
                              tooltip:
                                  getTranslated('audio', context) ?? 'Audio',
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
                              tooltip:
                                  getTranslated('submit', context) ?? 'Submit',
                              onPressed: _sendingComment
                                  ? null
                                  : () async {
                                      final txt =
                                          _commentController.text.trim();
                                      if (txt.isEmpty &&
                                          _commentImagePath == null &&
                                          _commentImageUrl == null &&
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
                                            imageUrl: _commentImageUrl,
                                          );
                                        } else {
                                          await svc.createReply(
                                            commentId: _replyingTo!.id,
                                            text: txt,
                                            imagePath: _commentImagePath,
                                            audioPath: _commentAudioPath,
                                            imageUrl: _commentImageUrl,
                                          );
                                        }
                                        _commentController.clear();
                                        setState(() {
                                          _commentImagePath = null;
                                          _commentImageUrl = null;
                                          _commentAudioPath = null;
                                          _replyingTo = null;
                                        });
                                        await _refreshAll();
                                      } catch (e) {
                                        showCustomSnackBar(
                                            e.toString(), context,
                                            isError: true);
                                      } finally {
                                        if (mounted) {
                                          setState(
                                              () => _sendingComment = false);
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.send),
                            ),
                            IconButton(
                              tooltip:
                                  getTranslated('cancel', context) ?? 'Cancel',
                              onPressed: () =>
                                  setState(() => _showInput = false),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        if (_commentImagePath != null ||
                            _commentImageUrl != null ||
                            _commentAudioPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (_commentImagePath != null)
                                  InputChip(
                                    label: Text(
                                      '${getTranslated('file', context) ?? 'File'}: ${_basename(_commentImagePath!)}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onDeleted: () => setState(
                                        () => _commentImagePath = null),
                                  ),
                                if (_commentImageUrl != null)
                                  InputChip(
                                    label: Text(
                                      '${getTranslated('gif_url', context) ?? 'GIF URL'}: ${_commentImageUrl!}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onDeleted: () =>
                                        setState(() => _commentImageUrl = null),
                                  ),
                                if (_commentAudioPath != null)
                                  InputChip(
                                    label: Text(
                                      '${getTranslated('audio', context) ?? 'Audio'}: ${_basename(_commentAudioPath!)}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                        label: Text(getTranslated('write_comment', context) ??
                            'Write a comment'),
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
  final bool loading;
  const _PostAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.loading = false,
  });
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bool enabled = onTap != null && !loading;
    final Color iconColor = onSurface.withOpacity(enabled ? .8 : .4);
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(iconColor),
                  ),
                )
              else
                Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: iconColor),
              ),
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
            url: post.audioUrl!,
            autoplay: true,
            title: post.fileName,
          ),
        ],
      );
    }
    if ((post.audioUrl ?? '').isNotEmpty) {
      return _AudioPlayerBox(
        url: post.audioUrl!,
        autoplay: false,
        title: post.fileName,
      );
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
  final String? description;
  final int? productId;
  final String? slug;
  const _ProductBlock({
    this.title,
    required this.images,
    this.price,
    this.currency,
    this.description,
    this.productId,
    this.slug,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final String? priceText = _formatPrice(context);
    final String descriptionText = _plainText(description);
    final bool canNavigate = productId != null && productId! > 0;

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
                if (priceText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    priceText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                if (descriptionText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    descriptionText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onSurface.withOpacity(.8),
                        ),
                  ),
                ],
                if (canNavigate) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          _openProduct(context, _sanitizeSlug(slug)),
                      child: Text(getTranslated('view_detail', context) ??
                          'View detail'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProduct(
    BuildContext context,
    String? initialSlug,
  ) async {
    if (productId == null || productId! <= 0) {
      showCustomSnackBar(
          getTranslated('product_not_found', context) ?? 'Product unavailable',
          context);
      return;
    }
    String? slugValue = initialSlug;
    final controller = context.read<ProductDetailsController>();
    slugValue ??=
        await controller.resolveSlugByProductId(productId!, silent: true);
    if (!context.mounted) return;
    if (slugValue == null) {
      showCustomSnackBar(
          getTranslated('product_not_found', context) ?? 'Product unavailable',
          context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetails(
          productId: productId,
          slug: slugValue,
        ),
      ),
    );
  }

  String? _formatPrice(BuildContext context) {
    if (price == null) return null;
    if (currency != null && currency!.isNotEmpty) {
      return '${price!.toStringAsFixed(2)} $currency';
    }
    return PriceConverter.convertPrice(context, price!);
  }

  String _plainText(String? source) {
    if (source == null || source.trim().isEmpty) return '';
    final withoutTags = source.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final decoded = withoutTags.replaceAll('&nbsp;', ' ');
    return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _sanitizeSlug(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;
    return trimmed;
  }
}

String _sharedSubtitleText(BuildContext context, SocialPost parent) {
  final SocialPost? shared = parent.sharedPost;
  if (shared == null) return '';
  final String original =
      shared.userName ?? (getTranslated('user', context) ?? 'User');
  final String verb =
      getTranslated('shared_post_from', context) ?? 'shared a post from';
  return '$verb $original';
}

List<String> _topReactionLabels(SocialPost post, {int limit = 3}) {
  final entries = post.reactionBreakdown.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (entries.isEmpty) {
    if (post.reactionCount > 0 || post.myReaction.isNotEmpty) {
      return <String>[
        post.myReaction.isNotEmpty ? post.myReaction : 'Like',
      ];
    }
    return const <String>[];
  }
  return entries.take(limit).map((e) => e.key).toList();
}

String _reactionActionLabel(BuildContext context, String reaction) {
  final String defaultLabel = getTranslated('like', context) ?? 'Like';
  if (reaction.isEmpty || reaction == 'Like') return defaultLabel;
  switch (reaction) {
    case 'Love':
      return getTranslated('love', context) ?? 'Love';
    case 'HaHa':
      return 'HaHa';
    case 'Wow':
      return 'Wow';
    case 'Sad':
      return getTranslated('sad', context) ?? 'Sad';
    case 'Angry':
      return getTranslated('angry', context) ?? 'Angry';
    default:
      return reaction;
  }
}

class _ReactionIconStack extends StatelessWidget {
  final List<String> labels;
  final double size;
  const _ReactionIconStack({
    required this.labels,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final double overlap = size * 0.67;
    final double width =
        size + (labels.length > 1 ? (labels.length - 1) * overlap : 0);
    final Color borderColor = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: size,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = labels.length - 1; i >= 0; i--)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: _reactionIcon(labels[i], size: size),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatSocialCount(int value) {
  if (value <= 0) return '0';
  if (value < 1000) return value.toString();
  const units = [
    _CountUnit(threshold: 1000000000, suffix: 'B'),
    _CountUnit(threshold: 1000000, suffix: 'M'),
    _CountUnit(threshold: 1000, suffix: 'K'),
  ];
  for (final unit in units) {
    if (value >= unit.threshold) {
      final double scaled = value / unit.threshold;
      final int precision = scaled >= 100 ? 0 : 1;
      final String formatted =
          _trimTrailingZeros(scaled.toStringAsFixed(precision));
      return '$formatted${unit.suffix}';
    }
  }
  return value.toString();
}

String _trimTrailingZeros(String input) {
  if (!input.contains('.')) return input;
  return input.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

class _CountUnit {
  final int threshold;
  final String suffix;
  const _CountUnit({required this.threshold, required this.suffix});
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
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        double targetHeight = width / aspect;
        double targetWidth = width;
        if (targetHeight > maxHeight) {
          targetHeight = maxHeight;
          targetWidth = targetHeight * aspect;
        }
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: targetWidth,
                  height: targetHeight,
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
      },
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
  final Set<String> _replyReactionLoading = <String>{};
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;

  void _sortReplies() {
    int comparison(SocialComment a, SocialComment b) {
      final DateTime? aTime = a.createdAt;
      final DateTime? bTime = b.createdAt;
      if (aTime != null && bTime != null) {
        final cmp = aTime.compareTo(bTime);
        if (cmp != 0) return -cmp;
      } else if (aTime != null) {
        return -1;
      } else if (bTime != null) {
        return 1;
      }
      final int aId = int.tryParse(a.id) ?? 0;
      final int bId = int.tryParse(b.id) ?? 0;
      return bId.compareTo(aId);
    }

    _replies = [..._replies]..sort(comparison);
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final list =
          await widget.service.getCommentReplies(commentId: widget.comment.id);
      setState(() {
        _replies = list;
        _expanded = true;
        _sortReplies();
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

  Future<void> _reactOnReply(SocialComment reply, String reaction) async {
    final idx = _replies.indexWhere((e) => e.id == reply.id);
    if (idx == -1) return;
    if (_replyReactionLoading.contains(reply.id)) return;
    final previous = _replies[idx];
    final was = previous.myReaction;
    final now = reaction;
    int delta = 0;
    if (was.isEmpty && now.isNotEmpty) {
      delta = 1;
    } else if (was.isNotEmpty && now.isEmpty) {
      delta = -1;
    }
    final optimistic = previous.copyWith(
      myReaction: now,
      reactionCount: (previous.reactionCount + delta).clamp(0, 1 << 31).toInt(),
    );
    setState(() {
      _replies = [
        ..._replies.sublist(0, idx),
        optimistic,
        ..._replies.sublist(idx + 1),
      ];
    });
    _replyReactionLoading.add(reply.id);
    try {
      await widget.service.reactToReply(
        replyId: reply.id,
        reaction: now,
      );
    } catch (e) {
      setState(() {
        _replies = [
          ..._replies.sublist(0, idx),
          previous,
          ..._replies.sublist(idx + 1),
        ];
      });
      showCustomSnackBar(e.toString(), context, isError: true);
    } finally {
      _replyReactionLoading.remove(reply.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final replyActionStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: onSurface.withOpacity(.6));
    if (!_expanded) {
      final repliesCount = widget.comment.repliesCount ?? 0;
      if (repliesCount == 0) {
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _load,
          child: Text(
            '${getTranslated('view_replies', context) ?? 'View replies'} ($repliesCount)',
            style: replyActionStyle,
          ),
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
                              r.userName ??
                                  (getTranslated('user', context) ?? 'User'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if ((r.timeText ?? '').isNotEmpty)
                            Text(
                              _formatTimeText(context, r.timeText),
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
                          child: _CommentImagePreview(url: r.imageUrl!),
                        ),
                      if ((r.audioUrl ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _AudioPlayerBox(
                              url: r.audioUrl!, autoplay: false),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            // TRÁI: nút Reply + (icon Like cố định + reactionCount)
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        widget.onRequestReply(widget.comment),
                                    // Nếu muốn reply trực tiếp vào reply hiện tại:
                                    // onPressed: () => widget.onRequestReply(r),
                                    child: Text(
                                      getTranslated('reply', context) ??
                                          'Reply',
                                      style: replyActionStyle,
                                    ),
                                  ),

                                  // Chỉ chèn khoảng cách & cụm (👍 + count) khi count > 0
                                  if (r.reactionCount > 0) ...[
                                    const SizedBox(width: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _reactionIcon('Like', size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatSocialCount(r.reactionCount),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    onSurface.withOpacity(.6),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // PHẢI: nút Reaction (icon theo myReaction + NHÃN), tap/long-press
                            Builder(
                              builder: (reactCtx) {
                                final reacted = r.myReaction.isNotEmpty;
                                final style = Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: reacted
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : onSurface.withOpacity(.6),
                                      fontWeight:
                                          reacted ? FontWeight.w600 : null,
                                    );

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final next =
                                        r.myReaction == 'Like' ? '' : 'Like';
                                    _reactOnReply(r, next);
                                  },
                                  onLongPress: () {
                                    final overlay = Overlay.of(reactCtx);
                                    if (overlay == null) return;
                                    final overlayBox = overlay.context
                                        .findRenderObject() as RenderBox;
                                    final box = reactCtx.findRenderObject()
                                        as RenderBox?;
                                    final Offset centerGlobal = box != null
                                        ? box.localToGlobal(
                                            box.size.center(Offset.zero),
                                            ancestor: overlayBox,
                                          )
                                        : overlayBox.size.center(Offset.zero);

                                    _showReactionsOverlay(
                                      reactCtx,
                                      centerGlobal,
                                      onSelect: (val) => _reactOnReply(r, val),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _reactionIcon(r.myReaction, size: 18),
                                      const SizedBox(width: 6),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => setState(() => _expanded = false),
                child: Text(
                    getTranslated('collapse_replies', context) ??
                        'Collapse replies',
                    style: replyActionStyle),
              ),
              // TextButton(
              //   onPressed: () => widget.onRequestReply(widget.comment),
              //   child: Text(getTranslated('reply', context) ?? 'Reply',
              //       style: replyActionStyle),
              // ),
            ],
          ),
        ),
        // form reply inline (đang tắt)
        if (false)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: getTranslated('write_reply', context) ??
                        'Write a reply...',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: getTranslated('send', context) ?? 'Send',
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

class _CommentImagePreview extends StatelessWidget {
  final String url;
  const _CommentImagePreview({required this.url});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageViewer(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 140,
          width: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.open_in_full,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showImageViewer(BuildContext context, String url) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: getTranslated('close', context) ?? 'Close',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Center(
                  child: InteractiveViewer(
                      child: CachedNetworkImage(imageUrl: url))),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxHeight = MediaQuery.of(context).size.height * 0.6;
        double targetHeight = width / ar;
        double targetWidth = width;
        if (targetHeight > maxHeight) {
          targetHeight = maxHeight;
          targetWidth = targetHeight * ar;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: targetWidth,
                height: targetHeight,
                child: VideoPlayer(_controller),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(_controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
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
                          (posMs.clamp(0, totalMs <= 0 ? 1 : totalMs))
                              .toDouble();
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
      },
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

String _basename(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  return parts.isNotEmpty ? parts.last : path;
}

String _formatTimeText(BuildContext context, String? raw) {
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

  if (diff.inSeconds < 60) {
    return '${diff.inSeconds} ${getTranslated('seconds_ago', context) ?? 'seconds ago'}';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} ${getTranslated('minutes_ago', context) ?? 'minutes ago'}';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} ${getTranslated('hours_ago', context) ?? 'hours ago'}';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} ${getTranslated('days_ago', context) ?? 'days ago'}';
  }
  if (diff.inDays < 30) {
    return '${(diff.inDays / 7).floor()} ${getTranslated('weeks_ago', context) ?? 'weeks ago'}';
  }
  if (diff.inDays < 365) {
    return '${(diff.inDays / 30).floor()} ${getTranslated('months_ago', context) ?? 'months ago'}';
  }
  return '${(diff.inDays / 365).floor()} ${getTranslated('years_ago', context) ?? 'years ago'}';
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
