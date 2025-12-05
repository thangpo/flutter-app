import 'hotel_rooms_section.dart';
import 'hotel_review_section.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';


class HotelDetailBody extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final Key? roomsSectionKey;
  final ValueChanged<HotelBookingSummary>? onBookingSummaryChanged;

  const HotelDetailBody({
    super.key,
    required this.hotel,
    this.roomsSectionKey,
    this.onBookingSummaryChanged,
  });

  @override
  State<HotelDetailBody> createState() => _HotelDetailBodyState();
}

class _HotelDetailBodyState extends State<HotelDetailBody> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: true);
    final isDark = theme.darkTheme;

    return _buildHotelInfo(context, widget.hotel, isDark);
  }

  Widget _buildHotelInfo(
      BuildContext context, Map<String, dynamic> hotel, bool isDark) {
    final String title = (hotel['title'] ?? hotel['name'] ?? '').toString();
    final String locationText = (hotel['location'] is Map)
        ? (hotel['location']?['name'] ?? '').toString()
        : (hotel['location'] ?? '').toString();
    final String address =
    (hotel['address'] ?? hotel['map_address'] ?? '').toString();
    final String? lat = hotel['map_lat']?.toString();
    final String? lng = hotel['map_lng']?.toString();
    final dynamic reviewSummaryRaw = hotel['review_summary'];

    final double score = double.tryParse(
      (reviewSummaryRaw is Map
          ? reviewSummaryRaw['score']
          : hotel['review_score'])
          ?.toString() ??
          '0',
    ) ??
        0;

    final dynamic reviewListRaw = hotel['review_list'] ?? hotel['reviewList'];
    final List<dynamic> reviews;
    if (reviewListRaw is Map && reviewListRaw['data'] is List) {
      reviews = List<dynamic>.from(reviewListRaw['data'] as List);
    } else if (reviewListRaw is List) {
      reviews = reviewListRaw;
    } else {
      reviews = const [];
    }

    final int reviewCount =
        int.tryParse(hotel['review_count']?.toString() ?? '') ??
            (reviewListRaw is Map && reviewListRaw['total'] != null
                ? int.tryParse(reviewListRaw['total'].toString()) ??
                reviews.length
                : reviews.length);

    final String priceText = (hotel['price'] ?? hotel['min_price'] ?? '')
        .toString()
        .replaceAll('.0', '');

    final dynamic attributesRaw = hotel['attributes'];
    final List<dynamic> attributes =
    attributesRaw is List ? attributesRaw : const [];
    final dynamic termsRaw = hotel['terms'];
    final List<dynamic> rawTerms = termsRaw is List ? termsRaw : const [];
    final dynamic roomsRaw = hotel['rooms'];
    final List<dynamic> rooms = roomsRaw is List ? roomsRaw : const [];

    final Map<int, String> roomTermNameMap = {};
    for (final attr in attributes) {
      if (attr is Map && attr['terms'] is List) {
        for (final t in (attr['terms'] as List)) {
          if (t is Map) {
            final int? termId = int.tryParse(t['id']?.toString() ?? '');
            final String name =
            (t['translation']?['name'] ?? t['name'] ?? '').toString();
            if (termId != null && name.isNotEmpty) {
              roomTermNameMap[termId] = name;
            }
          }
        }
      }
    }

    final String policyHtml =
    (hotel['policy'] ?? hotel['extra_info'] ?? hotel['term'] ?? '')
        .toString();
    final String contentHtml = (hotel['content'] ?? '').toString();
    final bgColor = isDark ? const Color(0xFF111315) : Colors.white;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.grey[700];

    Widget currentTabView;
    if (_currentTab == 0) {
      currentTabView = _buildDescriptionTab(
        hotel: hotel,
        contentHtml: contentHtml,
        policyHtml: policyHtml,
        isDark: isDark,
      );
    } else if (_currentTab == 1) {
      currentTabView = _buildLocationFacilityTab(
        hotel: hotel,
        address: address,
        lat: lat,
        lng: lng,
        attributes: attributes,
        rawTerms: rawTerms,
        isDark: isDark,
      );
    } else {
      currentTabView = _buildReviewTab(
        context: context,
        score: score,
        reviewCount: reviewCount,
        reviews: reviews,
        isDark: isDark,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (priceText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$priceText ₫',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '/Đêm',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                if (locationText.isNotEmpty || address.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText.isNotEmpty ? locationText : address,
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                if (score > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount đánh giá)',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          _buildBasicInfoSection(hotel, isDark),

          const SizedBox(height: 12),

          _buildTabs(isDark),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: currentTabView,
          ),

          const SizedBox(height: 24),

          if (rooms.isNotEmpty)
            HotelRoomsSection(
              key: widget.roomsSectionKey,
              hotelId: hotel['id'] ?? 0,
              rooms: rooms,
              roomTermNameMap: roomTermNameMap,
              onBookingSummaryChanged: widget.onBookingSummaryChanged,
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    final labels = ['Mô tả', 'Vị trí & ích', 'Đánh giá'];
    final bg = isDark ? const Color(0xFF181A1F) : Colors.grey[100];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = index == _currentTab;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _currentTab = index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark ? Colors.blue[700] : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? (isDark ? Colors.white : Colors.blue[700])
                            : (isDark ? Colors.white70 : Colors.grey[700]),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDescriptionTab({
    required Map<String, dynamic> hotel,
    required String contentHtml,
    required String policyHtml,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final greyText = isDark ? Colors.white70 : Colors.grey[800];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contentHtml.isNotEmpty)
          Html(
            data: contentHtml,
            style: {
              "html": Style(
                backgroundColor: Colors.transparent,
              ),
              "body": Style(
                backgroundColor: Colors.transparent,
              ),
              "p": Style(
                fontSize: FontSize(15),
                lineHeight: LineHeight(1.7),
                color: greyText,
              ),
              "strong": Style(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            },
          ),
        if (policyHtml.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            "Chính sách & lưu ý",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Html(
            data: policyHtml,
            style: {
              "html": Style(
                backgroundColor: Colors.transparent,
              ),
              "body": Style(
                backgroundColor: Colors.transparent,
              ),
              "p": Style(
                fontSize: FontSize(15),
                lineHeight: LineHeight(1.6),
                color: greyText,
              ),
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLocationFacilityTab({
    required Map<String, dynamic> hotel,
    required String address,
    required String? lat,
    required String? lng,
    required List<dynamic> attributes,
    required List<dynamic> rawTerms,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final greyText = isDark ? Colors.white70 : Colors.grey[800];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (address.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 20, color: Colors.blue[400]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: greyText,
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 12),

        if (lat != null &&
            lng != null &&
            lat.isNotEmpty &&
            lng.isNotEmpty)
          _buildMapPreview(lat, lng, isDark),

        const SizedBox(height: 18),

        if (attributes.isNotEmpty || rawTerms.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiện nghi & dịch vụ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAmenitiesSection(attributes, rawTerms, isDark),
        ],
      ],
    );
  }

  Widget _buildReviewTab({
    required BuildContext context,
    required double score,
    required int reviewCount,
    required List<dynamic> reviews,
    required bool isDark,
  }) {
    if (score <= 0 && reviews.isEmpty) {
      return Text(
        getTranslated('no_reviews_yet', context) ??
            'Chưa có đánh giá nào.',
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      );
    }

    return HotelReviewSection(
      score: score,
      reviewCount: reviewCount,
      reviews: reviews,
    );
  }

  Widget _buildBasicInfoSection(Map<String, dynamic> hotel, bool isDark) {
    final String starText = (hotel['star_rate'] ??
        hotel['star'] ??
        hotel['review_score_total'] ??
        '')
        .toString();
    final String checkIn =
    (hotel['check_in_time'] ?? hotel['check_in'] ?? '').toString();
    final String checkOut =
    (hotel['check_out_time'] ?? hotel['check_out'] ?? '').toString();
    final String minNight =
    (hotel['min_night'] ?? hotel['min_stay'] ?? '').toString();

    final List<Widget> items = [];

    if (starText.isNotEmpty) {
      items.add(_buildInfoChip(
        icon: Icons.hotel_class_rounded,
        label: "$starText sao",
        isDark: isDark,
      ));
    }
    if (checkIn.isNotEmpty) {
      items.add(_buildInfoChip(
        icon: Icons.login_rounded,
        label: "Nhận phòng: $checkIn",
        isDark: isDark,
      ));
    }
    if (checkOut.isNotEmpty) {
      items.add(_buildInfoChip(
        icon: Icons.logout_rounded,
        label: "Trả phòng: $checkOut",
        isDark: isDark,
      ));
    }
    if (minNight.isNotEmpty) {
      items.add(_buildInfoChip(
        icon: Icons.nights_stay_rounded,
        label: "Tối thiểu $minNight đêm",
        isDark: isDark,
      ));
    }

    if (items.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items,
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final bg = isDark ? const Color(0xFF1D2025) : Colors.grey[50];
    final border = isDark ? Colors.white10 : Colors.grey[200];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(String lat, String lng, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1F23) : Colors.white;

    final double? latVal = double.tryParse(lat);
    final double? lngVal = double.tryParse(lng);

    // Nếu toạ độ lỗi thì fallback về card cũ
    if (latVal == null || lngVal == null) {
      return GestureDetector(
        onTap: () =>
            launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng')),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          height: 190,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: isDark ? const Color(0xFF25272C) : Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.map_rounded,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              _buildMapOverlayBar(),
            ],
          ),
        ),
      );
    }

    // ✅ Map thật với FlutterMap + marker tại vị trí khách sạn
    final LatLng center = LatLng(latVal, lngVal);

    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng')),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        height: 190,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              fm.FlutterMap(
                options: fm.MapOptions(
                  initialCenter: center,
                  initialZoom: 15,
                ),
                children: [
                  fm.TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vnshop.vietnamtoure',
                  ),
                  fm.MarkerLayer(
                    markers: [
                      fm.Marker(
                        point: center,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 26,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              _buildMapOverlayBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapOverlayBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Row(
              children: [
                Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Google Maps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              'Xem bản đồ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection(
      List<dynamic> attributes, List<dynamic> rawTerms, bool isDark) {
    final List<Widget> sections = [];

    for (final attr in attributes) {
      if (attr is Map) {
        sections.add(
          _buildAttributeSection(
            Map<String, dynamic>.from(attr as Map),
            isDark,
          ),
        );
      }
    }

    if (rawTerms.isNotEmpty) {
      sections.add(const SizedBox(height: 8));
      sections.add(
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: rawTerms.map((t) {
            final name = (t is Map)
                ? (t['translation']?['name'] ??
                t['name'] ??
                t['display_name'] ??
                '')
                .toString()
                : t.toString();

            if (name.isEmpty) return const SizedBox.shrink();

            return _buildAmenityChip(name, isDark);
          }).toList(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _buildAmenityChip(String name, bool isDark) {
    final bg = isDark ? const Color(0xFF1E1F23) : Colors.white;
    final border = isDark ? Colors.white10 : Colors.blue[100];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border!),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.blue.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeSection(
      Map<String, dynamic> attr, bool isDark) {
    final terms = attr['terms'] as List? ?? [];
    if (terms.isEmpty) return const SizedBox();

    IconData sectionIcon = Icons.check_circle_outline_rounded;
    String attrName = (attr['name'] ?? '').toString().trim();

    if (attrName.toLowerCase().contains('loại') ||
        attrName.toLowerCase().contains('property')) {
      sectionIcon = Icons.apartment_rounded;
    } else if (attrName.toLowerCase().contains('tiện') ||
        attrName.toLowerCase().contains('facilities')) {
      sectionIcon = Icons.spa_rounded;
    } else if (attrName.toLowerCase().contains('dịch vụ') ||
        attrName.toLowerCase().contains('service')) {
      sectionIcon = Icons.room_service_rounded;
    }

    final titleColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(sectionIcon, size: 18, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              attrName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: terms.asMap().entries.map((entry) {
            final index = entry.key;
            final term = entry.value;
            final name = (term is Map)
                ? (term['translation']?['name'] ??
                term['name'] ??
                term['display_name'] ??
                '')
                .toString()
                : term.toString();

            if (name.isEmpty) return const SizedBox.shrink();

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 250 + (index * 40)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final double opacity = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                );
              },
              child: _buildAmenityChip(name, isDark),
            );
          }).toList(),
        ),
      ],
    );
  }
}