// lib/features/social/screens/member_list_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';

typedef MemberPageLoader = Future<MemberPage> Function(String? afterCursor);
typedef OnUserTap = void Function(SocialUser user);
typedef OnUserIdTap = void Function(String userId);
typedef AdminPredicate = bool Function(SocialUser user);

class MemberPage {
  final List<SocialUser> users;
  final String? nextCursor;
  MemberPage({required this.users, this.nextCursor});
}

/// Màu kẻ “hairline” mặc định (xám rất nhạt)
const kHairline = Color(0xFFEAEAF0);

class MemberListBottomSheet extends StatefulWidget {
  final String title; // "Followers" | "Following" | "Members"
  final MemberPageLoader pageLoader;
  final OnUserTap? onUserTap;      // callback cũ (nhận cả SocialUser)
  final OnUserIdTap? onUserIdTap;  // callback mới (nhận userId)
  final int? totalCount;
  final AdminPredicate? isAdmin;

  /// Tuỳ chỉnh màu đường kẻ / skeleton / thanh kéo.
  final Color? separatorColor;

  const MemberListBottomSheet({
    super.key,
    required this.title,
    required this.pageLoader,
    this.onUserTap,
    this.onUserIdTap,
    this.totalCount,
    this.isAdmin,
    this.separatorColor,
  });

  @override
  State<MemberListBottomSheet> createState() => _MemberListBottomSheetState();
}

class _MemberListBottomSheetState extends State<MemberListBottomSheet> {
  final List<SocialUser> _items = [];
  String? _nextCursor;
  bool _loading = false;
  bool _firstLoaded = false;
  bool _hasMore = true;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPage(null);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120) {
      _loadPage(_nextCursor);
    }
  }

  Future<void> _loadPage(String? after) async {
    setState(() => _loading = true);
    try {
      final page = await widget.pageLoader(after);
      setState(() {
        _firstLoaded = true;
        _items.addAll(page.users);
        _nextCursor = page.nextCursor;
        _hasMore = page.nextCursor != null && page.users.isNotEmpty;
      });
    } catch (_) {
      setState(() {
        _hasMore = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _defaultOpenProfile(String userId) {
    // đóng sheet trước (dùng rootNavigator để chắc chắn)
    Navigator.of(context, rootNavigator: true).pop();
    // push sau khi pop
    Future.microtask(() {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: userId)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sep = widget.separatorColor ??
        (theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(.10)
            : kHairline);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Thanh kéo
            Container(
              width: 44, height: 5,
              decoration: BoxDecoration(
                color: sep,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.totalCount != null)
                          Text(
                            'Member count: ${widget.totalCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Danh sách
            Expanded(
              child: !_firstLoaded && _loading
                  ? _LoadingList(sep: sep)
                  : _items.isEmpty
                  ? const _EmptyView()
                  : ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: sep,
                ),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  final u = _items[index];

                  void handleTap() {
                    final id = u.id;
                    if (id.isEmpty) return;
                    if (widget.onUserIdTap != null) {
                      widget.onUserIdTap!(id);
                    } else if (widget.onUserTap != null) {
                      widget.onUserTap!(u);
                    } else {
                      _defaultOpenProfile(id);
                    }
                  }

                  return ListTile(
                    leading: InkWell(
                      onTap: handleTap,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage: (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                            ? NetworkImage(u.avatarUrl!) as ImageProvider
                            : null,
                        child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                            ? Text(_initials(u.displayName ?? u.userName ?? ''))
                            : null,
                      ),
                    ),
                    title: InkWell(
                      onTap: handleTap,
                      child: Text(u.displayName ?? u.userName ?? 'Unknown'),
                    ),
                    subtitle: (u.userName != null && u.userName!.isNotEmpty)
                        ? InkWell(
                      onTap: handleTap,
                      child: Text('@${u.userName}'),
                    )
                        : null,
                    trailing: _buildTrailingBadge(u, theme, sep),
                    onTap: handleTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
        parts.last.characters.take(1).toString())
        .toUpperCase();
  }

  Widget? _buildTrailingBadge(SocialUser u, ThemeData theme, Color sep) {
    final bool isAdmin = widget.isAdmin?.call(u) ?? false;
    if (!isAdmin) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: sep),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Group Admin', style: theme.textTheme.labelMedium),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Không có thành viên nào.'),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  final Color sep;
  const _LoadingList({required this.sep});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(height: 1, color: sep),
      itemBuilder: (_, __) {
        return ListTile(
          leading: CircleAvatar(backgroundColor: sep, radius: 22),
          title: Container(height: 12, width: 140, color: sep),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(height: 10, width: 100, color: sep),
          ),
        );
      },
    );
  }
}
