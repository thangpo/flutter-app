import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/controllers/refund_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/widgets/refund_image_selection_widget.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

import '../../product/domain/models/product_model.dart';

class RefundRequestWidget extends StatefulWidget {
  final Product? product;
  final int orderDetailsId;
  final String orderId;
  const RefundRequestWidget({super.key, this.product, required this.orderDetailsId, required this.orderId});

  @override
  State<RefundRequestWidget> createState() => _RefundRequestWidgetState();
}

class _RefundRequestWidgetState extends State<RefundRequestWidget> {

  final TextEditingController _refundReasonController = TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _refundReasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('refund_request', context)),
      body: SingleChildScrollView(
        child: Consumer<RefundController>(
            builder: (context, refundController, _) {
              return Column(children: [

                (refundController.refundInfoModel != null && refundController.refundInfoModel!.refund != null)?
                Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor,
                            boxShadow: Provider.of<ThemeController>(context, listen: false).darkTheme ? null :
                            [BoxShadow(color: Colors.grey.withValues(alpha:.2), spreadRadius: 1,
                                blurRadius: 7, offset: const Offset(0, 1))],
                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
                        child: Column(children: [

                          TitleWithAmountRow(title: getTranslated('total_price', context)!,
                              amount: PriceConverter.convertPrice(context,
                                  refundController.refundInfoModel!.refund!.productPrice!*refundController.refundInfoModel!.refund!.quntity!)),

                          Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                              child: TitleWithAmountRow(title: getTranslated('product_discount', context)!,
                                  amount: '-${PriceConverter.convertPrice(context, refundController.refundInfoModel!.refund!.productTotalDiscount)}')),

                          TitleWithAmountRow(title: getTranslated('tax', context)!,
                              amount: PriceConverter.convertPrice(context, refundController.refundInfoModel!.refund!.productTotalTax)),

                          Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                              child: TitleWithAmountRow(title: getTranslated('sub_total', context)!,
                                  amount: PriceConverter.convertPrice(context, refundController.refundInfoModel!.refund!.subtotal))),

                          TitleWithAmountRow(title: getTranslated('coupon_discount', context)!,
                              amount: PriceConverter.convertPrice(context, refundController.refundInfoModel!.refund!.couponDiscount)),

                          if((refundController.refundInfoModel?.refund?.referralDiscount ?? 0) > 0) ...[
                            const SizedBox(height: Dimensions.paddingSizeSmall),

                            TitleWithAmountRow(
                              title: getTranslated('referral_discount', context)!,
                              amount: '-${PriceConverter.convertPrice(context, refundController.refundInfoModel!.refund!.referralDiscount)}',
                            ),
                          ],


                          Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                              child: Divider(color: Theme.of(context).primaryColor.withValues(alpha:0.125), height: 2)),

                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(getTranslated('total_refund_amount', context)!, style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color) ),
                            Text(PriceConverter.convertPrice(context, refundController.refundInfoModel!.refund!.refundAmount),
                                style: robotoBold)])]))]),
                ): const SizedBox(),


                const SizedBox(height: Dimensions.paddingSizeDefault),


                Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Row(children: [
                      Text(getTranslated('refund_reason', context)!, style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color )),
                      Icon(Icons.keyboard_arrow_down, color: Theme.of(context).hintColor, size: 30)])),

                Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: CustomTextFieldWidget(maxLines: 4,
                        controller: _refundReasonController, inputAction: TextInputAction.done)
                ),


                const RefundImageSelectionWidget(),

                refundController.isLoading? const Center(child: CircularProgressIndicator()) :
                Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall), child: CustomButton(
                  buttonText: getTranslated('send_request', context),
                  onTap: () {String reason  = _refundReasonController.text.trim().toString();
                  if(reason.isEmpty) {
                    showCustomSnackBar(getTranslated('reason_required', context)??'', context);
                  }else {
                    refundController.refundRequest(widget.orderId, widget.orderDetailsId, refundController.refundInfoModel!.refund!.refundAmount,reason);}
                  },
                )),
              ]);
            }
        ),
      ),
    );
  }
}


class TitleWithAmountRow extends StatelessWidget {
  final String title;
  final String amount;
  const TitleWithAmountRow({
    super.key, required this.title, required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: textRegular.copyWith(color: Theme.of(context).hintColor)),
      Text(amount, style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
    ],
    );
  }
}
