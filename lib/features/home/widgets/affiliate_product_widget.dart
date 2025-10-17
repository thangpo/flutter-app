import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/services/api_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/product_detail_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AffiliateProductWidget extends StatefulWidget {
  const AffiliateProductWidget({super.key});

  @override
  State<AffiliateProductWidget> createState() => _AffiliateProductWidgetState();
}

class _AffiliateProductWidgetState extends State<AffiliateProductWidget> {
  final ApiService apiService = ApiService();
  late Future<List<dynamic>> _products;

  final PageController _bannerController = PageController();
  final PageController _featuredController = PageController();
  Timer? _bannerAutoScrollTimer;
  Timer? _featuredAutoScrollTimer;
  int _currentBannerPage = 0;
  int _currentFeaturedPage = 0;

  final formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _products = apiService.fetchProducts();
  }

  @override
  void dispose() {
    _bannerAutoScrollTimer?.cancel();
    _featuredAutoScrollTimer?.cancel();
    _bannerController.dispose();
    _featuredController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll(int totalPages) {
    _bannerAutoScrollTimer?.cancel();
    _bannerAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentBannerPage < totalPages - 1) {
        _currentBannerPage++;
      } else {
        _currentBannerPage = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startFeaturedAutoScroll(int totalPages) {
    _featuredAutoScrollTimer?.cancel();
    _featuredAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentFeaturedPage < totalPages - 1) {
        _currentFeaturedPage++;
      } else {
        _currentFeaturedPage = 0;
      }
      if (_featuredController.hasClients) {
        _featuredController.animateToPage(
          _currentFeaturedPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _products,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đang tải sản phẩm...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  "Lỗi: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "Không có sản phẩm",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        } else {
          final items = snapshot.data!;

          // Chia nhóm sản phẩm
          final vip1 = items.take(8).toList(); // Lấy 8 sản phẩm cho featured
          final vip2 = items.length > 8 ? items.skip(8).take(8).toList() : [];
          final vip3 = items.length > 16 ? items.skip(16).toList() : [];

          // Khởi động auto-scroll
          if (vip2.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final totalPages = (vip2.length / 2).ceil();
              _startBannerAutoScroll(totalPages);
            });
          }

          if (vip1.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final totalPages = (vip1.length / 4).ceil();
              _startFeaturedAutoScroll(totalPages);
            });
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey.shade50, Colors.white],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vip2.isNotEmpty) ...[
                    _buildPromotionalBanner(vip2),
                    const SizedBox(height: 16),
                  ],

                  if (vip1.isNotEmpty) ...[
                    _buildFeaturedBanner(vip1),
                    const SizedBox(height: 24),
                  ],

                  if (vip3.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: "Khám phá thêm",
                      subtitle: "Nhiều lựa chọn hơn",
                      icon: Icons.explore,
                      color: Colors.green,
                    ),
                    GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: vip3.length,
                      itemBuilder: (context, index) {
                        return _buildExploreCard(context, vip3[index]);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildPromotionalBanner(List<dynamic> products) {
    final totalPages = (products.length / 2).ceil();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      height: 215,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade600,
            Colors.purple.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade300.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, color: Colors.orange.shade600, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Ưu đãi đặc biệt',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _bannerController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBannerPage = index;
                      });
                    },
                    itemCount: totalPages,
                    itemBuilder: (context, pageIndex) {
                      final startIndex = pageIndex * 2;
                      final endIndex = (startIndex + 2).clamp(0, products.length);
                      final pageProducts = products.sublist(startIndex, endIndex);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: pageProducts.map((product) {
                            return Expanded(
                              child: _buildBannerProductCard(product),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalPages, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentBannerPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentBannerPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner(List<dynamic> products) {
    final totalPages = (products.length / 4).ceil();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      height: 450,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade300.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Sản phẩm nổi bật',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Products PageView - 4 sản phẩm
                Expanded(
                  child: PageView.builder(
                    controller: _featuredController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentFeaturedPage = index;
                      });
                    },
                    itemCount: totalPages,
                    itemBuilder: (context, pageIndex) {
                      final startIndex = pageIndex * 4;
                      final endIndex = (startIndex + 4).clamp(0, products.length);
                      final pageProducts = products.sublist(startIndex, endIndex);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: pageProducts.length,
                          itemBuilder: (context, index) {
                            return _buildFeaturedProductCard(pageProducts[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Page Indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalPages, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentFeaturedPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentFeaturedPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerProductCard(dynamic product) {
    final imageUrl = product["image"] ?? "";
    final name = product["name"] ?? "";
    final price = (product["price"] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => _navigateToDetail(context, product),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 70,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_outlined, size: 28, color: Colors.grey.shade400),
                ),
              ),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formatter.format(price),
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProductCard(dynamic product) {
    final imageUrl = product["image"] ?? "";
    final name = product["name"] ?? "";
    final price = (product["price"] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => _navigateToDetail(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatter.format(price),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(BuildContext context, dynamic p) {
    final imageUrl = p["image"] ?? "";
    final name = p["name"] ?? "";
    final price = (p["price"] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => _navigateToDetail(context, p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        height: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formatter.format(price),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, dynamic p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          sku: p["sku"],
          domain: p["domain"],
        ),
      ),
    );
  }
}