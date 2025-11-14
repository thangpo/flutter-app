import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/domain/models/coupon_item_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/domain/models/coupon_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

class CouponController extends ChangeNotifier {
  final CouponServiceInterface? couponRepo;
  CouponController({required this.couponRepo});

  CouponModel? _coupon;
  double? _discount;
  bool _isLoading = false;
  CouponModel? get coupon => _coupon;
  double? get discount => _discount;
  bool get isLoading => _isLoading;
  String _couponCode = '';
  bool _isApplied = false;
  String get couponCode => _couponCode;
  bool get isApplied => _isApplied;

  void removeCoupon(){
    debugPrint("🗑️ Removing coupon: code=$_couponCode, discount=$_discount");
    _discount = null;
    _couponCode = '';
    _isApplied = false;
    Provider.of<CheckoutController>(Get.context!, listen: false).getReferralAmount('0');
    notifyListeners();
    debugPrint("✅ Coupon removed");
  }

  Future<void> applyCoupon(BuildContext context, String coupon, double order) async {
    debugPrint("🎫 Applying coupon: code=$coupon, order=$order");

    _isLoading = true;
    notifyListeners();

    ApiResponseModel apiResponse = await couponRepo!.get(coupon);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data;

      debugPrint("📋 Coupon API response: $map");

      // Xử lý discount value TRƯỚC
      if (map['coupon_discount'] != null) {
        try {
          String dis = map['coupon_discount'].toString();
          _discount = double.parse(dis);
        } catch (e) {
          debugPrint("⚠️ Error parsing discount: $e, setting discount to 0");
          _discount = 0.0;
        }
      } else {
        _discount = 0.0;
      }

      // SAU ĐÓ mới set coupon code và isApplied
      // QUAN TRỌNG: Luôn set isApplied = true và lưu couponCode, bất kể discount là bao nhiêu
      _couponCode = coupon;
      _isApplied = true;

      debugPrint("✅ Coupon applied: code=$_couponCode, discount=$_discount, isApplied=$_isApplied");

      _isLoading = false;
      notifyListeners();

      // Hiển thị thông báo cho user
      if (_discount! > 0) {
        showCustomSnackBar(
            '${getTranslated('you_got', Get.context!)} '
                '${PriceConverter.convertPrice(Get.context!, _discount)} '
                '${getTranslated('discount', Get.context!)}',
            Get.context!,
            isError: false,
            isToaster: true
        );
      } else {
        // Thông báo khi discount = 0 - có thể nhận ưu đãi khác
        showCustomSnackBar(
            'Mã "$coupon" đã được áp dụng thành công!',
            Get.context!,
            isError: false,
            isToaster: true
        );
      }

      // Cập nhật checkout controller với giá trị discount (kể cả khi = 0)
      Provider.of<CheckoutController>(Get.context!, listen: false)
          .getReferralAmount(PriceConverter.convertPriceWithoutSymbol(Get.context!, _discount));

    } else {
      debugPrint("❌ Coupon apply failed: ${apiResponse.response?.data}");
      _isLoading = false;
      _isApplied = false;
      _couponCode = '';
      _discount = null;
      notifyListeners();

      showCustomSnackBar(apiResponse.response?.data, Get.context!, isToaster: true);
    }
  }

  List<Coupons>? couponList;
  CouponItemModel? couponItemModel;

  Future<void> getCouponList(BuildContext context, int offset) async {
    _isLoading = true;
    ApiResponseModel apiResponse = await couponRepo!.getList(offset: offset);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      couponList = [];
      _isLoading = false;
      couponList!.addAll(CouponItemModel.fromJson(apiResponse.response!.data).coupons!);
      couponItemModel = CouponItemModel.fromJson(apiResponse.response!.data);
    }
    _isLoading = false;
    notifyListeners();
  }

  List<Coupons>? availableCouponList;

  Future<void> getAvailableCouponList() async {
    availableCouponList = [];
    ApiResponseModel apiResponse = await couponRepo!.getAvailableCouponList();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      apiResponse.response?.data.forEach((coupon) => availableCouponList?.add(Coupons.fromJson(coupon)));
    }
    notifyListeners();
  }

  int couponCurrentIndex = 0;

  void setCurrentIndex(int index) {
    couponCurrentIndex = index;
    notifyListeners();
  }

  Future<void> getSellerWiseCouponList(int sellerId, int offset) async {
    _isLoading = true;
    ApiResponseModel apiResponse = await couponRepo!.getSellerCouponList(sellerId, offset);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isLoading = false;
      couponItemModel = CouponItemModel.fromJson(apiResponse.response!.data);
    } else {
      showCustomSnackBar(apiResponse.response!.data, Get.context!, isToaster: true);
    }
    _isLoading = false;
    notifyListeners();
  }

  void removePrevCouponData() {
    debugPrint("🧹 Removing previous coupon data");
    _coupon = null;
    _isLoading = false;
    _discount = null;
    _couponCode = '';
    _isApplied = false;
    debugPrint("✅ Previous coupon data cleared");
  }
}