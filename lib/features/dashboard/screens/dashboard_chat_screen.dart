import 'dart:io' show Platform;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chats_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/search_chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_mess.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';

/// Dashboard thu gọn cho các danh sách chat (1-1, Page, Group).
/// Chỉ hiển thị khi ở màn list, không áp vào màn chat chi tiết.
class DashboardChatScreen extends StatefulWidget {
  final String accessToken;

  /// Tab mặc định: 0 = Chat, 1 = Page chat, 2 = Group chatZ, 3 = Search.
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
  final GlobalKey<SearchChatScreenState> _searchKey =
      GlobalKey<SearchChatScreenState>();
  final List<int> _tabHistory = [];
  static const int _homeIndex = -1; // bỏ tab home
  static const int _searchIndex = 3;

  @override
  void initState() {
    super.initState();
    // index: 0=chat,1=page,2=group,3=search
    _pageIndex = widget.initialIndex.clamp(0, _searchIndex);
    _tabHistory.add(_pageIndex);
    if (!kIsWeb && Platform.isIOS) {
      _iosMajor = _detectIOSMajor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOSPlatform = !kIsWeb && Platform.isIOS;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool hideNav = _pageIndex == _searchIndex && isKeyboardOpen;

    Color navActiveColor = cs.primary;
    if (isIOSPlatform && platformBrightness == Brightness.dark) {
      navActiveColor = _boostLightness(navActiveColor, 0.20);
    }
    String t(String key, String fallback) =>
        getTranslated(key, context) ?? fallback;
    Object _sym(String sfSymbol, IconData fallback) {
      final v = _iosMajor ?? 0;
      return v >= 26 ? sfSymbol : fallback;
    }

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
        key: _searchKey,
        accessToken: widget.accessToken,
      ),
    ];

    final Widget body = PageStorage(
      bucket: _bucket,
      child: IndexedStack(index: _pageIndex, children: screens),
    );

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

    final Widget scaffold = isIOSPlatform
        ? AdaptiveScaffold(
            body: body,
            bottomNavigationBar: hideNav
                ? null
                : AdaptiveBottomNavigationBar(
                    items: iosDestinations,
                    selectedIndex: _pageIndex,
                    onTap: _setPage,
                    useNativeBottomBar: true, // iOS 26+ sẽ là UITabBar native
                    selectedItemColor:
                        navActiveColor, // màu icon/label khi chọn
                    // unselectedItemColor: CupertinoColors.inactiveGray, // (tuỳ chọn)
                  ),
          )
        : Scaffold(
            body: body,
            bottomNavigationBar: hideNav
                ? null
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ChatAndroidBottomBar(
                      items: items,
                      currentIndex: _pageIndex,
                      onTap: _setPage,
                    ),
                  ),
          );

    return WillPopScope(
      onWillPop: _onWillPop,
      child: scaffold,
    );
  }

  void _setPage(int index) {

    if (index == _pageIndex) return;
    setState(() {
      _pageIndex = index;
      _pushTabHistory(index);
    });
    if (index == _searchIndex) {
      _searchKey.currentState?.focusInput();
    }
  }

  Future<bool> _onWillPop() async {
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        _pageIndex = _tabHistory.last;
      });
      if (_pageIndex == _searchIndex) {
        _searchKey.currentState?.focusInput();
      }
      return false;
    }
    return true;
  }

  void _pushTabHistory(int index) {
    if (_tabHistory.isEmpty || _tabHistory.last != index) {
      _tabHistory.add(index);
      const int maxLen = 10;
      if (_tabHistory.length > maxLen) {
        _tabHistory.removeRange(0, _tabHistory.length - maxLen);
      }
    }
  }

  int? _detectIOSMajor() {
    try {
      final s = Platform.operatingSystemVersion;
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
  final bool addSpacerAfter;

  _ChatNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.addSpacerAfter = false,
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
            const double gapWidth = 16;
            final int gapCount =
                items.where((element) => element.addSpacerAfter).length;
            final double barWidth = constraints.maxWidth;
            final double itemWidth =
                (barWidth - (gapWidth * gapCount)) / items.length;

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
                    top: 16,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: circleLeft,
                    bottom: circleBottom,
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scaffoldBg,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 22,
                    child: Row(
                      children: List.generate(items.length, (i) {
                        final item = items[i];
                        final bool active = i == currentIndex;
                        final icon = active
                            ? (item.activeIcon ?? item.icon)
                            : item.icon;

                        return Row(
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => onTap(i),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 4),
                                    Icon(
                                      icon,
                                      color: active
                                          ? Colors.blue
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        color: active
                                            ? Colors.blue
                                            : Colors.grey.shade700,
                                        fontSize: 11.5,
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (item.addSpacerAfter)
                              const SizedBox(width: gapWidth),
                          ],
                        );
                      }),
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
