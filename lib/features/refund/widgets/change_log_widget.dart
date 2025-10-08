import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_details_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/controllers/refund_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class ChangeLogWidget extends StatelessWidget {
  const ChangeLogWidget({super.key});

  @override
  Widget build(BuildContext context) {

    return Consumer<RefundController>(
      builder: (context, refundReq, _) {
        return Container(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(color: Colors.grey[Provider.of<ThemeController>(context).darkTheme ? 800 : 200]!,
                spreadRadius: 0.5, blurRadius: 0.3)],),
          child: refundReq.refundResultModel != null? (refundReq.refundResultModel!.refundRequest != null && refundReq.refundResultModel!.refundRequest!.isNotEmpty)?
          ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: refundReq.refundResultModel!.refundRequest![0].refundStatus?.length,
              itemBuilder: (context,index) {
                return Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Expanded(flex: 1, child:Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 40,height: 40,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeLarge),
                          color: Theme.of(context).primaryColor,),
                        child: Padding(
                          padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall, top: Dimensions.paddingSizeEight, right: Dimensions.paddingSizeEight, bottom: Dimensions.paddingSizeEight),
                          child: Image.asset(Images.refundLogImage),
                        ),
                    ),

                    index == refundReq.refundResultModel!.refundRequest![0].refundStatus!.length-1? const SizedBox():
                    Container(height : 60,width: 2, color: Theme.of(context).primaryColor)],)),


                  Expanded(flex:6,
                    child: Container(margin: const EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall,
                        right: Dimensions.paddingSizeExtraSmall, top: Dimensions.paddingSizeSmall),

                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        ItemWidget(lestValue: 'refund_request_status', rightValue: refundReq.refundResultModel!.refundRequest![0].refundStatus![index].status!),

                        Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                            child: ItemWidget(lestValue: 'updated_by', rightValue: refundReq.refundResultModel!.refundRequest![0].refundStatus![index].changeBy ?? '',
                            ),
                        ),

                        refundReq.refundResultModel!.refundRequest![0].refundStatus![index].message != null && refundReq.refundResultModel!.refundRequest![0].refundStatus![index].message!.isNotEmpty
                            ? ItemWidget(lestValue: 'reason', rightValue: refundReq.refundResultModel!.refundRequest![0].refundStatus![index].message ?? '')
                            : const SizedBox.shrink(),

                      ]),
                    ),
                  ),
                ],
                );
              }
          ): Center(child: Image.asset(Images.noData)) : const Expanded(child: Center(child: CircularProgressIndicator())),
        );
      }
    );
  }
}

class ItemWidget extends StatelessWidget {
  final String? lestValue;
  final String? rightValue;
  final bool isPayment;
  final TextStyle? style;
  const ItemWidget({super.key, required this.lestValue, required this.rightValue,  this.isPayment = false, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${getTranslated(lestValue, context)} : ',
          style: style ??  titilliumRegular.copyWith(color: Theme.of(context).hintColor,
              fontSize: Dimensions.fontSizeDefault)),
      Expanded(
        child: Text(rightValue?.capitalize() ?? '', style: robotoBold.copyWith(color: rightValue! == 'Pending'? Theme.of(context).primaryColor : rightValue! == 'Refunded'? Theme.of(context).colorScheme.onTertiaryContainer : rightValue! == 'Rejected'? Theme.of(context).colorScheme.error : rightValue! == 'Approved'? Theme.of(context).colorScheme.onTertiaryContainer : isPayment? Theme.of(context).colorScheme.onTertiaryContainer : Theme.of(context).hintColor,
            fontSize: Dimensions.fontSizeDefault), maxLines: 2, overflow: TextOverflow.ellipsis),
      )]);
  }
}
