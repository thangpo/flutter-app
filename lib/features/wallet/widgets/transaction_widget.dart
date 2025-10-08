import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class TransactionWidget extends StatelessWidget {
  final WalletTransactionList? transactionModel;
  final bool isLastIndex;
  const TransactionWidget({super.key, this.transactionModel, required this.isLastIndex});

  @override
  Widget build(BuildContext context) {
    final bool isLtr = Provider.of<LocalizationController>(context, listen: false).isLtr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding, vertical: Dimensions.paddingSizeSmall),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if(transactionModel!.adminBonus! > 0)
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
              Row(children: [
                const Image(image: AssetImage(Images.coinDebit), width: 25,height: 25,),
                const SizedBox(width: Dimensions.paddingSizeSmall,),

                Text( '+' , style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeLarge),),

                Text(PriceConverter.convertPrice(context, transactionModel!.adminBonus), style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeLarge),),
              ],
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall,),


              Text('admin bonus', style: textRegular.copyWith(color: Theme.of(context).hintColor),),


            ],)),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(DateConverter.estimatedDateYear(DateTime.parse(transactionModel!.createdAt!)),
                style: textRegular.copyWith(color: Theme.of(context).hintColor),),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall,),


              Text( transactionModel!.credit! > 0 ? 'Credit': 'Debit',
                style: textRegular.copyWith(color: transactionModel!.credit! > 0 ? Colors.green: Colors.red),
              ),
            ],),
          ],),
          if(transactionModel!.adminBonus! > 0)
          Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Divider(thickness: .4,color: Theme.of(context).hintColor.withValues(alpha:.8),),),
          Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
            Row(children: [
                Image(image: AssetImage(transactionModel!.credit! > 0 ? Images.coinDebit: Images.coinCredit), width: 25,height: 25,),
              const SizedBox(width: Dimensions.paddingSizeSmall,),

             if(isLtr) Text( transactionModel!.credit! > 0 ? '+': '-',
                style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: Dimensions.fontSizeLarge),
              ),

                Text(PriceConverter.convertPrice(context,
                    transactionModel!.credit! > 0 ? transactionModel!.credit: transactionModel!.debit),
                  style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: Dimensions.fontSizeLarge),
                ),

              if(!isLtr) Text( transactionModel!.credit! > 0 ? '+': '-',
                style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: Dimensions.fontSizeLarge),
              ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall,),



            transactionModel?.paymentMethod != null?
            Text('${getTranslated(transactionModel?.transactionType, context)} ${getTranslated('via', context)} ${(transactionModel?.paymentMethod??'').replaceAll('_', ' ')}', style: textRegular.copyWith(color: Theme.of(context).hintColor),):
            Text('${getTranslated(transactionModel?.transactionType, context)}', style: textRegular.copyWith(color: Theme.of(context).hintColor),),


          ],)),
          Column(crossAxisAlignment: CrossAxisAlignment.end,children: [
            Text(DateConverter.estimatedDateYear(DateTime.parse(transactionModel!.createdAt!)),
              style: textRegular.copyWith(color: Theme.of(context).hintColor),),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall,),


            Text( transactionModel!.credit! > 0 ? 'Credit': 'Debit',
              style: textRegular.copyWith(color: transactionModel!.credit! > 0 ? Colors.green: Colors.red),
            ),
          ],),
          ],),

         if(!isLastIndex) Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Divider(thickness: .4,color: Theme.of(context).hintColor.withValues(alpha:.8),),),
        ],
      ),);
  }
}
