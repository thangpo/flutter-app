import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/aster_theme/more_store_widget.dart';
import 'package:provider/provider.dart';

class MoreStoreView extends StatefulWidget {
  final bool isHome;
  const MoreStoreView({super.key,  this.isHome = false});
  @override
  State<MoreStoreView> createState() => _MoreStoreViewState();
}

class _MoreStoreViewState extends State<MoreStoreView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, moreSellerProvider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for(int i = 0; i < moreSellerProvider.moreStoreList.length; i++) SizedBox(
              width: MediaQuery.of(context).size.width / 5,
              child: MoreStoreWidget(
                moreStore: moreSellerProvider.moreStoreList[i],
                index: i, length: moreSellerProvider.moreStoreList.length,
              ),
            ),
          ]),
        );
      }
    );
  }
}
