import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_calendar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_date_range_picker_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class WalletFilterBottomSheetWidget extends StatefulWidget {
  const WalletFilterBottomSheetWidget({super.key});

  @override
  State<WalletFilterBottomSheetWidget> createState() => _WalletFilterBottomSheetWidgetState();
}

class _WalletFilterBottomSheetWidgetState extends State<WalletFilterBottomSheetWidget> {

  static const List<String> filterTypeList = ['all', 'debit', 'credit'];


  @override
  void initState() {
    super.initState();

    Provider.of<WalletController>(context, listen: false).initFilterData();

  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return Consumer<WalletController>(builder: (context, walletController, _) {
      return Container(
        constraints: BoxConstraints(maxHeight: size.height * 0.70),
        decoration: BoxDecoration(
            color: Theme.of(context).highlightColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimensions.paddingSizeTwelve),
              topRight: Radius.circular(Dimensions.paddingSizeTwelve),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: .05),
                blurRadius: 17.89,
                offset: const Offset(0, 4.77),
              ),
            ]
        ),
        child: Column(children: [

          const _FilterTitleWidget(),
          Divider(height: 1, color: Theme.of(context).hintColor.withValues(alpha: .15), thickness: 1),

          Expanded(child: SizedBox(child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///Filter by
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                child: Text(getTranslated('filter_by', context)!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color:  Theme.of(context).textTheme.bodyLarge?.color)),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                child: SizedBox(height: 60, width: size.width, child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterTypeList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: ()=> walletController.setSelectedProductType(type: filterTypeList[index]),
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 50),
                          decoration: BoxDecoration(
                            border: Border.all(color: filterTypeList[index] == walletController.selectedFilterBy
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).hintColor),
                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                          ),
                          child: Center(child: Padding(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: Text(getTranslated(filterTypeList[index], context)!, style: textRegular.copyWith(
                              color: walletController.selectedFilterBy == filterTypeList[index]
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).hintColor,
                            )),
                          )),
                        ),
                      ),
                    );
                  },
                )),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Divider(height: 1, color: Theme.of(context).hintColor.withValues(alpha: .15), thickness: 1),


              ///Date Range
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                child: Text(getTranslated('date_range', context)!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color:  Theme.of(context).textTheme.bodyLarge?.color)),
              ),

              InkWell(
                onTap: ()=> showDialog(context: context, builder: (BuildContext context){
                  return Dialog(child: SizedBox(height: 400, child: CustomCalendarWidget(
                    initDateRange: PickerDateRange(walletController.startDate, walletController.endDate),
                    onSubmit: (range) => walletController.setSelectedDate(startDate: range?.startDate, endDate: range?.endDate),
                  )));
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Theme.of(context).hintColor.withValues(alpha: .15)),
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        CustomDateRangePickerWidget(
                          text: walletController.startDate == null
                              ? 'dd-mm-yyyy'
                              : DateConverter.dateStringMonthYear(walletController.startDate),
                        ),

                        const Icon(Icons.horizontal_rule, size: Dimensions.paddingSizeLarge),

                        CustomDateRangePickerWidget(
                          text: walletController.endDate == null
                              ? 'dd-mm-yyyy'
                              : DateConverter.dateStringMonthYear(walletController.endDate),
                        ),
                      ]),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        child: CustomAssetImageWidget(Images.calenderIcon),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Divider(height: 1, color: Theme.of(context).hintColor.withValues(alpha: .15), thickness: 1),


              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                child: Text(getTranslated('earn_by', context)!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color:  Theme.of(context).textTheme.bodyLarge?.color)),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: ListView.builder(
                  itemCount: AppConstants.walletEarnTypeList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index)=> _FilterItem(
                    title: getTranslated(AppConstants.walletEarnTypeList[index], context),
                    checked: walletController.selectedEarnByList?.contains(AppConstants.walletEarnTypeList[index]) ?? false,
                    onTap: ()=> walletController.onUpdateEarnBy(AppConstants.walletEarnTypeList[index]),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall,),

            ],
          )))),

          ///Bottom button
          SafeArea(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(
                color: Colors.grey[Provider.of<ThemeController>(context).darkTheme ? 800 : 200]!,
                spreadRadius: 0.5, blurRadius: 0.3,
              )],
            ),
            height: 80,
            child: Row(children: [
              Expanded(child: CustomButton(
                buttonText: '${getTranslated('clear_filter', context)}',
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: .125),
                buttonHeight: 55,
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                onTap: (){
                  Navigator.pop(context);


                  if(_isClearFilterData(walletController.walletTransactionModel)) {
                    walletController.getTransactionList(1);
                  }
                },
              )),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: CustomButton(
                isLoading: walletController.walletTransactionModel == null,
                buttonText: '${getTranslated('filter', context)}',
                backgroundColor: _canFilter() ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                buttonHeight: 55,
                onTap: _canFilter() ? (){

                  walletController.getTransactionList(
                    1,
                    transactionTypes: walletController.selectedEarnByList?.toList(),
                    endDate: walletController.endDate,
                    startDate: walletController.startDate,
                    filterBy: walletController.selectedFilterBy,

                  );

                  Navigator.pop(context);

                } : null,
              )),

            ]),
          )),
        ]),
      );
    });
  }

  bool _canFilter() {

    final WalletController walletController = Provider.of<WalletController>(context, listen: false);

    if (walletController.walletTransactionModel == null) return true;


    // Check if transaction types match
    final areTransactionTypesEqual =
        walletController.selectedEarnByList?.length == walletController.walletTransactionModel?.transactionTypes?.length &&
            walletController.selectedEarnByList?.toSet().containsAll(walletController.walletTransactionModel?.transactionTypes?.toSet() ?? {}) == true;

    // Check other conditions directly
    return !(areTransactionTypesEqual) ||
        walletController.endDate != walletController.walletTransactionModel?.endDate ||
        walletController.startDate != walletController.walletTransactionModel?.startDate ||
        walletController.selectedFilterBy != walletController.walletTransactionModel?.filterBy;
  }


  bool _isClearFilterData(WalletTransactionModel? walletModel) {
    return walletModel?.startDate != null ||
        walletModel?.endDate != null ||
        (walletModel?.transactionTypes?.isNotEmpty ?? false) ||
        (walletModel?.filterBy != null && (walletModel?.filterBy?.isNotEmpty ?? false));
  }




}



class _FilterTitleWidget extends StatelessWidget {
  const _FilterTitleWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 60, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Stack(children: [
        Align(alignment: Alignment.center, child: Text(
          getTranslated('filter_data', context)!,
          style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge, color:  Theme.of(context).textTheme.bodyLarge?.color),
        )),

        Positioned(right: 0, top: Dimensions.paddingSizeTwelve, child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Theme.of(context).hintColor.withValues(alpha: .25),
            ),
            child: const Center(child: CustomAssetImageWidget(Images.crossIcon, height: 15)),
          ),
        )),
      ]),
    ));
  }
}


class _FilterItem extends StatelessWidget {
  final String? title;
  final bool checked;
  final Function()? onTap;
  const _FilterItem({required this.title, required this.checked, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, mainAxisSize: MainAxisSize.min, children: [
            Expanded(child: Text(title??'', style: textRegular.copyWith(color: checked ? null : Theme.of(context).hintColor))),

            Icon(checked ? Icons.check_box_outlined : Icons.check_box_outline_blank_rounded,
                color: (checked && !Provider.of<ThemeController>(context, listen: false).darkTheme)?
                Theme.of(context).primaryColor:(checked && Provider.of<ThemeController>(context, listen: false).darkTheme)?
                Colors.white : Theme.of(context).hintColor.withValues(alpha:.5)),

          ],),),
      ),
    );
  }
}

