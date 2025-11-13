import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/main.dart';
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
  final List<int> selectedCartIds;

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
    required this.selectedCartIds,
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
  final Map<String, double> _shopShippingFeesVND = {};
  final Map<String, double> _originalShopFeesVND = {};
  final Map<String, String> _shopNames = {};
  final Map<String, double> _shopFreeDeliverySavings = {};
  Map<String, dynamic> _buildCheckedIds() {
    final Map<String, dynamic> checkedIds = {};
    _shopShippingFeesVND.forEach((shopId, feeVND) {
      checkedIds[shopId] = {
        "name": _shopNames[shopId] ?? "Shop $shopId",
        "fee": feeVND,
      };
    });
    return checkedIds;
  }
  static const double USD_TO_VND_RATE = 26000.0;
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

    if (Provider.of<SplashController>(context, listen: false).configModel?.offlinePayment != null) {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final couponProvider = Provider.of<CouponController>(context);
    final checkoutProvider = Provider.of<CheckoutController>(context);

    if (couponProvider.discount != null &&
        checkoutProvider.addressIndex != null &&
        widget.hasPhysical &&
        !_isCalculatingShipping) {
      debounceHelper.run(() {
        if (mounted) {
          _calculateShippingFee();
        }
      });
    }
  }

  double _convertVNDtoUSD(double vndAmount) {
    return vndAmount / USD_TO_VND_RATE;
  }

  Map<String, List<int>> _getCartIdsByGroupId() {
    Map<String, List<int>> result = {};
    for (final cart in widget.cartList) {
      if (cart.isChecked == true && cart.cartGroupId != null) {
        final groupList = result.putIfAbsent(cart.cartGroupId!, () => []);
        if (!groupList.contains(cart.id!)) {
          groupList.add(cart.id!);
        }
      }
    }
    debugPrint("Cart IDs by Group: $result");
    return result;
  }

  Map<String, (int, String, String, int?)> _getShopInfoByGroupId() {
    Map<String, (int, String, String, int?)> shopInfo = {};
    Map<String, int> groupIndexMap = {};
    int locationIndex = 0;
    for (final cart in widget.cartList) {
      if (!cart.isChecked! || cart.cartGroupId == null) continue;
      if (groupIndexMap.containsKey(cart.cartGroupId)) continue;
      groupIndexMap[cart.cartGroupId!] = locationIndex++;
    }
    for (final cart in widget.cartList) {
      if (!cart.isChecked! || cart.cartGroupId == null) continue;
      if (shopInfo.containsKey(cart.cartGroupId)) continue;
      final idx = groupIndexMap[cart.cartGroupId!];
      if (idx == null || idx >= widget.fromDistrictIds.length) continue;
      final districtId = widget.fromDistrictIds[idx];
      final wardId = widget.fromWardIds[idx];
      final shopId = cart.sellerIs == 'admin' ? 0 : cart.sellerId;
      if (districtId == null || wardId == null) continue;
      final shopName = cart.shopInfo ?? 'Shop #${cart.cartGroupId}';
      shopInfo[cart.cartGroupId!] = (districtId, wardId, shopName, shopId);
    }
    debugPrint("Shop Info by Group: $shopInfo");
    return shopInfo;
  }

  Future<bool> _checkFreeDeliveryForShop({
    required double feeVND,
    required int cartId,
    required int sellerId,
  }) async {
    try {
      debugPrint("🚀 _checkFreeDeliveryForShop CALLED for sellerId=$sellerId, cartId=$cartId");
      final response = await http.post(
        Uri.parse('https://vnshop247.com/api/v1/free/free-delivery'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "fee": feeVND,
          "cart_id": cartId,
          "seller_id": sellerId,
        }),
      );
      debugPrint("📭 Free delivery API response: ${response.statusCode} - ${response.body}");
      debugPrint("Free Delivery API (cart_id: $cartId, seller_id: $sellerId): ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == 1;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking free delivery for seller $sellerId: $e");
      return false;
    }
  }

  Future<void> _calculateShippingFee() async {
    if (!widget.hasPhysical || widget.onlyDigital) {
      setState(() {
        _calculatedShippingFee = 0;
        _shippingError = null;
        _shopShippingFeesVND.clear();
        _shopNames.clear();
        _originalShopFeesVND.clear();
        _shopFreeDeliverySavings.clear();
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
        _shopShippingFeesVND.clear();
        _shopNames.clear();
        _originalShopFeesVND.clear();
        _shopFreeDeliverySavings.clear();
      });
      return;
    }

    final selectedAddress = addressController.addressList![orderProvider.addressIndex!];
    final toDistrictId = int.tryParse(selectedAddress.district ?? '0') ?? 0;
    final toWardCode = selectedAddress.province ?? '';

    if (toDistrictId == 0 || toWardCode.isEmpty) {
      setState(() {
        _shippingError = 'Invalid delivery address';
        _calculatedShippingFee = 0;
        _shopShippingFeesVND.clear();
        _shopNames.clear();
        _originalShopFeesVND.clear();
        _shopFreeDeliverySavings.clear();
      });
      return;
    }

    setState(() {
      _isCalculatingShipping = true;
      _shippingError = null;
      _shopShippingFeesVND.clear();
      _shopNames.clear();
      _originalShopFeesVND.clear();
      _shopFreeDeliverySavings.clear();
    });

    try {
      double totalShippingCostVND = 0;
      final cartIdsByGroup = _getCartIdsByGroupId();
      final shopInfoByGroup = _getShopInfoByGroupId();

      final couponProvider = Provider.of<CouponController>(context, listen: false);
      final hasCoupon = couponProvider.isApplied;

      debugPrint("🎟️ Coupon status:");
      debugPrint("hasCoupon (applied): $hasCoupon");
      debugPrint("   → hasCoupon: $hasCoupon");
      debugPrint("   → couponCode: '${couponProvider.couponCode}'");
      debugPrint("   → discount: ${couponProvider.discount}");

      for (final entry in cartIdsByGroup.entries) {
        final groupId = entry.key;
        final cartIds = entry.value;
        if (cartIds.isEmpty) continue;

        final shopInfo = shopInfoByGroup[groupId];
        if (shopInfo == null) continue;

        final (fromDistrictId, fromWardId, shopName, shopId) = shopInfo;

        final requestBody = {
          "seller": jsonEncode({
            "from_district_id": fromDistrictId,
            "from_ward_id": fromWardId,
          }),
          "cart_id": cartIds,
          "to_district_id": toDistrictId,
          "to_ward_code": toWardCode,
        };

        debugPrint("📦 Calculating shipping for shop $shopId ($shopName)...");

        final response = await http.post(
          Uri.parse('https://vnshop247.com/api/v1/shippingAPI/ghn/calculate-fee'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['ok'] == true) {
            final feeVND = (data['totalShippingCost'] ?? 0).toDouble();
            final shopIdStr = shopId.toString();

            _originalShopFeesVND[shopIdStr] = feeVND;
            _shopShippingFeesVND[shopIdStr] = feeVND;
            _shopNames[shopIdStr] = shopName;

            debugPrint("💰 Shop $shopId: Original shipping fee = $feeVND VND");
            debugPrint("🎟️ hasCoupon = $hasCoupon (discount: ${couponProvider.discount}, code: ${couponProvider.couponCode})");

            if (hasCoupon) {
              debugPrint("🔍 BẮT ĐẦU kiểm tra free delivery cho shop $shopId ($shopName)...");

              final cartIdForCheck = cartIds.first;
              final sellerIdForCheck = shopId ?? 0;

              debugPrint("   → cart_id: $cartIdForCheck");
              debugPrint("   → seller_id: $sellerIdForCheck");
              debugPrint("   → fee: $feeVND VND");

              try {
                debugPrint("   → Đang gọi API _checkFreeDeliveryForShop...");
                final isFree = await _checkFreeDeliveryForShop(
                  feeVND: feeVND,
                  cartId: cartIdForCheck,
                  sellerId: sellerIdForCheck,
                );

                debugPrint("   → Kết quả trả về: isFree = $isFree");

                if (isFree) {
                  _shopFreeDeliverySavings[shopIdStr] = feeVND;
                  _shopShippingFeesVND[shopIdStr] = 0;
                  debugPrint("✅ Shop $shopId được MIỄN PHÍ vận chuyển! Tiết kiệm $feeVND VND");
                } else {
                  debugPrint("❌ Shop $shopId KHÔNG được miễn phí vận chuyển");
                }
              } catch (e) {
                debugPrint("⚠️ Lỗi khi kiểm tra free delivery cho shop $shopId: $e");
              }
            } else {
              debugPrint("⚠️ KHÔNG CÓ COUPON - Bỏ qua kiểm tra free delivery");
              debugPrint("   → discount: ${couponProvider.discount}");
              debugPrint("   → couponCode: ${couponProvider.couponCode}");
            }

            totalShippingCostVND += _shopShippingFeesVND[shopIdStr]!;
          } else {
            setState(() {
              _shippingError = data['message'] ?? 'Shipping calculation failed';
              _isCalculatingShipping = false;
            });
            return;
          }
        } else {
          setState(() {
            _shippingError = 'Server error: ${response.statusCode}';
            _isCalculatingShipping = false;
          });
          return;
        }
      }

      final totalShippingCostUSD = _convertVNDtoUSD(totalShippingCostVND);

      debugPrint("📊 Final shipping summary:");
      debugPrint("   Total VND: $totalShippingCostVND");
      debugPrint("   Total USD: $totalShippingCostUSD");
      debugPrint("   Free delivery savings: ${_shopFreeDeliverySavings.length} shops");

      setState(() {
        _calculatedShippingFee = totalShippingCostUSD;
        _isCalculatingShipping = false;
        _shippingError = null;
      });
    } catch (e, stack) {
      debugPrint("❌ Exception in shipping calculation: $e\n$stack");
      setState(() {
        _shippingError = 'Network error: $e';
        _isCalculatingShipping = false;
        _calculatedShippingFee = 0;
        _shopShippingFeesVND.clear();
        _shopNames.clear();
        _originalShopFeesVND.clear();
        _shopFreeDeliverySavings.clear();
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
                              SizedBox(width: 30, height: 30, child: CircularProgressIndicator())
                            ],
                          )
                              : Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            color: Theme.of(context).cardColor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CheckoutConditionCheckBox(),
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                CustomButton(
                                  onTap: (orderProvider.isLoading || !orderProvider.isAcceptTerms)
                                      ? null
                                      : () async {
                                    if (orderProvider.addressIndex == null && widget.hasPhysical) {
                                      Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => const SavedAddressListScreen()));
                                      showCustomSnackBar(
                                          getTranslated('select_a_shipping_address', context), context,
                                          isToaster: true);
                                      return;
                                    }

                                    if (!orderProvider.isCheckCreateAccount ||
                                        (orderProvider.isCheckCreateAccount &&
                                            (passwordFormKey.currentState?.validate() ?? false))) {
                                      String orderNote = orderProvider.orderNoteController.text.trim();
                                      String couponCode = couponProvider.discount != null && couponProvider.discount != 0
                                          ? couponProvider.couponCode
                                          : '';
                                      String couponCodeAmount = couponProvider.discount != null && couponProvider.discount != 0
                                          ? couponProvider.discount.toString()
                                          : '0';

                                      String addressId = orderProvider.addressIndex != null
                                          ? locationProvider.addressList![orderProvider.addressIndex!].id.toString()
                                          : '';
                                      String billingAddressId = addressId;

                                      double finalShippingFee = widget.hasPhysical ? _calculatedShippingFee : 0;

                                      if (orderProvider.paymentMethodIndex != -1) {
                                        final checkedIds = _buildCheckedIds();

                                        orderProvider.digitalPaymentPlaceOrder(
                                          orderNote: orderNote,
                                          customerId: Provider.of<AuthController>(context, listen: false).isLoggedIn()
                                              ? profileProvider.userInfoModel?.id.toString()
                                              : Provider.of<AuthController>(context, listen: false).getGuestToken(),
                                          addressId: addressId,
                                          billingAddressId: billingAddressId,
                                          couponCode: couponCode,
                                          couponDiscount: couponCodeAmount,
                                          paymentMethod: orderProvider.selectedDigitalPaymentMethodName,
                                          checkedIds: checkedIds,
                                        );
                                      } else if (orderProvider.isCODChecked && !widget.onlyDigital) {
                                        final checkedIds = _buildCheckedIds();
                                        orderProvider.placeOrder(
                                          callback: _callback,
                                          addressID: addressId,
                                          couponCode: couponCode,
                                          couponAmount: couponCodeAmount,
                                          billingAddressId: billingAddressId,
                                          orderNote: orderNote,
                                          checkedIds: checkedIds,
                                        );
                                      } else if (orderProvider.isOfflineChecked) {
                                        Navigator.of(context).push(MaterialPageRoute(
                                            builder: (_) => OfflinePaymentScreen(
                                                payableAmount: _order +
                                                    finalShippingFee -
                                                    widget.discount -
                                                    (_referralDiscount ?? 0) -
                                                    (_couponDiscount ?? 0) +
                                                    widget.tax,
                                                callback: _callback)));
                                      } else if (orderProvider.isWalletChecked) {
                                        showAnimatedDialog(
                                          context,
                                          WalletPaymentWidget(
                                            currentBalance: profileProvider.balance ?? 0,
                                            orderAmount: _order +
                                                finalShippingFee -
                                                widget.discount -
                                                (_referralDiscount ?? 0) -
                                                (_couponDiscount ?? 0) +
                                                widget.tax,
                                            onTap: () {
                                              if (profileProvider.balance! <
                                                  (_order +
                                                      finalShippingFee -
                                                      widget.discount -
                                                      (_referralDiscount ?? 0) -
                                                      (_couponDiscount ?? 0) +
                                                      widget.tax)) {
                                                showCustomSnackBar(
                                                    getTranslated('insufficient_balance', context), context,
                                                    isToaster: true);
                                              } else {
                                                Navigator.pop(context);
                                                orderProvider.placeOrder(
                                                  callback: _callback,
                                                  wallet: true,
                                                  addressID: addressId,
                                                  couponCode: couponCode,
                                                  couponAmount: couponCodeAmount,
                                                  billingAddressId: billingAddressId,
                                                  orderNote: orderNote,
                                                );
                                              }
                                            },
                                          ),
                                          dismissible: false,
                                          willFlip: true,
                                        );
                                      } else {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (c) => PaymentMethodBottomSheetWidget(onlyDigital: widget.onlyDigital),
                                        );
                                      }
                                    }
                                  },
                                  buttonText: '${getTranslated('proceed', context)}',
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
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
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                          child: ShippingDetailsWidget(
                            hasPhysical: widget.hasPhysical,
                            passwordFormKey: passwordFormKey,
                            onAddressChanged: () {
                              setState(() {
                                _calculatedShippingFee = 0;
                                _shippingError = null;
                                _shopShippingFeesVND.clear();
                                _shopNames.clear();
                                _originalShopFeesVND.clear();
                                _shopFreeDeliverySavings.clear();
                              });
                              debounceHelper.run(() {
                                if (mounted) {
                                  _calculateShippingFee();
                                }
                              });
                            },
                          ),
                        ),
                        if (Provider.of<AuthController>(context, listen: false).isLoggedIn())
                          Padding(
                            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                            child: CouponApplyWidget(couponController: _controller, orderAmount: _order),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                          child: ChoosePaymentWidget(onlyDigital: widget.onlyDigital),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
                          child: Text(
                            getTranslated('order_summary', context) ?? '',
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                          child: Consumer<CheckoutController>(
                            builder: (context, checkoutController, child) {
                              _couponDiscount = Provider.of<CouponController>(context).discount ?? 0;
                              _referralDiscount = Provider.of<CheckoutController>(context).referralAmount?.amount ?? 0;

                              double finalShippingFee = widget.hasPhysical ? _calculatedShippingFee : 0;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  widget.quantity > 1
                                      ? AmountWidget(
                                    title: '${getTranslated('sub_total', context)} (${widget.quantity} ${getTranslated('items', context)})',
                                    amount: PriceConverter.convertPrice(context, _order),
                                  )
                                      : AmountWidget(
                                    title: '${getTranslated('sub_total', context)} (${widget.quantity} ${getTranslated('item', context)})',
                                    amount: PriceConverter.convertPrice(context, _order),
                                  ),

                                  if (_shopFreeDeliverySavings.isNotEmpty)
                                    Column(
                                      children: _shopFreeDeliverySavings.entries.map((entry) {
                                        final shopId = entry.key;
                                        final savedVND = entry.value;
                                        final savedUSD = _convertVNDtoUSD(savedVND);
                                        final shopName = _shopNames[shopId] ?? "Shop $shopId";

                                        return AmountWidget(
                                          title: 'Miễn phí vận chuyển ($shopName)',
                                          amount: '-${PriceConverter.convertPrice(context, savedUSD)}',
                                          amountStyle: TextStyle(color: Colors.green),
                                        );
                                      }).toList(),
                                    ),

                                  if (widget.hasPhysical)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
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
                                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                          ],
                                        ),

                                        if (!_isCalculatingShipping && _shippingError == null && _shopNames.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 16, top: 4),
                                            child: Column(
                                              children: _shopNames.entries.map((entry) {
                                                final shopId = entry.key;
                                                final shopName = entry.value;
                                                final feeVND = _shopShippingFeesVND[shopId] ?? 0;
                                                final originalFeeVND = _originalShopFeesVND[shopId] ?? 0;
                                                final feeUSD = _convertVNDtoUSD(feeVND);
                                                final isFree = feeVND == 0 && originalFeeVND > 0;

                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 1),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        "• $shopName${isFree ? ' (Miễn phí)' : ''}",
                                                        style: textRegular.copyWith(
                                                          fontSize: Dimensions.fontSizeSmall,
                                                          color: isFree ? Colors.green : Theme.of(context).hintColor,
                                                        ),
                                                      ),
                                                      Text(
                                                        isFree ? 'Miễn phí' : PriceConverter.convertPrice(context, feeUSD),
                                                        style: textRegular.copyWith(
                                                          fontSize: Dimensions.fontSizeSmall,
                                                          color: isFree ? Colors.green : null,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    ),

                                  if (_shippingError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _shippingError!,
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ),

                                  AmountWidget(title: getTranslated('discount', context), amount: PriceConverter.convertPrice(context, widget.discount)),
                                  AmountWidget(title: getTranslated('coupon_voucher', context), amount: PriceConverter.convertPrice(context, _couponDiscount)),
                                  AmountWidget(title: getTranslated('tax', context), amount: PriceConverter.convertPrice(context, widget.tax)),
                                  if ((_referralDiscount ?? 0) > 0)
                                    AmountWidget(title: getTranslated('referral_discount', context), amount: PriceConverter.convertPrice(context, _referralDiscount)),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  Divider(height: 5, color: Theme.of(context).hintColor),
                                  AmountWidget(
                                    title: getTranslated('total_payable', context),
                                    amount: PriceConverter.convertPrice(
                                      context,
                                      _order + finalShippingFee - (_referralDiscount ?? 0) - widget.discount - (_couponDiscount ?? 0) + widget.tax,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${getTranslated('order_note', context)}',
                                style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              CustomTextFieldWidget(
                                hintText: getTranslated('enter_note', context),
                                inputType: TextInputType.multiline,
                                inputAction: TextInputAction.done,
                                maxLines: 3,
                                focusNode: _orderNoteNode,
                                controller: Provider.of<CheckoutController>(context).orderNoteController,
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
      Navigator.of(Get.context!).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
      showAnimatedDialog(
        context,
        OrderPlaceDialogWidget(
          icon: Icons.check,
          title: getTranslated(createAccount ? 'order_placed_Account_Created' : 'order_placed', context),
          description: getTranslated('your_order_placed', context),
          isFailed: false,
        ),
        dismissible: false,
        willFlip: true,
      );
    } else {
      showCustomSnackBar(message, context, isToaster: true);
    }
  }
}