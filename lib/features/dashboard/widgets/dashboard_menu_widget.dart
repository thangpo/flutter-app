import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class CustomMenuWidget extends StatelessWidget {
  final bool isSelected;
  final String name;
  final String icon;
  final bool showCartCount;
  final VoidCallback onTap;
  final Color? activeColorOverride;
  final Color? inactiveColorOverride;

  const CustomMenuWidget({
    super.key,
    required this.isSelected,
    required this.name,
    required this.icon,
    required this.onTap,
    this.showCartCount = false,
    this.activeColorOverride,
    this.inactiveColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        activeColorOverride ?? Theme.of(context).primaryColor;

    // ðŸ”¥ MÃ u icon + text khi chÆ°a chá»n â†’ ÄEN
    final Color inactiveColor = inactiveColorOverride ?? Colors.black;

    return InkWell(
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    icon,
                    width: Dimensions.menuIconSize,
                    height: Dimensions.menuIconSize,

                    // â­ CHá»– QUAN TRá»ŒNG
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                if (showCartCount)
                  Positioned.fill(
                    child: Container(
                      transform: Matrix4.translationValues(5, -3, 0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Consumer<CartController>(
                          builder: (context, cart, child) {
                            return CircleAvatar(
                              radius: ResponsiveHelper.isTab(context) ? 10 : 7,
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              child: Text(
                                cart.cartList.length.toString(),
                                style: titilliumSemiBold.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,

              // â­ CHá»– QUAN TRá»ŒNG
              style: textRegular.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: Dimensions.fontSizeSmall,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),

              child: Text(
                getTranslated(name, context)!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


