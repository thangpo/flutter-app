import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class FilterCheckItemWidget extends StatelessWidget {
  final String? title;
  final bool checked;
  final Function()? onTap;
  const FilterCheckItemWidget({super.key, required this.title, required this.checked, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, mainAxisSize: MainAxisSize.min, children: [
            Expanded(child: Text(title ?? '', style: textRegular.copyWith(color: checked ? null : Theme.of(context).hintColor))),

            Icon(checked ? Icons.check_box_outlined : Icons.check_box_outline_blank_rounded,
                color: (checked && !Provider.of<ThemeController>(context, listen: false).darkTheme) ?
                Theme.of(context).primaryColor:(checked && Provider.of<ThemeController>(context, listen: false).darkTheme) ?
                Colors.white : Theme.of(context).hintColor.withValues(alpha:.5),
            ),
          ]),
        ),
      ),
    );
  }
}
