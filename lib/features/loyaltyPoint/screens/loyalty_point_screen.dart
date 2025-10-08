import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/filter_icon_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/transaction_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/controllers/loyalty_point_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/domain/models/loyalty_point_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/widget/loyalty_filter_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/widget/loyalty_point_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/home_screens.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/widget/loyalty_point_converter_dialogue_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/widget/loyalty_point_info_widget.dart';
import 'package:provider/provider.dart';



class LoyaltyPointScreen extends StatefulWidget {
  const LoyaltyPointScreen({super.key});
  @override
  State<LoyaltyPointScreen> createState() => _LoyaltyPointScreenState();
}

class _LoyaltyPointScreenState extends State<LoyaltyPointScreen> {
  final ScrollController scrollController = ScrollController();


  @override
  void initState() {
    super.initState();

    if(Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<LoyaltyPointController>(context, listen: false).getLoyaltyPointList(context, 1, isUpdate: false);
    }


  }


  @override
  Widget build(BuildContext context) {
    final bool isGuestMode = !Provider.of<AuthController>(context, listen: false).isLoggedIn();


    return Scaffold(
        body: RefreshIndicator(color: Theme.of(context).cardColor,
          backgroundColor: Theme.of(context).primaryColor,
          onRefresh: () async => Provider.of<LoyaltyPointController>(context, listen: false).getLoyaltyPointList(context,1),
          child: NestedScrollView(
            controller: scrollController,
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                    toolbarHeight: 70,
                    expandedHeight: 200.0,
                    backgroundColor: innerBoxIsScrolled ? Theme.of(context).cardColor : Theme.of(context).primaryColor,
                    floating: false,
                    pinned: true,
                    automaticallyImplyLeading : innerBoxIsScrolled?  true : false,
                    leading: innerBoxIsScrolled? InkWell(onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.arrow_back_ios, color: Theme.of(context).hintColor,)) : const SizedBox(),

                    flexibleSpace: FlexibleSpaceBar(centerTitle: true,
                        title: innerBoxIsScrolled ? Text(getTranslated('loyalty_point', context)!,
                          style: textMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: Dimensions.fontSizeLarge),): const SizedBox(),
                        background: const LoyaltyPointInfoWidget())),

                SliverPersistentHeader(pinned: true, delegate: SliverDelegate(
                  height: 60,
                  child: Container(
                    height: 60, // Explicit height matching the delegate
                    color: Theme.of(context).canvasColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.homePagePadding,
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(
                          '${getTranslated('point_history', context)}',
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),

                        Selector<LoyaltyPointController, LoyaltyPointModel?>(
                          selector: (context, loyaltyController) => loyaltyController.loyaltyPointModel,
                          builder: (context, loyaltyPointModel, _) {
                            return FilterIconWidget(
                              filterCount: _getFilterCount(loyaltyPointModel),
                              onTap: loyaltyPointModel == null
                                  ? null
                                  : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (builder) => const LoyaltyFilterBottomSheetWidget(),
                                );
                              },
                            );
                          },
                        ),
                      ],
                      ),
                    ),
                  ),
                )),
              ];
            },
            body: isGuestMode ? const NotLoggedInWidget() : Consumer<LoyaltyPointController>(
                builder: (context, loyaltyPointController, _) {
                  return (loyaltyPointController.loyaltyPointModel?.loyaltyPointList?.isNotEmpty ?? false) ? PaginatedListView(
                    scrollController: scrollController,
                    onPaginate: (int? offset)=> loyaltyPointController.getLoyaltyPointList(
                      context, offset ?? 1,
                      startDate: loyaltyPointController.loyaltyPointModel?.startDate,
                      endDate: loyaltyPointController.loyaltyPointModel?.endDate,
                      filterBy: loyaltyPointController.loyaltyPointModel?.filterBy,
                      transactionTypes: loyaltyPointController.loyaltyPointModel?.transactionTypes,
                    ),
                    totalSize: loyaltyPointController.loyaltyPointModel?.totalSize,
                    offset: loyaltyPointController.loyaltyPointModel?.offset,
                    limit: loyaltyPointController.loyaltyPointModel?.limit ,
                    itemView: Expanded(child: ListView.builder(
                      itemCount: loyaltyPointController.loyaltyPointModel?.loyaltyPointList?.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (ctx,index){
                        return LoyaltyPointWidget(
                          loyaltyPointModel: loyaltyPointController.loyaltyPointModel?.loyaltyPointList?[index],
                          isLastItem: index + 1 == loyaltyPointController.loyaltyPointModel?.loyaltyPointList?.length,
                        );
                      },
                    )),
                  ) : (loyaltyPointController.loyaltyPointModel?.loyaltyPointList?.isEmpty ?? false) ? NoInternetOrDataScreenWidget(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height / 6),
                    isNoInternet: false, icon: Images.noTransactionIcon, message: 'no_transaction_history',
                  ) : const TransactionShimmer();
                }
            ),
          ),
        ),

        floatingActionButton: Padding(padding: const EdgeInsets.only(left: 30),
            child: Consumer<ProfileController>(
                builder: (context, profile, _){
                  return CustomButton(leftIcon : Images.dollarIcon,
                      buttonText: '${getTranslated('convert_to_currency', context)}',
                      onTap: () {showDialog(context: context, builder: (context) => Dialog(
                          insetPadding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          child: LoyaltyPointConverterDialogueWidget(myPoint: profile.userInfoModel!.loyaltyPoint ?? 0)));});}))
    );
  }

  int _getFilterCount(LoyaltyPointModel? loyaltyPointModel) {
    if (loyaltyPointModel == null) return 0;

    final int nonNullFiltersCount = [
      loyaltyPointModel.filterBy,
      loyaltyPointModel.startDate,

    ].whereType<Object>().length;

    final int transactionTypesCount = loyaltyPointModel.transactionTypes?.length ?? 0;

    return nonNullFiltersCount + transactionTypesCount;
  }

}
