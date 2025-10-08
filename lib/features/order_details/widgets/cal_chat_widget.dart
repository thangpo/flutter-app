
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/shop_helper.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class CallAndChatWidget extends StatelessWidget {
  final OrderDetailsController? orderProvider;
  final Orders? orderModel;
  final bool isSeller;
  const CallAndChatWidget({super.key, this.orderProvider, this.isSeller = false, this.orderModel});

  @override
  Widget build(BuildContext context) {
    String? phone = isSeller? orderProvider!.orderDetails![0].seller!.phone : orderModel!.deliveryMan!.phone;
    String? name = isSeller? orderProvider!.orderDetails![0].seller!.shop!.name : '${orderModel!.deliveryMan!.fName!} ${orderModel!.deliveryMan!.lName!}';
    int? id =  isSeller ? orderProvider!.orderDetails![0].seller!.id : orderModel!.deliveryMan!.id;
    String? image =  isSeller ? orderProvider!.orderDetails![0].seller!.imageFullUrl?.path : orderModel!.deliveryMan!.imageFullUrl?.path;

    return Row(children: [
      InkWell(onTap: ()=> _launchUrl("tel:$phone"),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Container(width: 40,height: 40,decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha:.0525),
                  border: Border.all(color: Theme.of(context).hintColor),
                  borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Image.asset(Images.callIcon,color: Theme.of(context).colorScheme.onTertiaryContainer)))),

      InkWell(onTap: (){
        Provider.of<ChatController>(context, listen: false).setUserTypeIndex(context, 1);
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(
          image: image,
          id: id,
          name: name,
          userType: isSeller ? 1 : 0,
          isShopTemporaryClosed: isSeller
              ? orderProvider!.orderDetails![0].seller?.shop?.temporaryClose ?? false
              : false,
          isShopOnVacation: isSeller ?
          ShopHelper.isVacationActive(
            context,
            startDate: orderProvider?.orderDetails?[0].seller?.shop?.vacationStartDate,
            endDate: orderProvider?.orderDetails?[0].seller?.shop?.vacationEndDate,
            vacationDurationType: orderProvider?.orderDetails?[0].seller?.shop?.vacationDurationType,
            vacationStatus: orderProvider?.orderDetails?[0].seller?.shop?.vacationStatus,
            isInHouseSeller: orderProvider?.orderDetails?[0].order?.sellerIs == 'admin',
          ) : false,
        )));
      },
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Container(width: 40,decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha:.0525),
                  border: Border.all(color: Theme.of(context).hintColor),
                  borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Image.asset(Images.smsIcon,color: Theme.of(context).primaryColor))))
    ],);
  }
}
Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw 'Could not launch $url';
  }
}