import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hotel_service.dart';
import '../widgets/hotel_detail_body.dart';
import '../widgets/hotel_book_button.dart';
import '../widgets/hotel_detail_app_bar.dart';
import '../screens/hotel_checkout_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import '../widgets/hotel_rooms_section.dart' show HotelBookingSummary, HotelSelectedRoom;

class HotelDetailScreen extends StatefulWidget {
  final String slug;

  const HotelDetailScreen({super.key, required this.slug});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen>
    with TickerProviderStateMixin {
  final HotelService _hotelService = HotelService();
  late Future<Map<String, dynamic>> _hotelFuture;

  String _tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  late AnimationController _animationController;
  late AnimationController _fabController;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _roomsSectionKey = GlobalKey();

  int _currentImageIndex = 0;

  HotelBookingSummary? _bookingSummary;

  Map<String, dynamic>? _hotelDetail;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _refreshHotel();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshHotel() async {
    try {
      final future = _hotelService.fetchHotelDetail(widget.slug);

      setState(() {
        _hotelFuture = future;
      });
      _animationController.forward(from: 0);

      final hotel = await future;
      if (!mounted) return;
      setState(() {
        _hotelDetail = hotel;
      });
    } catch (_) {

    }
  }

  void _scrollToRooms() {
    final ctx = _roomsSectionKey.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  String _formatVndPrice(num value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: true);
    final isDark = theme.darkTheme;

    final totalRoomsSelected = _bookingSummary?.totalRooms ?? 0;

    final scaffoldBg = isDark ? const Color(0xFF0E1012) : Colors.grey[50];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _refreshHotel,
        color: isDark ? Colors.blue[400] : Colors.blue[700],
        child: FutureBuilder<Map<String, dynamic>>(
          future: _hotelFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmer(isDark);
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildError(context, snapshot.error?.toString(), isDark);
            }

            final hotel = snapshot.data!;
            return _buildContent(hotel);
          },
        ),
      ),
      floatingActionButton: HotelBookButton(
        totalRoomsSelected: totalRoomsSelected,
        onPressed: () => _onBookNowPressed(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildShimmer(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        children: [
          Container(height: 350, color: isDark ? Colors.grey[900] : Colors.white),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 250,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 180,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String? error, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.grey[600];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          ),
          const SizedBox(height: 24),
          Text(
            getTranslated("error", context) ?? "Lỗi tải dữ liệu",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error,
                style: TextStyle(color: subText),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshHotel,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              getTranslated('retry', context) ?? "Thử lại",
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> hotel) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        HotelDetailAppBar(
          hotel: hotel,
          currentImageIndex: _currentImageIndex,
          onImageIndexChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
        ),
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final curvedValue =
              Curves.easeOutCubic.transform(_animationController.value);
              return Opacity(
                opacity: curvedValue,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - curvedValue)),
                  child: HotelDetailBody(
                    hotel: hotel,
                    roomsSectionKey: _roomsSectionKey,
                    onBookingSummaryChanged: (summary) {
                      setState(() {
                        _bookingSummary = summary;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onBookNowPressed(BuildContext context) {
    final summary = _bookingSummary;
    if (summary == null || summary.totalRooms == 0) {
      _scrollToRooms();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _tr(context, 'please_select_room_before_booking', 'Vui lòng chọn phòng trước khi đặt.')
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final bookingData = _hotelDetail != null
        ? _hotelDetail!['booking_data'] as Map<String, dynamic>?
        : null;

    _showBookingDialog(context, summary, bookingData);
  }

  void _showBookingDialog(
      BuildContext context,
      HotelBookingSummary summary,
      Map<String, dynamic>? bookingData,
      ) {
    final bool canEditStayInfo = true;

    DateTime? start = summary.startDate;
    DateTime? end = summary.endDate;
    int adults = summary.adults;
    int children = summary.children;

    List<HotelSelectedRoom> rooms =
    List<HotelSelectedRoom>.from(summary.rooms);

    final clearAllRooms = summary.clearAllRooms;
    final removeRoom = summary.removeRoom;

    final List<Map<String, dynamic>> extraPriceItems =
        (bookingData?['extra_price'] as List?)
            ?.where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
            [];

    final List<Map<String, dynamic>> buyerFeeItems =
        (bookingData?['buyer_fees'] as List?)
            ?.where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
            [];

    final int hotelId = () {
      final raw = bookingData?['object_id'];
      if (raw is int) return raw;
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) return parsed;
      }
      final raw2 = _hotelDetail?['id'];
      if (raw2 is int) return raw2;
      if (raw2 is String) {
        final parsed2 = int.tryParse(raw2);
        if (parsed2 != null) return parsed2;
      }
      return 0;
    }();

    List<bool> extraSelected =
    extraPriceItems.map((e) => (e['enable']?.toString() == '1')).toList();

    int currentStep = 0;
    final PageController pageController = PageController(initialPage: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Provider.of<ThemeController>(ctx, listen: true);
        final isDark = theme.darkTheme;
        final dialogBg = isDark ? const Color(0xFF181A1F) : Colors.white;

        return StatefulBuilder(
          builder: (ctx, setState) {
            final theme = Provider.of<ThemeController>(ctx, listen: true);
            final isDark = theme.darkTheme;

            final Color cardBg = isDark ? const Color(0xFF1E1F23) : Colors.grey[50]!;
            final Color cardBorder = isDark ? Colors.white10 : Colors.grey[200]!;
            final Color primaryText = isDark ? Colors.white : Colors.black87;
            final Color secondaryText = isDark ? Colors.white70 : Colors.grey[700]!;

            double _calcRoomLineTotal(HotelSelectedRoom r, int nights) {
              final int qty = r.quantity <= 0 ? 1 : r.quantity;
              final int usedNights = (nights > 0)
                  ? nights
                  : (r.nights != null && r.nights! > 0 ? r.nights! : 1);
              final double perNight = r.pricePerNight;

              return perNight * usedNights * qty;
            }

            int nights = 0;
            if (start != null && end != null) {
              nights = end!.difference(start!).inDays;
              if (nights < 1) nights = 1;
            }

            double roomsTotal = rooms.fold(
              0.0,
                  (sum, r) => sum + _calcRoomLineTotal(r, nights),
            );
            final bool hasRooms = rooms.isNotEmpty;

            double extrasTotal = 0;
            for (int i = 0; i < extraPriceItems.length; i++) {
              if (!extraSelected[i]) continue;
              final priceStr = extraPriceItems[i]['price']?.toString() ?? '0';
              final p = double.tryParse(
                  priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                  0;
              extrasTotal += p;
            }

            double buyerFeesTotal = 0;
            for (final fee in buyerFeeItems) {
              final priceStr = fee['price']?.toString() ?? '0';
              final p = double.tryParse(
                  priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                  0;
              buyerFeesTotal += p;
            }

            final double grandTotal =
                roomsTotal + extrasTotal + buyerFeesTotal;

            String dateText;
            if (start == null || end == null) {
              dateText = 'Chưa chọn';
            } else {
              final fmt = DateFormat('dd/MM/yyyy');
              dateText = '${fmt.format(start!)} - ${fmt.format(end!)}';
            }

            void goToStep(int step) {
              if (step < 0 || step > 3) return;
              setState(() {
                currentStep = step;
              });
              pageController.animateToPage(
                step,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }

            void handleNext() {
              if (currentStep == 0) {
                if (rooms.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          _tr(context, 'please_select_room', 'Bạn chưa chọn phòng nào. Vui lòng chọn phòng.')
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }
              }
              if (currentStep == 1) {
                if (start == null || end == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          _tr(context, 'please_select_checkin_checkout', 'Vui lòng chọn ngày nhận và trả phòng.')
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }
              }
              if (currentStep < 3) {
                goToStep(currentStep + 1);
              }
            }

            void onConfirmBooking() {
              if (start == null || end == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        _tr(context, 'please_select_checkin_checkout', 'Vui lòng chọn ngày nhận và trả phòng.')
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              final int diff = end!.difference(start!).inDays;
              if (diff < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        _tr(context, 'checkout_must_after_checkin_one_day',
                            'Ngày trả phòng phải sau ngày nhận phòng ít nhất 1 ngày.')
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              if (rooms.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        _tr(context, 'please_select_room', 'Bạn chưa chọn phòng nào. Vui lòng chọn phòng.')
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              final int requestedAdults = adults;
              final int requestedChildren = children;

              int adultsCapacity = 0;
              int childrenCapacity = 0;

              for (final r in rooms) {
                final int perRoomAdults =
                (r.adultsPerRoom ?? r.maxGuests ?? 0);
                final int perRoomChildren = (r.childrenPerRoom ?? 0);

                adultsCapacity += perRoomAdults * r.quantity;
                childrenCapacity += perRoomChildren * r.quantity;
              }

              if (requestedAdults > adultsCapacity ||
                  requestedChildren > childrenCapacity) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(
                      _tr(context, 'over_capacity_title', 'Vượt quá sức chứa'),
                    ),
                    content: Text(
                      _tr(
                        context,
                        'over_capacity_message',
                        'Số người lớn hoặc trẻ em vượt quá sức chứa '
                            'của các phòng đã chọn.\n'
                            'Vui lòng đặt thêm phòng hoặc chọn loại phòng khác.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
                return;
              }

              final List<Map<String, dynamic>> selectedExtras = [];
              for (int i = 0; i < extraPriceItems.length; i++) {
                if (extraSelected[i]) {
                  selectedExtras.add(extraPriceItems[i]);
                }
              }

              final hotelData = _hotelDetail ?? {};

              String? hotelImage;
              final gallery = hotelData['gallery'];
              if (gallery is List && gallery.isNotEmpty) {
                final first = gallery.first;
                if (first is Map) {
                  final u = (first['large'] ?? first['thumb'] ?? '').toString();
                  if (u.isNotEmpty) {
                    hotelImage = u;
                  }
                }
              }

              if (hotelImage == null || hotelImage.isEmpty) {
                if (hotelData['image_url'] is String &&
                    (hotelData['image_url'] as String).isNotEmpty) {
                  hotelImage = hotelData['image_url'] as String;
                } else if (hotelData['image'] is String &&
                    (hotelData['image'] as String).isNotEmpty) {
                  hotelImage = hotelData['image'] as String;
                } else if (hotelData['banner_image'] is String &&
                    (hotelData['banner_image'] as String).isNotEmpty) {
                  hotelImage = hotelData['banner_image'] as String;
                }
              }

              String? hotelLocation;
              final locRaw = hotelData['location'];
              if (locRaw is Map) {
                hotelLocation = (locRaw['name'] ?? locRaw['title'])?.toString();
              }
              hotelLocation ??= (hotelData['address'] ?? hotelData['map_address'] ?? '')?.toString();
              if (hotelLocation == 'null') hotelLocation = null;

              double? hotelRating;
              int? reviewCount;

              final reviewSummaryRaw = hotelData['review_summary'];
              if (reviewSummaryRaw is Map) {
                hotelRating = double.tryParse(
                  (reviewSummaryRaw['score'] ?? '').toString(),
                ) ??
                    0;
                reviewCount = int.tryParse(
                  (reviewSummaryRaw['total'] ??
                      reviewSummaryRaw['review_count'] ??
                      '')
                      .toString(),
                ) ??
                    0;
              } else {
                hotelRating = double.tryParse(
                  (hotelData['review_score'] ?? '').toString(),
                ) ??
                    0;
                reviewCount = int.tryParse(
                  (hotelData['review_count'] ?? '').toString(),
                ) ??
                    0;
              }

              Navigator.of(ctx).pop();

              Future.microtask(() {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HotelCheckoutScreen(
                      data: HotelCheckoutData(
                        hotelId: hotelId,
                        hotelSlug: widget.slug,
                        hotelName: _hotelDetail?['title']?.toString() ?? '',
                        checkIn: start!,
                        checkOut: end!,
                        nights: nights,
                        adults: requestedAdults,
                        children: requestedChildren,
                        rooms: rooms,
                        selectedExtras: selectedExtras,
                        buyerFees: buyerFeeItems,
                        roomsTotal: roomsTotal,
                        extrasTotal: extrasTotal,
                        buyerFeesTotal: buyerFeesTotal,
                        grandTotal: grandTotal,
                        hotelImage: hotelImage,
                        hotelRating: hotelRating,
                        reviewCount: reviewCount,
                        hotelLocation: hotelLocation,
                      ),
                    ),
                  ),
                );
              });
            }

            Future<void> pickDate(bool isStart) async {
              final now = DateTime.now();
              final initial = isStart ? (start ?? now) : (end ?? start ?? now);
              final firstDate = now;
              final lastDate = now.add(const Duration(days: 365));

              final picked = await showDatePicker(
                context: ctx,
                initialDate: initial,
                firstDate: firstDate,
                lastDate: lastDate,
              );

              if (picked == null) return;
              final rootScaffoldContext = context;

              if (isStart) {
                if (end != null && picked.isAfter(end!)) {
                  ScaffoldMessenger.of(rootScaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        _tr(rootScaffoldContext, 'checkin_cannot_after_checkout',
                            'Ngày nhận phòng không được sau ngày trả phòng'),
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }
                setState(() {
                  start = picked;
                });
              } else {
                if (start != null && picked.isBefore(start!)) {
                  ScaffoldMessenger.of(rootScaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        _tr(rootScaffoldContext, 'checkout_cannot_before_checkin',
                            'Ngày trả phòng không được trước ngày nhận phòng'),
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }
                setState(() {
                  end = picked;
                });
              }
            }

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          size: 22,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tr(ctx, 'confirm_booking_title', 'Xác nhận đặt phòng'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _buildStepTitle(context, currentStep),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 360,
                      child: PageView(
                        controller: pageController,
                        physics: hasRooms
                            ? const BouncingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            currentStep = index;
                          });
                        },
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated('selected_rooms', ctx) ?? 'Phòng đã chọn',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: primaryText,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        clearAllRooms?.call();
                                        setState(() {
                                          rooms.clear();
                                          if (currentStep != 0) {
                                            currentStep = 0;
                                            pageController.animateToPage(
                                              0,
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.delete_forever_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      label: Text(
                                        getTranslated('clear_all', ctx) ?? 'Hủy tất cả',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (rooms.isEmpty)
                                  Text(
                                    getTranslated('no_room_selected', ctx) ??
                                        'Chưa có phòng nào, vui lòng quay lại chọn phòng.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryText,
                                    ),
                                  )
                                else
                                  ...rooms.map((r) {
                                    final double lineTotal = _calcRoomLineTotal(r, nights);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: cardBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  r.name,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: primaryText,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${getTranslated('room_count', ctx) ?? 'Số phòng'}: ${r.quantity}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: secondaryText,
                                                  ),
                                                ),
                                                if (r.nights > 0)
                                                  Text(
                                                    '${r.nights} ${getTranslated('nights', ctx) ?? 'đêm'} • '
                                                        '${_formatVndPrice(r.pricePerNight)} / ${getTranslated('per_night', ctx) ?? 'đêm'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.white60
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                _formatVndPrice(lineTotal),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  removeRoom?.call(r.id);
                                                  setState(() {
                                                    rooms.removeWhere(
                                                            (element) => element.id == r.id);
                                                    if (rooms.isEmpty && currentStep != 0) {
                                                      currentStep = 0;
                                                      pageController.animateToPage(
                                                        0,
                                                        duration:
                                                        const Duration(milliseconds: 300),
                                                        curve: Curves.easeInOut,
                                                      );
                                                    }
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                tooltip: getTranslated(
                                                    'remove_this_room', ctx) ??
                                                    'Xóa phòng này',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),

                          // STEP 2 – Thời gian & số khách
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTranslated('stay_time', ctx) ?? 'Thời gian lưu trú',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed:
                                        canEditStayInfo ? () => pickDate(true) : null,
                                        icon: const Icon(
                                          Icons.login_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          start == null
                                              ? (getTranslated('check_in', ctx) ?? 'Nhận phòng')
                                              : DateFormat('dd/MM/yyyy').format(start!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed:
                                        canEditStayInfo ? () => pickDate(false) : null,
                                        icon: const Icon(
                                          Icons.logout_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          end == null
                                              ? (getTranslated('check_out', ctx) ?? 'Trả phòng')
                                              : DateFormat('dd/MM/yyyy').format(end!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nights > 0
                                      ? '${getTranslated('date_range', ctx) ?? 'Khoảng ngày'}: '
                                      '$dateText  •  $nights ${getTranslated('nights', ctx) ?? 'đêm'}'
                                      : '${getTranslated('date_range', ctx) ?? 'Khoảng ngày'}: $dateText',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  getTranslated('guests', ctx) ?? 'Số khách',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildCounterRow(
                                  label: getTranslated('adults', ctx) ?? 'Người lớn',
                                  value: adults,
                                  min: 1,
                                  onChanged: (v) {
                                    setState(() {
                                      adults = v;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildCounterRow(
                                  label: getTranslated('children', ctx) ?? 'Trẻ em',
                                  value: children,
                                  min: 0,
                                  onChanged: (v) {
                                    setState(() {
                                      children = v;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${getTranslated('current_room_price', ctx) ?? 'Giá phòng hiện tại'}: '
                                      '${_formatVndPrice(roomsTotal)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: primaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // STEP 3 – Giá thêm / Phụ phí
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (extraPriceItems.isNotEmpty || buyerFeeItems.isNotEmpty) ...[
                                  Text(
                                    getTranslated('extra_fee', ctx) ?? 'Giá thêm / Phụ phí',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...extraPriceItems.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final item = entry.value;
                                    final name = (item['name'] ?? '').toString();
                                    final priceHtml =
                                    (item['price_html'] ?? '').toString();
                                    return CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: extraSelected[i],
                                      onChanged: (v) {
                                        setState(() {
                                          extraSelected[i] = v ?? false;
                                        });
                                      },
                                      title: Text(
                                        name,
                                        style: TextStyle(color: primaryText),
                                      ),
                                      subtitle: Text(
                                        priceHtml.isNotEmpty
                                            ? priceHtml
                                            : '${item['price'] ?? '0'} ₫',
                                        style: TextStyle(
                                          color: secondaryText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }),
                                  if (buyerFeeItems.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    ...buyerFeeItems.map((fee) {
                                      final name = (fee['name'] ??
                                          fee['type_name'] ??
                                          'Phí dịch vụ')
                                          .toString();
                                      final priceHtml =
                                      (fee['price_html'] ?? '').toString();
                                      final price = (fee['price'] ?? '').toString();
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.info_outline_rounded,
                                          size: 20,
                                          color: Colors.orange,
                                        ),
                                        title: Text(
                                          name,
                                          style: TextStyle(color: primaryText),
                                        ),
                                        subtitle: Text(
                                          '${getTranslated('auto_included', ctx) ?? 'Đã bao gồm tự động'} • '
                                              '${priceHtml.isNotEmpty ? priceHtml : '$price ₫'}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: secondaryText,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ] else
                                  Text(
                                    getTranslated('no_extra_fee', ctx) ??
                                        'Không có phụ phí thêm nào.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryText,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  getTranslated('current_subtotal', ctx) ??
                                      'Tổng tạm tính hiện tại:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatVndPrice(grandTotal),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTranslated('booking_summary', ctx) ??
                                      'Tổng kết đặt phòng',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  getTranslated('rooms', ctx) ?? 'Phòng:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...rooms.map((r) {
                                  final int qty = r.quantity <= 0 ? 1 : r.quantity;
                                  final int usedNights = (nights > 0)
                                      ? nights
                                      : (r.nights != null && r.nights! > 0
                                      ? r.nights!
                                      : 1);

                                  final double lineTotal =
                                  _calcRoomLineTotal(r, nights);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: primaryText,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$qty ${getTranslated('room', ctx) ?? 'phòng'} • '
                                                    '$usedNights ${getTranslated('nights', ctx) ?? 'đêm'} × '
                                                    '${_formatVndPrice(r.pricePerNight)} / '
                                                    '${getTranslated('per_night', ctx) ?? 'đêm'}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: secondaryText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatVndPrice(lineTotal),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: primaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                Text(
                                  getTranslated('time_and_guests', ctx) ??
                                      'Thời gian & khách:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${getTranslated('date', ctx) ?? 'Ngày'}: '
                                      '$dateText${nights > 0 ? '  •  $nights ${getTranslated('nights', ctx) ?? 'đêm'}' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: primaryText,
                                  ),
                                ),
                                Text(
                                  '$adults ${getTranslated('adults', ctx) ?? 'người lớn'}, '
                                      '$children ${getTranslated('children', ctx) ?? 'trẻ em'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (extraPriceItems.isNotEmpty ||
                                    buyerFeeItems.isNotEmpty) ...[
                                  Text(
                                    getTranslated('extra_fee_and_surcharge', ctx) ??
                                        'Giá thêm & phụ phí:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (extraPriceItems.isNotEmpty)
                                    ...extraPriceItems
                                        .asMap()
                                        .entries
                                        .where((e) => extraSelected[e.key])
                                        .map((entry) {
                                      final item = entry.value;
                                      final name =
                                      (item['name'] ?? '').toString();
                                      final priceHtml =
                                      (item['price_html'] ?? '').toString();
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: primaryText,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            priceHtml.isNotEmpty
                                                ? priceHtml
                                                : '${item['price'] ?? '0'} ₫',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: primaryText,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  if (buyerFeeItems.isNotEmpty)
                                    ...buyerFeeItems.map((fee) {
                                      final name =
                                      (fee['name'] ?? fee['type_name'] ?? 'Phí dịch vụ')
                                          .toString();
                                      final priceHtml =
                                      (fee['price_html'] ?? '').toString();
                                      final price =
                                      (fee['price'] ?? '').toString();
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$name (${getTranslated('auto', ctx) ?? 'tự động'})',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: primaryText,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            priceHtml.isNotEmpty
                                                ? priceHtml
                                                : '$price ₫',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: primaryText,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  getTranslated('final_total_amount', ctx) ??
                                      'Tổng tạm tính cuối cùng:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatVndPrice(grandTotal),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${_tr(context, "booking_current_subtotal", "Tổng tạm tính hiện tại:")} ${_formatVndPrice(grandTotal)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (currentStep > 0)
                              OutlinedButton(
                                onPressed: () => goToStep(currentStep - 1),
                                child: Text(
                                  _tr(context, 'back', 'Quay lại'),
                                ),
                              ),
                            if (currentStep > 0)
                              const SizedBox(width: 8),
                            if (hasRooms)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: currentStep < 3
                                      ? handleNext
                                      : onConfirmBooking,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    currentStep < 3
                                        ? _tr(context, 'next', 'Tiếp theo')
                                        : _tr(context, 'book_now', 'Đặt phòng'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =============== STEP TITLE ===============

  Widget _buildStepTitle(BuildContext context, int currentStep) {
    // "Bước"
    final stepText = _tr(context, 'step', 'Bước');
    String subtitle = '$stepText ${currentStep + 1} / 4';

    String title;
    switch (currentStep) {
      case 0:
        title = _tr(context, 'step1_selected_rooms', '1. Phòng đã chọn');
        break;
      case 1:
        title = _tr(context, 'step2_stay_and_guests', '2. Thời gian & số khách');
        break;
      case 2:
        title = _tr(context, 'step3_extra_fees', '3. Giá thêm & phụ phí');
        break;
      case 3:
      default:
        title = _tr(context, 'step4_confirm_and_book', '4. Xác nhận & đặt phòng');
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.blue[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required int min,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}