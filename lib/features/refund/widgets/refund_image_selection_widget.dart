import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/controllers/refund_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

class RefundImageSelectionWidget extends StatelessWidget {
  const RefundImageSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RefundController>(
        builder: (context, refundProvider,_) {
          return Column(children: [

            refundProvider.refundImage.isNotEmpty?
            SizedBox(height: 100, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: refundProvider.refundImage.length,
                itemBuilder: (BuildContext context, index){
                  return  refundProvider.refundImage.isNotEmpty ?
                  Padding(padding: const EdgeInsets.all(8.0), child: Stack(children: [
                    Container(width: 100, height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault)),
                        child: Image.file(File(refundProvider.refundImage[index]!.path), width: 100, height: 100, fit: BoxFit.cover),
                      ),
                    ),


                    Positioned(top:0,right:0, child: InkWell(onTap :() => refundProvider.removeRefundImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).hintColor,
                          borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.clear,color: Colors.white,size: Dimensions.iconSizeExtraSmall),
                        ),
                      ),
                    )),
                  ])) : const SizedBox();})
            ) : const SizedBox(),


            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).hintColor.withValues(alpha:0.5)),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall)
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: InkWell(
                onTap: () => refundProvider.pickRefundImage(false),
                child: SizedBox(height: 30, child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    getTranslated('upload_image', context)!,
                    style: textRegular.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Image.asset(Images.uploadImage, color: Theme.of(context).primaryColor),
                ],
                )),
              ),
            ),
          ]);
        }
    );
  }
}
