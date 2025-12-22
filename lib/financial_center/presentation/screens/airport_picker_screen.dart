import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/airport_models.dart';
import '../services/flight_airport_api.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class AirportPickerScreen extends StatefulWidget {
  final String title;
  final AirportItem? selected;
  final int? disabledAirportId;

  const AirportPickerScreen({
    super.key,
    required this.title,
    this.selected,
    this.disabledAirportId,
  });

  @override
  State<AirportPickerScreen> createState() => _AirportPickerScreenState();
}

class _AirportPickerScreenState extends State<AirportPickerScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String _q = '';
  List<AirportItem> _items = [];

  String tr(String key, String fallback) {
    final v = getTranslated(key, context);
    if (v == null || v.isEmpty || v == key) return fallback;
    return v;
  }

  @override
  void initState() {
    super.initState();
    _load();

    _searchCtl.addListener(() {
      final v = _searchCtl.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _q = v);
        _load();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await FlightAirportApi.fetchAirports(q: _q, limit: 30, page: 1);
      if (!mounted) return;
      setState(() => _items = res);
    } catch (e) {
      if (!mounted) return;
      final msg = tr('airport_load_error', 'Failed to load airports: {error}')
          .replaceAll('{error}', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F7FB);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surface2 = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white70 : Colors.black54;
    final border = isDark ? Colors.white10 : Colors.black12;

    final disabledId = widget.disabledAirportId;
    final selectedId = widget.selected?.id;

    final topItems = _items.length > 4 ? _items.take(4).toList() : _items;
    final restItems = _items.length > 4 ? _items.skip(4).toList() : <AirportItem>[];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: textMain,
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtl,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: textMain),
              decoration: InputDecoration(
                hintText: tr('airport_search_hint', 'Search by name / code / address…'),
                hintStyle: TextStyle(color: textSub),
                prefixIcon: Icon(Icons.search, color: textSub),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading && _items.isEmpty
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('airport_find_best_title', 'Find the best airport'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                ),
                if (_loading) const SizedBox(width: 12),
                if (_loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 170,
              child: topItems.isEmpty
                  ? _EmptyTopPlaceholder(
                onRetry: _load,
                isDark: isDark,
                surface: surface,
                border: border,
                textSub: textSub,
                tr: tr,
              )
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: topItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final a = topItems[i];
                  final isDisabled = (disabledId != null && a.id == disabledId);
                  final isSelected = (selectedId != null && a.id == selectedId);

                  return _TopAirportCard(
                    airport: a,
                    isSelected: isSelected,
                    isDisabled: isDisabled,
                    onTap: isDisabled ? null : () => Navigator.pop(context, a),
                    isDark: isDark,
                    tr: tr,
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Text(
                  tr('airport_popular_title', 'Popular airports'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textMain,
                  ),
                ),
                const Spacer(),
                Text(
                  tr('airport_items_count', '{count} items')
                      .replaceAll('{count}', restItems.length.toString()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _EmptyListPlaceholder(
                  onRetry: _load,
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  textSub: textSub,
                  tr: tr,
                ),
              )
            else if (restItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tr('airport_no_more', 'No more airports.'),
                  style: TextStyle(color: textSub),
                ),
              )
            else
              ...restItems.map((a) {
                final isDisabled = (disabledId != null && a.id == disabledId);
                final isSelected = (selectedId != null && a.id == selectedId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PopularAirportTile(
                    airport: a,
                    isSelected: isSelected,
                    isDisabled: isDisabled,
                    onTap: isDisabled ? null : () => Navigator.pop(context, a),
                    isDark: isDark,
                    surface: surface,
                    surface2: surface2,
                    border: border,
                    textMain: textMain,
                    textSub: textSub,
                    tr: tr,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TopAirportCard extends StatelessWidget {
  final AirportItem airport;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final bool isDark;
  final String Function(String, String) tr;

  const _TopAirportCard({
    required this.airport,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    required this.isDark,
    required this.tr,
  });

  List<Color> _gradientForId(int id) {
    final palettes = <List<Color>>[
      [const Color(0xFF0EA5E9), const Color(0xFF1D4ED8)],
      [const Color(0xFF22C55E), const Color(0xFF15803D)],
      [const Color(0xFFF97316), const Color(0xFFB45309)],
      [const Color(0xFFA78BFA), const Color(0xFF6D28D9)],
      [const Color(0xFF06B6D4), const Color(0xFF0F766E)],
    ];
    return palettes[id.abs() % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final loc = airport.location?.name ?? '';
    final code = airport.code;
    final sub = [if (loc.isNotEmpty) loc, if (code.isNotEmpty) code].join(' • ');

    final colors = _gradientForId(airport.id);
    final borderColor = isSelected ? const Color(0xFF22C55E) : Colors.transparent;

    return Opacity(
      opacity: isDisabled ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Text(
                    isDisabled
                        ? tr('airport_locked', 'Locked')
                        : tr('airport_new', 'New'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.flight,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),

              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      airport.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularAirportTile extends StatelessWidget {
  final AirportItem airport;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  final bool isDark;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color textMain;
  final Color textSub;
  final String Function(String, String) tr;

  const _PopularAirportTile({
    required this.airport,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    required this.isDark,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.textMain,
    required this.textSub,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    final loc = airport.location?.name ?? '';
    final address = (airport.address ?? '').replaceAll('\n', ' ').trim();
    final subtitle = [if (loc.isNotEmpty) loc, if (address.isNotEmpty) address].join(' • ');

    final borderColor = isSelected ? const Color(0xFF22C55E) : border;

    return Opacity(
      opacity: isDisabled ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: surface2,
                ),
                child: Icon(
                  Icons.flight_takeoff,
                  size: 22,
                  color: textMain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${airport.name} (${airport.code})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                        color: textMain,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tr('airport_selected', 'Selected'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (isDisabled)
                Text(
                  tr('airport_selected', 'Selected'),
                  style: TextStyle(color: textSub, fontWeight: FontWeight.w700),
                )
              else
                Icon(Icons.chevron_right, color: textSub),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTopPlaceholder extends StatelessWidget {
  final Future<void> Function() onRetry;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textSub;
  final String Function(String, String) tr;

  const _EmptyTopPlaceholder({
    required this.onRetry,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textSub,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: textSub),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('airport_no_data', 'No data to display.'),
              style: TextStyle(color: textSub, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => onRetry(),
            child: Text(tr('airport_reload', 'Reload')),
          ),
        ],
      ),
    );
  }
}

class _EmptyListPlaceholder extends StatelessWidget {
  final Future<void> Function() onRetry;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textSub;
  final String Function(String, String) tr;

  const _EmptyListPlaceholder({
    required this.onRetry,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textSub,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, color: textSub),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('airport_empty_list', 'No airports found.'),
              style: TextStyle(color: textSub, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => onRetry(),
            child: Text(tr('airport_reload', 'Reload')),
          ),
        ],
      ),
    );
  }
}