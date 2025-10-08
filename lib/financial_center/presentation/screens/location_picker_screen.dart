import 'package:flutter/material.dart';

class LocationPickerScreen extends StatelessWidget {
  final String title;
  final Function(Map<String, String>) onLocationSelected;

  const LocationPickerScreen({
    super.key,
    required this.title,
    required this.onLocationSelected,
  });

  static const Color oceanBlue = Color(0xFF0891B2);
  static const Color oceanLight = Color(0xFF06B6D4);
  static const Color oceanDark = Color(0xFF0E7490);

  @override
  Widget build(BuildContext context) {
    final popularLocations = [
      {"city": "Hồ Chí Minh", "code": "SGN"},
      {"city": "Hà Nội", "code": "HAN"},
      {"city": "Đà Nẵng", "code": "DAD"},
      {"city": "Vinh", "code": "VII"},
      {"city": "Huế", "code": "HUI"},
      {"city": "Hải Phòng", "code": "HPH"},
      {"city": "Bangkok", "code": "BKK"},
      {"city": "Singapore", "code": "SIN"},
      {"city": "Phnom Penh", "code": "PNH"},

      // Các điểm quốc tế phổ biến của American Airlines
      {"city": "New York (JFK)", "code": "JFK"},
      {"city": "Los Angeles", "code": "LAX"},
      {"city": "Chicago", "code": "ORD"},
      {"city": "Dallas/Fort Worth", "code": "DFW"},
      {"city": "Miami", "code": "MIA"},
      {"city": "London", "code": "LHR"},
      {"city": "Tokyo", "code": "HND"},
      {"city": "Paris", "code": "CDG"},
      {"city": "Madrid", "code": "MAD"},
    ];

    final trendingDestinations = [
      {
        "city": "Phú Quốc",
        "code": "PQC",
        "subtitle": "Giá thấp nhất trong năm",
        "price": "730.600đ",
        "image": "https://cdn.pixabay.com/photo/2016/11/29/05/55/beach-1867271_1280.jpg"
      },
      {
        "city": "Seoul",
        "code": "ICN",
        "subtitle": "Pháo Hoa Quốc tế Seoul 27/9",
        "price": "1.914.000đ",
        "image": "https://cdn.pixabay.com/photo/2016/11/23/14/45/fireworks-1850745_1280.jpg"
      },
      {
        "city": "Bangkok",
        "code": "BKK",
        "subtitle": "Lễ hội đèn lồng Loy Krathong 05/11",
        "price": "1.473.000đ",
        "image": "https://cdn.pixabay.com/photo/2018/11/12/19/04/thailand-3810780_1280.jpg"
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: oceanBlue,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [oceanBlue, oceanLight.withOpacity(0.1)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: oceanBlue.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Nhập thành phố hoặc sân bay",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: oceanBlue, size: 24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: oceanLight.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: oceanLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.my_location,
                              color: oceanBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Vị trí hiện tại của bạn",
                            style: TextStyle(
                              color: oceanDark,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: oceanBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Địa điểm phổ biến",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: popularLocations.map((loc) {
                  return InkWell(
                    onTap: () {
                      final data = {
                        "city": loc["city"]!,
                        "code": loc["code"]!,
                      };
                      onLocationSelected(data);
                      Navigator.pop(context, data);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: oceanLight.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: oceanLight.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loc["city"]!,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            loc["code"]!,
                            style: TextStyle(
                              color: oceanBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: oceanBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Top xu hướng",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: trendingDestinations.length,
              itemBuilder: (context, index) {
                final item = trendingDestinations[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final data = {
                          "city": item["city"]!,
                          "code": item["code"]!,
                        };
                        onLocationSelected(data);
                        Navigator.pop(context, data);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item["image"]!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: oceanLight.withOpacity(0.1),
                                    child: Icon(
                                      Icons.image,
                                      color: oceanBlue,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item["city"]!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: oceanLight.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item["code"]!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: oceanDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item["subtitle"]!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        "Từ ",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      Text(
                                        item["price"]!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: oceanBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: oceanLight,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}