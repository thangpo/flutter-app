import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/widgets/banners_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/widgets/category_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/home_screens.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/featured_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/announcement_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/menu_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/search_home_page_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/latest_product_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/screens/search_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_story_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/flight_booking_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/flight_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/tour_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/tour_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/duffel_service.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  late Future<List<dynamic>> _toursFuture;
  late Future<List<dynamic>> _flightsFuture;

  @override
  void initState() {
    super.initState();
    _ensureBaseData();
    _toursFuture = _fetchTours();
    _flightsFuture = _fetchFlights();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final social = context.read<SocialController>();
      social.loadCurrentUser();
      if (social.posts.isEmpty || social.stories.isEmpty) {
        social.refresh();
      }
    });
  }

  void _ensureBaseData() {
    // HomePage.loadData uses global navigator context; kick it asynchronously to avoid blocking init.
    scheduleMicrotask(() => HomePage.loadData(false));
  }

  Future<List<dynamic>> _fetchTours() async {
    try {
      final data = await TourService.fetchTours();
      return data.take(10).toList();
    } catch (e) {
      debugPrint('Failed to load tours: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> _fetchFlights() async {
    final now = DateTime.now().add(const Duration(days: 3));
    final departure = DateFormat('yyyy-MM-dd').format(now);
    try {
      final offers = await DuffelService.searchFlights(
        fromCode: 'SGN',
        toCode: 'HAN',
        departureDate: departure,
        adults: 1,
      );
      return offers.take(10).toList();
    } catch (e) {
      debugPrint('Failed to load flights: $e');
      rethrow;
    }
  }

  Future<void> _onRefresh() async {
    final tours = _fetchTours();
    final flights = _fetchFlights();
    final socialRefresh = context.read<SocialController>().refresh();
    setState(() {
      _toursFuture = tours;
      _flightsFuture = flights;
    });
    await Future.wait([
      HomePage.loadData(true),
      tours,
      flights,
      socialRefresh,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final splash = Provider.of<SplashController>(context, listen: false);
    final announcementEnabled = splash.configModel?.announcement?.status == '1';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                elevation: 0,
                centerTitle: false,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).highlightColor,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(Images.logoWithNameImage, height: 35),
                    const MenuWidget(),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: announcementEnabled
                    ? Consumer<SplashController>(
                        builder: (context, splashCtrl, _) {
                          final data = splashCtrl
                              .configModel?.announcement?.announcement;
                          if (data != null && splashCtrl.onOff) {
                            return AnnouncementWidget(
                                announcement:
                                    splashCtrl.configModel!.announcement);
                          }
                          return const SizedBox.shrink();
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverDelegate(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: const Hero(
                      tag: 'search',
                      child: Material(child: SearchHomePageWidget()),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: Dimensions.paddingSizeDefault,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BannersWidget(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      TourCarouselSection(future: _toursFuture),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      const CategoryListWidget(isHomePage: true),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      const LatestProductsSection(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      const FeaturedProductsSection(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      const SocialStoriesSection(),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      FlightCarouselSection(future: _flightsFuture),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      const TopSocialPostsSection(),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),
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
}

class TourCarouselSection extends StatelessWidget {
  final Future<List<dynamic>> future;
  const TourCarouselSection({super.key, required this.future});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoadingSkeleton(height: 220);
        }
        if (snapshot.hasError) {
          return _SectionError(
            message: getTranslated('failed_to_load_tours', context) ??
                'Khong the tai tour moi.',
          );
        }
        final tours = snapshot.data ?? <dynamic>[];
        if (tours.isEmpty) {
          return const _SectionError(
            message: 'Chua co tour nao.',
            compact: true,
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitleRowWidget(
                title: getTranslated('new_tours', context) ?? 'Tour moi nhat',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TourListScreen()),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CarouselSlider.builder(
                options: CarouselOptions(
                  height: 230,
                  viewportFraction: 0.78,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.18,
                ),
                itemCount: tours.length,
                itemBuilder: (context, index, realIndex) {
                  return _TourCard(
                    data: tours[index],
                    theme: theme,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class LatestProductsSection extends StatelessWidget {
  const LatestProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const LatestProductListWidget();
  }
}

class FeaturedProductsSection extends StatelessWidget {
  const FeaturedProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturedProductWidget();
  }
}

class SocialStoriesSection extends StatelessWidget {
  const SocialStoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      child: Consumer<SocialController>(
        builder: (context, controller, _) {
          final stories = controller.stories;
          final hasStories = stories.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitleRowWidget(
                title: getTranslated('social_stories', context) ??
                    'Social stories',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SocialFeedScreen()),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hasStories ? stories.length + 1 : 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _CreateStoryCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SocialCreateStoryScreen(),
                          ),
                        ),
                      );
                    }
                    final story = stories[index - 1];
                    if (story.items.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _StoryPreviewCard(
                      story: story,
                      onTap: () {
                        final List<SocialStory> ordered =
                            List<SocialStory>.from(controller.stories);
                        final startIndex = ordered
                            .indexWhere((element) => element.id == story.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SocialStoryViewerScreen(
                              stories: ordered,
                              initialStoryIndex:
                                  startIndex >= 0 ? startIndex : 0,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FlightCarouselSection extends StatelessWidget {
  final Future<List<dynamic>> future;
  const FlightCarouselSection({super.key, required this.future});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoadingSkeleton(height: 210);
        }
        if (snapshot.hasError) {
          return _SectionError(
            message: getTranslated('failed_to_load_flights', context) ??
                'Khong the tai ve may bay.',
          );
        }

        final flights = snapshot.data ?? <dynamic>[];
        if (flights.isEmpty) {
          return const _SectionError(
            message: 'Chua co ve may bay phu hop.',
            compact: true,
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitleRowWidget(
                title:
                    getTranslated('featured_flights', context) ?? 'Ve may bay',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FlightBookingScreen()),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: flights.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                  itemBuilder: (context, index) => _FlightOfferCard(
                    offer: flights[index],
                    theme: theme,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TopSocialPostsSection extends StatelessWidget {
  const TopSocialPostsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const horizontal = Dimensions.paddingSizeDefault;
    return Consumer<SocialController>(
      builder: (context, controller, _) {
        final List<SocialPost> posts = controller.posts;
        final bool loading = controller.loading && posts.isEmpty;
        if (loading) {
          return const _SectionLoadingSkeleton(height: 260);
        }
        final List<SocialPost> topPosts = _selectTopSocialPosts(posts);
        if (topPosts.isEmpty) {
          return _SectionError(
            message: getTranslated('no_popular_posts', context) ??
                'Chua co bai viet noi bat.',
            compact: true,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontal),
              child: TitleRowWidget(
                title: getTranslated('top_social_posts', context) ??
                    'Bai viet noi bat',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SocialFeedScreen()),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            for (int i = 0; i < topPosts.length; i++) ...[
              SocialPostCard(post: topPosts[i]),
              if (i != topPosts.length - 1)
                const SizedBox(height: Dimensions.paddingSizeSmall),
            ],
          ],
        );
      },
    );
  }
}

List<SocialPost> _selectTopSocialPosts(List<SocialPost> source) {
  if (source.isEmpty) return const <SocialPost>[];
  final sorted = List<SocialPost>.from(source);
  sorted.sort((a, b) {
    final int reactionCompare = b.reactionCount.compareTo(a.reactionCount);
    if (reactionCompare != 0) {
      return reactionCompare;
    }
    final int bTime = _postTimestampValue(b);
    final int aTime = _postTimestampValue(a);
    return bTime.compareTo(aTime);
  });
  final top = sorted.take(6).toList();
  top.sort((a, b) => _postTimestampValue(b).compareTo(_postTimestampValue(a)));
  return top;
}

int _postTimestampValue(SocialPost post) {
  final DateTime? dt = _resolvePostTime(post.timeText);
  if (dt != null) {
    return dt.millisecondsSinceEpoch;
  }
  return int.tryParse(post.id) ?? 0;
}

DateTime? _resolvePostTime(String? raw) {
  if (raw == null) return null;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final int? value = int.tryParse(trimmed);
  if (value == null) return null;
  if (value >= 1000000000000) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value >= 1000000000) {
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }
  return DateTime.now().subtract(Duration(seconds: value));
}

class _TourCard extends StatelessWidget {
  final dynamic data;
  final ThemeData theme;

  const _TourCard({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final image = data['image_url'] ?? data['cover_image'];
    final title = data['title'] ?? 'Tour';
    final location = data['location'] ?? data['destination'] ?? 'Vietnam';
    final duration = data['duration'] ?? data['time'] ?? '';
    final price = _formatPrice(data['price']);

    return InkWell(
      onTap: () {
        final dynamic id = data['id'];
        if (id != null) {
          final int? parsedId = id is int ? id : int.tryParse(id.toString());
          if (parsedId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TourDetailScreen(tourId: parsedId),
              ),
            );
            return;
          }
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TourListScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: image != null && image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: theme.dividerColor),
                        errorWidget: (_, __, ___) =>
                            Container(color: theme.dividerColor),
                      )
                    : Container(color: theme.dividerColor),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (duration.toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                duration,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            price,
                            style: TextStyle(
                              color: theme.primaryColorDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
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

  String _formatPrice(dynamic raw) {
    if (raw == null) return 'Lien he';
    try {
      final num price = raw is num ? raw : double.tryParse(raw.toString()) ?? 0;
      if (price == 0) return 'Lien he';
      final formatter =
          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
      return formatter.format(price);
    } catch (_) {
      return 'Lien he';
    }
  }
}

class _FlightOfferCard extends StatelessWidget {
  final dynamic offer;
  final ThemeData theme;

  const _FlightOfferCard({required this.offer, required this.theme});

  @override
  Widget build(BuildContext context) {
    final owner = offer['owner']?['name'] ?? 'Airline';
    final slices = (offer['slices'] as List?) ?? const [];
    final firstSlice = slices.isNotEmpty ? slices.first : null;
    final segments = (firstSlice?['segments'] as List?) ?? const [];
    final firstSegment = segments.isNotEmpty ? segments.first : null;
    final from = firstSlice?['origin']?['iata_code'] ?? 'SGN';
    final to = firstSlice?['destination']?['iata_code'] ?? 'HAN';
    final departureIso = firstSegment?['departing_at'];
    final arrivalIso = firstSegment?['arriving_at'];
    final price = '${offer['total_amount']} ${offer['total_currency']}';
    final cabin = offer['cabin_class'] ?? 'economy';

    return InkWell(
      onTap: () {
        final id = offer['id'];
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlightDetailScreen(flightId: id),
            ),
          );
        }
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
                  child: Text(
                    owner.isNotEmpty ? owner[0] : '?',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    owner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(departureIso),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        from,
                        style: TextStyle(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.flight_takeoff, color: theme.primaryColor, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(arrivalIso),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        to,
                        style: TextStyle(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    cabin.toString().toUpperCase(),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic isoString) {
    if (isoString == null) return '--:--';
    try {
      final date = DateTime.parse(isoString.toString()).toLocal();
      return DateFormat.Hm().format(date);
    } catch (_) {
      return '--:--';
    }
  }
}

class _CreateStoryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateStoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              getTranslated('create_story', context) ?? 'Create story',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPreviewCard extends StatelessWidget {
  final SocialStory story;
  final VoidCallback onTap;

  const _StoryPreviewCard({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = story.thumbUrl ?? story.mediaUrl;
    final name = story.userName ?? 'Story';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: image != null && image.isNotEmpty
                    ? Image.network(
                        image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: theme.dividerColor),
                      )
                    : Container(
                        color: theme.dividerColor,
                        child: Icon(
                          Icons.auto_stories,
                          color: theme.hintColor,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLoadingSkeleton extends StatelessWidget {
  final double height;
  const _SectionLoadingSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).dividerColor.withValues(alpha: 0.18);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final bool compact;
  const _SectionError({required this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: compact
            ? Dimensions.paddingSizeSmall
            : Dimensions.paddingSizeDefault,
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  SliverDelegate({required this.child, this.height = 70});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}
