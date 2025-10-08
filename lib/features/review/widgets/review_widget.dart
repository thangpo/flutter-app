import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/domain/models/review_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/image_diaglog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/rating_bar_widget.dart';
import 'package:readmore/readmore.dart';
import 'package:shimmer/shimmer.dart';

class ReviewWidget extends StatelessWidget {
  final ReviewModel reviewModel;
  const ReviewWidget({super.key, required this.reviewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(20),
            child: FadeInImage.assetNetwork(placeholder: Images.placeholder, height: Dimensions.chooseReviewImageSize,
              width: Dimensions.chooseReviewImageSize, fit: BoxFit.cover,
              image: '${reviewModel.customer != null ? reviewModel.customer!.imageFullUrl?.path : '' }',
              imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholder, height: Dimensions.chooseReviewImageSize,
                  width: Dimensions.chooseReviewImageSize, fit: BoxFit.cover))),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),


          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${reviewModel.customer == null ? getTranslated('user_not_exist', context): reviewModel.customer!.fName ?? ''} ${
                    reviewModel.customer == null ? '' : reviewModel.customer!.lName ?? ''}',
                  style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                  maxLines: 1, overflow: TextOverflow.ellipsis),

                reviewModel.createdAt != null ?
                Text(DateConverter.dateTimeStringToMonthDateAndTime(reviewModel.createdAt!),
                    style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)) : const SizedBox()
              ]),


              Row(children: [
                const Icon(Icons.star,color: Colors.orange),
                Text('${reviewModel.rating!.toDouble()} /5', style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                  maxLines: 1, overflow: TextOverflow.ellipsis)]),
            ]),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          child: ReadMoreText(
            reviewModel.comment ?? '',
            trimMode: TrimMode.Line,
            trimLines: 3,
            textAlign: TextAlign.justify,
            preDataTextStyle: const TextStyle(fontWeight: FontWeight.w500),
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            colorClickableText: Theme.of(context).primaryColor,
            trimCollapsedText: getTranslated('view_moree', context)!,
            trimExpandedText: getTranslated('view_less', context)!,
          ),

          // Text(reviewModel.comment ?? '', textAlign: TextAlign.left,
          //   style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
          //   maxLines: 3, overflow: TextOverflow.ellipsis)
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),


        (reviewModel.attachmentFullUrl != null && reviewModel.attachmentFullUrl!.isNotEmpty) ?
        SizedBox(height: 40,
          child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: reviewModel.attachmentFullUrl!.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: (){
                  showDialog(context: context, builder: (_)=> ImageDialog(
                      imageUrl: '${reviewModel.attachmentFullUrl![index].path}'));
                },
                child:


                Container(
                  margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: FadeInImage.assetNetwork(
                      placeholder: Images.placeholder, height: Dimensions.chooseReviewImageSize,
                      width: Dimensions.chooseReviewImageSize, fit: BoxFit.cover,
                      image: '${reviewModel.attachmentFullUrl![index].path}',
                      imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholder,
                          height: Dimensions.chooseReviewImageSize,
                          width: Dimensions.chooseReviewImageSize, fit: BoxFit.cover))))

              );})) :
        const SizedBox(),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),




        reviewModel.reply != null ?
        Row( mainAxisSize: MainAxisSize.max,  crossAxisAlignment: CrossAxisAlignment.start, children: [
          CustomPaint(
            size: const Size(15, 40),
            painter: DashedLinePainter(),
          ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).primaryColor.withValues(alpha:0.05),
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.10))
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Image.asset(Images.sellerReplyIcon, height: 20, width: 20),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        Text(getTranslated('reply_by_seller', context)!, style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                        ],
                      ),


                      Text(DateConverter.dateTimeStringToMonthDateAndTime(reviewModel.reply!.createdAt!),
                          style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),


                    ReadMoreText(
                      reviewModel.reply?.replyText ?? '',
                      trimMode: TrimMode.Line,
                      trimLines: 3,
                      textAlign: TextAlign.justify,
                      preDataTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                      style:  TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      colorClickableText: Theme.of(context).primaryColor,
                      trimCollapsedText: getTranslated('view_moree', context)!,
                      trimExpandedText: getTranslated('view_less', context)!,
                    ),

                    //Text(reviewModel.reply?.replyText ?? '', style: textRegular),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                  ],
                ),
              ),
            ),
          ],
        ) : const SizedBox(),








      ]),
    );
  }
}

class ReviewShimmer extends StatelessWidget {
  const ReviewShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!, enabled: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [CircleAvatar(maxRadius: 15,
            backgroundColor: Theme.of(context).colorScheme.onPrimary, child: const Icon(Icons.person)),
          const SizedBox(width: 5),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(height: 10, width: 50, color:  Theme.of(context).colorScheme.secondaryContainer),
              const SizedBox(width: 5),
              const RatingBar(rating: 0, size: 12)]),
            Container(height: 10, width: 50, color:  Theme.of(context).colorScheme.secondaryContainer)])]),
        const SizedBox(height: 5),
        Container(height: 20, width: 200, color:  Theme.of(context).colorScheme.secondaryContainer),
      ]),
    );
  }
}


class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Theme.of(Get.context!).primaryColor.withValues(alpha:0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double dashWidth = 5, dashSpace = 3;
    Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height - size.width / 2)
      ..arcToPoint(Offset(size.width, size.height),
          radius: Radius.circular(size.width / 2), clockwise: false);

    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}