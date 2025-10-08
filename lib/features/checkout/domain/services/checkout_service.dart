import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/services/checkout_service_interface.dart';

class CheckoutService implements CheckoutServiceInterface{
  CheckoutRepositoryInterface checkoutRepositoryInterface;


  CheckoutService({required this.checkoutRepositoryInterface});

  @override
  Future cashOnDeliveryPlaceOrder({String? addressID,
    String? couponCode,
    String? couponDiscountAmount,
    String? billingAddressId,
    String? orderNote,
    bool? isCheckCreateAccount,
    String? password,
    double? cashChangeAmount,
    String? currentCurrencyCode,
  }) async{
    return await checkoutRepositoryInterface.cashOnDeliveryPlaceOrder(
     addressID: addressID,
      couponCode: couponCode,
      couponDiscountAmount: couponDiscountAmount,
      billingAddressId: billingAddressId,
      orderNote: orderNote,
      isCheckCreateAccount: isCheckCreateAccount,
      password: password,
      cashChangeAmount: cashChangeAmount,
      currentCurrencyCode: currentCurrencyCode,
    );
  }

  @override
  Future digitalPaymentPlaceOrder(String? orderNote, String? customerId, String? addressId, String? billingAddressId, String? couponCode, String? couponDiscount, String? paymentMethod, bool? isCheckCreateAccount, String? password) async {
    return await checkoutRepositoryInterface.digitalPaymentPlaceOrder(orderNote, customerId, addressId, billingAddressId, couponCode, couponDiscount, paymentMethod, isCheckCreateAccount, password);
  }

  @override
  Future offlinePaymentList()  async{
   return await checkoutRepositoryInterface.offlinePaymentList();
  }

  @override
  Future offlinePaymentPlaceOrder(String? addressID, String? couponCode, String? couponDiscountAmount, String? billingAddressId, String? orderNote, List<String?> typeKey, List<String> typeValue, int? id, String name, String? paymentNote,bool? isCheckCreateAccount, String? password) async{
    return await checkoutRepositoryInterface.offlinePaymentPlaceOrder(addressID, couponCode, couponDiscountAmount, billingAddressId, orderNote, typeKey, typeValue, id, name, paymentNote, isCheckCreateAccount, password);
  }

  @override
  Future walletPaymentPlaceOrder(String? addressID, String? couponCode, String? couponDiscountAmount, String? billingAddressId, String? orderNote, bool? isCheckCreateAccount, String? password) async{
    return await checkoutRepositoryInterface.walletPaymentPlaceOrder(addressID, couponCode, couponDiscountAmount, billingAddressId, orderNote, isCheckCreateAccount, password);
  }

  @override
  Future getReferralAmount(String? amount) async {
    return await checkoutRepositoryInterface.getReferralAmount(amount);
  }
}