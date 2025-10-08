import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/domain/models/brand_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/widgets/brand_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/screens/brand_and_category_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:provider/provider.dart';

class BrandListWidget extends StatefulWidget {
  final bool isHomePage;
  const BrandListWidget({super.key, required this.isHomePage});

  @override
  State<BrandListWidget> createState() => _BrandListWidgetState();
}

class _BrandListWidgetState extends State<BrandListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Consumer<BrandController>(
      builder: (context, brandProvider, child) {

        return (brandProvider.brandListSorted?.isNotEmpty ?? false) ? widget.isHomePage?
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: (brandProvider.brandModel?.brands ?? []).map((brand)=>  _HomeBrandItemWidget(brand: brand)).toList(),
        )) : SingleChildScrollView(
          controller: _scrollController,
          child: PaginatedListView(
              scrollController: _scrollController,
              totalSize: brandProvider.brandModel?.totalSize,
              offset: brandProvider.brandModel?.offset,
              onPaginate: (int? offset) async {
                await brandProvider.getBrandList(offset: offset!);
              },
              itemView: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: (1/1.3),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 5),
                padding: EdgeInsets.zero,
                itemCount: brandProvider.brandListSorted?.length ?? 0,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BrandAndCategoryProductScreen(
                        isBrand: true,
                        id: brandProvider.brandListSorted?[index].id,
                        name: brandProvider.brandListSorted?[index].name,
                        image: brandProvider.brandListSorted?[index].imageFullUrl?.path,
                      )));
                    },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                          ),
                          child: CustomImageWidget(image:'${brandProvider.brandListSorted?[index].imageFullUrl?.path!}'),
                        ),
                      )),

                      SizedBox(height: (MediaQuery.of(context).size.width / 4) * 0.3, child: Center(
                        child: Text(
                          brandProvider.brandListSorted?[index].name ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      )),
                    ]),
                  );
                },
              )
          ),
        ) : BrandShimmerWidget(isHomePage: widget.isHomePage);
      },
    );
  }
}

class _HomeBrandItemWidget extends StatelessWidget {
  final BrandModel brand;
  const _HomeBrandItemWidget({
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final BrandController brandController = Provider.of<BrandController>(context, listen: false);

    return InkWell(splashColor: Colors.transparent, highlightColor: Colors.transparent,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BrandAndCategoryProductScreen(
          isBrand: true,
          id: brand.id,
          name: brand.name,
          image: brand.imageFullUrl?.path,
        )));
      },
      child: Padding(padding: EdgeInsets.only(
        left : Provider.of<LocalizationController>(context, listen: false).isLtr
            ? Dimensions.paddingSizeDefault : 0,
        right: brandController.brandModel!.brands!.length == brandController.brandModel!.brands!.indexOf(brand) + 1
            ?  Dimensions.paddingSizeDefault : Provider.of<LocalizationController>(context, listen: false).isLtr
            ? 0 : Dimensions.paddingSizeDefault,
      ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(width: ResponsiveHelper.isTab(context)? 120 :50, height: ResponsiveHelper.isTab(context)? 120 :50,
            decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(5)),
                color: Theme.of(context).highlightColor,
                boxShadow: Provider.of<ThemeController>(context, listen: false).darkTheme ?
                null :[BoxShadow(color: Colors.grey.withValues(alpha:0.12), spreadRadius: 1, blurRadius: 1, offset: const Offset(0, 1))]),
            child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: CustomImageWidget(image: '${brand.imageFullUrl?.path!}')),
          ),
        ],
        ),
      ),
    );
  }
}


