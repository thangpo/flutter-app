import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/seller_card.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/seller_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

class AllTopSellerScreen extends StatefulWidget {
  final String title;
  const AllTopSellerScreen({super.key, required this.title});

  @override
  State<AllTopSellerScreen> createState() => _AllTopSellerScreenState();
}

class _AllTopSellerScreenState extends State<AllTopSellerScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Provider.of<ShopController>(context, listen: false).setSellerType('top', notify: false);

  }

  @override
  Widget build(BuildContext context) {
    return Selector<ShopController, String?>(
      selector: (ctx, shopController) => shopController.sellerTypeTitle,
      builder: (context, sellerTypeTitle, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).highlightColor,
          appBar: CustomAppBar(
            title: '${getTranslated(sellerTypeTitle, context)}',
            showResetIcon: true,
            reset: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: PopupMenuButton(itemBuilder: (context) => [

                PopupMenuItem(value: "new", textStyle: textRegular.copyWith(color: Theme.of(context).hintColor), child: Text(getTranslated('new_seller',context)??'')),

                PopupMenuItem(value: "all", textStyle: textRegular.copyWith(color: Theme.of(context).hintColor), child: Text(getTranslated('all_seller',context)??'')),

                PopupMenuItem(value: "top", textStyle: textRegular.copyWith(color: Theme.of(context).hintColor), child: Text(getTranslated('top_seller',context)??'')),

              ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraSmall,
                    vertical:  Dimensions.paddingSizeSmall,
                  ),
                  child: Image.asset(Images.dropdown, scale: 3),
                ),
                onSelected: (dynamic value) {
                  final ShopController shopController = Provider.of<ShopController>(context, listen: false);

                  shopController.setSellerType(value, notify: true);
                },
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Consumer<ShopController>(builder: (context, topSellerProvider, child) {
              return (topSellerProvider.filteredSellerModel?.sellers?.isNotEmpty ?? false) ? PaginatedListView(
                scrollController: scrollController,
                onPaginate: (int? offset) async {
                  await topSellerProvider.getFilteredSellerList(
                    offset: offset ?? 1,
                    type: topSellerProvider.sellerType,
                    // false, offset?? 1, type : topSellerProvider.sellerType,
                  );
                },
                totalSize: topSellerProvider.filteredSellerModel?.totalSize,
                offset: topSellerProvider.filteredSellerModel?.offset,
                itemView: Expanded(
                  child: ListView.builder(
                    itemCount: topSellerProvider.filteredSellerModel?.sellers?.length,
                    padding: EdgeInsets.zero,
                    controller: scrollController,
                    itemBuilder: (BuildContext context, int index) {
                      return SellerCard(
                        sellerModel: topSellerProvider.filteredSellerModel?.sellers?[index],
                        isHomePage: false,
                        index: index,
                        length: topSellerProvider.filteredSellerModel?.sellers?.length ?? 0,
                      );
                    },
                  ),
                ),
              )
                  : (topSellerProvider.filteredSellerModel?.sellers?.isEmpty ?? false)
                  ? const SizedBox()
                  : const SellerShimmer();

            }),
          ),
        );
      },
    );
  }
}
