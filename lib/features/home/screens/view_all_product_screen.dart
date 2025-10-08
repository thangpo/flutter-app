import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class ViewAllProductScreen extends StatefulWidget {
  final ProductType productType;
  const ViewAllProductScreen({super.key, required this.productType});

  @override
  State<ViewAllProductScreen> createState() => _ViewAllProductScreenState();
}

class _ViewAllProductScreenState extends State<ViewAllProductScreen> {
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();

    Provider.of<ProductController>(context, listen: false).getAllProductModelByType(
      offset: 1, type: widget.productType, isUpdate: false,
    );

  }


  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Provider.of<ThemeController>(context).darkTheme;

    return Scaffold(
      backgroundColor: isDarkTheme ? Theme.of(context).scaffoldBackgroundColor : null,
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: getTranslated(_getTitle(widget.productType), context)),

      body: Consumer<ProductController>(
        builder: (context, productController, child) {
          if (productController.allProductModel?.products?.isNotEmpty ?? false) {

            return PaginatedListView(
              scrollController: _scrollController,
              onPaginate: (int? offset) async {
                await productController.getAllProductModelByType(offset: offset ?? 1, type: widget.productType);
              },
              totalSize: productController.allProductModel?.totalSize,
              offset: productController.allProductModel?.offset,
              itemView: Expanded(child: MasonryGridView.count(
                controller: _scrollController,
                itemCount: productController.allProductModel?.products?.length ?? 0,
                crossAxisCount: ResponsiveHelper.isTab(context) ? 3 : 2,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall).copyWith(bottom: Dimensions.paddingSizeDefault),
                itemBuilder: (BuildContext context, int index) {
                  return ProductWidget(productModel: productController.allProductModel!.products![index]);
                },
              )), // Replace with your actual item view
            );

          } else if (productController.allProductModel?.products?.isEmpty ?? false) {
            return const NoInternetOrDataScreenWidget(isNoInternet: false);

          } else {
            return const ProductShimmer(isHomePage: false, isEnabled: true);
          }
        },
      ),
    );
  }


  String _getTitle(ProductType productType) {
    switch (productType) {

      case ProductType.featuredProduct:
        return 'featured_product';

      case ProductType.justForYou:
        return 'just_for_you';

      default: return 'latest_product';
    }
  }
}
