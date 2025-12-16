import 'dart:io' show Platform;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chats_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_mess.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/search_chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

/// Dashboard thu gọn cho các danh sách chat (1-1, Page, Group).
/// Chỉ hiển thị khi ở màn list, không áp vào màn chat chi tiết.
class DashboardChatScreen extends StatefulWidget {
  final String accessToken;

  /// Tab mặc định: 0 = Chat, 1 = Page chat, 2 = Group chat, 3 = Search.
  final int initialIndex;

  const DashboardChatScreen({
    super.key,
    required this.accessToken,
    this.initialIndex = 0,
  }) : assert(initialIndex >= 0 && initialIndex <= 3,
            'initialIndex must be 0, 1, 2 hoặc 3');

  @override
  State<DashboardChatScreen> createState() => _DashboardChatScreenState();
}

class _DashboardChatScreenState extends State<DashboardChatScreen> {
  late int _pageIndex;
  final PageStorageBucket _bucket = PageStorageBucket();
  int? _iosMajor;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex;
    if (!kIsWeb && Platform.isIOS) {
      _iosMajor = _detectIOSMajor();
    }
  }

  // ... các import & class giữ nguyên

  @override
  Widget build(BuildContext context) {
    final bool isIOSPlatform = !kIsWeb && Platform.isIOS;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color navActiveColor = cs.primary;
    if (isIOSPlatform && platformBrightness == Brightness.dark) {
      navActiveColor = _boostLightness(navActiveColor, 0.20);
    }
    String t(String key, String fallback) =>
        getTranslated(key, context) ?? fallback;

    final List<Widget> screens = [
      FriendsListScreen(
          key: const PageStorageKey('chat_friends'),
          accessToken: widget.accessToken,
          showFooterNav: false),
      PageMessagesScreen(
          key: const PageStorageKey('chat_pages'),
          accessToken: widget.accessToken,
          showFooterNav: false),
      GroupChatsScreen(
          key: const PageStorageKey('chat_groups'),
          accessToken: widget.accessToken,
          showFooterNav: false),
      SearchChatScreen(
        key: const PageStorageKey('chat_search'),
        accessToken: widget.accessToken,
      ),
    ];

    final Widget body = PageStorage(
      bucket: _bucket,
      child: IndexedStack(index: _pageIndex, children: screens),
    );

    // -------- iOS dùng AdaptiveBottomNavigationBar (auto iOS 26+ / iOS cũ) --------
    if (isIOSPlatform) {
      // iOS 26+ -> SF Symbol string, iOS thấp hơn -> CupertinoIcons
      Object _sym(String sfSymbol, IconData fallback) {
        final v = _iosMajor ?? 0;
        return v >= 26 ? sfSymbol : fallback;
      }

      final iosDestinations = <AdaptiveNavigationDestination>[
        AdaptiveNavigationDestination(
          icon: _sym('bubble.left.and.bubble.right.fill',
              CupertinoIcons.chat_bubble_2_fill),
          label: t('chat_section', 'Chat'),
        ),
        AdaptiveNavigationDestination(
          icon: _sym('flag.fill', CupertinoIcons.flag_fill),
          label: t('pages', 'Pages'),
        ),
        AdaptiveNavigationDestination(
          icon: _sym('person.3.fill', CupertinoIcons.person_3_fill),
          label: t('group_chat', 'Group'),
          addSpacerAfter:
              true, // Tạo khoảng trống để tab Search nằm tách bên phải (iOS 26+)
        ),
        AdaptiveNavigationDestination(
          icon: _sym('magnifyingglass', CupertinoIcons.search),
          label: t('search', 'Search'),
          isSearch: true,
        ),
      ];

      return AdaptiveScaffold(
        body: body,
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          items: iosDestinations,
          selectedIndex: _pageIndex,
          onTap: _setPage,
          useNativeBottomBar: true, // iOS 26+ sẽ là UITabBar native
          selectedItemColor: navActiveColor, // màu icon/label khi chọn
          // unselectedItemColor: CupertinoColors.inactiveGray, // (tuỳ chọn)
        ),
      );
    }

    // -------- Android giữ nguyên custom bar của bạn --------
    final List<_ChatNavItem> items = [
      _ChatNavItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          label: t('chat_section', 'Chat')),
      _ChatNavItem(
          icon: Icons.flag_outlined,
          activeIcon: Icons.flag,
          label: t('pages', 'Pages')),
      _ChatNavItem(
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups,
          label: t('group_chat', 'Group')),
      _ChatNavItem(
          icon: Icons.search_outlined,
          activeIcon: Icons.search,
          label: t('search', 'Search')),
    ];

    return Scaffold(
      body: body,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ChatAndroidBottomBar(
          items: items,
          currentIndex: _pageIndex,
          onTap: _setPage,
        ),
      ),
    );
  }

  void _setPage(int index) {
    // Search tab: mở màn search_chat full-screen
    if (index == 3) {
      setState(() => _pageIndex = index);
      final route = (!kIsWeb && Platform.isIOS)
          ? CupertinoPageRoute(
              fullscreenDialog: true,
              builder: (_) => SearchChatScreen(accessToken: widget.accessToken),
            )
          : MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => SearchChatScreen(accessToken: widget.accessToken),
            );
      Navigator.of(context).push(route);
      return;
    }

    if (index == _pageIndex) return;
    setState(() => _pageIndex = index);
  }

  int? _detectIOSMajor() {
    try {
      final s = Platform.operatingSystemVersion;
      // Đồng bộ cách bắt phiên bản với dashboard_screen để không miss glyph SF Symbol
      final m = RegExp(r'(\d+)(?:\.\d+)?').firstMatch(s);
      if (m != null) return int.tryParse(m.group(1)!);
    } catch (_) {}
    return null;
  }

  Color _boostLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final double newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}

class _ChatNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  _ChatNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });
}

class ChatAndroidBottomBar extends StatelessWidget {
  final List<_ChatNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ChatAndroidBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color barColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8EBF0);
    final Color scaffoldBg = theme.scaffoldBackgroundColor;

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double barWidth = constraints.maxWidth;
            final double itemWidth = barWidth / items.length;

            const double circleSize = 70;
            const double circleBottom = 40;

            final double circleCenterX = itemWidth * (currentIndex + 0.5);
            final double circleLeft = circleCenterX - circleSize / 2;

            return SizedBox(
              height: 110,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 76,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: List.generate(
                          items.length,
                          (index) => Expanded(
                            child: _ChatAndroidNavItemWidget(
                              item: items[index],
                              selected: index == currentIndex,
                              onTap: () => onTap(index),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 230),
                    curve: Curves.easeOutCubic,
                    left: circleLeft,
                    bottom: circleBottom,
                    child: Container(
                      height: circleSize,
                      width: circleSize,
                      decoration: BoxDecoration(
                        color: scaffoldBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            items[currentIndex].activeIcon ??
                                items[currentIndex].icon,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatAndroidNavItemWidget extends StatelessWidget {
  final _ChatNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _ChatAndroidNavItemWidget({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color iconColor =
        selected ? cs.primary : cs.onSurface.withOpacity(0.7);
    final FontWeight labelWeight = selected ? FontWeight.w600 : FontWeight.w400;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!selected)
              Icon(item.icon, size: 24, color: iconColor)
            else
              const SizedBox(height: 16),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11.5,
                fontWeight: labelWeight,
                color: cs.onSurface.withOpacity(selected ? 0.95 : 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
