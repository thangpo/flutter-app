import 'dart:async';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/search_chat_result.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/group_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/chat_search_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_page_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/chat_preview_helper.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class SearchChatScreen extends StatefulWidget {
  final String accessToken;
  const SearchChatScreen({super.key, required this.accessToken});

  @override
  State<SearchChatScreen> createState() => SearchChatScreenState();
}

class SearchChatScreenState extends State<SearchChatScreen>  with SingleTickerProviderStateMixin{
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  late final TabController _tabController;
  bool _loading = false;
  String? _error;
  SearchChatResult _result = const SearchChatResult();

  final SocialChatRepository _chatRepo = SocialChatRepository();
  final GroupChatRepository _groupRepo = GroupChatRepository();

  final Map<String, String> _friendPreviewCache = {};
  final Map<String, int> _friendTimeCache = {};

  final Map<String, String> _groupPreviewCache = {};
  final Map<String, int> _groupTimeCache = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      FocusScope.of(context).unfocus();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void focusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _result = const SearchChatResult();
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ChatSearchService.search(
        accessToken: widget.accessToken,
        text: query,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _result = const SearchChatResult();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int? _normalizedTs(int? ts) {
    if (ts == null || ts <= 0) return null;
    if (ts > 2000000000) return ts ~/ 1000;
    return ts;
  }

  String _formatTime(int? ts) {
    final norm = _normalizedTs(ts);
    if (norm == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(norm * 1000);
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    String two(int n) => n.toString().padLeft(2, '0');
    if (sameDay) return '${two(dt.hour)}:${two(dt.minute)}';
    final diff = now.difference(dt);
    if (diff.inDays < 7) return '${diff.inDays}d';
    final sameYear = dt.year == now.year;
    return '${two(dt.day)}/${two(dt.month)}${sameYear ? '' : '/${dt.year}'}';
  }

  Map<String, SocialStory> _storyByUserId(List<SocialStory> stories) {
    final Map<String, SocialStory> map = {};
    for (final s in stories) {
      final uid = s.userId;
      if (uid != null && uid.isNotEmpty && s.items.isNotEmpty) {
        map[uid] = s;
      }
    }
    return map;
  }

  Future<void> _ensureFriendLatest(SocialFriend u) async {
    if (_friendPreviewCache.containsKey(u.id)) return;
    _friendPreviewCache[u.id] = '';
    try {
      final msgs = await _chatRepo.getUserMessages(
        token: widget.accessToken,
        peerUserId: u.id,
        limit: 1,
      );
      if (msgs.isNotEmpty) {
        final m = msgs.last;
        String text = (m['display_text'] ?? '').toString().trim();
        if (text.isEmpty) {
          text = pickWoWonderText(m);
        }
        int? ts;
        final rawTime = m['time'] ?? m['time_text'] ?? m['timestamp'] ?? m['created_at'];
        if (rawTime is num) ts = rawTime.toInt();
        if (rawTime is String) ts = int.tryParse(rawTime);
        if (!mounted) return;
        setState(() {
          _friendPreviewCache[u.id] = text;
          if (ts != null) {
            _friendTimeCache[u.id] = ts;
          }
        });
      }
    } catch (_) {}
  }

  String _friendPreview(SocialFriend u, BuildContext context) {
    final cached = _friendPreviewCache[u.id] ?? '';
    final raw = cached.isNotEmpty
        ? cached
        : (u.lastMessageText ?? '').trim();
    return normalizeChatPreview(raw, context);
  }

  String _friendTimeLabel(SocialFriend u) {
    final ts = _normalizedTs(_friendTimeCache[u.id]) ?? _normalizedTs(u.lastMessageTime);
    if (ts != null) {
      return _formatTime(ts);
    }
    final ls = (u.lastSeen ?? '').trim();
    return ls;
  }

  Future<void> _openChat(SocialFriend u) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          accessToken: widget.accessToken,
          peerUserId: u.id.toString(),
          peerName: u.name.isNotEmpty
              ? u.name
              : '${getTranslated('search_chat_user_prefix', context) ?? 'User #'}${u.id}',
          peerAvatar: u.avatar,
        ),
      ),
    );
  }

  Future<void> _ensureGroupPreview(ChatGroupHit g) async {
    final gid = g.groupId;
    if (gid.isEmpty) return;
    if (_groupPreviewCache.containsKey(gid)) return;
    _groupPreviewCache[gid] = '';
    try {
      final msgs = await _groupRepo.fetchMessages(gid, limit: 1);
      if (msgs.isNotEmpty) {
        final m = msgs.last;
        String txt = (m['display_text'] ?? '').toString().trim();
        if (txt.isEmpty) {
          txt = pickWoWonderText(m);
        }
        int? ts;
        final rawTime = m['time'] ?? m['time_text'] ?? m['timestamp'];
        if (rawTime is num) ts = rawTime.toInt();
        if (rawTime is String) ts = int.tryParse(rawTime);
        if (!mounted) return;
        setState(() {
          _groupPreviewCache[gid] = txt;
          if (ts != null) _groupTimeCache[gid] = ts;
        });
      }
    } catch (_) {}
  }

  String _groupPreview(Map<String, dynamic> g, BuildContext context) {
    final gid = (g['group_id'] ?? g['id'] ?? '').toString();
    final cached = _groupPreviewCache[gid] ?? '';
    if (cached.isNotEmpty) return normalizeChatPreview(cached, context);

    final sender = (g['last_sender_name'] ?? g['last_sender'] ?? '').toString();
    final lm = g['last_message'];
    Map<String, dynamic>? lastMap;
    if (lm is Map<String, dynamic>) {
      lastMap = Map<String, dynamic>.from(lm);
    } else if (lm is Map) {
      lastMap = Map<String, dynamic>.from(lm);
    }

    if (lastMap != null) {
      String txt = (lastMap['display_text'] ?? '').toString().trim();
      if (txt.isEmpty) {
        txt = (lastMap['text'] ?? lastMap['message'] ?? '').toString().trim();
      }
      if (txt.isEmpty) {
        txt = pickWoWonderText(lastMap);
      }
      if (txt.isNotEmpty) {
        final preview = sender.isNotEmpty ? '$sender: $txt' : txt;
        return normalizeChatPreview(preview, context);
      }
    }

    final raw = g['last_message_text'] ?? g['last_text'] ?? g['last_msg'];
    if (raw is String && raw.trim().isNotEmpty) {
      final txt = sender.isNotEmpty ? '$sender: ${raw.trim()}' : raw.trim();
      return normalizeChatPreview(txt, context);
    }

    final type = (g['last_message_type'] ?? g['type_two'] ?? '').toString();
    if (type.isNotEmpty) {
      final tag = '[$type]';
      return sender.isNotEmpty ? '$sender: $tag' : tag;
    }

    return getTranslated('no_messages_yet', context) ?? 'Bat dau doan chat';
  }

  String _groupTime(ChatGroupHit g) {
    final gid = g.groupId;
    final cached = _groupTimeCache[gid];
    if (cached != null) return _formatTime(cached);
    if (g.lastMessageTime != null) return _formatTime(g.lastMessageTime);
    final rawTime = g.raw['last_time'] ?? g.raw['time'];
    final parsed = rawTime is num ? rawTime.toInt() : int.tryParse('$rawTime');
    if (parsed != null && parsed > 0) return _formatTime(parsed);
    return '';
  }

  int _groupUnread(ChatGroupHit g) {
    if (g.unread != null) return g.unread!;
    final raw = g.raw['unread'] ?? g.raw['unread_count'] ?? g.raw['count_unread'];
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  void _openGroup(ChatGroupHit g) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatScreen(
          groupId: g.groupId,
          groupName: g.name,
        ),
      ),
    );
  }

  void _openPage(PageChatThread t) {
    final recipientId = t.isMyPage ? t.userId : t.ownerId;
    final chatTitle = t.isMyPage
        ? (t.peerName.isNotEmpty ? t.peerName : t.pageTitle)
        : t.pageTitle;
    final chatAvatar = t.isMyPage && t.peerAvatar.isNotEmpty ? t.peerAvatar : t.avatar;
    final subtitle = t.isMyPage ? '(${t.pageName})' : '@${t.pageName}';

    try {
      context.read<SocialPageController>().markPageThreadRead(
            t.pageId,
            peerId: recipientId,
          );
    } catch (_) {}

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PageChatScreen(
          pageId: int.tryParse(t.pageId) ?? 0,
          recipientId: recipientId,
          pageTitle: chatTitle,
          pageAvatar: chatAvatar,
          pageSubtitle: subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final socialCtrl = context.watch<SocialController>();
    final storyMap = _storyByUserId(socialCtrl.stories);

    final tabs = [
      getTranslated('search_tab_all', context) ?? 'All',
      getTranslated('search_tab_friends', context) ?? 'Friends',
      getTranslated('search_tab_pages', context) ?? 'Pages',
      getTranslated('search_tab_groups', context) ?? 'Groups',
    ];

    // ✅ màu cho tab bar tự theo theme
    final Color tabBackground = cs.surface;
    final Color tabSelected = cs.primary;
    final Color tabUnselected = cs.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    // ✅ màu cho search field trong AppBar
    final Color searchFill = Color.alphaBlend(
      cs.onSurface.withOpacity(isDark ? 0.12 : 0.05),
      cs.surface,
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: cs.surface, // ✅ auto light/dark
        appBar: AppBar(
          backgroundColor: cs.surface, // ✅ auto
          surfaceTintColor: Colors.transparent,
          foregroundColor: cs.onSurface, // ✅ icon + text auto
          titleSpacing: 0,
          toolbarHeight: kToolbarHeight + 12,
          title: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (v) {
                _onQueryChanged(v);
                setState(() {}); // để suffixIcon (nút x) cập nhật
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: getTranslated('search_chat_hint', context) ??
                    'Tìm bạn bè, nhóm, page',
                hintStyle: TextStyle(
                  color: cs.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: searchFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: cs.primary.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                suffixIcon: _controller.text.trim().isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close, color: cs.onSurface.withOpacity(0.55)),
                  onPressed: () {
                    _controller.clear();
                    _onQueryChanged('');
                    setState(() {});
                  },
                )
                    : null,
              ),
              style: TextStyle(color: cs.onSurface),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: _controller.text.trim().isEmpty
              ? Center(
            child: Text(
              getTranslated('search_chat_enter_keyword', context) ??
                  'Nhập từ khóa để tìm kiếm',
              style: TextStyle(color: cs.onSurface.withOpacity(0.75)),
            ),
          )
              : Column(
            children: [
              _androidPillTabBar(context, tabs),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(
                    tabs.length,
                        (index) => _buildTabContent(index, cs, storyMap),
                  ),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  Widget _androidPillTabBar(BuildContext context, List<String> tabs) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final unselected = cs.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedBuilder(
          animation: _tabController.animation!,
          builder: (context, _) {
            final page = _tabController.animation!.value;
            final dist = (page - page.round()).abs().clamp(0.0, 0.5);
            final progress = (dist / 0.5).clamp(0.0, 1.0);
            final radius = lerpDouble(12, 999, progress)!;

            return TabBar(
              controller: _tabController,
              isScrollable: false,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(radius),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: unselected,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent(
    int tabIndex,
    ColorScheme cs,
    Map<String, SocialStory> storyMap,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final bool showFriends = tabIndex == 0 || tabIndex == 1;
    final bool showPages = tabIndex == 0 || tabIndex == 2;
    final bool showGroups = tabIndex == 0 || tabIndex == 3;

    final friendsList = showFriends ? _result.friends : const <SocialFriend>[];
    final pagesList = showPages ? _result.pages : const <PageChatThread>[];
    final groupsList = showGroups ? _result.groups : const <ChatGroupHit>[];

    final hasResult =
        friendsList.isNotEmpty || groupsList.isNotEmpty || pagesList.isNotEmpty;

    if (_controller.text.trim().isEmpty) {
      return Center(
        child: Text(
          getTranslated('search_chat_enter_keyword', context) ??
              'Nhập từ khóa để tìm kiếm',
        ),
      );
    }

    if (!hasResult) {
      return Center(
        child: Text(
          getTranslated('no_results_found', context) ?? 'Không tìm thấy kết quả',
        ),
      );
    }

    return ListView(
      key: PageStorageKey('search_tab_$tabIndex'),
      children: [
        if (friendsList.isNotEmpty) ...[
          _SectionHeader(
            title: getTranslated('search_section_friends', context) ?? 'Bạn bè',
          ),
          ...friendsList.map((u) {
            final story = storyMap[u.id];
            final preview = _friendPreview(u, context);
            final timeLabel = _friendTimeLabel(u);
            final unread = u.hasUnread;
            _ensureFriendLatest(u);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (story != null && story.items.isNotEmpty) {
                        final stories = storyMap.values.toList();
                        final storyIndex = stories.indexOf(story);
                        final itemIndex =
                            story.items.indexWhere((e) => e.isViewed == false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SocialStoryViewerScreen(
                              stories: stories,
                              initialStoryIndex: storyIndex < 0 ? 0 : storyIndex,
                              initialItemIndex: itemIndex < 0 ? 0 : itemIndex,
                            ),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        StoryChatAvatar(
                          avatar: u.avatar,
                          label: u.name,
                          online: u.isOnline,
                          story: story,
                        ),
                        if (unread)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openChat(u),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                    color: cs.onSurface,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                              if (timeLabel.isNotEmpty)
                                Text(
                                  timeLabel,
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(.55),
                                    fontSize: 11.5,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            preview.isEmpty ? ' ' : preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread ? cs.onSurface : cs.onSurface.withOpacity(.6),
                              fontSize: 13,
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (groupsList.isNotEmpty) ...[
          _SectionHeader(
            title: getTranslated('search_section_groups', context) ?? 'Nhóm',
          ),
          ...groupsList.map((g) {
            _ensureGroupPreview(g);
            final preview = _groupPreview(g.raw, context);
            final time = _groupTime(g);
            final unread = _groupUnread(g);
            final avatar = g.avatar ?? '';

            return _GroupTile(
              cs: cs,
              avatarUrl: avatar,
              title: g.name,
              subtitle: preview,
              timeText: time,
              unread: unread,
              muted: (g.mute ?? const {})['notify'] == 'no',
              online: false,
              onTap: () => _openGroup(g),
            );
          }),
        ],
        if (pagesList.isNotEmpty) ...[
          _SectionHeader(
            title: getTranslated('search_section_pages', context) ?? 'Page',
          ),
          ...pagesList.cast<PageChatThread>().map((PageChatThread p) {
            final isOwner = p.isMyPage;
            final displayName = isOwner
                ? (p.peerName.isNotEmpty ? p.peerName : p.pageTitle)
                : p.pageTitle;
            final subtitle = isOwner ? '(${p.pageName})' : '@${p.pageName}';
            final avatarUrl = isOwner && p.peerAvatar.isNotEmpty ? p.peerAvatar : p.avatar;
            final fallback = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
            final unread = p.unreadCount > 0;

            return InkWell(
              onTap: () => _openPage(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Colors.transparent,
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                          backgroundColor: cs.surfaceVariant.withOpacity(.3),
                          child: avatarUrl.isEmpty
                              ? Text(
                                  fallback,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        if (isOwner)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight:
                                        unread ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                p.lastMessageTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.w400,
                              color: unread ? cs.onSurface : cs.onSurface.withOpacity(.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final ColorScheme cs;
  final String avatarUrl;
  final String title;
  final String subtitle;
  final String timeText;
  final int unread;
  final bool muted;
  final bool online;
  final VoidCallback onTap;

  const _GroupTile({
    required this.cs,
    required this.avatarUrl,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.unread,
    required this.muted,
    required this.online,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    final initial = title.isNotEmpty ? title.characters.first.toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          initial,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                            color: cs.onSurface,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(.5),
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle.isEmpty ? ' ' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread ? cs.onSurface : cs.onSurface.withOpacity(.7),
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryChatAvatar extends StatelessWidget {
  final String? avatar;
  final String label;
  final bool online;
  final SocialStory? story;

  const StoryChatAvatar({
    super.key,
    required this.avatar,
    required this.label,
    required this.online,
    this.story,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool hasStory = story != null && story!.items.isNotEmpty;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasStory
                ? const LinearGradient(
                    colors: [
                      Color(0xFF1877F2),
                      Color(0xFF9C27B0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      cs.surfaceVariant,
                      cs.surfaceVariant,
                    ],
                  ),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: cs.surfaceVariant,
            backgroundImage: (avatar != null && avatar!.isNotEmpty)
                ? NetworkImage(avatar!)
                : null,
            child: (avatar == null || avatar!.isEmpty)
                ? Text(
                    label.isNotEmpty ? label[0] : '?',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: online ? Colors.green : cs.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
