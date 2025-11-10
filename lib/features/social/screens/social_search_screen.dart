import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_channel.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_group_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class SocialSearchScreen extends StatefulWidget {
  const SocialSearchScreen({super.key});

  @override
  State<SocialSearchScreen> createState() => _SocialSearchScreenState();
}

class _SocialSearchScreenState extends State<SocialSearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final Set<String> _locallyFollowed = <String>{};
  final Set<String> _followBusy = <String>{};

  @override
  void initState() {
    super.initState();
    final sc = context.read<SocialController>();
    _controller = TextEditingController(text: sc.searchKeyword);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        if (sc.hasSearchQuery && sc.searchResult.isEmpty && !sc.searchLoading) {
          sc.refreshSearchResults();
        }
      }
    });
  }

  bool _isFollowingUser(SocialUser user) {
    return user.isFollowing || _locallyFollowed.contains(user.id);
  }

  Future<void> _handleFollowTap(SocialUser user) async {
    if (_followBusy.contains(user.id)) return;
    final socialController = context.read<SocialController>();
    setState(() => _followBusy.add(user.id));
    try {
      final bool followed =
          await socialController.toggleFollowUser(targetUserId: user.id);
      setState(() {
        if (followed) {
          _locallyFollowed.add(user.id);
        } else {
          _locallyFollowed.remove(user.id);
        }
      });
    } catch (e) {
      showCustomSnackBar(e.toString(), context, isError: true);
    } finally {
      setState(() => _followBusy.remove(user.id));
    }
  }

  Future<void> _handleMessageTap(SocialUser user) async {
    final socialController = context.read<SocialController>();
    final token = socialController.accessToken;
    if (token == null || token.isEmpty) {
      showCustomSnackBar(
        getTranslated('please_login', context) ??
            'Vui lòng đăng nhập để sử dụng tính năng nhắn tin.',
        context,
        isError: true,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          accessToken: token,
          peerUserId: user.id,
          peerName: user.displayName ?? user.userName ?? user.id,
          peerAvatar: user.avatarUrl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarBackground =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBackground,
        titleSpacing: 0,
        title: _buildSearchField(theme),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: _handleClear,
          ),
        ],
      ),
      body: Consumer<SocialController>(
        builder: (context, sc, _) => _buildBody(context, sc),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm bạn bè, nhóm, trang...',
        border: InputBorder.none,
        hintStyle: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w400),
        prefixIcon: const Icon(Icons.search),
      ),
      onChanged: (value) =>
          context.read<SocialController>().updateSearchKeyword(value),
      onSubmitted: (value) =>
          context.read<SocialController>().searchNow(value.trim()),
    );
  }

  Widget _buildBody(BuildContext context, SocialController sc) {
    if (!sc.hasSearchQuery) {
      return _CenteredMessage(
        icon: Icons.search,
        title: 'Bắt đầu tìm kiếm',
        message: 'Nhập từ khóa để tìm user, page, group hoặc channel.',
      );
    }

    if (sc.searchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sc.searchError != null && sc.searchResult.isEmpty) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        title: 'Không thể tìm kiếm',
        message: sc.searchError ?? 'Đã có lỗi xảy ra, hãy thử lại.',
        trailing: TextButton(
          onPressed: () => sc.refreshSearchResults(),
          child: const Text('Thử lại'),
        ),
      );
    }

    final result = sc.searchResult;
    if (result.isEmpty) {
      return _CenteredMessage(
        icon: Icons.search_off_outlined,
        title: 'Không tìm thấy kết quả',
        message: 'Hãy thử với từ khóa khác.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
      children: [
        if (result.users.isNotEmpty)
          _SearchSection(
            title: 'Người dùng',
            children: result.users.map(_buildUserTile).toList(),
          ),
        if (result.pages.isNotEmpty)
          _SearchSection(
            title: 'Trang',
            children: result.pages.map(_buildPageTile).toList(),
          ),
        if (result.groups.isNotEmpty)
          _SearchSection(
            title: 'Nhóm',
            children: result.groups.map(_buildGroupTile).toList(),
          ),
        if (result.channels.isNotEmpty)
          _SearchSection(
            title: 'Kênh',
            children: result.channels.map(_buildChannelTile).toList(),
          ),
      ],
    );
  }

  Widget _buildUserTile(SocialUser user) {
    final context = this.context;
    final theme = Theme.of(context);
    final subtitle = user.userName != null && user.userName!.isNotEmpty
        ? '@${user.userName}'
        : null;
    final bool canFollow = !user.isFriend && !_isFollowingUser(user);
    final bool canMessage = !canFollow;
    String? statusLabel;
    VoidCallback? statusAction;
    bool isBusy = false;
    if (canMessage) {
      statusLabel = getTranslated('message', context) ?? 'Nhan tin';
      statusAction = () {
        _handleMessageTap(user);
      };
    } else if (canFollow) {
      statusLabel = getTranslated('follow', context) ?? 'Follow';
      statusAction = () {
        _handleFollowTap(user);
      };
      isBusy = _followBusy.contains(user.id);
    }
    final TextStyle statusStyle = theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        );
    final ButtonStyle statusButtonStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final Widget? statusButton = (statusLabel != null && statusAction != null)
        ? TextButton(
            onPressed: isBusy ? null : statusAction,
            style: statusButtonStyle,
            child: isBusy
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Text(statusLabel, style: statusStyle),
          )
        : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _Avatar(
        imageUrl: user.avatarUrl,
        fallbackIcon: Icons.person_outline,
      ),
      title: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            user.displayName ?? user.userName ?? user.id,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600, // hoặc FontWeight.bold
            ),
          ),
          if (statusButton != null) statusButton,
        ],
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(targetUserId: user.id),
          ),
        );
      },
    );
  }

  Widget _buildPageTile(SocialPage page) {
    final context = this.context;
    final subtitle = page.category ?? page.username ?? page.url ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _Avatar(
        imageUrl: page.avatarUrl,
        fallbackIcon: Icons.flag_outlined,
      ),
      title: Text(page.title ?? page.name),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      // trailing: const Icon(Icons.open_in_new),
      onTap: () => _openExternal(page.url),
    );
  }

  Widget _buildGroupTile(SocialGroup group) {
    final context = this.context;
    final subtitle = group.category ?? group.description ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _Avatar(
        imageUrl: group.avatarUrl,
        fallbackIcon: Icons.group_outlined,
      ),
      title: Text(group.title ?? group.name),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      // trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SocialGroupDetailScreen(
              groupId: group.id,
              initialGroup: group,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelTile(SocialChannel channel) {
    final subtitle = channel.category ??
        (channel.subscriberCount > 0
            ? '${channel.subscriberCount} người theo dõi'
            : '');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _Avatar(
        imageUrl: channel.avatarUrl,
        fallbackIcon: Icons.live_tv_outlined,
      ),
      title: Text(channel.title ?? channel.name),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      // trailing: const Icon(Icons.open_in_new),
      onTap: () => _openExternal(channel.url),
    );
  }

  Future<void> _openExternal(String? url) async {
    if (url == null || url.isEmpty) {
      _showSnackBar('Liên kết không khả dụng');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar('Liên kết không hợp lệ');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Không mở được liên kết');
    }
  }

  void _handleClear() {
    if (_controller.text.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    _controller.clear();
    context.read<SocialController>().clearSearch();
    _focusNode.requestFocus();
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SearchSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SearchSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.transparent,
            elevation: 0,
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double size;

  const _Avatar({
    required this.imageUrl,
    required this.fallbackIcon,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(size / 2);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Icon(fallbackIcon, color: theme.hintColor),
                placeholder: (_, __) => Container(
                  color: theme.colorScheme.surfaceVariant,
                ),
              )
            : Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(fallbackIcon, color: theme.hintColor),
              ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? trailing;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            if (trailing != null) ...[
              const SizedBox(height: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
