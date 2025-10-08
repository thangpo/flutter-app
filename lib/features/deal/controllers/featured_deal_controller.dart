import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/domain/services/featured_deal_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/helper/data_sync_helper.dart';

class FeaturedDealController extends ChangeNotifier {
  final FeaturedDealServiceInterface featuredDealServiceInterface;
  FeaturedDealController({required this.featuredDealServiceInterface});

  int? _featuredDealSelectedIndex;
  List<Product>? _featuredDealProductList;
  List<Product>? get featuredDealProductList => _featuredDealProductList;
  int? get featuredDealSelectedIndex => _featuredDealSelectedIndex;


  Future<void> getFeaturedDealList() async {
    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => featuredDealServiceInterface.getFeaturedDeal(source: DataSourceEnum.local),
      fetchFromClient: () => featuredDealServiceInterface.getFeaturedDeal(source: DataSourceEnum.client),
      onResponse: (data, source) {
        _featuredDealProductList = [];
        data.forEach((featuredDeal) => _featuredDealProductList?.add(Product.fromJson(featuredDeal)));
        _featuredDealSelectedIndex = 0;
        notifyListeners();
      },
    );
  }


  void changeSelectedIndex(int selectedIndex) {
    _featuredDealSelectedIndex = selectedIndex;
    notifyListeners();
  }
}
