import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/debounce_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart' show SliverMasonryGrid;
import 'package:provider/provider.dart';

class HomeProductListWidget extends StatelessWidget {
  final ScrollController? scrollController;
  const HomeProductListWidget({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {

    return  Consumer<ProductController>(
        builder: (context, productController, child) {

          final products = productController.selectedProductModel?.products ?? [];
          final totalSize = productController.selectedProductModel?.totalSize;
          final offset = productController.selectedProductModel?.offset;

          if (products.isEmpty && (productController.selectedProductModel != null)) {
            return const SliverToBoxAdapter(
              child: NoInternetOrDataScreenWidget(isNoInternet: false),
            );
          }

          if (products.isEmpty) {
            return const SliverToBoxAdapter(
              child: ProductShimmer(isHomePage: false, isEnabled: true),
            );
          }
        return SliverPaginatedMasonryGrid(
          scrollController: scrollController,
          onPaginate: (offset) {
             productController.getSelectedProductModel(offset ?? 1);
          },
          totalSize: totalSize,
          offset: offset,
          itemCount: products.length,
          crossAxisCount: ResponsiveHelper.isTab(context) ? 3 : 2,
          mainAxisSpacing: Dimensions.paddingSizeSmall,
          crossAxisSpacing: Dimensions.paddingSizeSmall,
          itemBuilder: (context, index) => ProductWidget(
            productModel: products[index],
          ),
        );
      }
    );
  }
}



class SliverPaginatedMasonryGrid extends StatefulWidget {
  final Function(int? offset) onPaginate;
  final int? totalSize;
  final int? offset;
  final int? limit;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final bool enabledPagination;
  final ScrollController? scrollController;


  const SliverPaginatedMasonryGrid({
    super.key,
    required this.onPaginate,
    required this.totalSize,
    required this.offset,
    required this.itemCount,
    required this.itemBuilder,
    this.limit = 10,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 4.0,
    this.crossAxisSpacing = 4.0,
    this.enabledPagination = true,
    this.scrollController,
  });

  @override
  State<SliverPaginatedMasonryGrid> createState() => _SliverPaginatedMasonryGridState();
}

class _SliverPaginatedMasonryGridState extends State<SliverPaginatedMasonryGrid> {
  int? _offset;
  late List<int?> _offsetList;
  bool _isLoading = false;
  final _debounce = DebounceHelper(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _offset = 1;
    _offsetList = [1];
    widget.scrollController?.addListener(_scrollListener);
  }



  void _scrollListener() {
    if (widget.scrollController?.position.pixels == widget.scrollController?.position.maxScrollExtent &&
        widget.totalSize != null &&
        !_isLoading &&
        widget.enabledPagination) {
      _debounce.run(_paginate);
    }
  }

  Future<void> _paginate() async {
    final pageSize = (widget.totalSize! / widget.limit!).ceil();
    if (_offset! < pageSize && !_offsetList.contains(_offset! + 1)) {
      setState(() => _isLoading = true);
      await widget.onPaginate(_offset! + 1);
      if (mounted) {
        setState(() {
          _offset = _offset! + 1;
          _offsetList.add(_offset);
          _isLoading = false;
        });
      }
    } else if (_isLoading && mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offset != null) {
      _offset = widget.offset;
      _offsetList = [];
      for (int index = 1; index <= widget.offset!; index++) {
        _offsetList.add(index);
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      sliver: SliverMainAxisGroup(
        slivers: [

          SliverMasonryGrid.count(
            crossAxisCount: widget.crossAxisCount,
            mainAxisSpacing: widget.mainAxisSpacing,
            crossAxisSpacing: widget.crossAxisSpacing,
            childCount: widget.itemCount,
            itemBuilder: widget.itemBuilder,
          ),
          if (_isLoading ||
              (widget.totalSize != null &&
                  _offset! < (widget.totalSize! / widget.limit!).ceil() &&
                  !_offsetList.contains(_offset! + 1)))
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}