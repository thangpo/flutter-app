import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'hotel_rooms_section.dart';
import 'hotel_review_section.dart';

class HotelDetailBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _buildHotelInfo(context, hotel);
  }

  Widget _buildHotelInfo(BuildContext context, Map<String, dynamic> hotel) {
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

    // Map term_id -> tên term để map cho room
    final Map<int, String> roomTermNameMap = {};
    for (final attr in attributes) {
      if (attr is Map && attr['terms'] is List) {
        for (final t in (attr['terms'] as List)) {
          if (t is Map) {
            final int? termId = int.tryParse(t['id']?.toString() ?? '');
            final String name = (t['translation']?['name'] ??
                t['name'] ??
                '')
                .toString();
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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Header: tên, điểm, vị trí, giá ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Score
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (score > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  score.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (reviewCount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '$reviewCount đánh giá',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Location
                if (locationText.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationText,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Price card
                if (priceText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Giá từ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$priceText ₫",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// --- Thông tin tổng quan (sao, check-in/out, min night) ---
          _buildBasicInfoSection(hotel),

          /// --- Mô tả ---
          if (contentHtml.isNotEmpty)
            _buildSection(
              title: "Mô tả",
              icon: Icons.description_rounded,
              child: Html(
                data: contentHtml,
                style: {
                  "p": Style(
                    fontSize: FontSize(15),
                    lineHeight: LineHeight(1.7),
                    color: Colors.grey[800],
                  ),
                  "strong": Style(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                },
              ),
            ),

          /// --- Địa chỉ ---
          if (address.isNotEmpty)
            _buildSection(
              title: "Địa chỉ",
              icon: Icons.location_city_rounded,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.pin_drop_rounded,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          /// --- Map preview ---
          if (lat != null &&
              lng != null &&
              lat.isNotEmpty &&
              lng.isNotEmpty)
            _buildMapPreview(lat, lng),

          /// --- Amenities ---
          if (attributes.isNotEmpty || rawTerms.isNotEmpty)
            _buildAmenitiesSection(attributes, rawTerms),

          /// --- Rooms (gắn key ở đây) ---
          if (rooms.isNotEmpty)
            HotelRoomsSection(
              key: roomsSectionKey,
              hotelId: hotel['id'] ?? 0,
              rooms: rooms,
              roomTermNameMap: roomTermNameMap,
              onBookingSummaryChanged: onBookingSummaryChanged,
            ),

          /// --- Reviews ---
          if (score > 0 || reviews.isNotEmpty)
            HotelReviewSection(
              score: score,
              reviewCount: reviewCount,
              reviews: reviews,
            ),

          /// --- Policy ---
          if (policyHtml.isNotEmpty)
            _buildSection(
              title: "Chính sách & lưu ý",
              icon: Icons.rule_folder_rounded,
              child: Html(
                data: policyHtml,
                style: {
                  "p": Style(
                    fontSize: FontSize(15),
                    lineHeight: LineHeight(1.6),
                    color: Colors.grey[800],
                  ),
                },
              ),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Colors.blue[700]),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(Map<String, dynamic> hotel) {
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
      ));
    }
    if (checkIn.isNotEmpty) {
      items.add(_buildInfoChip(
        icon: Icons.login_rounded,
        label: "Nhận phòng: $checkIn",
      ));
    }
    if (checkOut.isNotEmpty) {
      items.add(_buildInfoChip(
        icon: Icons.logout_rounded,
        label: "Trả phòng: $checkOut",
      ));
    }
    if (minNight.isNotEmpty) {
      items.add(_buildInfoChip(
        icon: Icons.nights_stay_rounded,
        label: "Tối thiểu $minNight đêm",
      ));
    }

    if (items.isEmpty) return const SizedBox();

    return _buildSection(
      title: "Thông tin tổng quan",
      icon: Icons.info_outline_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items,
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(String lat, String lng) {
    return _buildSection(
      title: "Vị trí trên bản đồ",
      icon: Icons.map_rounded,
      child: GestureDetector(
        onTap: () =>
            launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng')),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.map_rounded,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.blue[700]!.withOpacity(0.95),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Nhấn để xem trên Google Maps',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection(
      List<dynamic> attributes,
      List<dynamic> rawTerms,
      ) {
    final List<Widget> sections = [];

    for (final attr in attributes) {
      if (attr is Map) {
        sections.add(
          _buildAttributeSection(
            Map<String, dynamic>.from(attr as Map),
          ),
        );
      }
    }

    if (rawTerms.isNotEmpty) {
      sections.add(
        _buildSection(
          title: "Tiện nghi",
          icon: Icons.spa_rounded,
          child: Wrap(
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

              return _buildAmenityChip(name);
            }).toList(),
          ),
        ),
      );
    }

    return Column(children: sections);
  }

  Widget _buildAmenityChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeSection(Map<String, dynamic> attr) {
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

    return _buildSection(
      title: attrName,
      icon: sectionIcon,
      child: Wrap(
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
            duration: Duration(milliseconds: 300 + (index * 50)),
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
            child: _buildAmenityChip(name),
          );
        }).toList(),
      ),
    );
  }
}