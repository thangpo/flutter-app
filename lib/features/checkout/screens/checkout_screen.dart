import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/saved_address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/checkout_condition_checkbox.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/screens/offline_payment_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/controllers/shipping_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/debounce_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/amount_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/animated_custom_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/choose_payment_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/coupon_apply_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_details_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/wallet_payment_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/order_place_dialog_widget.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckoutScreen extends StatefulWidget {
  final List<CartModel> cartList;
  final bool fromProductDetails;
  final double totalOrderAmount;
  final double shippingFee;
  final double discount;
  final double tax;
  final int? sellerId;
  final bool onlyDigital;
  final bool hasPhysical;
  final int quantity;
  final List<int?> fromDistrictIds;
  final List<String?> fromWardIds;
  final int? cartId;

  const CheckoutScreen({
    super.key,
    required this.cartList,
    this.fromProductDetails = false,
    required this.discount,
    required this.tax,
    required this.totalOrderAmount,
    required this.shippingFee,
    this.sellerId,
    this.onlyDigital = false,
    required this.quantity,
    required this.hasPhysical,
    required this.fromDistrictIds,
    required this.fromWardIds,
    this.cartId,
  });

  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();

  final FocusNode _orderNoteNode = FocusNode();
  double _order = 0;
  double? _couponDiscount;
  double? _referralDiscount;
  double _calculatedShippingFee = 0;
  bool _isCalculatingShipping = false;
  String? _shippingError;

  static const double USD_TO_VND_RATE = 25000.0;

  DebounceHelper debounceHelper = DebounceHelper(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    Provider.of<AddressController>(context, listen: false).getAddressList();
    Provider.of<CheckoutController>(context, listen: false).getReferralAmount('0');
    Provider.of<CouponController>(context, listen: false).removePrevCouponData();
    Provider.of<CartController>(context, listen: false).getCartData(context);
    Provider.of<CheckoutController>(context, listen: false).resetPaymentMethod();
    Provider.of<ShippingController>(context, listen: false).getChosenShippingMethod(context);
    if (Provider.of<SplashController>(context, listen: false).configModel != null &&
        Provider.of<SplashController>(context, listen: false).configModel!.offlinePayment != null) {
      Provider.of<CheckoutController>(context, listen: false).getOfflinePaymentList();
    }

    if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<CouponController>(context, listen: false).getAvailableCouponList();
    }

    if (Provider.of<CheckoutController>(context, listen: false).isAcceptTerms) {
      Provider.of<CheckoutController>(context, listen: false).toggleTermsCheck(isUpdate: false);
    }

    Provider.of<CheckoutController>(context, listen: false).clearData();
  }

  double _convertVNDtoUSD(double vndAmount) {
    return vndAmount / USD_TO_VND_RATE;
  }

  Future<void> _calculateShippingFee() async {
    if (!widget.hasPhysical || widget.onlyDigital) {
      setState(() {
        _calculatedShippingFee = 0;
        _shippingError = null;
      });
      return;
    }

    final orderProvider = Provider.of<CheckoutController>(context, listen: false);
    final addressController = Provider.of<AddressController>(context, listen: false);

    if (orderProvider.addressIndex == null ||
        addressController.addressList == null ||
        orderProvider.addressIndex! >= addressController.addressList!.length) {
      setState(() {
        _shippingError = 'Please select a delivery address';
        _calculatedShippingFee = 0;
      });
      return;
    }

    final selectedAddress = addressController.addressList![orderProvider.addressIndex!];

    if (widget.cartId == null ||
        widget.fromDistrictIds.isEmpty ||
        widget.fromWardIds.isEmpty ||
        selectedAddress.district == null ||
        selectedAddress.province == null) {
      setState(() {
        _shippingError = 'Missing shipping information';
        _calculatedShippingFee = 0;
      });
      debugPrint("🚨 Missing info: cartId=${widget.cartId}, "
          "fromDistrictIds=${widget.fromDistrictIds}, "
          "fromWardIds=${widget.fromWardIds}, "
          "district=${selectedAddress.district}, "
          "province=${selectedAddress.province}");
      return;
    }

    if (widget.fromDistrictIds.length != widget.fromWardIds.length) {
      setState(() {
        _shippingError = 'Invalid shop data';
        _calculatedShippingFee = 0;
      });
      debugPrint("🚨 Mismatch length: fromDistrictIds(${widget.fromDistrictIds.length}) "
          "!= fromWardIds(${widget.fromWardIds.length})");
      return;
    }

    setState(() {
      _isCalculatingShipping = true;
      _shippingError = null;
    });

    try {
      double totalShippingCostVND = 0;
      final toDistrictId = int.tryParse(selectedAddress.district ?? '0') ?? 0;
      final toWardCode = selectedAddress.province ?? '';

      for (int i = 0; i < widget.fromDistrictIds.length; i++) {
        final fromDistrictId = widget.fromDistrictIds[i];
        final fromWardId = widget.fromWardIds[i];

        if (fromDistrictId == null || fromWardId == null) {
          debugPrint("⚠️ Skip seller because fromDistrictId=$fromDistrictId or fromWardId=$fromWardId");
          continue;
        }

        final sellerString = "{\"from_district_id\":$fromDistrictId,\"from_ward_id\":\"$fromWardId\"}";

        final requestBody = {
          "seller": sellerString,
          "cart_id": widget.cartId,
          "to_district_id": toWardCode,
          "to_ward_code": toDistrictId,
        };

        debugPrint("📦 Calling GHN API for seller $i: ${jsonEncode(requestBody)}");

        final response = await http.post(
          Uri.parse('https://vnshop247.com/api/v1/shippingAPI/ghn/calculate-fee'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        debugPrint("📩 Response ${response.statusCode}: ${response.body}");

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['ok'] == true) {
            totalShippingCostVND += (responseData['totalShippingCost'] ?? 0).toDouble();
            debugPrint("✅ Success: totalShippingCost VND=${responseData['totalShippingCost']}");
          } else {
            debugPrint("❌ GHN API returned error: ${responseData['message']}");
            setState(() {
              _shippingError = responseData['message'] ?? 'Failed to calculate shipping fee';
              _isCalculatingShipping = false;
              _calculatedShippingFee = 0;
            });
            return;
          }
        } else {
          debugPrint("❌ HTTP Error: ${response.statusCode} - ${response.body}");
          setState(() {
            _shippingError = 'Server error: ${response.statusCode}';
            _isCalculatingShipping = false;
            _calculatedShippingFee = 0;
          });
          return;
        }
      }

      double totalShippingCostUSD = _convertVNDtoUSD(totalShippingCostVND);

      setState(() {
        _calculatedShippingFee = totalShippingCostUSD;
        _isCalculatingShipping = false;
        _shippingError = null;
      });

      debugPrint("✅ Tổng phí vận chuyển VND: $totalShippingCostVND");
      debugPrint("✅ Tổng phí vận chuyển USD: $_calculatedShippingFee");

    } catch (e, stack) {
      debugPrint("🔥 Exception: $e");
      debugPrint(stack.toString());
      setState(() {
        _shippingError = 'Network error: ${e.toString()}';
        _isCalculatingShipping = false;
        _calculatedShippingFee = 0;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    _order = widget.totalOrderAmount + widget.discount;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      bottomNavigationBar: Consumer<AddressController>(
        builder: (context, locationProvider, _) {
          return Consumer<CheckoutController>(
              builder: (context, orderProvider, child) {
                return Consumer<CouponController>(
                    builder: (context, couponProvider, _) {
                      return Consumer<CartController>(
                          builder: (context, cartProvider, _) {
                            return Consumer<ProfileController>(
                                builder: (context, profileProvider, _) {
                                  return orderProvider.isLoading
                                      ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator())
                                    ],
                                  )
                                      : Container(
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeDefault),
                                    color: Theme.of(context).cardColor,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CheckoutConditionCheckBox(),
                                        const SizedBox(
                                            height: Dimensions.paddingSizeSmall),
                                        CustomButton(
                                          onTap: (orderProvider.isLoading ||
                                              !orderProvider.isAcceptTerms)
                                              ? null
                                              : () async {
                                            if (orderProvider.addressIndex ==
                                                null &&
                                                widget.hasPhysical) {
                                              Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (BuildContext
                                                      context) =>
                                                      const SavedAddressListScreen()));
                                              showCustomSnackBar(
                                                  getTranslated(
                                                      'select_a_shipping_address',
                                                      context),
                                                  context,
                                                  isToaster: true);
                                            } else {
                                              if (!orderProvider
                                                  .isCheckCreateAccount ||
                                                  (orderProvider
                                                      .isCheckCreateAccount &&
                                                      (passwordFormKey
                                                          .currentState
                                                          ?.validate() ??
                                                          false))) {
                                                String orderNote =
                                                orderProvider
                                                    .orderNoteController
                                                    .text
                                                    .trim();
                                                String couponCode =
                                                couponProvider.discount !=
                                                    null &&
                                                    couponProvider
                                                        .discount !=
                                                        0
                                                    ? couponProvider
                                                    .couponCode
                                                    : '';
                                                String couponCodeAmount =
                                                couponProvider.discount !=
                                                    null &&
                                                    couponProvider
                                                        .discount !=
                                                        0
                                                    ? couponProvider
                                                    .discount
                                                    .toString()
                                                    : '0';

                                                String addressId =
                                                orderProvider
                                                    .addressIndex !=
                                                    null
                                                    ? locationProvider
                                                    .addressList![
                                                orderProvider
                                                    .addressIndex!]
                                                    .id
                                                    .toString()
                                                    : '';

                                                String billingAddressId =
                                                    addressId;

                                                double finalShippingFee = widget.hasPhysical ? _calculatedShippingFee : 0;

                                                if (orderProvider
                                                    .paymentMethodIndex !=
                                                    -1) {
                                                  orderProvider
                                                      .digitalPaymentPlaceOrder(
                                                      orderNote:
                                                      orderNote,
                                                      customerId: Provider.of<
                                                          AuthController>(
                                                          context,
                                                          listen:
                                                          false)
                                                          .isLoggedIn()
                                                          ? profileProvider
                                                          .userInfoModel
                                                          ?.id
                                                          .toString()
                                                          : Provider.of<
                                                          AuthController>(
                                                          context,
                                                          listen:
                                                          false)
                                                          .getGuestToken(),
                                                      addressId:
                                                      addressId,
                                                      billingAddressId:
                                                      billingAddressId,
                                                      couponCode:
                                                      couponCode,
                                                      couponDiscount:
                                                      couponCodeAmount,
                                                      paymentMethod:
                                                      orderProvider
                                                          .selectedDigitalPaymentMethodName);
                                                } else if (orderProvider
                                                    .isCODChecked &&
                                                    !widget.onlyDigital) {
                                                  orderProvider.placeOrder(
                                                      callback: _callback,
                                                      addressID: addressId,
                                                      couponCode: couponCode,
                                                      couponAmount:
                                                      couponCodeAmount,
                                                      billingAddressId:
                                                      billingAddressId,
                                                      orderNote: orderNote);
                                                } else if (orderProvider
                                                    .isOfflineChecked) {
                                                  Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                          builder: (_) => OfflinePaymentScreen(
                                                              payableAmount: _order +
                                                                  finalShippingFee -
                                                                  widget
                                                                      .discount -
                                                                  (_referralDiscount ??
                                                                      0) -
                                                                  (_couponDiscount ?? 0) +
                                                                  widget.tax,
                                                              callback:
                                                              _callback)));
                                                } else if (orderProvider
                                                    .isWalletChecked) {
                                                  showAnimatedDialog(
                                                      context,
                                                      WalletPaymentWidget(
                                                          currentBalance:
                                                          profileProvider
                                                              .balance ??
                                                              0,
                                                          orderAmount: _order +
                                                              finalShippingFee -
                                                              widget.discount -
                                                              (_referralDiscount ??
                                                                  0) -
                                                              (_couponDiscount ?? 0) +
                                                              widget.tax,
                                                          onTap: () {
                                                            if (profileProvider
                                                                .balance! <
                                                                (_order +
                                                                    finalShippingFee -
                                                                    widget
                                                                        .discount -
                                                                    (_referralDiscount ??
                                                                        0) -
                                                                    (_couponDiscount ?? 0) +
                                                                    widget
                                                                        .tax)) {
                                                              showCustomSnackBar(
                                                                  getTranslated(
                                                                      'insufficient_balance',
                                                                      context),
                                                                  context,
                                                                  isToaster:
                                                                  true);
                                                            } else {
                                                              Navigator.pop(
                                                                  context);
                                                              orderProvider
                                                                  .placeOrder(
                                                                  callback:
                                                                  _callback,
                                                                  wallet:
                                                                  true,
                                                                  addressID:
                                                                  addressId,
                                                                  couponCode:
                                                                  couponCode,
                                                                  couponAmount:
                                                                  couponCodeAmount,
                                                                  billingAddressId:
                                                                  billingAddressId,
                                                                  orderNote:
                                                                  orderNote);
                                                            }
                                                          }),
                                                      dismissible: false,
                                                      willFlip: true);
                                                } else {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                    Colors.transparent,
                                                    builder: (c) =>
                                                        PaymentMethodBottomSheetWidget(
                                                            onlyDigital: widget
                                                                .onlyDigital),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          buttonText:
                                          '${getTranslated('proceed', context)}',
                                        )
                                      ],
                                    ),
                                  );
                                });
                          });
                    });
              });
        },
      ),
      appBar: CustomAppBar(title: getTranslated('checkout', context)),
      body: Consumer<AuthController>(
        builder: (context, authProvider, _) {
          return Consumer<CheckoutController>(
            builder: (context, orderProvider, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (orderProvider.addressIndex != null &&
                    !_isCalculatingShipping &&
                    _calculatedShippingFee == 0 &&
                    widget.hasPhysical) {
                  _calculateShippingFee();
                }
              });

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(0),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: Dimensions.paddingSizeDefault),
                          child: ShippingDetailsWidget(
                              hasPhysical: widget.hasPhysical,
                              passwordFormKey: passwordFormKey,
                              onAddressChanged: () {
                                _calculateShippingFee();
                              }),
                        ),
                        if (Provider.of<AuthController>(context, listen: false)
                            .isLoggedIn())
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: Dimensions.paddingSizeSmall),
                            child: CouponApplyWidget(
                                couponController: _controller,
                                orderAmount: _order),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeSmall),
                          child: ChoosePaymentWidget(
                              onlyDigital: widget.onlyDigital),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeSmall),
                          child: Text(
                              getTranslated('order_summary', context) ?? '',
                              style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  color:
                                  Theme.of(context).textTheme.bodyLarge?.color)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault),
                          child: Consumer<CheckoutController>(
                            builder: (context, checkoutController, child) {
                              _couponDiscount =
                                  Provider.of<CouponController>(context).discount ??
                                      0;
                              _referralDiscount = Provider.of<CheckoutController>(
                                  context)
                                  .referralAmount
                                  ?.amount ??
                                  0;

                              double finalShippingFee = widget.hasPhysical ? _calculatedShippingFee : 0;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  widget.quantity > 1
                                      ? AmountWidget(
                                    title:
                                    '${getTranslated('sub_total', context)} (${widget.quantity} ${getTranslated('items', context)})',
                                    amount: PriceConverter.convertPrice(
                                        context, _order),
                                  )
                                      : AmountWidget(
                                    title:
                                    '${getTranslated('sub_total', context)} (${widget.quantity} ${getTranslated('item', context)})',
                                    amount: PriceConverter.convertPrice(
                                        context, _order),
                                  ),

                                  if (widget.hasPhysical)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AmountWidget(
                                            title: getTranslated('shipping_fee', context),
                                            amount: _isCalculatingShipping
                                                ? 'Calculating...'
                                                : _shippingError != null
                                                ? 'Error'
                                                : PriceConverter.convertPrice(context, finalShippingFee),
                                          ),
                                        ),
                                        if (_isCalculatingShipping)
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                      ],
                                    ),

                                  if (_shippingError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _shippingError!,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                    ),

                                  AmountWidget(
                                      title: getTranslated('discount', context),
                                      amount: PriceConverter.convertPrice(
                                          context, widget.discount)),
                                  AmountWidget(
                                      title: getTranslated('coupon_voucher', context),
                                      amount: PriceConverter.convertPrice(
                                          context, _couponDiscount)),
                                  AmountWidget(
                                      title: getTranslated('tax', context),
                                      amount: PriceConverter.convertPrice(
                                          context, widget.tax)),
                                  if ((_referralDiscount ?? 0) > 0)
                                    AmountWidget(
                                      title:
                                      getTranslated('referral_discount', context),
                                      amount: PriceConverter.convertPrice(
                                          context, _referralDiscount),
                                    ),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeSmall),
                                  Divider(
                                      height: 5, color: Theme.of(context).hintColor),
                                  AmountWidget(
                                    title: getTranslated('total_payable', context),
                                    amount: PriceConverter.convertPrice(
                                      context,
                                      (_order +
                                          finalShippingFee -
                                          (_referralDiscount ?? 0) -
                                          widget.discount -
                                          (_couponDiscount ?? 0) +
                                          widget.tax),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeDefault,
                              0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${getTranslated('order_note', context)}',
                                    style: textRegular.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              CustomTextFieldWidget(
                                hintText: getTranslated('enter_note', context),
                                inputType: TextInputType.multiline,
                                inputAction: TextInputAction.done,
                                maxLines: 3,
                                focusNode: _orderNoteNode,
                                controller: orderProvider.orderNoteController,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _callback(bool isSuccess, String message, String orderID, bool createAccount) async {
    if (isSuccess) {
      Navigator.of(Get.context!).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashBoardScreen()),
              (route) => false);
      showAnimatedDialog(
          context,
          OrderPlaceDialogWidget(
            icon: Icons.check,
            title: getTranslated(
                createAccount ? 'order_placed_Account_Created' : 'order_placed',
                context),
            description: getTranslated('your_order_placed', context),
            isFailed: false,
          ),
          dismissible: false,
          willFlip: true);
    } else {
      showCustomSnackBar(message, context, isToaster: true);
    }
  }
}