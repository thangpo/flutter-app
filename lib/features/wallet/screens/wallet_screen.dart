import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/filter_icon_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/aster_theme_home_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/transaction_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/widgets/transaction_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/widgets/wallet_bonus_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/widgets/wallet_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/widgets/wallet_filter_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';


class WalletScreen extends StatefulWidget {
  final bool isBacButtonExist;
  const WalletScreen({super.key, this.isBacButtonExist = true});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final tooltipController = JustTheController();
  final TextEditingController inputAmountController = TextEditingController();
  final FocusNode focusNode = FocusNode();


  final ScrollController scrollController = ScrollController();
  final bool darkMode = Provider.of<ThemeController>(Get.context!, listen: false).darkTheme;
  final bool isGuestMode = !Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn();

  @override
  void initState() {
    super.initState();

    if(Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<WalletController>(context, listen: false).getTransactionList(1, isUpdate: false);
      Provider.of<ProfileController>(context, listen: false).getUserInfo(context);
      Provider.of<WalletController>(context, listen: false).getWalletBonusBannerList();

    }
  }

  @override
  void dispose() {
    super.dispose();

    tooltipController.dispose();
    inputAmountController.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(resizeToAvoidBottomInset: false, body: RefreshIndicator(
      color: Theme.of(context).cardColor,
      backgroundColor: Theme.of(context).primaryColor,
      onRefresh: () async {
        Provider.of<WalletController>(context, listen: false).getTransactionList(1);
      },
      child: CustomScrollView(controller: scrollController, slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          iconTheme:  IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
          backgroundColor: Theme.of(context).cardColor,
          leading: InkWell(onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios,),
          ),
          centerTitle: true,
          title: Text(getTranslated('wallet', context)!,style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),

        SliverToBoxAdapter(child: Column(children: [

          isGuestMode
              ? NotLoggedInWidget(message: getTranslated('to_view_the_wishlist', context))
              : Column(children: [
            Consumer<WalletController>(builder: (context, walletP,_) {
              return Padding(
                  padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                  child: Container(
                    height: MediaQuery.of(context).size.width / 3.0,
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                    margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Provider.of<ThemeController>(context, listen: false).darkTheme
                          ? Theme.of(context).cardColor
                          : Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                      boxShadow: [BoxShadow(color: Colors.grey[darkMode ? 900 : 200]!, spreadRadius: 0.5, blurRadius: 0.3)],
                    ),
                    child: WalletCardWidget(
                      tooltipController: tooltipController, focusNode: focusNode,
                      inputAmountController: inputAmountController,
                    ),
                  ));
            }),

            if(Provider.of<SplashController>(context, listen: false).configModel?.addFundsToWallet == 1)
            const WalletBonusWidget()

          ]),
        ])),


        SliverPersistentHeader(pinned: true, delegate: SliverDelegate(height: 60, child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(children: [
            const SizedBox(height: Dimensions.paddingSizeLarge,),
            Consumer<WalletController>(builder: (context, walletController, child) {
              return Padding(padding: const EdgeInsets.only(left: Dimensions.homePagePadding, right: Dimensions.homePagePadding),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${getTranslated('wallet_history', context)}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color:  Theme.of(context).textTheme.bodyLarge?.color),),

                  FilterIconWidget(
                    filterCount: _getFilterCount(walletController.walletTransactionModel),
                    onTap: walletController.walletTransactionModel == null ? null : (){
                      showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_)=> const WalletFilterBottomSheetWidget()
                      );
                    },
                  ),

                ]),
              );
            }),
          ]),
        ))),

        SliverToBoxAdapter(
          child: isGuestMode ? const NotLoggedInWidget() : Consumer<WalletController>(
              builder: (context, walletController, _) {
                return (walletController.walletTransactionModel?.walletTransactionList?.isNotEmpty ?? false) ?  PaginatedListView(
                  scrollController: scrollController,
                  onPaginate: (int? offset) async => walletController.getTransactionList(
                    offset ?? 1,
                    startDate: walletController.walletTransactionModel?.startDate,
                    endDate: walletController.walletTransactionModel?.endDate,
                    filterBy: walletController.walletTransactionModel?.filterBy,
                    transactionTypes: walletController.walletTransactionModel?.transactionTypes,
                  ),
                  totalSize: walletController.walletTransactionModel?.totalSize,
                  offset: walletController.walletTransactionModel?.offset,
                  itemView: RepaintBoundary(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: walletController.walletTransactionModel?.walletTransactionList?.length,
                      itemBuilder: (ctx,index){
                        return TransactionWidget(
                          transactionModel: walletController.walletTransactionModel?.walletTransactionList?[index],
                          isLastIndex: index + 1 == walletController.walletTransactionModel?.walletTransactionList?.length,
                        );
                      },
                    ),
                  ),
                ) : (walletController.walletTransactionModel?.walletTransactionList?.isEmpty ?? false) ?
                const NoInternetOrDataScreenWidget(
                  padding: EdgeInsets.only(top: 50),
                  isNoInternet: false, message: 'no_transaction_history', icon: Images.noTransactionIcon,
                ) : const TransactionShimmer();
              }
          ),
        ),
      ]),
    ));
  }

  int _getFilterCount(WalletTransactionModel? walletTransactionModel) {
    if (walletTransactionModel == null) return 0;

    final int nonNullFiltersCount = [
      walletTransactionModel.filterBy,
      walletTransactionModel.startDate,
    ].whereType<Object>().length;

    final int transactionTypesCount = walletTransactionModel.transactionTypes?.length ?? 0;

    return nonNullFiltersCount + transactionTypesCount;
  }
}






