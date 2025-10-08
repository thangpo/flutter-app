import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/controllers/order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/models/order_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/controllers/review_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/widgets/review_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';

class ReviewButtonWidget extends StatefulWidget {
  final OrderDetailsModel orderDetailsModel;
  final String orderType;
  final String orderId;
  final Function callback;
  final int index;

  const ReviewButtonWidget({super.key, required this.orderDetailsModel, required this.orderType, required this.orderId, required this.callback, required this.index});

  @override
  State<ReviewButtonWidget> createState() => _ReviewButtonWidgetState();
}

class _ReviewButtonWidgetState extends State<ReviewButtonWidget> with TickerProviderStateMixin {


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.10)
        ),

        child: Column(children: [

          Consumer<OrderDetailsController>(
              builder: (context, orderProvider, child) {
                return Column(children: [

                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Row(children: [

                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const CustomAssetImageWidget(Images.myReviewIcon, height: 30, width: 30),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Text('${getTranslated('my_review', context)}', style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),

                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        if(widget.orderDetailsModel.deliveryStatus == 'delivered' && widget.orderType != "POS" && widget.orderDetailsModel.reviewModel != null)
                          Container(
                            height: 25, width: 25,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).cardColor,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15), // 15% opacity black
                                      offset: const Offset(0, 4),
                                      blurRadius: 4,
                                      spreadRadius: 0),
                                ]
                            ),

                            child: InkWell(
                              onTap: () async {
                                Provider.of<ReviewController>(context, listen: false).removeData();

                                await orderProvider.setOrderReviewExpanded(
                                  widget.index,
                                  (orderProvider.orderDetails?[widget.index].isExpanded ?? false) ? false : true,
                                );

                                if(orderProvider.orderDetails?[widget.index].isExpanded ?? false){
                                  await Provider.of<ReviewController>(context, listen: false).getOrderWiseReview(
                                    widget.orderDetailsModel.productId.toString(),
                                    widget.orderDetailsModel.orderId.toString(),
                                    showLoading: true,
                                  );
                                }
                              },
                              child: Icon(
                                  (orderProvider.orderDetails?[widget.index].isExpanded ?? false) ?
                                  Icons.keyboard_arrow_down : Icons.keyboard_arrow_up
                              ),
                            ),
                          ),
                      ]),

                      const Spacer(),
                      Consumer<OrderController>(
                          builder: (context, orderController, _) {
                            return orderController.orderTypeIndex == 1 && widget.orderType != "POS" ? InkWell(
                              onTap: () async {
                                if(orderController.orderTypeIndex == 1) {
                                  if(orderProvider.orderDetails?[widget.index].isExpanded ?? false){
                                    await orderProvider.setOrderReviewExpanded(
                                      widget.index,
                                      orderProvider.orderDetails![widget.index].isExpanded! ? false : true,
                                    );
                                    // _toggleExpansion();
                                  }
                                  Provider.of<ReviewController>(context, listen: false).removeData();
                                  showDialog(context: context, builder: (context) => Dialog(
                                    insetPadding: EdgeInsets.zero, backgroundColor: Colors.transparent,
                                    child: ReviewDialog(productID: widget.orderDetailsModel.productDetails!.id.toString(),
                                        orderId: widget.orderId,
                                        callback: widget.callback,
                                        orderDetailsModel: widget.orderDetailsModel,
                                        orderType: widget.orderType),
                                  ));
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),


                                child: Row(children: [

                                  const CustomAssetImageWidget(Images.myReviewIconWhite, height: 20, width: 20),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                  Text(
                                      widget.orderDetailsModel.reviewModel == null ?
                                      '${getTranslated('review_product', context)}' :
                                      '${getTranslated('update_review', context)}',
                                      style: textBold.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                      )
                                  ),

                                ]),
                              ),
                            ) : const SizedBox();
                          }
                      ),
                    ]),
                  ),


                  AnimatedSize(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: (orderProvider.orderDetails?[widget.index].isExpanded ?? false)
                        ? ReviewReplyViewWidget(isExpand: orderProvider.orderDetails?[widget.index].isExpanded ?? false)
                        : const SizedBox.shrink(),
                  ),


                ]);
              }
          ),
        ]),
      ),
    );
  }
}






class ReviewReplyViewWidget extends StatelessWidget {
  final bool isExpand;
  const ReviewReplyViewWidget({super.key, required this.isExpand});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewController>(
        builder: (context, reviewController, child) {
          return isExpand ?
          reviewController.isLoading ? const HorizontalLoader() : reviewController.orderWiseReview != null ?
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault).copyWith(top: 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                reviewController.orderWiseReview!.createdAt != null ?
                Text(DateConverter.dateTimeStringToMonthDateAndTime(
                    reviewController.orderWiseReview!.createdAt!),
                    style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault, color: Theme
                        .of(context)
                        .hintColor)) : const SizedBox(),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.star_rate_rounded, color: Colors.orange, size: 20),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      '(${double.parse(reviewController.orderWiseReview!.rating.toString()).toStringAsFixed(1)})',
                      style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                    ),
                  ),
                ]),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),


              ReadMoreText(
                reviewController.orderWiseReview?.comment ?? '',
                trimMode: TrimMode.Line,
                trimLines: 3,
                textAlign: TextAlign.justify,
                preDataTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                colorClickableText: Theme.of(context).primaryColor,
                trimCollapsedText: getTranslated('view_moree', context)!,
                trimExpandedText: '   ${getTranslated('view_less', context)!}',
              ),


              if(reviewController.orderWiseReview != null &&
                  reviewController.orderWiseReview!.attachmentFullUrl != null &&
                  reviewController.orderWiseReview!.attachmentFullUrl!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                  child: SizedBox(height: 45,
                    child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: reviewController.orderWiseReview?.attachmentFullUrl?.length,
                        itemBuilder: (BuildContext context, index) {
                          return Stack(children: [
                            Padding(padding: const EdgeInsets.only(
                                right: Dimensions.paddingSizeSmall),
                              child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(20)),),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeExtraSmall)),
                                    child: CustomImageWidget(
                                      height: 40,
                                      width: 40,
                                      image: "${reviewController.orderWiseReview?.attachmentFullUrl?[index].path}",
                                    ),
                                  )
                              ),
                            ),
                          ]);
                        }
                    ),
                  ),
                ),


              reviewController.orderWiseReview?.reply != null ?
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Image.asset(Images.sellerReplyIcon, height: 20, width: 20),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Text(getTranslated('reply_by_seller', context)!, style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text(
                  DateConverter.dateTimeStringToMonthDateAndTime(reviewController.orderWiseReview!.reply!.createdAt!),
                  style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),


                ReadMoreText(
                  reviewController.orderWiseReview?.reply?.replyText ?? '',
                  trimMode: TrimMode.Line,
                  trimLines: 3,
                  textAlign: TextAlign.justify,
                  preDataTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                  colorClickableText: Theme.of(context).primaryColor,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  trimCollapsedText: getTranslated('view_moree', context)!,
                  trimExpandedText: getTranslated('view_less', context)!,
                ),

              ]) : const SizedBox(),
            ]),
          ) :
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
            child: Text(getTranslated('no_review_found', context)!, style: titleRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          ) : const SizedBox();
        });
  }
}









class HorizontalLoader extends StatefulWidget {
  const HorizontalLoader({super.key});

  @override
  HorizontalLoaderState createState() => HorizontalLoaderState();
}

class HorizontalLoaderState extends State<HorizontalLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: false);

    _animations = List.generate(4, (index) {
      final startInterval = index * 0.25;
      final endInterval = startInterval + 0.25;

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startInterval, endInterval, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          return FadeTransition(
            opacity: _animations[index],
            child: Container(
              width: 10,
              height: 10,
              color: Theme.of(context).primaryColor,
            ),
          );
        }),
      ),
    );
  }
}