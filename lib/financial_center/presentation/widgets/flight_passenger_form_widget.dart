import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import '../models/flight_checkout_args.dart' as m;

enum PaymentMethod { counter, sepay }

extension PaymentMethodX on PaymentMethod {
  String key() {
    switch (this) {
      case PaymentMethod.counter:
        return 'payment_counter';
      case PaymentMethod.sepay:
        return 'payment_sepay';
    }
  }

  String fallbackLabel() {
    switch (this) {
      case PaymentMethod.counter:
        return 'Thanh toán tại quầy';
      case PaymentMethod.sepay:
        return 'SePay';
    }
  }
}

class FlightPassengerFormWidget extends StatefulWidget {
  final m.FlightCheckoutArgs args;

  // Giữ lại để không break chỗ gọi cũ, nhưng file này không dùng nữa
  final bool isDark;
  final Color card;
  final Color textMain;
  final Color textSub;
  final Color accent;

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController countryCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController addressCtrl;
  final List<TextEditingController> passengerNameCtrls;
  final TextEditingController specialRequestCtrl;
  final TextEditingController couponCtrl;
  final VoidCallback? onApplyCoupon;
  final PaymentMethod selectedPayment;
  final ValueChanged<PaymentMethod> onPaymentChanged;
  final bool submitting;
  final VoidCallback onSubmit;
  final String Function(double) formatVnd;

  const FlightPassengerFormWidget({
    super.key,
    required this.args,
    required this.isDark,
    required this.card,
    required this.textMain,
    required this.textSub,
    required this.accent,
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.countryCtrl,
    required this.cityCtrl,
    required this.addressCtrl,
    required this.passengerNameCtrls,
    required this.specialRequestCtrl,
    required this.couponCtrl,
    this.onApplyCoupon,
    required this.selectedPayment,
    required this.onPaymentChanged,
    required this.formatVnd,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  State<FlightPassengerFormWidget> createState() => _FlightPassengerFormWidgetState();
}

class _FlightPassengerFormWidgetState extends State<FlightPassengerFormWidget> {
  int _step = 0;

  void _goNext({
    required bool isDark,
  }) {
    final formState = widget.formKey.currentState;
    final ok = formState?.validate() ?? false;
    if (!ok) return;

    if (widget.passengerNameCtrls.isNotEmpty) {
      final fullName = '${widget.lastNameCtrl.text} ${widget.firstNameCtrl.text}'.trim();
      final p1 = widget.passengerNameCtrls.first;
      if (p1.text.trim().isEmpty && fullName.isNotEmpty) {
        p1.text = fullName;
      }
    }

    setState(() => _step = 1);
  }

  void _goBackStep() => setState(() => _step = 0);

  @override
  Widget build(BuildContext context) {
    // ====== THEME AUTO (light/dark) ======
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Card + text tự theo theme
    final card = scheme.surface;
    final textMain = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final textSub = textMain.withOpacity(0.65);
    final accent = scheme.primary;

    final payNow = getTranslated('pay_now', context) ?? 'Pay now';
    final headerTitle = _step == 0
        ? (getTranslated('booking_info_title', context) ?? 'Thông tin người đặt')
        : (getTranslated('companions_info_title', context) ?? 'Thông tin người đi cùng');

    Widget stepChild;

    if (_step == 0) {
      stepChild = Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStep1(
            context,
            isDark: isDark,
            card: card,
            textMain: textMain,
            textSub: textSub,
            accent: accent,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: widget.submitting ? null : () => _goNext(isDark: isDark),
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
      );
    } else {
      stepChild = Dismissible(
        key: const ValueKey('step2_dismiss'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          if (!widget.submitting) _goBackStep();
          return false;
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.25)),
          ),
          child: Text(
            getTranslated('swipe_back_hint', context) ?? 'Vuốt từ trái sang phải để quay lại bước trước',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
          ),
        ),
        child: Column(
          key: const ValueKey('step2'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Text(
                getTranslated('swipe_back_hint', context) ?? 'Mẹo: Vuốt từ trái sang phải để quay lại bước trước.',
                style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            _buildStep2(
              context,
              isDark: isDark,
              card: card,
              textMain: textMain,
              textSub: textSub,
              accent: accent,
            ),
            const SizedBox(height: 14),
            _buildSummaryCard(
              context,
              isDark: isDark,
              card: card,
              textMain: textMain,
              textSub: textSub,
              accent: accent,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: widget.submitting ? null : _handlePayNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: widget.submitting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  payNow,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Form(
          key: widget.formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _StepHeaderNoBack(
                isDark: isDark,
                textMain: textMain,
                accent: accent,
                title: headerTitle,
                step: _step,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final offsetTween = Tween<Offset>(
                    begin: _step == 0 ? const Offset(-0.06, 0) : const Offset(0.06, 0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic));

                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: anim.drive(offsetTween),
                      child: child,
                    ),
                  );
                },
                child: stepChild,
              ),
            ],
          ),
        ),

        IgnorePointer(
          ignoring: !widget.submitting,
          child: AnimatedOpacity(
            opacity: widget.submitting ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _LoadingOverlay(
              isDark: isDark,
              message: getTranslated('processing_payment', context) ?? 'Đang xử lý thanh toán...',
            ),
          ),
        ),
      ],
    );
  }

  void _handlePayNow() {
    debugPrint('[PAY_NOW] pressed');
    FocusScope.of(context).unfocus();

    final formState = widget.formKey.currentState;
    if (formState == null) return;

    final ok = formState.validate();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated('please_fill_required', context) ??
                'Vui lòng điền đầy đủ thông tin bắt buộc.',
          ),
        ),
      );
      return;
    }

    widget.onSubmit();
  }

  Widget _buildStep1(
      BuildContext context, {
        required bool isDark,
        required Color card,
        required Color textMain,
        required Color textSub,
        required Color accent,
      }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            getTranslated('contact_information', context) ?? 'Contact information',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Field(
                  isDark: isDark,
                  label: getTranslated('last_name', context) ?? 'Last name',
                  controller: widget.lastNameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (getTranslated('please_enter_last_name', context) ?? 'Please enter last name')
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  isDark: isDark,
                  label: getTranslated('first_name', context) ?? 'First name',
                  controller: widget.firstNameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (getTranslated('please_enter_first_name', context) ?? 'Please enter first name')
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
            isDark: isDark,
            label: getTranslated('email', context) ?? 'Email',
            controller: widget.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return getTranslated('please_enter_email', context) ?? 'Please enter email';
              if (!s.contains('@')) return getTranslated('invalid_email', context) ?? 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 10),
          _Field(
            isDark: isDark,
            label: getTranslated('phone', context) ?? 'Phone',
            controller: widget.phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().length < 8)
                ? (getTranslated('invalid_phone', context) ?? 'Invalid phone number')
                : null,
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          Text(
            getTranslated('address_information', context) ?? 'Address information',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          _Field(
            isDark: isDark,
            label: getTranslated('country', context) ?? 'Country',
            controller: widget.countryCtrl,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (getTranslated('please_enter_country', context) ?? 'Please enter country')
                : null,
          ),
          const SizedBox(height: 10),
          _Field(
            isDark: isDark,
            label: getTranslated('city', context) ?? 'City',
            controller: widget.cityCtrl,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (getTranslated('please_enter_city', context) ?? 'Please enter city')
                : null,
          ),
          const SizedBox(height: 10),
          _Field(
            isDark: isDark,
            label: getTranslated('address', context) ?? 'Address',
            controller: widget.addressCtrl,
            textInputAction: TextInputAction.done,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (getTranslated('please_enter_address', context) ?? 'Please enter address')
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(
      BuildContext context, {
        required bool isDark,
        required Color card,
        required Color textMain,
        required Color textSub,
        required Color accent,
      }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            getTranslated('passenger_information', context) ?? 'Passenger information',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ...List.generate(widget.passengerNameCtrls.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Field(
                isDark: isDark,
                label: '${getTranslated('passenger', context) ?? 'Passenger'} ${i + 1}',
                controller: widget.passengerNameCtrls[i],
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (getTranslated('please_enter_passenger_name', context) ?? 'Please enter passenger name')
                    : null,
              ),
            );
          }),
          const SizedBox(height: 4),
          _Field(
            isDark: isDark,
            label: getTranslated('special_request', context) ?? 'Special request (optional)',
            controller: widget.specialRequestCtrl,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            validator: (_) => null,
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          Text(
            getTranslated('discount_code', context) ?? 'Discount code',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Field(
                  isDark: isDark,
                  label: getTranslated('enter_discount_code', context) ?? 'Enter code',
                  controller: widget.couponCtrl,
                  textInputAction: TextInputAction.done,
                  validator: (_) => null,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.submitting ? null : widget.onApplyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(
                    getTranslated('apply', context) ?? 'Apply',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          Text(
            getTranslated('payment_method', context) ?? 'Payment method',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          _PaymentRadioTile(
            isDark: isDark,
            textMain: textMain,
            textSub: textSub,
            value: PaymentMethod.counter,
            groupValue: widget.selectedPayment,
            onChanged: widget.onPaymentChanged,
          ),
          _PaymentRadioTile(
            isDark: isDark,
            textMain: textMain,
            textSub: textSub,
            value: PaymentMethod.sepay,
            groupValue: widget.selectedPayment,
            onChanged: widget.onPaymentChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required bool isDark,
        required Color card,
        required Color textMain,
        required Color textSub,
        required Color accent,
      }) {
    final passengersLabel = getTranslated('passengers', context) ?? 'Passengers';
    final unitLabel = getTranslated('price', context) ?? 'Price';
    final totalLabel = getTranslated('total', context) ?? 'Total';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.args.airlineName,
            style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.args.flightCode} • ${widget.args.fromCode} → ${widget.args.toCode}',
            style: TextStyle(color: textSub, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.args.departTimeText} (${widget.args.fromCode})',
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Text(
                  '${widget.args.arriveTimeText} (${widget.args.toCode})',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 10),
          Text(
            '$passengersLabel: ${widget.args.passengers}',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '$unitLabel: ${widget.formatVnd(widget.args.unitPrice)} / 1',
            style: TextStyle(color: textSub, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalLabel: ${widget.formatVnd(widget.args.totalPrice)}',
            style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _StepHeaderNoBack extends StatelessWidget {
  final bool isDark;
  final Color textMain;
  final Color accent;
  final String title;
  final int step;

  const _StepHeaderNoBack({
    required this.isDark,
    required this.textMain,
    required this.accent,
    required this.title,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final border = accent;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 1.3),
                color: Colors.transparent,
              ),
              child: Text(
                title,
                style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Text(
            '${step + 1}/2',
            style: TextStyle(color: accent, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _PaymentRadioTile extends StatelessWidget {
  final bool isDark;
  final Color textMain;
  final Color textSub;
  final PaymentMethod value;
  final PaymentMethod groupValue;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentRadioTile({
    required this.isDark,
    required this.textMain,
    required this.textSub,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white12 : Colors.black12;
    final label = getTranslated(value.key(), context) ?? value.fallbackLabel();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: RadioListTile<PaymentMethod>(
        value: value,
        groupValue: groupValue,
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
        title: Text(label, style: TextStyle(color: textMain, fontWeight: FontWeight.w800)),
        subtitle: Text(
          getTranslated('${value.key()}_desc', context) ?? '',
          style: TextStyle(color: textSub, fontWeight: FontWeight.w600),
        ),
        activeColor: isDark ? Colors.white : Colors.black,
        dense: true,
      ),
    );
  }
}

class _Field extends StatefulWidget {
  final bool isDark;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.isDark,
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final FocusNode _focusNode;
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _hasText = widget.controller.text.trim().isNotEmpty;

    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _focused = _focusNode.hasFocus);
    });

    widget.controller.addListener(() {
      final now = widget.controller.text.trim().isNotEmpty;
      if (now != _hasText && mounted) setState(() => _hasText = now);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.isDark ? Colors.white12 : Colors.black12;
    final fill = widget.isDark ? const Color(0xFF0E1621) : const Color(0xFFF6F6F7);
    final text = widget.isDark ? Colors.white : Colors.black;
    final activeBorderColor = _focused ? Theme.of(context).colorScheme.primary : border;

    final activeShadow = _focused
        ? [
      BoxShadow(
        blurRadius: 18,
        offset: const Offset(0, 10),
        color: Colors.black.withOpacity(widget.isDark ? 0.35 : 0.10),
      ),
    ]
        : const <BoxShadow>[];

    final lift = (_focused || _hasText) ? 1.0 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, -lift, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: activeShadow,
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.maxLines,
        scrollPadding: const EdgeInsets.only(bottom: 140),
        style: TextStyle(color: text, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: activeBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: activeBorderColor, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final bool isDark;
  final String message;

  const _LoadingOverlay({
    required this.isDark,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(isDark ? 0.45 : 0.28),
        alignment: Alignment.center,
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121E2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.18),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
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