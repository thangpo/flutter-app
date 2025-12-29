import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/repositories/profile_repository.dart';
import '../services/flight_service.dart';
import 'flight_invoice_screen.dart';
import '../models/flight_checkout_args.dart' as m;
import '../widgets/flight_route_hero_map.dart';
import '../widgets/flight_passenger_form_widget.dart';

class FlightCheckoutScreen extends StatefulWidget {
  final m.FlightCheckoutArgs args;
  const FlightCheckoutScreen({super.key, required this.args});

  @override
  State<FlightCheckoutScreen> createState() => _FlightCheckoutScreenState();
}

class _FlightCheckoutScreenState extends State<FlightCheckoutScreen> {
  int _step = 0;
  bool _submitting = false;
  late ProfileRepository _profileRepository;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;
  late final List<TextEditingController> _passengerNameCtrls;
  late final TextEditingController _specialRequestCtrl;
  late final TextEditingController _couponCtrl;

  PaymentMethod _selectedPayment = PaymentMethod.counter;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _countryCtrl = TextEditingController(text: 'Việt Nam');
    _cityCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _specialRequestCtrl = TextEditingController();
    _couponCtrl = TextEditingController();
    final pax = widget.args.passengers < 1 ? 1 : widget.args.passengers;
    _passengerNameCtrls = List.generate(pax, (_) => TextEditingController());

    _initProfileRepo();
  }

  Future<void> _initProfileRepo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dio = Dio();
      final loggingInterceptor = LoggingInterceptor();
      final dioClient = DioClient(
        AppConstants.baseUrl,
        dio,
        loggingInterceptor: loggingInterceptor,
        sharedPreferences: prefs,
      );

      _profileRepository = ProfileRepository(
        dioClient: dioClient,
        sharedPreferences: prefs,
      );

      await _loadUserData();
    } catch (e) {
      debugPrint("INIT_PROFILE_REPO_ERR: $e");
    }
  }

  Future<void> _loadUserData() async {
    final response = await _profileRepository.getProfileInfo();
    if (!response.isSuccess) return;

    final userData = response.response.data;
    if (!mounted) return;

    setState(() {
      _firstNameCtrl.text = userData['f_name'] ?? '';
      _lastNameCtrl.text = userData['l_name'] ?? '';
      _emailCtrl.text = userData['email'] ?? '';
      _phoneCtrl.text = userData['phone'] ?? '';
      _countryCtrl.text =
      (userData['country']?.toString().trim().isNotEmpty ?? false) ? userData['country'] : 'Việt Nam';
      _cityCtrl.text = userData['city'] ?? '';
      _addressCtrl.text = userData['address'] ?? '';
    });
  }

  String _formatVnd(double value) {
    final n = value.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      final pos = n.length - i;
      buf.write(n[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return '${buf.toString()} ₫';
  }

  void _goNext() => setState(() => _step = 1);

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step = 0);
  }

  Future<void> _submitBooking() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final contactInfo = <String, dynamic>{
        "first_name": _firstNameCtrl.text.trim(),
        "last_name": _lastNameCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "phone": _phoneCtrl.text.trim(),
        "country": _countryCtrl.text.trim(),
        "city": _cityCtrl.text.trim(),
        "address": _addressCtrl.text.trim(),
      };

      final passengers = _passengerNameCtrls.asMap().entries.map((e) {
        return {
          "index": e.key + 1,
          "full_name": e.value.text.trim(),
        };
      }).toList();

      final paxCount = passengers.length;
      final gateway = _selectedPayment == PaymentMethod.sepay ? "sepay" : "offline_payment";
      final seatClassName = (widget.args.seatClassName?.toString().trim().isNotEmpty ?? false)
          ? widget.args.seatClassName.toString().trim()
          : "Economy";
      final amount = widget.args.totalPrice;
      final flightInfo = <String, dynamic>{
        "airline_name": widget.args.airlineName,
        "flight_code": widget.args.flightCode,
        "from_code": widget.args.fromCode,
        "to_code": widget.args.toCode,
        "depart_time": widget.args.departTimeText,
        "arrive_time": widget.args.arriveTimeText,
        "unit_price": widget.args.unitPrice,
        "total_price": widget.args.totalPrice,
        "seat_class": seatClassName,
        "seat_qty": paxCount,
        "items": [
          {
            "name": seatClassName,
            "qty": paxCount,
            "unit_price": widget.args.unitPrice,
            "line_total": widget.args.unitPrice * paxCount,
          }
        ],
      };

      final debugPayload = {
        "object_model": "flight",
        "object_id": widget.args.flightId,
        "start_date": widget.args.departDateIso,
        "end_date": null,
        "total_guests": paxCount,
        "customer_notes": _specialRequestCtrl.text.trim(),
        "gateway": gateway,
        "amount": amount,
        "contact_info": contactInfo,
        "passengers": passengers,
        "flight_info": flightInfo,
        if (_couponCtrl.text.trim().isNotEmpty) "coupon_code": _couponCtrl.text.trim(),
      };

      debugPrint("BOOKING_PAYLOAD:\n${const JsonEncoder.withIndent('  ').convert(debugPayload)}");

      final res = await FlightService.createBooking(
        objectModel: "flight",
        objectId: widget.args.flightId,
        startDate: widget.args.departDateIso,
        endDate: null,
        totalGuests: paxCount,
        customerNotes: _specialRequestCtrl.text.trim().isEmpty ? null : _specialRequestCtrl.text.trim(),
        gateway: gateway,
        amount: amount,
        contactInfo: contactInfo,
        passengers: passengers,
        flightInfo: flightInfo,
        extra: {
          if (_couponCtrl.text.trim().isNotEmpty) "coupon_code": _couponCtrl.text.trim(),
        },
      );

      debugPrint("BOOKING_OK:\n${const JsonEncoder.withIndent('  ').convert(res)}");

      if (!mounted) return;

      final success = res["success"] == true;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"]?.toString() ?? "Booking failed")),
        );
        return;
      }

      final bookingData = Map<String, dynamic>.from(res["data"] ?? {});

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FlightInvoiceScreen(
            booking: bookingData,
            flightInfo: flightInfo,
            contactInfo: contactInfo,
            passengers: passengers.cast<Map<String, dynamic>>(),
          ),
        ),
      );
    } catch (e, st) {
      debugPrint("BOOKING_ERR: $e\n$st");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _specialRequestCtrl.dispose();
    _couponCtrl.dispose();
    for (final c in _passengerNameCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    final bg = isDark ? const Color(0xFF0E1621) : const Color(0xFFF6F6F7);
    final card = isDark ? const Color(0xFF121E2C) : Colors.white;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = (isDark ? Colors.white : Colors.black).withOpacity(0.6);
    final accent = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    final title = _step == 0
        ? (getTranslated('flight_detail', context) ?? 'Chi tiết chuyến bay')
        : (getTranslated('passenger_info', context) ?? 'Thông tin hành khách');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textMain,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _submitting ? null : _goBack,
        ),
        title: Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _step == 0
            ? _CheckoutStepOverview(
          key: const ValueKey('step_overview'),
          args: widget.args,
          isDark: isDark,
          card: card,
          textMain: textMain,
          textSub: textSub,
          accent: accent,
          onNext: _submitting ? () {} : _goNext,
          formatVnd: _formatVnd,
        )
            : FlightPassengerFormWidget(
          key: const ValueKey('step_form'),
          args: widget.args,
          isDark: isDark,
          card: card,
          textMain: textMain,
          textSub: textSub,
          accent: accent,
          formKey: _formKey,
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          emailCtrl: _emailCtrl,
          phoneCtrl: _phoneCtrl,
          countryCtrl: _countryCtrl,
          cityCtrl: _cityCtrl,
          addressCtrl: _addressCtrl,
          passengerNameCtrls: _passengerNameCtrls,
          specialRequestCtrl: _specialRequestCtrl,
          couponCtrl: _couponCtrl,
          onApplyCoupon: _submitting
              ? null
              : () {
          },
          selectedPayment: _selectedPayment,
          onPaymentChanged: (v) => setState(() => _selectedPayment = v),
          formatVnd: _formatVnd,
          submitting: _submitting,
          onSubmit: _submitBooking,
        ),
      ),
    );
  }
}

class _CheckoutStepOverview extends StatelessWidget {
  final m.FlightCheckoutArgs args;
  final bool isDark;
  final Color card;
  final Color textMain;
  final Color textSub;
  final Color accent;
  final VoidCallback onNext;
  final String Function(double) formatVnd;

  const _CheckoutStepOverview({
    super.key,
    required this.args,
    required this.isDark,
    required this.card,
    required this.textMain,
    required this.textSub,
    required this.accent,
    required this.onNext,
    required this.formatVnd,
  });

  @override
  Widget build(BuildContext context) {
    final itinerary = args.itinerary;
    final originColor = accent;
    final destColor = isDark ? const Color(0xFF0B0F14) : Colors.black;
    const cardHeightEstimate = 180.0;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final fitPadding = EdgeInsets.fromLTRB(28, 90, 28, cardHeightEstimate + 40 + safeBottom);

    return Stack(
      children: [
        Positioned.fill(
          child: FlightRouteHeroMap(
            from: itinerary.fromLatLng,
            to: itinerary.toLatLng,
            fromLabel: args.fromCode,
            toLabel: args.toCode,
            fromName: args.fromCode,
            toName: args.toCode,
            originColor: originColor,
            destColor: destColor,
            isDark: isDark,
            splitT: 0.55,
            planeT: 0.52,
            curveFactor: 0.22,
            lineWidth: 4,
            dashedOrigin: true,
            dashedDest: true,
            rotateToRoute: true,
            fitPadding: fitPadding,
            planeColor: Colors.pinkAccent,
            planeIcon: Icons.airplanemode_active,
            planeRotationOffsetRad: -math.pi / 2,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                          color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          args.airlineName,
                          style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${args.flightCode} • ${args.fromCode} → ${args.toCode}',
                          style: TextStyle(color: textSub, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${args.departTimeText} (${args.fromCode})',
                                style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${args.arriveTimeText} (${args.toCode})',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: isDark ? Colors.white12 : Colors.black12),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${getTranslated('passengers', context) ?? 'Số hành khách'}: ${args.passengers}',
                                style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              formatVnd(args.totalPrice),
                              style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        getTranslated('next', context) ?? 'Next',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}