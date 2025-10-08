
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ClearanceTitleRowWidget extends StatelessWidget {
  final String? title;
  final Function? icon;
  final Function? onTap;
  final bool? isDetailsPage;
  final bool isHomeScreen;
  final Color? titleColor;
  final bool isBackExist;
  final Color? percentColor;
  final String? discountPercent;

  const ClearanceTitleRowWidget({
    super.key,
    required this.title,
    this.icon, this.onTap,
    this.isDetailsPage,
    this.isHomeScreen = true,
    this.titleColor,
    this.isBackExist = false,
    this.percentColor,
    this.discountPercent
  });

  @override
  Widget build(BuildContext context) {
    final bool isLtr  = Provider.of<LocalizationController>(context, listen: false).isLtr;
    final double size = MediaQuery.sizeOf(context).width;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: isHomeScreen ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 13,
      child: Stack(children: [

        Positioned(
            left: isLtr ? !isHomeScreen ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault : null,
            right: !isLtr ? !isHomeScreen ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault : null,
            child: Align(
              alignment: isLtr ? Alignment.centerLeft : Alignment.centerRight,
                child: !isHomeScreen
                    ? _HomeTitleBackgroundImage(isLtr: isLtr, size: size)
                    : _ShopTitleBackgroundImage(isLtr: isLtr, size: size),
            ),
        ),

        isHomeScreen ? Positioned(
          left: isLtr ? MediaQuery.of(context).size.width / 8 : null,
          right: !isLtr ? MediaQuery.of(context).size.width / 8 : null,
          bottom: Dimensions.paddingSizeExtraLarge,
          child: Text(getTranslated('save_more', context)!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: percentColor ?? (Theme.of(context).primaryColor),
              )
          ),
        ) : const SizedBox(),

        Positioned(child: Align(alignment: isHomeScreen ? Alignment.bottomCenter : Alignment.center, child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isBackExist ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeDefault),
          child: Row(
            mainAxisAlignment: isLtr ? MainAxisAlignment.spaceAround : MainAxisAlignment.spaceBetween,
              children: [
            if(isBackExist) IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded, size: 18,
                color: Colors.white,
              ), onPressed: ()=> Navigator.maybePop(context),
            ),

            Padding(
              padding: isLtr ? const EdgeInsets.all(0) : const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
              child: Text(title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge ,
                    color: titleColor ?? (Theme.of(context).highlightColor),
                  )
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            const SizedBox(),

            icon != null ? InkWell(
                onTap: icon as void Function()?,
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15),
                    child:  SvgPicture.asset(Images.filterImage,
                        height: Dimensions.iconSizeDefault,
                        width: Dimensions.iconSizeDefault,
                        colorFilter: ColorFilter.mode(Theme.of(context).textTheme.bodyMedium!.color!, BlendMode.srcIn)
                    )
                )
            ) : const SizedBox.shrink(),

            onTap != null ? Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: InkWell(onTap: onTap as void Function()?,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  isDetailsPage == null ? Text(getTranslated('VIEW_ALL', context)!,
                      style: titilliumRegular.copyWith(color: Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeDefault,)) : const SizedBox.shrink(),
                ]),
              ),
            ) :  const SizedBox.shrink(),
          ]),
        ))),
      ]),
    );
  }
}


class _TitleBackgroundImagePaint extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    paint.color = const Color(0xffFB6C4C);
    path = Path();
    path.lineTo(size.width * 0.97, 0);
    path.cubicTo(size.width * 0.97, 0, size.width * 0.02, 0, size.width * 0.02, 0);
    path.cubicTo(size.width * 0.01, 0, 0, size.height * 0.06, 0, size.height * 0.13);
    path.cubicTo(0, size.height * 0.13, 0, size.height * 0.88, 0, size.height * 0.88);
    path.cubicTo(0, size.height * 0.94, size.width * 0.01, size.height, size.width * 0.02, size.height);
    path.cubicTo(size.width * 0.02, size.height, size.width, size.height, size.width, size.height);
    path.cubicTo(size.width, size.height, size.width, size.height * 0.96, size.width, size.height * 0.94);
    path.cubicTo(size.width, size.height * 0.94, size.width * 0.92, size.height * 0.53, size.width * 0.92, size.height * 0.53);
    path.cubicTo(size.width * 0.92, size.height * 0.52, size.width * 0.92, size.height / 2, size.width * 0.92, size.height * 0.48);
    path.cubicTo(size.width * 0.92, size.height * 0.48, size.width * 0.98, size.height * 0.06, size.width * 0.98, size.height * 0.06);
    path.cubicTo(size.width * 0.98, size.height * 0.03, size.width * 0.98, 0, size.width * 0.97, 0);
    path.cubicTo(size.width * 0.97, 0, size.width * 0.97, 0, size.width * 0.97, 0);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}



class _HomeTitleBackgroundImage extends StatelessWidget {
  final bool isLtr;
  final double size;
  const _HomeTitleBackgroundImage({required this.isLtr, required this.size});

  @override
  Widget build(BuildContext context) {
    return !isLtr 
        ? Transform.flip(flipX: true, child: Image.asset(Images.clearanceShopTitle, width: MediaQuery.sizeOf(context).width/2.2,))
        : SizedBox(width: size / 2.2, child: CustomPaint(painter: _TitleBackgroundImagePaint(), child: const Padding(padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall), child: Text('',),),),);
  }
}



class _ShopTitleBackgroundImage extends StatelessWidget {
  final bool isLtr;
  final double size;
  const _ShopTitleBackgroundImage({required this.isLtr, required this.size});

  @override
  Widget build(BuildContext context) {
    return !isLtr 
        ? Transform.flip(flipX: true, child: Image.asset(Images.clearanceHomeTitle, width: MediaQuery.sizeOf(context).width/2.1,))
        : Image.asset(Images.clearanceHomeTitle, width: size / 2.1,);
  }
}

