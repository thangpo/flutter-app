import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/seller_card.dart';
import 'package:provider/provider.dart';

class AllSellerWidget extends StatelessWidget {
  final String? title;
  const AllSellerWidget({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Selector<ShopController, SellerModel?>(
      selector: (ctx, shopController)=> shopController.allSellerModel,
      builder: (context, sellerModel, child) {
        return (sellerModel?.sellers?.isNotEmpty ?? false)
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                itemCount: sellerModel?.sellers?.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) =>
                    SizedBox(
                      width: 250,
                      child: SellerCard(
                        sellerModel: sellerModel?.sellers?[index],
                        isHomePage: true,
                        index: index,
                        length: sellerModel?.sellers?.length ?? 0,
                      ),
                    ),
              ),
            ),
          ],
        )
            : const SizedBox();
      },
    );
  }
}
