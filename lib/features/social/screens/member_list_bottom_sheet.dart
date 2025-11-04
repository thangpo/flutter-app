import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';

typedef MemberPageLoader = Future<MemberPage> Function(String? afterCursor);
typedef OnUserTap = void Function(SocialUser user);
typedef AdminPredicate = bool Function(SocialUser user);

class MemberPage {
  final List<SocialUser> users;
  final String? nextCursor;
  MemberPage({required this.users, this.nextCursor});
}

class MemberListBottomSheet extends StatefulWidget {
  final String title; // "Followers" | "Following" | "Members"
  final MemberPageLoader pageLoader;
  final OnUserTap? onUserTap;
  final int? totalCount;
  final AdminPredicate? isAdmin;

  const MemberListBottomSheet({
    super.key,
    required this.title,
    required this.pageLoader,
    this.onUserTap,
    this.totalCount,
    this.isAdmin,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            Container(
              width: 44, height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (widget.totalCount != null)
                          Text('Member count: ${widget.totalCount}',
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
            Expanded(
              child: !_firstLoaded && _loading
                  ? const _LoadingList()
                  : _items.isEmpty
                  ? const _EmptyView()
                  : ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(),
                      )),
                    );
                  }
                  final u = _items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                          ? NetworkImage(u.avatarUrl!) as ImageProvider
                          : null,
                      child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                          ? Text(_initials(u.displayName ?? u.userName ?? ''))
                          : null,
                    ),
                    title: Text(u.displayName ?? u.userName ?? 'Unknown'),
                    subtitle: (u.userName != null && u.userName!.isNotEmpty)
                        ? Text('@${u.userName}')
                        : null,
                    trailing: _buildTrailingBadge(u, theme),
                    onTap: widget.onUserTap != null ? () => widget.onUserTap!(u) : null,
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
        parts.last.characters.take(1).toString()).toUpperCase();
  }

  Widget? _buildTrailingBadge(SocialUser u, ThemeData theme) {
    final bool isAdmin = widget.isAdmin?.call(u) ?? false;
    if (!isAdmin) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
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
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (_, __) {
        return ListTile(
          leading: CircleAvatar(backgroundColor: theme.dividerColor, radius: 22),
          title: Container(height: 12, width: 140, color: theme.dividerColor),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(height: 10, width: 100, color: theme.dividerColor),
          ),
        );
      },
    );
  }
}
