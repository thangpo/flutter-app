import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_friends_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_friends_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_mess.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_page_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';

// nhóm chat
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/chat_preview_helper.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/create_story_tile.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';



class FriendsListScreen extends StatefulWidget {
  final String accessToken;
  final bool showFooterNav;
  const FriendsListScreen(
      {super.key, required this.accessToken, this.showFooterNav = true});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final friendsCtrl = Get.put(SocialFriendsController(SocialFriendsRepository()));
  final _chatRepo = SocialChatRepository();
  final searchCtrl = TextEditingController();

  int _tabIndex = 0;
  int chatBadgeCount = 1;
  bool notifDot = true;
  Timer? _pollTimer;
  static final Map<String, int> _localLastActivity = {};
  final Map<String, String> _lastTextCache = {};
  static final Map<String, int> _localLastRead = {};
  final Map<String, int> _lastTimeCache = {};
  String _searchKeyword = '';
  final Map<String, String> _groupPreviewCache = {};
  final Map<String, int> _groupTimeCache = {};

  @override
  void initState() {
    super.initState();
    friendsCtrl.load(widget.accessToken, context: context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pageCtrl = context.read<SocialPageController>();
      if (!pageCtrl.loadingPageChatList && pageCtrl.pageChatList.isEmpty) {
        pageCtrl.loadPageChatList();
        pageCtrl.startPageChatListPolling();
      }

      final groupCtrl = context.read<GroupChatController>();
      if (!groupCtrl.groupsLoading && groupCtrl.groups.isEmpty) {
        groupCtrl.loadGroups();
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshLatestChats();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  int _getLastMessageTs(SocialFriend u) {
    final cached = _lastTimeCache[u.id];
    if (cached != null && cached > 0) {
      return _normalizedTimestamp(cached) ?? 0;
    }
    if (u.lastMessageTime != null && u.lastMessageTime! > 0) {
      return _normalizedTimestamp(u.lastMessageTime!) ?? 0;
    }
    return 0;
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

  bool _hasUnviewedStory(SocialStory s) {
    return s.items.any((e) => e.isViewed == false);
  }

  bool _isUnread(SocialFriend u) {
    final lastMsgTs = _getLastMessageTs(u);
    final lastReadTs = _localLastRead[u.id] ?? 0;
    return lastMsgTs > lastReadTs;
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      friendsCtrl.load(widget.accessToken, context: context),
      context.read<SocialPageController>().refreshPageChatList(),
      context.read<GroupChatController>().loadGroups(),
    ]);
  }

  int _compareByLastMessage(SocialFriend a, SocialFriend b) {
    final taLocal = _localLastActivity[a.id.toString()];
    final tbLocal = _localLastActivity[b.id.toString()];

    final ta = taLocal ?? a.lastMessageTime ?? 0;
    final tb = tbLocal ?? b.lastMessageTime ?? 0;

    if (ta == 0 && tb == 0) return 0;
    return tb.compareTo(ta);
  }

  int? _normalizedTimestamp(int? ts) {
    if (ts == null || ts <= 0) return null;
    if (ts > 2000000000) {
      return ts ~/ 1000;
    }
    return ts;
  }

  String _formatTimeLabel(SocialFriend u) {
    final ts = _normalizedTimestamp(_lastTimeCache[u.id] ?? u.lastMessageTime);
    if (ts != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      final now = DateTime.now();
      final diff = now.difference(dt);
      String two(int n) => n.toString().padLeft(2, '0');

      final sameDay =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      if (sameDay) {
        return '${two(dt.hour)}:${two(dt.minute)}';
      }
      if (diff.inDays < 7) {
        return '${diff.inDays}d';
      }
      final sameYear = dt.year == now.year;
      return '${two(dt.day)}/${two(dt.month)}${sameYear ? '' : '/${dt.year}'}';
    }

    final ls = (u.lastSeen ?? '').trim();
    return ls;
  }

  Future<void> _refreshLatestChats() async {
    final list = friendsCtrl.friends;

    for (final u in list) {
      try {
        final msgs = await _chatRepo.getUserMessages(
          token: widget.accessToken,
          peerUserId: u.id,
          limit: 1,
        );

        if (msgs.isEmpty) continue;

        final m = msgs.last;
        final tsRaw = m['time'] ?? m['timestamp'];
        final ts = tsRaw is num ? tsRaw.toInt() : int.tryParse('$tsRaw') ?? 0;
        final normalizedTs = _normalizedTimestamp(ts) ?? 0;
        final currentTs = _getLastMessageTs(u);

        if (normalizedTs > currentTs) {
          setState(() {
            _lastTimeCache[u.id] = ts;
            _lastTextCache[u.id] =
                (m['display_text'] ?? pickWoWonderText(m)).toString();
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _loadLatestIfMissing(SocialFriend u) async {
    if (_lastTextCache.containsKey(u.id)) return;
    _lastTextCache[u.id] = '';
    try {
      final msgs = await _chatRepo.getUserMessages(
        token: widget.accessToken,
        peerUserId: u.id.toString(),
        limit: 1,
      );
      if (msgs.isNotEmpty) {
        final m = msgs.last;
        String text = (m['display_text'] ?? '').toString().trim();
        if (text.isEmpty) {
          text = pickWoWonderText(m);
        }
        int? ts;
        final rawTime =
            m['time'] ?? m['time_text'] ?? m['timestamp'] ?? m['created_at'];
        if (rawTime is num) {
          ts = rawTime.toInt();
        } else if (rawTime is String) {
          ts = int.tryParse(rawTime);
        }
        if (!mounted) return;
        setState(() {
          _lastTextCache[u.id] = text;
          if (ts != null) {
            _lastTimeCache[u.id] = ts;
            _localLastActivity[u.id] = _normalizedTimestamp(ts) ?? ts;
          }
        });
      }
    } catch (_) {

    }
  }

  bool _matchesSearch(List<String> sources) {
    if (_searchKeyword.isEmpty) return true;
    return sources.any(
      (txt) => txt.toLowerCase().contains(_searchKeyword),
    );
  }

  int _pageTimestamp(PageChatThread t) {
    final raw = t.lastMessageTime.trim();
    if (raw.isEmpty) return 0;

    final numeric = int.tryParse(raw);
    if (numeric != null) {
      return _normalizedTimestamp(numeric) ?? numeric;
    }

    try {
      final dt = DateTime.parse(raw);
      return dt.millisecondsSinceEpoch ~/ 1000;
    } catch (_) {}

    final parts = raw.split(':');
    if (parts.length == 2) {
      final now = DateTime.now();
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return DateTime(now.year, now.month, now.day, h, m)
            .millisecondsSinceEpoch ~/
            1000;
      }
    }

    return 0;
  }

  String _pagePreview(PageChatThread t, BuildContext context) {
    String text = t.lastMessage.trim();
    if (text.isEmpty) {
      final type = t.lastMessageType.toLowerCase();
      switch (type) {
        case 'image':
          text = '[Image]';
          break;
        case 'video':
          text = '[Video]';
          break;
        case 'voice':
        case 'audio':
          text = '[Voice]';
          break;
        default:
          if (type.isNotEmpty) text = '[$type]';
      }
    }
    return normalizeChatPreview(text, context);
  }

  String _formatTimestampLabel(int ts) {
    if (ts <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);
    String two(int n) => n.toString().padLeft(2, '0');

    final sameDay =
    dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) {
      return '${two(dt.hour)}:${two(dt.minute)}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d';
    }
    final sameYear = dt.year == now.year;
    return '${two(dt.day)}/${two(dt.month)}${sameYear ? '' : '/${dt.year}'}';
  }

  int _groupUnread(Map<String, dynamic> g) {
    final raw = g['unread'] ?? g['unread_count'] ?? g['count_unread'] ?? 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  bool _groupOnline(Map<String, dynamic> g) {
    final v = g['is_online'] ?? g['online'] ?? g['active'];
    if (v is bool) return v;
    if (v == null) return false;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  int _groupLastTimestamp(Map<String, dynamic> g) {
    final gid = (g['group_id'] ?? g['id'] ?? '').toString();
    final cached = _groupTimeCache[gid];
    if (cached != null) return _normalizedTimestamp(cached) ?? cached;

    final fields = [
      g['last_time'],
      g['time'],
      g['last_message_time'],
      g['last_msg_time'],
    ];
    for (final f in fields) {
      final v = _asInt(f);
      final n = _normalizedTimestamp(v);
      if (n != null && n > 0) return n;
    }
    return 0;
  }

  String _groupPreview(Map<String, dynamic> g, BuildContext context) {
    final sender = (g['last_sender_name'] ?? g['last_sender'] ?? '').toString();

    final lm = g['last_message'];
    Map<String, dynamic>? lastMap;
    if (lm is Map<String, dynamic>) {
      lastMap = Map<String, dynamic>.from(lm);
    } else if (lm is List && lm.isNotEmpty && lm.first is Map) {
      lastMap = Map<String, dynamic>.from(lm.first as Map);
    }

    if (lastMap != null) {
      String txt = (lastMap['display_text'] ?? '').toString().trim();
      if (txt.isEmpty) {
        txt = (lastMap['text'] ??
            lastMap['message'] ??
            lastMap['textDecoded'] ??
            '')
            .toString()
            .trim();
      }
      if (txt.isEmpty) {
        txt = pickWoWonderText(lastMap);
      }
      if (txt.isNotEmpty) {
        final normalized = normalizeChatPreview(txt, context);
        return sender.isNotEmpty ? '$sender: $normalized' : normalized;
      }
    }

    final text = g['last_message_text'] ??
        g['last_text'] ??
        g['text'] ??
        g['last_message'] ??
        g['last_msg'] ??
        '';
    if (text is String && text.trim().isNotEmpty) {
      final t = normalizeChatPreview(text.replaceAll('\n', ' ').trim(), context);
      return sender.isNotEmpty ? '$sender: $t' : t;
    }

    final type = (g['last_message_type'] ?? g['type_two'] ?? '').toString();
    String tag = '';
    switch (type) {
      case 'image':
        tag = '[Image]';
        break;
      case 'video':
        tag = '[Video]';
        break;
      case 'voice':
      case 'audio':
        tag = '[Voice]';
        break;
      case 'file':
        tag = '[File]';
        break;
      default:
        if (type.isNotEmpty) tag = '[$type]';
    }
    if (tag.isNotEmpty) {
      return sender.isNotEmpty ? '$sender: $tag' : tag;
    }

    return getTranslated('no_messages_yet', context) ?? 'Bat dau doan chat';
  }

  Future<void> _ensureGroupPreview(
      Map<String, dynamic> g, GroupChatController ctrl) async {
    final groupId = (g['group_id'] ?? g['id'] ?? '').toString();
    if (groupId.isEmpty || _groupPreviewCache.containsKey(groupId)) return;
    _groupPreviewCache[groupId] = '';

    try {
      final msgs = await ctrl.repo.fetchMessages(groupId, limit: 1);
      if (msgs.isNotEmpty) {
        final m = msgs.last;
        String txt = (m['display_text'] ?? '').toString().trim();
        if (txt.isEmpty) {
          txt = pickWoWonderText(m);
        }
        int? ts;
        final rawTime = m['time'] ?? m['time_text'] ?? m['timestamp'];
        ts = _asInt(rawTime);

        if (!mounted) return;
        setState(() {
          _groupPreviewCache[groupId] = txt;
          if (ts != null) _groupTimeCache[groupId] = ts;
        });
      }
    } catch (_) {
      // ignore errors; keep fallback preview
    }
  }

  Color _badgeColorFor(_ChatEntryType type) {
    switch (type) {
      case _ChatEntryType.page:
        return Colors.blue;
      case _ChatEntryType.group:
        return Colors.deepPurple;
      case _ChatEntryType.friend:
        return Colors.blue;
    }
  }

  IconData _badgeIconFor(_ChatEntryType type) {
    switch (type) {
      case _ChatEntryType.page:
        return Icons.flag_outlined;
      case _ChatEntryType.group:
        return Icons.groups;
      case _ChatEntryType.friend:
        return Icons.chat_bubble;
    }
  }

  List<_ChatEntry> _buildEntries({
    required List<SocialFriend> friends,
    required Map<String, SocialStory> storyMap,
    required SocialPageController pageCtrl,
    required GroupChatController groupCtrl,
    required BuildContext context,
  }) {
    final entries = <_ChatEntry>[];

    for (final u in friends) {
      final bool unread = _isUnread(u);
      _loadLatestIfMissing(u);
      final cachedText = _lastTextCache[u.id] ?? '';
      final rawPreview =
      (cachedText.isNotEmpty ? cachedText : (u.lastMessageText ?? ''))
          .toString()
          .trim();

      final messagePreview = normalizeChatPreview(rawPreview, context);
      final statusFallback = u.isOnline
          ? getTranslated('active_now', context) ?? ''
          : (u.lastSeen ?? '').trim();
      final preview = messagePreview.isNotEmpty ? messagePreview : statusFallback;
      final rawTime = _formatTimeLabel(u).trim();
      final timeLabel = rawTime.isNotEmpty ? rawTime : ' ';
      final int ts = _getLastMessageTs(u);

      entries.add(
        _ChatEntry(
          type: _ChatEntryType.friend,
          id: 'user:${u.id}',
          title: u.name,
          subtitle: null,
          preview: preview,
          timeLabel: timeLabel,
          timestamp: ts,
          avatar: u.avatar,
          unread: unread,
          online: u.isOnline,
          badge: null,
          friend: u,
          story: storyMap[u.id],
          onTap: () => _openChat(u),
        ),
      );
    }

    for (final t in pageCtrl.pageChatList) {
      final chatTitle = t.isMyPage
          ? (t.peerName.isNotEmpty ? t.peerName : t.pageTitle)
          : t.pageTitle;
      final subtitle = t.isMyPage ? '(${t.pageName})' : '@${t.pageName}';
      if (!_matchesSearch([
        chatTitle,
        subtitle,
        t.pageTitle,
        t.pageName,
        t.peerName,
      ])) {
        continue;
      }

      final ts = _pageTimestamp(t);
      final timeLabel = _formatTimestampLabel(ts);
      final previewRaw = _pagePreview(t, context);

      entries.add(
        _ChatEntry(
          type: _ChatEntryType.page,
          id: 'page:${t.pageId}:${t.userId}',
          title: chatTitle,
          subtitle: subtitle,
          preview: previewRaw,
          timeLabel: timeLabel.isNotEmpty
              ? timeLabel
              : (t.lastMessageTime.isNotEmpty ? t.lastMessageTime : ' '),
          timestamp: ts,
          avatar: t.peerAvatar.isNotEmpty ? t.peerAvatar : t.avatar,
          unread: t.unreadCount > 0,
          online: false,
          badge: null,
          friend: null,
          story: null,
          onTap: () => _openPageThread(t),
        ),
      );
    }

    for (final g in groupCtrl.groups) {
      final gid = (g['group_id'] ?? g['id'] ?? '').toString();
      if (gid.isEmpty) {
        continue;
      }
      final groupName =
      (g['group_name'] ?? g['name'] ?? 'Không tên').toString();
      final avatar = (g['avatar'] ?? g['image'] ?? '').toString();
      final previewCached = _groupPreviewCache[gid] ?? '';
      final preview =
      previewCached.isNotEmpty ? previewCached : _groupPreview(g, context);
      final ts = _groupLastTimestamp(g);
      final timeLabel = _formatTimestampLabel(ts);

      if (!_matchesSearch([groupName, preview, gid])) {
        continue;
      }
      _ensureGroupPreview(g, groupCtrl);

      entries.add(
        _ChatEntry(
          type: _ChatEntryType.group,
          id: 'group:$gid',
          title: groupName,
          subtitle: '',
          preview: preview,
          timeLabel: timeLabel.isNotEmpty ? timeLabel : ' ',
          timestamp: ts,
          avatar: avatar,
          unread: _groupUnread(g) > 0,
          online: _groupOnline(g),
          badge: null,
          friend: null,
          story: null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  groupId: gid,
                  groupName: groupName,
                ),
              ),
            );
          },
        ),
      );
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final socialCtrl = context.watch<SocialController>();
    final Map<String, SocialStory> storyMap =
    _storyByUserId(socialCtrl.stories);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Images.logoWithNameImage,
              height: 35,
            ),
          ],
        ),
      ),
      floatingActionButton: null,

      /// ✅ Thanh tab bar dạng "floating capsule"
      bottomNavigationBar: widget.showFooterNav
          ? Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom:
                    8 + bottomInset, // chừa chỗ cho thanh điều hướng hệ thống
              ),
              child: _MessengerFooter(
                currentIndex: _tabIndex,
                chatBadgeCount: chatBadgeCount,
                showNotifDot: notifDot,
                onTap: (i) {
                  setState(() => _tabIndex = i);

                  if (i == 1) {
                    // 👈 Tab STORIES → mở màn Trang / Tin nhắn Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PageMessagesScreen(accessToken: widget.accessToken),
                      ),
                    );
                  } else if (i == 2) {
                    // Group chat như cũ
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DashboardChatScreen(
                          accessToken: widget.accessToken,
                          initialIndex: 2,
                        ),
                      ),
                    );
                  }
                },
              ),
            )
          : null,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) {
                _searchKeyword = v.trim().toLowerCase();
                friendsCtrl.search(v);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: getTranslated('search', context) ?? 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 106,
            child: Obx(() {
              final list = List<SocialFriend>.from(friendsCtrl.friends);
              list.sort(_compareByLastMessage);

              if (friendsCtrl.isLoading.value && list.isEmpty) {
                return const _AvatarStripSkeleton();
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: list.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return const CreateStoryTile(size: 56);
                  }

                  final u = list[i - 1];
                  final SocialStory? story = storyMap[u.id];

                  return StoryAvatarTile(
                    name: u.name,
                    avatar: u.avatar,
                    online: u.isOnline,
                    story: story,
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
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Obx(() {
              final friends = List<SocialFriend>.from(friendsCtrl.filtered);
              friends.sort(_compareByLastMessage);

              final pageCtrl = context.watch<SocialPageController>();
              final groupCtrl = context.watch<GroupChatController>();

              final entries = _buildEntries(
                friends: friends,
                storyMap: storyMap,
                pageCtrl: pageCtrl,
                groupCtrl: groupCtrl,
                context: context,
              );

              final bool showSkeleton = friendsCtrl.isLoading.value &&
                  pageCtrl.loadingPageChatList &&
                  groupCtrl.groupsLoading &&
                  entries.isEmpty;

              if (showSkeleton) {
                return const _MessengerSkeleton();
              }

              final emptyLabel = getTranslated('no_conversations', context) ??
                  getTranslated('no_friends_yet', context) ??
                  'No conversations yet';

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: entries.isEmpty
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 36),
                    Center(child: Text(emptyLabel)),
                  ],
                )
                    : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final entry = entries[i];

                    if (entry.type == _ChatEntryType.friend) {
                      final u = entry.friend!;
                      final story = entry.story;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /// ===== AVATAR: XEM STORY =====
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
                                    avatar: entry.avatar,
                                    label: u.name,
                                    online: entry.online,
                                    story: story, // ⭐ border story
                                  ),
                                  if (entry.unread)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// ===== TEXT AREA: MỞ CHAT =====
                            Expanded(
                              child: InkWell(
                                onTap: entry.onTap, // ⭐ MỞ CHAT
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight:
                                              entry.unread ? FontWeight.w700 : FontWeight.w500,
                                              color: cs.onSurface,
                                              fontSize: 15.5,
                                            ),
                                          ),
                                        ),
                                        if (entry.timeLabel.isNotEmpty)
                                          Text(
                                            entry.timeLabel,
                                            style: TextStyle(
                                              color: cs.onSurface.withOpacity(.55),
                                              fontSize: 11.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.preview.isEmpty ? ' ' : entry.preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: entry.unread
                                            ? cs.onSurface
                                            : cs.onSurface.withOpacity(.6),
                                        fontSize: 13,
                                        fontWeight:
                                        entry.unread ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final badgeColor = _badgeColorFor(entry.type);
                    final badgeIcon = _badgeIconFor(entry.type);
                    final avatarText =
                    entry.title.isNotEmpty ? entry.title[0].toUpperCase() : '?';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: cs.surfaceVariant,
                                backgroundImage: (entry.avatar != null && entry.avatar!.isNotEmpty)
                                    ? NetworkImage(entry.avatar!)
                                    : null,
                                child: (entry.avatar == null || entry.avatar!.isEmpty)
                                    ? Text(
                                  avatarText,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    : null,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    badgeIcon,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (entry.unread)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: InkWell(
                              onTap: entry.onTap,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                entry.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: entry.unread
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  color: cs.onSurface,
                                                  fontSize: 15.5,
                                                ),
                                              ),
                                            ),
                                            if ((entry.badge ?? '').isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.only(left: 6),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withOpacity(.12),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  entry.badge!,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: badgeColor,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (entry.timeLabel.isNotEmpty)
                                        Text(
                                          entry.timeLabel,
                                          style: TextStyle(
                                            color: cs.onSurface.withOpacity(.55),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if ((entry.subtitle ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.5),
                                      child: Text(
                                        entry.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface.withOpacity(.65),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 3),
                                  Text(
                                    entry.preview.isEmpty ? ' ' : entry.preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: entry.unread
                                          ? cs.onSurface
                                          : cs.onSurface.withOpacity(.7),
                                      fontSize: 13,
                                      fontWeight: entry.unread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openChat(SocialFriend u) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    setState(() {
      _localLastRead[u.id] = now;
    });

    friendsCtrl.markRead(u.id);

    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          accessToken: widget.accessToken,
          peerUserId: u.id.toString(),
          peerName: (u.name.isNotEmpty) ? u.name : 'User #${u.id}',
          peerAvatar: u.avatar,
        ),
      ),
    );
  }

  void _openPageThread(PageChatThread t) {
    final pageCtrl = context.read<SocialPageController>();
    final recipientId = t.isMyPage ? t.userId : t.ownerId;
    pageCtrl.markPageThreadRead(t.pageId, peerId: recipientId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PageChatScreen(
          pageId: int.tryParse(t.pageId) ?? 0,
          recipientId: recipientId,
          pageTitle: t.isMyPage
              ? (t.peerName.isNotEmpty ? t.peerName : t.pageTitle)
              : t.pageTitle,
          pageAvatar:
          t.peerAvatar.isNotEmpty ? t.peerAvatar : t.avatar,
          pageSubtitle: t.isMyPage ? '(${t.pageName})' : '@${t.pageName}',
        ),
      ),
    );
  }
}

enum _ChatEntryType { friend, page, group }

class _ChatEntry {
  final _ChatEntryType type;
  final String id;
  final String title;
  final String? subtitle;
  final String preview;
  final String timeLabel;
  final int timestamp;
  final String? avatar;
  final bool unread;
  final bool online;
  final String? badge;
  final SocialFriend? friend;
  final SocialStory? story;
  final VoidCallback onTap;

  _ChatEntry({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.timeLabel,
    required this.timestamp,
    required this.avatar,
    required this.unread,
    required this.online,
    required this.badge,
    required this.friend,
    required this.story,
    required this.onTap,
  });
}

class _MessengerFooter extends StatelessWidget {
  final int currentIndex;
  final int chatBadgeCount;
  final bool showNotifDot;
  final ValueChanged<int> onTap;

  const _MessengerFooter({
    required this.currentIndex,
    required this.chatBadgeCount,
    required this.showNotifDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget item({
      required int index,
      required IconData icon,
      required String label,
      int? badge,
      bool dot = false,
    }) {
      final bool active = currentIndex == index;
      final Color iconColor = active ? Colors.blue : Colors.grey.shade700;
      final Color textColor = active ? Colors.blue : Colors.grey.shade700;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onTap(index),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 24, color: iconColor),
                    if ((badge ?? 0) > 0)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: _Badge(text: (badge!).toString()),
                      ),
                    if (dot)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: _Dot(color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.5),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            item(
              index: 0,
              icon: Icons.chat_bubble,
              label: getTranslated('chat_section', context)!,
              badge: chatBadgeCount,
            ),
            item(
              index: 1,
              icon: Icons.flag_outlined,
              label: getTranslated('pages', context) ?? 'Pages',
            ),
            item(
              index: 2,
              icon: Icons.groups,
              label: getTranslated('group_chat', context)!,
              dot: showNotifDot,
            ),
            item(
              index: 3,
              icon: Icons.menu,
              label: getTranslated('menu', context)!,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CreateStoryTile extends StatelessWidget {
  const _CreateStoryTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cs.surfaceVariant,
                child: Icon(
                  Icons.add,
                  color: cs.onSurface.withOpacity(.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            getTranslated('create_story', context) ?? 'Create story',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

class _AvatarStoryTile extends StatelessWidget {
  final String name;
  final String? avatar;
  final bool online;
  final VoidCallback? onTap;
  const _AvatarStoryTile({
    required this.name,
    required this.avatar,
    required this.online,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: (avatar != null && avatar!.isNotEmpty)
                      ? NetworkImage(avatar!)
                      : null,
                  child: (avatar == null || avatar!.isEmpty)
                      ? Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
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
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final String? url;
  final bool online;
  final String label;
  const _ChatAvatar({
    required this.url,
    required this.online,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: cs.surfaceVariant,
          backgroundImage:
              (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
          child: (url == null || url!.isEmpty)
              ? Text(
                  label.isNotEmpty ? label[0] : '?',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
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

class _AvatarStripSkeleton extends StatelessWidget {
  const _AvatarStripSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (_, __) => Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: cs.surfaceVariant),
          const SizedBox(height: 6),
          Container(width: 54, height: 10, color: cs.surfaceVariant),
        ],
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemCount: 8,
    );
  }
}

class _MessengerSkeleton extends StatelessWidget {
  const _MessengerSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(radius: 26, backgroundColor: cs.surfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, color: cs.surfaceVariant),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 220, color: cs.surfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
    final bool hasUnviewed = hasStory && story!.items.any((e) => e.isViewed == false);

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
            backgroundImage:
            (avatar != null && avatar!.isNotEmpty)
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

class StoryAvatarTile extends StatelessWidget {
  final String name;
  final String? avatar;
  final bool online;
  final SocialStory? story;
  final VoidCallback? onTap;

  const StoryAvatarTile({
    super.key,
    required this.name,
    required this.avatar,
    required this.online,
    this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool hasStory = story != null && story!.items.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            /// ===== AVATAR + STORY BORDER =====
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasStory
                    ? const LinearGradient(
                  colors: [
                    Color(0xFF1877F2), // Facebook blue
                    Color(0xFF9C27B0), // Purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: cs.surfaceVariant,
                backgroundImage:
                (avatar != null && avatar!.isNotEmpty)
                    ? NetworkImage(avatar!)
                    : null,
                child: (avatar == null || avatar!.isEmpty)
                    ? Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
            ),

            const SizedBox(height: 6),

            /// ===== NAME =====
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
