import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/widgets/custom_expansion_tile.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class FaqExpansionTileWidget extends StatefulWidget {
  final int index;
  final SplashController faq;
  const FaqExpansionTileWidget({super.key, required this.index, required this.faq});

  @override
  State<FaqExpansionTileWidget> createState() => _FaqExpansionTileWidgetState();
}

class _FaqExpansionTileWidgetState extends State<FaqExpansionTileWidget> {
  bool isExpanded = false;
  late int index;
  late SplashController faq;


  @override
  void initState() {
    // TODO: implement initState
    index = widget.index;
    faq = widget.faq;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: CustomExpansionTile(
          expandedAlignment: Alignment.topLeft,
          title:  Row(
            children: [
              Text( index < 9 ? '0${index+1}' : '${index+1}',
                  style: robotoBold.copyWith(color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeLarge)),

              const Expanded(child: SizedBox()),

            ],
          ),
          subtitle: Text(faq.configModel!.faq![index].question!,
              style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          trailing: Container(
            width: Dimensions.iconSizeLarge,
            height: Dimensions.iconSizeLarge,
            decoration: BoxDecoration(
              color: isExpanded ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha:.125), // Blue background
              shape: BoxShape.circle, // Circular shape
            ),

            child: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isExpanded ? Theme.of(context).highlightColor : Theme.of(context).textTheme.bodyLarge?.color, // White arrow color
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              isExpanded = expanded;
            });
          },
          children: [
            Padding(padding: const EdgeInsets.only(left: Dimensions.homePagePadding, right: Dimensions.homePagePadding, bottom: Dimensions.homePagePadding),
                child: Text(faq.configModel!.faq![index].answer!,style: textRegular, textAlign: TextAlign.justify),)]),
    );
  }
}
