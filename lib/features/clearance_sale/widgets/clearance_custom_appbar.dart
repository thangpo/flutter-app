import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';

class ClearanceCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final bool isBackButtonExist;
  final bool showActionButton;
  final Function()? onBackPressed;
  final bool centerTitle;
  final double? fontSize;
  final bool showResetIcon;
  final Widget? reset;
  final bool showLogo;

  const ClearanceCustomAppBar({
    super.key,
    required this.title,
    this.isBackButtonExist = true,
    this.onBackPressed,
    this.centerTitle= false,
    this.showActionButton= true,
    this.fontSize,
    this.showResetIcon = false,  this.reset,  this.showLogo = false});

  @override
  Widget build(BuildContext context) {

    return PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(

            actions: showResetIcon? [reset!]:[],
            backgroundColor: Theme.of(context).cardColor,
            toolbarHeight: 50,
            iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
            automaticallyImplyLeading: false,
            title: title,

            centerTitle: true,
            excludeHeaderSemantics: true,
            titleSpacing: 0,
            elevation: 1,
            clipBehavior: Clip.none,
            shadowColor: Theme.of(context).primaryColor.withValues(alpha:.1),
            leadingWidth: isBackButtonExist? 50 : 120,
            leading: isBackButtonExist ? IconButton(icon:  Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha:.75),),
                onPressed: () => onBackPressed != null ? onBackPressed!() : Navigator.pop(context)) :

            showLogo?
            Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                child: SizedBox(child: Image.asset(Images.logoWithNameImage))): const SizedBox())

    );
  }

  @override
  Size get preferredSize =>  Size(MediaQuery.of(Get.context!).size.width, 50);
}