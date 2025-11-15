import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/coupon_bottom_sheet_widget.dart';
import 'package:provider/provider.dart';

class CouponApplyWidget extends StatelessWidget {
  final TextEditingController couponController;
  final double orderAmount;
  const CouponApplyWidget({super.key, required this.couponController, required this.orderAmount});

  @override
  Widget build(BuildContext context) {
    return Consumer<CouponController>(
        builder: (context, couponProvider, _) {
          return Padding(
            padding: const EdgeInsets.only(
                left: Dimensions.paddingSizeDefault,
                right: Dimensions.paddingSizeDefault
            ),
            child: Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                  border: Border.all(
                      width: .5,
                      color: Theme.of(context).primaryColor.withValues(alpha: .25)
                  )
              ),

              // THAY ĐỔI CHÍNH: Kiểm tra isApplied thay vì discount != 0
              child: couponProvider.isApplied
                  ? _buildAppliedCoupon(context, couponProvider)
                  : _buildAddCouponButton(context),
            ),
          );
        }
    );
  }

  // Widget hiển thị khi đã áp mã
  Widget _buildAppliedCoupon(BuildContext context, CouponController couponProvider) {
    final hasDiscount = (couponProvider.discount ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                    height: 25,
                    width: 25,
                    child: Image.asset(Images.appliedCoupon)
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeExtraSmall
                  ),
                  child: Text(
                    couponProvider.couponCode,
                    style: textBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).textTheme.bodyLarge?.color
                    ),
                  ),
                ),

                // Hiển thị discount nếu > 0, hoặc text khác nếu = 0
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeExtraSmall
                    ),
                    child: hasDiscount
                        ? Text(
                      '(-${PriceConverter.convertPrice(context, couponProvider.discount)} off)',
                      style: textMedium.copyWith(
                          color: Theme.of(context).primaryColor
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                        : Text(
                      '(Ưu đãi đặc biệt)',
                      style: textMedium.copyWith(
                          color: Theme.of(context).primaryColor
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          InkWell(
              onTap: () => couponProvider.removeCoupon(),
              child: Icon(
                  Icons.clear,
                  color: Theme.of(context).colorScheme.error
              )
          ),
        ],
      ),
    );
  }

  // Widget hiển thị nút thêm mã
  Widget _buildAddCouponButton(BuildContext context) {
    return InkWell(
      onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (c) => CouponBottomSheetWidget(orderAmount: orderAmount)
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${getTranslated('add_coupon', context)}',
              style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color
              ),
            ),
            Text(
                '${getTranslated('add_more', context)}',
                style: textMedium.copyWith(
                    color: Theme.of(context).primaryColor
                )
            ),
          ],
        ),
      ),
    );
  }
}