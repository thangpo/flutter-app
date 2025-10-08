import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/seller_card.dart';
import 'package:provider/provider.dart';

class TopSellerWidget extends StatelessWidget {
  const TopSellerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ShopController, SellerModel?>(
      selector: (ctx, shopController)=> shopController.topSellerModel,
      builder: (context, sellerModel, child) {
        return  (sellerModel?.sellers?.isNotEmpty ?? false) ? ListView.builder(
          itemCount: sellerModel?.sellers?.length,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) => SizedBox(width: 250, child: SellerCard(
            sellerModel: sellerModel?.sellers?[index],
            isHomePage: true,
            index: index,
            length: sellerModel?.sellers?.length ?? 0,
          )),
        ) : const SizedBox();

      },
    );
  }
}



