import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/helper/color_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class TitleRowWidget extends StatelessWidget {
  final String? title;
  final Function? icon;
  final Function? onTap;
  final Duration? eventDuration;
  final bool? isDetailsPage;
  final bool isFlash;
  final Color? titleColor;
  final bool isBackExist;
  const TitleRowWidget({super.key, required this.title,this.icon, this.onTap, this.eventDuration, this.isDetailsPage, this.isFlash = false, this.titleColor, this.isBackExist = false});

  @override
  Widget build(BuildContext context) {
    int? days, hours, minutes, seconds;
    if (eventDuration != null) {
      days = eventDuration!.inDays;
      hours = eventDuration!.inHours - days * 24;
      minutes = eventDuration!.inMinutes - (24 * days * 60) - (hours * 60);
      seconds = eventDuration!.inSeconds - (24 * days * 60 * 60) - (hours * 60 * 60) - (minutes * 60);
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: isFlash ? BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeSmall)),
        color: Theme.of(context).primaryColor,
        gradient: LinearGradient(colors: [
          Theme.of(context).primaryColor,
          ColorHelper.blendColors(Colors.white, Theme.of(context).primaryColor, 0.7),
          ColorHelper.blendColors(Colors.white, Theme.of(context).primaryColor, 0.7),
        ]),
      ) : null,

      child: Stack(children: [



        if(eventDuration != null && !Provider.of<ThemeController>(context, listen: false).darkTheme)
          Positioned(bottom: -20, left: -6, child: SizedBox(
            width: 60,
            child: Image.asset(Images.currentShape, opacity: const AlwaysStoppedAnimation(.05)),
          )),

        if(eventDuration != null && !Provider.of<ThemeController>(context, listen: false).darkTheme)
        Positioned(
          top: 5, left: MediaQuery.of(context).size.width / 3,
          child: SizedBox(width: 35, child: Image.asset(
            Images.currentShape, opacity: const AlwaysStoppedAnimation(.15),
          )),
        ),

        if(eventDuration != null && !Provider.of<ThemeController>(context, listen: false).darkTheme)
        Positioned(right: -2, top: -5, child: SizedBox(
          width: 25,
          child: Image.asset(Images.currentShape, opacity: const AlwaysStoppedAnimation(.17)),
        )),


        Positioned(child: Align(alignment: Alignment.center, child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isBackExist ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeDefault),
          child: Row(children: [

            if(isBackExist) IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded, size: 18,
                color: Colors.white,
              ), onPressed: ()=> Navigator.maybePop(context),
            ),



            // Expanded(
              //child:

              Text(title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(
                fontSize: isFlash ? Dimensions.fontSizeSmall : Dimensions.fontSizeLarge,
                color: titleColor ?? (isFlash? Colors.white : Theme.of(context).textTheme.bodyLarge?.color),
              )),
            // ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            isFlash? Image.asset(Images.flashDeal, scale: 4):const SizedBox(),

            Flexible(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                eventDuration == null ? const Expanded(child: SizedBox.shrink()) :

                Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(width: 5),
                    TimerBox(time: days, day: getTranslated('day', context), isDetailsPage: isDetailsPage),

                    Padding(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      child: Text(isFlash ? '' :':', style: TextStyle(color: Theme.of(context).primaryColor)),
                    ),

                    TimerBox(time: hours, day: getTranslated('hour', context), isDetailsPage: isDetailsPage),

                    Padding(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      child: Text(isFlash ? '' :':', style: TextStyle(color: Theme.of(context).primaryColor)),
                    ),

                    TimerBox(time: minutes, day: getTranslated('min', context), isDetailsPage: isDetailsPage),

                    Padding(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      child: Text(isFlash ? '' :':', style: TextStyle(color: Theme.of(context).primaryColor)),
                    ),

                    TimerBox(time: seconds,day: getTranslated('sec', context), isDetailsPage: isDetailsPage),
                    const SizedBox(width: 5),
                  ]),
                ),



              ]),
            ),

            icon != null ? InkWell(
                onTap: icon as void Function()?,
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15),
                    child:  SvgPicture.asset(Images.filterImage,
                        height: Dimensions.iconSizeDefault,
                        width: Dimensions.iconSizeDefault,
                        colorFilter: ColorFilter.mode(Theme.of(context).textTheme.bodyMedium!.color!, BlendMode.srcIn))))
                : const SizedBox.shrink(),

            onTap != null && isFlash?
            InkWell(
              onTap: onTap as void Function()?,
              child: const SizedBox(height: 20, width: 20, child: Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
              )),
            ) : onTap != null && !isFlash ?
            Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
              child: InkWell(onTap: onTap as void Function()?,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  isDetailsPage == null ? Text(getTranslated('VIEW_ALL', context)!,
                      style: titilliumRegular.copyWith(color: Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeDefault,)) : const SizedBox.shrink(),
                ]),
              ),
            ):  const SizedBox.shrink(),

          ]),
        ))),
      ]),
    );
  }
}

class TimerBox extends StatelessWidget {
  final int? time;
  final bool isBorder;
  final String? day;
  final bool? isDetailsPage;

  const TimerBox({super.key, required this.time, this.isBorder = false, this.day,  this.isDetailsPage = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
      // width: MediaQuery.of(context).size.width/9.5,height: 55,
      decoration: BoxDecoration(
        border: isBorder ? Border.all(width: 2, color: Theme.of(context).textTheme.bodyMedium!.color!) : null,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 30,height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isDetailsPage != null && !Provider.of<ThemeController>(context, listen: false).darkTheme)?
                Theme.of(context).primaryColor.withValues(alpha: .12) : Colors.white,
                borderRadius: BorderRadius.circular(50),),
              child: Text(time! < 10 ? '0$time' : time.toString(),
                style: textBold.copyWith(
                  color: isBorder ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSizeExtraSmall,
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
              child: Text(day!, style: textBold.copyWith(color: isDetailsPage != null ?
              Theme.of(context).primaryColor : isBorder ?
              Theme.of(context).textTheme.bodyMedium?.color : Colors.white.withValues(alpha:.5),
                fontSize: Dimensions.fontSizeExtraSmall,)),
            ),
          ],
        ),
      ),
    );
  }
}
