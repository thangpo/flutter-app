import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/screens/category_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/widgets/category_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/screens/brand_and_category_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

import 'category_shimmer_widget.dart';

class CategoryListWidget extends StatelessWidget {
  final bool isHomePage;
  const CategoryListWidget({super.key, required this.isHomePage});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryController>(
      builder: (context, categoryProvider, child) {
        final categories = categoryProvider.categoryList;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Tiêu đề "Danh mục"
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall),
              child: TitleRowWidget(
                title: getTranslated('CATEGORY', context),
                onTap: () {
                  if (categories.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // --- Hiển thị danh mục dạng Grid
            categories.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // để cuộn theo màn hình cha
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4 danh mục mỗi hàng
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 8,
                        childAspectRatio:
                            0.75, // tỉ lệ width/height, 0.7–0.8 là đẹp
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BrandAndCategoryProductScreen(
                                  isBrand: false,
                                  id: category.id,
                                  name: category.name,
                                ),
                              ),
                            );
                          },
                          child: CategoryWidget(
                            category: category,
                            index: index,
                            length: categories.length,
                          ),
                        );
                      },
                    ),
                  )
                : const CategoryShimmerWidget(),
          ],
        );
      },
    );
  }
}
