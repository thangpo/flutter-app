import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flight_service.dart';
import '../widgets/flight_list_widget.dart';
import '../widgets/flight_search_form.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';

class FlightBookingScreen extends StatefulWidget {
  const FlightBookingScreen({super.key});

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  final Color headerBlue = const Color(0xFF2F6FED);

  List<dynamic> searchResults = [];
  bool isLoading = false;
  static const double _cardOverlap = 280;

  String tr(String key, String fallback) {
    final v = getTranslated(key, context);
    if (v == null || v.isEmpty || v == key) return fallback;
    return v;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialController>().loadUserProfile(
        targetUserId: null,
        force: false,
        useCache: true,
        backgroundRefresh: true,
      );
    });
  }

  String _displayNameFromSocial(SocialController sc) {
    final u = sc.currentUser;
    if (u == null) return tr('flight_user', 'User');

    final first = (u.firstName ?? '').trim();
    final last = (u.lastName ?? '').trim();
    final full = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    if (full.isNotEmpty) return full;

    final dn = (u.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final un = (u.userName ?? '').trim();
    if (un.isNotEmpty) return un;

    return tr('flight_user', 'User');
  }

  String? _avatarUrlFromSocial(SocialController sc) {
    final url = sc.currentUser?.avatarUrl;
    if (url == null || url.trim().isEmpty) return null;
    return url.trim();
  }

  Widget _squareAvatar({
    required bool isDark,
    required String? url,
    double size = 34,
    double radius = 10,
  }) {
    final bg = isDark ? Colors.white10 : Colors.black12;
    final fg = isDark ? Colors.white70 : Colors.black54;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: bg,
        child: (url != null)
            ? Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.person, color: fg, size: size * 0.6),
        )
            : Icon(Icons.person, color: fg, size: size * 0.6),
      ),
    );
  }

  void _showWarning(String message) {
    final isDark =
        Provider.of<ThemeController>(context, listen: false).darkTheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDark ? const Color(0xFFB91C1C) : Colors.red,
      ),
    );
  }

  void _showLoadingDialog() {
    final isDark =
        Provider.of<ThemeController>(context, listen: false).darkTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (_) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1220) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(headerBlue),
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  Future<void> _handleSearch(FlightSearchCriteria c) async {
    setState(() {
      searchResults = [];
      isLoading = true;
    });
    _showLoadingDialog();

    try {
      final start = _fmtDate(c.departureDate);
      final end =
      c.isRoundTrip ? _fmtDate(c.returnDate!) : _fmtDate(c.departureDate);

      final res = await FlightService.getFlights(params: {
        "limit": 20,
        "page": 1,
        "start": start,
        "end": end,
      });

      if (!mounted) return;

      final data = res["data"] as Map<String, dynamic>;
      final rows = (data["rows"] as List<dynamic>?) ?? <dynamic>[];

      setState(() {
        searchResults = rows;
        isLoading = false;
      });

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      Navigator.of(context).pop();
      _showWarning(
        "${tr('flight_error_search', 'Đã xảy ra lỗi khi tìm chuyến bay:')} $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeController>().darkTheme;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FB);
    final topInset = MediaQuery.of(context).padding.top;
    final collapsedH = kToolbarHeight + topInset;
    final expandedH = 210.0 + _cardOverlap;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: headerBlue,
            pinned: true,
            elevation: 0,
            expandedHeight: expandedH,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Consumer<SocialController>(
                    builder: (context, sc, _) {
                      final name = _displayNameFromSocial(sc);
                      final avatarUrl = _avatarUrlFromSocial(sc);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          border:
                          Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${tr('flight_hi', 'Hi,')} $name",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 8),
                            _squareAvatar(
                              isDark: isDark,
                              url: avatarUrl,
                              size: 32,
                              radius: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final t = ((constraints.maxHeight - collapsedH) /
                    (expandedH - collapsedH))
                    .clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: headerBlue),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _cardOverlap,
                      child: Container(color: bg),
                    ),

                    Positioned(
                      left: 16,
                      right: 16,
                      top: 88,
                      child: Opacity(
                        opacity: t,
                        child: Text(
                          tr('flight_book_title', 'Book your flight'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Opacity(
                        opacity: t,
                        child: IgnorePointer(
                          ignoring: t < 0.15,
                          child: Material(
                            type: MaterialType.transparency,
                            child: FlightSearchForm(
                              headerBlue: headerBlue,
                              onSearch: _handleSearch,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: FlightListWidget(
                flights: searchResults.isNotEmpty ? searchResults : null,
                isLoading: isLoading,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}