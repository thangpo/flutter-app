import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../services/hotel_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import '../widgets/hotel_detail_app_bar.dart';
import '../widgets/hotel_detail_body.dart';
import '../widgets/hotel_book_button.dart';
import '../screens/hotel_checkout_screen.dart';
import '../widgets/hotel_rooms_section.dart'
    show HotelBookingSummary, HotelSelectedRoom;


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
      // lỗi sẽ được FutureBuilder xử lý, không cần setState thêm ở đây
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
    final totalRoomsSelected = _bookingSummary?.totalRooms ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshHotel,
        color: Colors.blue[700],
        child: FutureBuilder<Map<String, dynamic>>(
          future: _hotelFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmer();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildError(snapshot.error?.toString());
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

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: ListView(
        children: [
          Container(height: 350, color: Colors.white),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 250,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 180,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
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

  Widget _buildError(String? error) {
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshHotel,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Thử lại", style: TextStyle(fontSize: 16)),
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
          content: const Text('Vui lòng chọn phòng trước khi đặt.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final bookingData =
    _hotelDetail != null ? _hotelDetail!['booking_data'] as Map<String, dynamic>? : null;

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

    List<HotelSelectedRoom> rooms = List<HotelSelectedRoom>.from(summary.rooms);

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
        return StatefulBuilder(
          builder: (ctx, setState) {
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
                      content: const Text(
                          'Bạn chưa chọn phòng nào. Vui lòng chọn phòng.'),
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
                      content: const Text(
                          'Vui lòng chọn ngày nhận và trả phòng.'),
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
                    content: const Text(
                      'Vui lòng chọn ngày nhận và trả phòng trước khi đặt.',
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
                    content: const Text(
                      'Ngày trả phòng phải sau ngày nhận phòng ít nhất 1 ngày.',
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
                    content: const Text(
                        'Bạn chưa chọn phòng nào. Vui lòng chọn phòng.'),
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
                final int perRoomAdults = (r.adultsPerRoom ?? r.maxGuests ?? 0);
                final int perRoomChildren = (r.childrenPerRoom ?? 0);

                adultsCapacity += perRoomAdults * r.quantity;
                childrenCapacity += perRoomChildren * r.quantity;
              }

              if (requestedAdults > adultsCapacity ||
                  requestedChildren > childrenCapacity) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Vượt quá sức chứa'),
                    content: const Text(
                      'Số người lớn hoặc trẻ em vượt quá sức chứa '
                          'của các phòng đã chọn.\n'
                          'Vui lòng đặt thêm phòng hoặc chọn loại phòng khác.',
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

              // Lấy danh sách extra được chọn
              final List<Map<String, dynamic>> selectedExtras = [];
              for (int i = 0; i < extraPriceItems.length; i++) {
                if (extraSelected[i]) {
                  selectedExtras.add(extraPriceItems[i]);
                }
              }

              // Đóng dialog trước
              Navigator.of(ctx).pop();

              // Đẩy sang màn checkout, truyền toàn bộ info màn 4
              Future.microtask(() {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HotelCheckoutScreen(
                      data: HotelCheckoutData(
                        hotelId: hotelId, // 👈 THÊM DÒNG NÀY
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
                      content: const Text(
                          'Ngày nhận phòng không được sau ngày trả phòng'),
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
                      content: const Text(
                          'Ngày trả phòng không được trước ngày nhận phòng'),
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
                        const Text(
                          'Xác nhận đặt phòng',
                          style: TextStyle(
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
                      child: _buildStepTitle(currentStep),
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
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Phòng đã chọn',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
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
                                      label: const Text(
                                        'Hủy tất cả',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (rooms.isEmpty)
                                  Text(
                                    'Chưa có phòng nào, vui lòng quay lại chọn phòng.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  )
                                else
                                  ...rooms.map((r) {
                                    final double lineTotal = _calcRoomLineTotal(r, nights);
                                    return Container(
                                      margin:
                                      const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  r.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Số phòng: ${r.quantity}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                if (r.nights > 0)
                                                  Text(
                                                    '${r.nights} đêm • ${_formatVndPrice(r.pricePerNight)} / đêm',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
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
                                                    rooms.removeWhere((element) => element.id == r.id);
                                                    if (rooms.isEmpty && currentStep != 0) {
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
                                                  Icons.close_rounded,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                tooltip: 'Xóa phòng này',
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

                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thời gian lưu trú',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: canEditStayInfo
                                            ? () => pickDate(true)
                                            : null,
                                        icon: const Icon(
                                          Icons.login_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          start == null
                                              ? 'Nhận phòng'
                                              : DateFormat('dd/MM/yyyy')
                                              .format(start!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: canEditStayInfo
                                            ? () => pickDate(false)
                                            : null,
                                        icon: const Icon(
                                          Icons.logout_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          end == null
                                              ? 'Trả phòng'
                                              : DateFormat('dd/MM/yyyy')
                                              .format(end!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nights > 0
                                      ? 'Khoảng ngày: $dateText  •  $nights đêm'
                                      : 'Khoảng ngày: $dateText',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Số khách',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildCounterRow(
                                  label: 'Người lớn',
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
                                  label: 'Trẻ em',
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
                                  'Giá phòng hiện tại: ${_formatVndPrice(roomsTotal)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (extraPriceItems.isNotEmpty ||
                                    buyerFeeItems.isNotEmpty) ...[
                                  const Text(
                                    'Giá thêm / Phụ phí',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...extraPriceItems
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final i = entry.key;
                                    final item = entry.value;
                                    final name =
                                    (item['name'] ?? '').toString();
                                    final priceHtml =
                                    (item['price_html'] ?? '')
                                        .toString();
                                    return CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: extraSelected[i],
                                      onChanged: (v) {
                                        setState(() {
                                          extraSelected[i] = v ?? false;
                                        });
                                      },
                                      title: Text(name),
                                      subtitle: Text(
                                        priceHtml.isNotEmpty
                                            ? priceHtml
                                            : '${item['price'] ?? '0'} ₫',
                                        style: TextStyle(
                                          color: Colors.grey[700],
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
                                      (fee['price_html'] ?? '')
                                          .toString();
                                      final price =
                                      (fee['price'] ?? '').toString();
                                      return ListTile(
                                        contentPadding:
                                        EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.info_outline_rounded,
                                          size: 20,
                                          color: Colors.orange,
                                        ),
                                        title: Text(name),
                                        subtitle: Text(
                                          'Đã bao gồm tự động • ' +
                                              (priceHtml.isNotEmpty
                                                  ? priceHtml
                                                  : '$price ₫'),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ] else
                                  Text(
                                    'Không có phụ phí thêm nào.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),

                                const SizedBox(height: 16),
                                Text(
                                  'Tổng tạm tính hiện tại:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
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
                                const Text(
                                  'Tổng kết đặt phòng',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Phòng:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...rooms.map((r) {
                                  final int qty = r.quantity <= 0 ? 1 : r.quantity;
                                  final int usedNights = (nights > 0)
                                      ? nights
                                      : (r.nights != null && r.nights! > 0 ? r.nights! : 1);

                                  final double lineTotal = _calcRoomLineTotal(r, nights);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$qty phòng • $usedNights đêm × ${_formatVndPrice(r.pricePerNight)} / đêm',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatVndPrice(lineTotal),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                Text(
                                  'Thời gian & khách:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ngày: $dateText'
                                      '${nights > 0 ? '  •  $nights đêm' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$adults người lớn, $children trẻ em',
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (extraPriceItems.isNotEmpty ||
                                    buyerFeeItems.isNotEmpty) ...[
                                  Text(
                                    'Giá thêm & phụ phí:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (extraPriceItems.isNotEmpty)
                                    ...extraPriceItems
                                        .asMap()
                                        .entries
                                        .where((e) =>
                                    extraSelected[e.key])
                                        .map((entry) {
                                      final item = entry.value;
                                      final name =
                                      (item['name'] ?? '')
                                          .toString();
                                      final priceHtml =
                                      (item['price_html'] ?? '')
                                          .toString();
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style:
                                              const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            priceHtml.isNotEmpty
                                                ? priceHtml
                                                : '${item['price'] ?? '0'} ₫',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  if (buyerFeeItems.isNotEmpty)
                                    ...buyerFeeItems.map((fee) {
                                      final name = (fee['name'] ??
                                          fee['type_name'] ??
                                          'Phí dịch vụ')
                                          .toString();
                                      final priceHtml =
                                      (fee['price_html'] ?? '')
                                          .toString();
                                      final price =
                                      (fee['price'] ?? '')
                                          .toString();
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$name (tự động)',
                                              style:
                                              const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            priceHtml.isNotEmpty
                                                ? priceHtml
                                                : '$price ₫',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  'Tổng tạm tính cuối cùng:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
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
                          'Tổng tạm tính hiện tại: ${_formatVndPrice(grandTotal)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => goToStep(currentStep - 1),
                                  child: const Text('Quay lại'),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    currentStep < 3 ? 'Tiếp theo' : 'Đặt phòng',
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

  Widget _buildStepTitle(int currentStep) {
    String title;
    String subtitle = 'Bước ${currentStep + 1} / 4';

    switch (currentStep) {
      case 0:
        title = '1. Phòng đã chọn';
        break;
      case 1:
        title = '2. Thời gian & số khách';
        break;
      case 2:
        title = '3. Giá thêm & phụ phí';
        break;
      case 3:
      default:
        title = '4. Xác nhận & đặt phòng';
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

  Widget _buildStepChip(String label, int index, int currentStep) {
    final bool isActive = index == currentStep;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.blue[800] : Colors.grey[700],
            ),
          ),
        ),
      ),
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