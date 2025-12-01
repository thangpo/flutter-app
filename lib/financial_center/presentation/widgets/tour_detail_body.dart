import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TourDetailBody extends StatefulWidget {
  final Map<String, dynamic> tour;
  final Color primaryOcean;
  final Color paleOcean;
  final Color darkBackground;
  final Color darkPrimary;

  const TourDetailBody({
    super.key,
    required this.tour,
    required this.primaryOcean,
    required this.paleOcean,
    required this.darkBackground,
    required this.darkPrimary,
  });

  @override
  State<TourDetailBody> createState() => _TourDetailBodyState();
}

class _TourDetailBodyState extends State<TourDetailBody> {
  int _tabIndex = 0;

  String _formatPrice(dynamic raw) {
    if (raw == null) return '0 ₫';
    final num? value = raw is num ? raw : num.tryParse(raw.toString());
    if (value == null) return '$raw';
    final formatter =
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: true);
    final isDark = theme.darkTheme;
    final tour = widget.tour;
    final gallery = List<String>.from(tour['gallery_urls'] ?? []);
    final String banner =
    (tour['banner_image_url'] ?? '').toString().trim();
    final List<String> heroImages = [];
    if (banner.isNotEmpty) heroImages.add(banner);
    for (final g in gallery) {
      final u = g.trim();
      if (u.isNotEmpty && u != banner) {
        heroImages.add(u);
      }
    }

    final bookingData = tour['booking_data'] ?? {};
    final reviews = tour['review_list']?['data'] ?? [];

    final dynamic priceRaw = tour['sale_price'] ?? tour['price'];
    final priceText = _formatPrice(priceRaw);
    final priceShort =
        '$priceText / ${getTranslated('per_person', context) ?? 'person'}';

    final rating =
        tour['review_score'] ?? tour['review_list']?['score'] ?? '4.5';
    final ratingStr = rating.toString();

    final durationValue = tour['duration']?.toString() ?? '';
    final durationUnit =
        getTranslated('day', context) ?? getTranslated('days', context) ?? 'day';
    final durationText =
    durationValue.isNotEmpty ? '$durationValue $durationUnit' : '-';

    final startDateText =
        bookingData['start_date_html'] ??
            getTranslated('flexible_date', context) ??
            'Flexible';

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroHeader(
            context,
            isDark: isDark,
            priceShort: priceShort,
            ratingStr: ratingStr,
            heroImages: heroImages,
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTabButton(
                      index: 0,
                      label:
                      getTranslated('overview', context) ?? 'Overview',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 24),
                    _buildTabButton(
                      index: 1,
                      label:
                      getTranslated('reviews', context) ?? 'Reviews',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_tabIndex == 0)
                  _buildOverviewSection(
                    context,
                    isDark: isDark,
                    startDateText: startDateText,
                    ratingStr: ratingStr,
                    durationText: durationText,
                    bookingData: bookingData,
                  )
                else
                  _buildReviewsSection(
                    context,
                    isDark: isDark,
                    reviews: reviews,
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDescriptionCard(context, isDark: isDark),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(
      BuildContext context, {
        required bool isDark,
        required String priceShort,
        required String ratingStr,
        required List<String> heroImages,
      }) {
    final tour = widget.tour;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: SizedBox(
          height: 500,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroImages.isNotEmpty)
                CarouselSlider(
                  options: CarouselOptions(
                    height: double.infinity,
                    viewportFraction: 1,
                    autoPlay: heroImages.length > 1,
                    enableInfiniteScroll: heroImages.length > 1,
                  ),
                  items: heroImages.map((imageUrl) {
                    return Builder(
                      builder: (context) => Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[400],
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Container(
                  color: Colors.grey[400],
                  child: const Icon(
                    Icons.image_outlined,
                    color: Colors.white,
                    size: 60,
                  ),
                ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tour['title'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                priceShort,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ratingStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.92),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.bookmark_border_rounded,
                        color:
                        isDark ? widget.darkPrimary : widget.primaryOcean,
                        size: 22,
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

  Widget _buildTabButton({
    required int index,
    required String label,
    required bool isDark,
  }) {
    final bool selected = _tabIndex == index;
    final Color activeColor =
    isDark ? widget.darkPrimary : widget.primaryOcean;

    return GestureDetector(
      onTap: () {
        setState(() => _tabIndex = index);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? activeColor
                  : (isDark ? Colors.white70 : Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 3,
            width: selected ? 42 : 24,
            decoration: BoxDecoration(
              color: selected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(
      BuildContext context, {
        required bool isDark,
        required String startDateText,
        required String ratingStr,
        required String durationText,
        required Map<String, dynamic> bookingData,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoPill(
                isDark: isDark,
                icon: Icons.calendar_today_rounded,
                text: startDateText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoPill(
                isDark: isDark,
                icon: Icons.star_rounded,
                text: '$ratingStr / 5',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoPill(
                isDark: isDark,
                icon: Icons.timelapse_rounded,
                text: durationText,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (bookingData.isNotEmpty) ...[
          Text(
            getTranslated('price_by_person', context) ?? 'Price by person',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? widget.darkPrimary : widget.primaryOcean,
            ),
          ),
          const SizedBox(height: 8),
          ...List.from(bookingData['person_types'] ?? []).map<Widget>((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]!.withOpacity(0.35)
                    : widget.paleOcean,
                borderRadius: BorderRadius.circular(10),
                border: isDark
                    ? Border.all(color: Colors.white.withOpacity(0.1))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                            isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          p['desc'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    p['display_price'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? widget.darkPrimary
                          : widget.primaryOcean,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (bookingData['extra_price'] != null &&
              bookingData['extra_price'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              getTranslated('extra_fees', context) ?? 'Extra fees',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? widget.darkPrimary : widget.primaryOcean,
              ),
            ),
            const SizedBox(height: 4),
            ...List.from(bookingData['extra_price']).map<Widget>((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e['name'],
                      style: TextStyle(
                        color:
                        isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      e['price_html'],
                      style: TextStyle(
                        color: isDark
                            ? widget.darkPrimary
                            : widget.primaryOcean,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, {required bool isDark}) {
    final tour = widget.tour;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: isDark ? widget.darkPrimary : widget.primaryOcean,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                getTranslated('description', context) ?? 'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? widget.darkPrimary : widget.primaryOcean,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HtmlWidget(
            tour['description'] ?? '',
            textStyle: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(
      BuildContext context, {
        required bool isDark,
        required List<dynamic> reviews,
      }) {
    if (reviews.isEmpty) {
      return Text(
        getTranslated('no_reviews_yet', context) ?? 'No reviews yet.',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[600],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...reviews.map<Widget>((r) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[850]!.withOpacity(0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isDark
                  ? Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.2,
              )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r['title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : Colors.grey.shade900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              r['rate_number'].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r['content'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white70
                          : Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.isDark,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white70 : Colors.grey[800],
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}