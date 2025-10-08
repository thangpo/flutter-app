
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/models/order_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/controllers/review_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:provider/provider.dart';

class DeliveryManReviewDialogWidget extends StatefulWidget {
  final Function? callback;
  final DeliveryManReview? existingDeliveryManReview;
  final String? orderId;
  final String? deliverymanAssignedAt;
  final DeliveryMan? deliveryMan;


  const DeliveryManReviewDialogWidget({
    super.key,
    this.callback,
    this.existingDeliveryManReview,
    this.orderId,
    this.deliverymanAssignedAt,
    this.deliveryMan,
  });

  @override
  State<DeliveryManReviewDialogWidget> createState() => _DeliveryManReviewDialogWidgetState();
}

class _DeliveryManReviewDialogWidgetState extends State<DeliveryManReviewDialogWidget> {
  final TextEditingController _controller = TextEditingController();




  Future<void> _loadData() async{
    final reviewController = Provider.of<ReviewController>(Get.context!, listen: false);

    if(widget.existingDeliveryManReview != null){
      reviewController.setRating(widget.existingDeliveryManReview?.rating ?? 0, isUpdate: false);
      _controller.text = widget.existingDeliveryManReview?.comment ?? '';
    }
  }



  @override
  void initState() {
    super.initState();

    _loadData();
  }


  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewController>(
        builder: (context, reviewController, _) {
          final double widthSize = MediaQuery.of(context).size.width;

          return Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault), color: Theme.of(context).cardColor),
            width: widthSize * 0.92,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall).copyWith(top: Dimensions.paddingSizeSmall),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              
                Align(alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha:0.20)),
                      child: Icon(Icons.clear, color: Theme.of(context).cardColor, size: Dimensions.paddingSizeDefault),
                    ),
                  ),
                ),
              
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.30), width: 1),
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(getTranslated('delivery_man', context)!, style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        )),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              
                        Row(children: [
              
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeLarge),
                            child: FadeInImage.assetNetwork(
                              placeholder: Images.placeholder, fit: BoxFit.scaleDown, width: Dimensions.paddingSizeButton, height: Dimensions.paddingSizeButton,
                              image: '${widget.deliveryMan?.imageFullUrl?.path}',
                              imageErrorBuilder: (c, o, s) => Image.asset(
                                Images.placeholder,
                                fit: BoxFit.cover,
                                width: Dimensions.paddingSizeButton,
                                height: Dimensions.paddingSizeButton,
                              ),
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              
                            Text('${widget.deliveryMan?.fName} ${widget.deliveryMan?.lName}', style:  textMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
              
                            /// Delivery assign design skipped
                            Text.rich(TextSpan(children: [
                              TextSpan(text: '${getTranslated('assign', context)!} : ', style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              )),
              
              
                              TextSpan(text: DateConverter.localToIsoString(DateTime.tryParse(widget.deliverymanAssignedAt ?? '') ?? DateTime.now()), style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              )),
              
                            ])),
              
                          ])),
              
                        ]),
                      ]),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeButton),
              
                    Center(child: Text(getTranslated('rate_the_quality', context)!, style: textMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ))),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
              
                    Center(child: SizedBox(height: 60,
                      child: ListView.builder(
                          itemCount: 5,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () => reviewController.setRating(index+1),
                              child: Column(children: [
                                Icon(
                                  reviewController.rating < (index+1) ? Icons.star_outline_rounded : Icons.star_rate_rounded,
                                  size: 40,
                                  color: reviewController.rating < (index+1) ? Theme.of(context).primaryColor.withValues(alpha:0.125) : Theme.of(context).primaryColor,
                                ),
              
                                if(reviewController.rating > 0 && index == (reviewController.rating-1))
                                  Text(getTranslated(AppConstants.reviewList[reviewController.rating-1], context)!, style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Theme.of(context).primaryColor,
                                  )),
                              ]),
                            );
                          }
                      ),
                    )),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
              
              
                    Align(alignment: Alignment.centerLeft,
                      child: Text(getTranslated('have_thoughts_to_share', context)!, style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      )),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
              
                    CustomTextFieldWidget(
                      maxLines: 3,
                      hintText: getTranslated('super_fast_delivery', context),
                      controller: _controller,
                      inputAction: TextInputAction.done,
                      borderColor: Theme.of(context).hintColor,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
              
              
                    /// skipped
                    /// todo - need to updated the logic
                    /// add Image to review
                    // if(reviewController.orderWiseReview != null && reviewController.orderWiseReview!.attachmentFullUrl != null && reviewController.orderWiseReview!.attachmentFullUrl!.isNotEmpty)
                    //   Padding(padding: const EdgeInsets.symmetric(vertical : Dimensions.paddingSizeDefault),
                    //       child: SizedBox(height: 75,
                    //           child: ListView.builder(
                    //               shrinkWrap: true,
                    //               scrollDirection: Axis.horizontal,
                    //               itemCount : reviewController.orderWiseReview?.attachmentFullUrl?.length ,
                    //               itemBuilder: (BuildContext context, index){
                    //                 // log("--img--> ${Provider.of<SplashController>(context, listen: false).baseUrls?.reviewImageUrl}/${reviewController.orderWiseReview?.attachment?[index]}");
                    //                 return Stack(children: [
                    //
                    //                   Padding(
                    //                       padding: const EdgeInsets.only(right : Dimensions.paddingSizeSmall),
                    //                       child: Container(
                    //                           decoration: BoxDecoration(
                    //                             borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    //                           ),
                    //                           child: ClipRRect(
                    //                               borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    //                               child:  CustomImageWidget(image: "${reviewController.orderWiseReview?.attachmentFullUrl?[index].path}", height: 50, width: 50),
                    //                           ),
                    //                       ),
                    //                   ),
                    //
                    //
                    //                   Positioned(top:0,right: 0,
                    //                       child: InkWell(
                    //                           onTap :() => reviewController.deleteOrderWiseReviewImage(
                    //                               reviewController.orderWiseReview!.id!.toString(),
                    //                               reviewController.orderWiseReview!.attachmentFullUrl![index].key ?? '',
                    //                               widget.productID ?? '',
                    //                               widget.orderId ?? '',
                    //                           ),
                    //                           child: Container(
                    //                               decoration: const BoxDecoration(color: Colors.white,
                    //                               borderRadius: BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault))),
                    //                               child: Padding(
                    //                                   padding: const EdgeInsets.all(4.0),
                    //                                   child: Icon(Icons.cancel,color: Theme.of(context).hintColor, size: Dimensions.paddingSizeDefault),
                    //                               ),
                    //                           ),
                    //                       ),
                    //                   ),
                    //                 ]);
                    //               },
                    //           ),
                    //       ),
                    //   ),
                    //
                    //
                    // Padding(padding: const EdgeInsets.symmetric(vertical : Dimensions.paddingSizeDefault),
                    //     child: SizedBox(height: 70,
                    //         child: ListView.separated(
                    //             scrollDirection: Axis.horizontal,
                    //             itemCount : reviewController.reviewImages.length + 1 ,
                    //             itemBuilder: (BuildContext context, index){
                    //               return (reviewController.reviewImages.length < 6) && (index == reviewController.reviewImages.length) ?
                    //               Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
                    //                 child: InkWell(onTap: ()=> reviewController.pickImage(false, fromReview: true),
                    //                   child: DottedBorder(
                    //                     strokeWidth: 1,
                    //                     dashPattern: const [6,4],
                    //                     color: Theme.of(context).primaryColor,
                    //                     borderType: BorderType.RRect,
                    //                     radius: const Radius.circular(Dimensions.paddingSizeSmall),
                    //                     /// todo - change the image according to the figma design
                    //                     child: const Center(child: Padding(
                    //                       padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                    //                       child: CustomAssetImageWidget(Images.uploadImage, height: Dimensions.marginSizeAuthSmall, width: Dimensions.marginSizeAuthSmall),
                    //                     )),
                    //
                    //                   ),
                    //                 ),
                    //               ) :
                    //               Stack(children: [
                    //                 Container(
                    //                   margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
                    //                     decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(20))),
                    //                     child: ClipRRect(
                    //                         borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeExtraSmall)),
                    //                         child:  Image.file(File(reviewController.reviewImages[index].path), width: 60, height: 60, fit: BoxFit.cover),
                    //                     ),
                    //                 ),
                    //
                    //                 Positioned(top:0,right: 0,
                    //                   child: InkWell(
                    //                     onTap :() => reviewController.removeImage(index,fromReview: true),
                    //                     child: Container(
                    //                       padding: const EdgeInsets.all(3),
                    //                       decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha:0.30)),
                    //                       child: Icon(Icons.clear, color: Theme.of(context).cardColor, size: Dimensions.paddingSizeDefault),
                    //                     ),
                    //                   ),
                    //                 ),
                    //
                    //               ]);
                    //             },
                    //           separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeLarge),
                    //
                    //         ),
                    //     ),
                    // ),
              
              
                    Provider.of<ReviewController>(context).errorText != null ?
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(Provider.of<ReviewController>(context).errorText!, style: textRegular.copyWith(color: Theme.of(context).colorScheme.error)),
                    ) : const SizedBox.shrink(),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
              
              
                    Consumer<ReviewController>(builder: (context, reviewController,_) => Consumer<OrderDetailsController>(
                        builder: (context, orderDetailsController, _) {
                          return CustomButton(
                            isLoading: reviewController.isLoading,
                            buttonText: getTranslated('submit', context),
                            onTap: () {
                              if(reviewController.rating == 0) {
                                reviewController.setErrorText('${getTranslated('add_a_rating', context)}');
                              }else if(_controller.text.isEmpty) {
                                reviewController.setErrorText('${getTranslated('write_a_review', context)}');
                              }else if(isReviewUnchanged(reviewController)) {
                                reviewController.setErrorText('${getTranslated('modify_review_before_resubmitting', context)}');
                              }else {
                                reviewController.setErrorText('');
              
                                reviewController.submitDeliveryManReview(orderId: widget.orderId ?? '', comment: _controller.text).then((value) async {
                                  if(value.isSuccess) {
                                    await orderDetailsController.getOrderDetails(widget.orderId ?? '');
                                    if(context.mounted) {
                                      Navigator.pop(context);
                                      widget.callback!();
              
                                      FocusScopeNode currentFocus = FocusScope.of(context);
                                      if (!currentFocus.hasPrimaryFocus) {
                                        currentFocus.unfocus();
                                      }
              
                                      _controller.clear();
                                    }
                                  }else {
                                    reviewController.setErrorText(value.message);
                                  }
                                });
                              }
                            },
                          );
                        }
                    )),
                  ]),
                ),
              ]),
            ),
          );
        }
    );
  }

  bool isReviewUnchanged(ReviewController reviewController) => widget.existingDeliveryManReview != null && widget.existingDeliveryManReview?.rating == reviewController.rating && widget.existingDeliveryManReview?.comment == _controller.text;
}
