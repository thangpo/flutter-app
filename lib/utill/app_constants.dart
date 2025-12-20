import 'package:flutter_sixvalley_ecommerce/common/enums/local_caches_type_enum.dart';
import 'package:flutter_sixvalley_ecommerce/localization/models/language_model.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';

class AppConstants {
  static const String appName = 'VNShop247';
  static const String slogan =
      'VNShop247: Tất cả trong tay, thỏa sức chi tiêu, thỏa sức bay xa.';
  static const String appVersion = '15.4';

  ///Flutter SDK 3.32.8
  static const LocalCachesTypeEnum cachesType = LocalCachesTypeEnum.all;

  static const String baseUrl = 'https://vnshop247.com';
  static const String travelBaseUrl = 'https://vietnamtoure.com/api';

  static const String socialBaseUrl = 'https://social.vnshop247.com';
  static const String socialServerKey =
      'f6e69c898ddd643154c9bd4b152555842e26a868-d195c100005dddb9f1a30a67a5ae42d4-19845955';
  static const String socialApiUpdateFcmTokenUri=
      'api/update_fcm_token';
  static const String socialAuthUri = '/api/auth';
  static const String socialCreateAccountUri = '/api/create-account';
  static const String socialDeleteAccessTokenUri = '/api/delete-access-token';
  static const String socialPostsUri = '/api/posts';
  static const String socialCreatePostUri = '/api/new_post';
  static const String socialGetStoriesUri = '/api/get-stories';
  static const String socialCreateStoryUri = '/api/create-story';
  static const String socialGetStoryByIdUri = '/api/get_story_by_id';
  static const String socialGetUserStoriesUri = '/api/get-user-stories';
  static const String socialGetUserDataUri = '/api/get-user-data';
  static const String socialReactUri = '/api/post-actions';
  static const String socialHidePostUri = '/api/hide_post';
  static const String socialGetEventUri = '/api/get-events';
  static const String socialGetEventByIdUri = '/api/get_event_by_id';
  static const String socialCreateEventUri = '/api/create-event';
  static const String socialEditOrDeleteEventUri = '/api/events';
  static const String socialInterestEventUri = '/api/interest-event';
  static const String socialGetPageDetailUri = '/api/get-page-data';
  static const String socialGoToEventUri = '/api/go-to-event';
  static const String socialReactStoryUri = '/api/react_story';
  static const String socialGetStoryViewsUri = '/api/get_story_views';
  static const String socialGetStoryReactionsUri = '/api/get-reactions';
  static const String socialGetPostDataUri = '/api/get-post-data';
  static const String socialCommentsUri = '/api/comments';
  static const String socialLiveUri = '/api/live';
  static const String socialGenerateAgoraTokenUri = '/api/generate_agora_token';
  static const String socialGenerateZegoTokenUri = '/api/zego_token';
  static const String socialAgoraAppId = '554e80e2bcfe401cbde32aaf13d48ce5';
  static const int socialZegoAppId = 1649787820; // AppID Zego cho Prebuilt Call
  // Resource ID offline push (ZEGOCLOUD console) cho Call Kit
  static const String socialZegoResourceId = 'voip_callkit';
  static const String socialCreateGroupUri = '/api/create-group';
  static const String socialGetPostColorsUri = '/api/get-post-colors';
  static const String socialGetPostColorByIdUri = '/api/get-post-color';
  static const String socialUpdateGroupUri = '/api/update-group-data';
  static const String socialJoinGroupUri = '/api/join-group';
  static const String socialGroupsUri = '/api/groups';
  static const String socialNotificationsUri = '/api/notifications';
  static const String socialGetMyGroupsUri = '/api/get-my-groups';
  static const String socialGetCommunityUri = '/api/get-community';
  static const String socialGetGroupMembersUri = '/api/get_group_members';
  static const String socialGetNotInGroupMembersUri =
      '/api/not_in_group_member';
  static const String socialMakeGroupAdminUri = '/api/make_group_admin';
  static const String socialDeleteGroupMemberUri = '/api/delete_group_member';
  static const String socialReportGroupUri = '/api/report_group';
  static const String socialDeleteGroupUri = '/api/delete_group';
  static const String socialGetGroupDataUri = '/api/get-group-data';
  static const String socialSearch = '/api/search';
  static const String socialRecentSearchUri = '/api/recent_search';
  static const String socialGetBirthdayUsersUri = '/api/get_friends_birthday';
  static const String socialReportCommentUri = '/api/report_comment';
  static const String socialFetchRecommendedUri = '/api/fetch-recommended';
  static const String socialGetUserDataInfoUri = '/api/get-user-data';
  static const String socialCheckUsernameUri = '/api/check_username';
  static const String socialGetUsername = '/api/get-user-data-username';

  static const String socialGetFriendsUri = '/api/get-friends';
  static const String socialGetFollowersUri = '/api/get-followers';
  static const String socialGetFollowingUri = '/api/get-following';

  // Chat APIs – dùng đúng path theo WoWonder
  static const String socialChatSendMessageUri = '/api/send-message';
  static const String socialChatGetUserMessagesUri = '/api/get_user_messages';
  static const String socialChatReadChatsUri = '/api/read_chats';

  //block user 04/11/2025
  static const String socialBlockUser='/api/block-user';
  static const String socialGetBlockUser='/api/get-blocked-users';

  static const String socialReportUser='/api/report_user';
  static const String socialGetAlbumUser='/api/get-user-albums/';

  //lấy page
  static const String socialFetchRecommendPage='/api/fetch-recommended';
  static const String socialGetMyPage='/api/get-my-pages';
  static const String socialGetCategory='/api/get_category';
  static const String socialCreatePage='/api/create-page';
  static const String socialUpdateDatePage='/api/update-page-data';
  static const String socialLikePage='/api/like-page';
  static const String socialSendMessPage='/api/page_chat';
  static const String socialGetPageChatList='/api/page_chat';
  static const String socialGetChatPage='/api/page_chat';
  static const String socialDeletePage='/api/delete_page';
  //follow
  static const String socialFollowUser = '/api/follow-user';
  static const String socialUpdateDataUser = '/api/update-user-data';

  static const String googleServerClientId = '839301392682-ss4cmfti3779n8m2dmiuv7a8uhcoffe5.apps.googleusercontent.com';
  static const String userId = 'userId';
  static const String name = 'name';
  static const String categoriesUri = '/api/v1/categories';
  static const String brandUri = '/api/v1/brands?guest_id=1';

  static const String brandProductUri = '/api/v1/brands/products/';
  static const String categoryProductUri = '/api/v1/categories/products/';
  static const String registrationUri = '/api/v1/auth/register';
  static const String loginUri = '/api/v1/auth/login';

  static const String logOut = '/api/v1/auth/logout';
  static const String latestProductUri =
      '/api/v1/products/latest?guest_id=1&limit=10&&offset=';
  static const String newArrivalProductUri =
      '/api/v1/products/new-arrival?guest_id=1&limit=10&&offset=';
  static const String topProductUri =
      '/api/v1/products/top-rated?guest_id=1&limit=10&&offset=';
  static const String bestSellingProductUri =
      '/api/v1/products/best-sellings?guest_id=1&limit=10&offset=';
  static const String discountedProductUri =
      '/api/v1/products/discounted-product?guest_id=1&limit=10&&offset=';
  static const String featuredProductUri =
      '/api/v1/products/featured?guest_id=1&limit=10&&offset=';
  static const String homeCategoryProductUri =
      '/api/v1/products/home-categories?guest_id=1';
  static const String productDetailsUri = '/api/v1/products/details/';
  static const String productReviewUri = '/api/v1/products/reviews/';
  static const String searchUri = '/api/v1/products/filter';
  static const String getSuggestionProductName =
      '/api/v1/products/suggestion-product?guest_id=1&name=';
  static const String configUri = '/api/v1/config';
  static const String addWishListUri =
      '/api/v1/customer/wish-list/add?product_id=';
  static const String removeWishListUri =
      '/api/v1/customer/wish-list/remove?product_id=';
  static const String updateProfileUri = '/api/v1/customer/update-profile';
  static const String customerUri = '/api/v1/customer/info';
  static const String addressListUri = '/api/v1/customer/address/list';
  static const String removeAddressUri = '/api/v1/customer/address';
  static const String addAddressUri = '/api/v1/customer/address/add';
  static const String getWishListUri = '/api/v1/customer/wish-list';
  static const String supportTicketUri =
      '/api/v1/customer/support-ticket/create';
  static const String getBannerList = '/api/v1/banners';
  static const String relatedProductUri = '/api/v1/products/related-products/';
  static const String orderUri = '/api/v1/customer/order/list?limit=10&offset=';
  static const String orderDetailsUri =
      '/api/v1/customer/order/details?order_id=';
  static const String orderPlaceUri = '/api/v1/customer/order/place';
  static const String sellerUri = '/api/v1/seller?seller_id=';
  static const String sellerProductUri = '/api/v1/seller/';
  static const String sellerList = '/api/v1/seller/list/';
  static const String trackingUri = '/api/v1/order/track?order_id=';
  static const String forgetPasswordUri = '/api/v1/auth/forgot-password';
  static const String getSupportTicketUri =
      '/api/v1/customer/support-ticket/get';
  static const String supportTicketConversationUri =
      '/api/v1/customer/support-ticket/conv/';
  static const String supportTicketReplyUri =
      '/api/v1/customer/support-ticket/reply/';
  static const String closeSupportTicketUri =
      '/api/v1/customer/support-ticket/close/';
  static const String submitReviewUri = '/api/v1/products/reviews/submit';
  static const String getOrderWiseReview = '/api/v1/products/review/';
  static const String updateOrderWiseReview = '/api/v1/products/review/update';
  static const String deleteOrderWiseReviewImage =
      '/api/v1/products/review/delete-image';
  static const String flashDealUri = '/api/v1/flash-deals';
  static const String featuredDealUri = '/api/v1/deals/featured';
  static const String flashDealProductUri = '/api/v1/flash-deals/products/';
  static const String counterUri = '/api/v1/products/counter/';
  static const String socialLinkUri = '/api/v1/products/social-share-link/';
  static const String shippingUri = '/api/v1/products/shipping-methods';
  static const String couponUri = '/api/v1/coupon/apply?code=';
  static const String messageUri = '/api/v1/customer/chat/get-messages/';
  static const String chatInfoUri = '/api/v1/customer/chat/list/';
  static const String searchChat = '/api/v1/customer/chat/search/';
  static const String sendMessageUri = '/api/v1/customer/chat/send-message/';
  static const String seenMessageUri = '/api/v1/customer/chat/seen-message/';
  static const String tokenUri = '/api/v1/customer/cm-firebase-token';
  static const String notificationUri = '/api/v1/notifications';
  static const String seenNotificationUri = '/api/v1/notifications/seen';
  static const String getCartDataUri = '/api/v1/cart';
  static const String addToCartUri = '/api/v1/cart/add';
  static const String updateCartQuantityUri = '/api/v1/cart/update';
  static const String removeFromCartUri = '/api/v1/cart/remove';
  static const String getShippingMethod = '/api/v1/shipping-method/by-seller';
  static const String chooseShippingMethod =
      '/api/v1/shipping-method/choose-for-order';
  static const String chosenShippingMethod = '/api/v1/shipping-method/chosen';
  static const String sendOtpToPhone = '/api/v1/auth/check-phone';
  static const String resendPhoneOtpUri = '/api/v1/auth/resend-otp-check-phone';
  static const String verifyPhoneUri = '/api/v1/auth/verify-phone';
  static const String socialLoginUri = '/api/v1/auth/social-customer-login';
  static const String sendOtpToEmail = '/api/v1/auth/check-email';
  static const String resendEmailOtpUri = '/api/v1/auth/resend-otp-check-email';
  static const String verifyEmailUri = '/api/v1/auth/verify-email';
  static const String resetPasswordUri = '/api/v1/auth/reset-password';
  static const String verifyOtpUri = '/api/v1/auth/verify-otp';
  static const String refundRequestUri = '/api/v1/customer/order/refund-store';
  static const String refundRequestPreReqUri = '/api/v1/customer/order/refund';
  static const String refundResultUri = '/api/v1/customer/order/refund-details';
  static const String cancelOrderUri = '/api/v1/order/cancel-order';
  static const String getSelectedShippingTypeUri =
      '/api/v1/shipping-method/check-shipping-type';
  static const String dealOfTheDay = '/api/v1/dealsoftheday/deal-of-the-day';
  static const String walletTransactionUri = '/api/v1/customer/wallet/list';
  static const String loyaltyPointUri = '/api/v1/customer/loyalty/list';
  static const String loyaltyPointConvert =
      '/api/v1/customer/loyalty/loyalty-exchange-currency';
  static const String deleteCustomerAccount = '/api/v1/customer/account-delete';
  static const String deliveryRestrictedCountryList =
      '/api/v1/customer/get-restricted-country-list';
  static const String deliveryRestrictedZipList =
      '/api/v1/customer/get-restricted-zip-list';
  static const String getOrderFromOrderId =
      '/api/v1/customer/order/get-order-by-id?order_id=';
  static const String offlinePayment =
      '/api/v1/customer/order/place-by-offline-payment';
  static const String walletPayment = '/api/v1/customer/order/place-by-wallet';
  static const String couponListApi = '/api/v1/coupon/list?limit=100&offset=';
  static const String sellerWiseCouponListApi = '/api/v1/coupons/';
  static const String sellerWiseBestSellingProduct = '/api/v1/seller/';
  static const String digitalPayment = '/api/v1/digital-payment';
  static const String offlinePaymentList =
      '/api/v1/customer/order/offline-payment-method-list';
  static const String sellerWiseCategoryList = '/api/v1/categories?seller_id=';
  static const String sellerWiseBrandList = '/api/v1/brands?seller_id=';
  static const String getDigitalAuthorList =
      '/api/v1/products/digital-author-list?guest_id=1';
  static const String getDigitalPublishingHouse =
      '/api/v1/products/digital-publishing-house-list?guest_id=1';
  static const String verifyProfileInfo = '/api/v1/auth/verify-profile-info';
  static const String firebaseAuthTokenStore =
      '/api/v1/auth/firebase-auth-token-store';
  static const String productRestockRequest =
      '/api/v1/cart/product-restock-request';
  static const String productRestockList =
      '/api/v1/customer/restock-requests/list?';
  static const String productRestockDelete =
      '/api/v1/customer/restock-requests/delete';
  static const String clearanceAllProductUri =
      '/api/v1/products/clearance-sale';
  static const String clearanceShopProductUri = '/api/v1/seller/';
  static const String clearanceShopSearchProductUri = '/api/v1/seller/';
  static const String businessPagesUri = '/api/v1/business-pages?type=';
  static const String getDeliveryManReview =
      '/api/v1/customer/order/deliveryman-review?order_id=';
  static const String submitDeliveryManReview =
      '/api/v1/customer/order/deliveryman-review/update?order_id=';
  static const String mergeGuestCart = '/api/v1/cart/get-merge-guest-cart';

  //address
  static const String updateAddressUri = '/api/v1/customer/address/update';
  static const String geocodeUri = '/api/v1/mapapi/geocode-api';
  static const String searchLocationUri =
      '/api/v1/mapapi/place-api-autocomplete';
  static const String placeDetailsUri = '/api/v1/mapapi/place-api-details';
  static const String distanceMatrixUri = '/api/v1/mapapi/distance-api';
  static const String chatWithDeliveryMan = '/api/v1/mapapi/distance-api';

  static const String getGuestIdUri = '/api/v1/get-guest-id';
  static const String mostDemandedProduct =
      '/api/v1/products/most-demanded-product?guest_id=1';
  static const String shopAgainFromRecentStore =
      '/api/v1/products/shop-again-product';
  static const String findWhatYouNeed = '/api/v1/categories/find-what-you-need';
  static const String orderTrack = '/api/v1/order/track-order';
  static const String addFundToWallet = '/api/v1/add-to-fund';
  static const String reorder = '/api/v1/customer/order/again';
  static const String walletBonusList = '/api/v1/customer/wallet/bonus-list';
  static const String moreStore = '/api/v1/seller/more';
  static const String justForYou = '/api/v1/products/just-for-you?guest_id=1';
  static const String mostSearching = '/api/v1/products/most-searching';
  static const String contactUsUri = '/api/v1/contact-us';
  static const String attributeUri = '/api/v1/attributes';
  static const String availableCoupon = '/api/v1/coupon/applicable-list';
  static const String downloadDigitalProduct =
      '/api/v1/customer/order/digital-product-download/';
  static const String otpVResendForDigitalProduct =
      '/api/v1/customer/order/digital-product-download-otp-resend';
  static const String otpVerificationForDigitalProduct =
      '/api/v1/customer/order/digital-product-download-otp-verify';
  static const String selectCartItemsUri = '/api/v1/cart/select-cart-items';
  static const String generateInvoice =
      '/api/v1/customer/order/generate-invoice?order_id=';

  static const String checkEmailUri = '/api/v1/auth/check-email';
  static const String checkPhoneUri = '/api/v1/auth/check-phone?phone=';
  static const String firebaseAuthVerify = '/api/v1/auth/firebase-auth-verify';
  static const String registerWithOtp = '/api/v1/auth/registration-with-otp';
  static const String verifyTokenUri = '/api/v1/auth/verify-token';
  static const String existingAccountCheck =
      '/api/v1/auth/existing-account-check';
  static const String referralAmountUri =
      '/api/v1/cart/get-referral-discount-redeem';

  static const String getCompareList = '/api/v1/customer/compare/list';
  static const String addToCompareList =
      '/api/v1/customer/compare/product-store';
  static const String removeAllFromCompareList =
      '/api/v1/customer/compare/clear-all';
  static const String replaceFromCompareList =
      '/api/v1/customer/compare/product-replace';
  static const String setCurrentLanguage = '/api/v1/customer/language-change';
  static const String registerWithSocialMedia =
      '/api/v1/auth/registration-with-social-media';
  // fcm firebase token
  static const String fcmApiKey='AIzaSyA3d7ByFeD97ZelFqdeIUCDAR68Ih4_hKE';
  static const String fcmMobilesdkAppId='1:839301392682:android:51ce0e1487edd71de45653';
  static const String fcmProjectNumber='839301392682';
  static const String fcmProjectId='vnsshop-c7883';
  // sharePreference
  static const String userLoginToken = 'user_login_token';
  static const String socialAccessToken = 'social_access_token';
  static const String socialUserId = 'social_user_id';
  static const String socialUserAvatar = 'social_user_avatar';
  static const String socialUserName = 'social_user_name';

  static const String guestId = 'guestId';
  static const String user = 'user';
  static const String userEmail = 'user_email';
  static const String userPassword = 'user_password';
  static const String homeAddress = 'home_address';
  static const String searchProductName = 'search_product';
  static const String officeAddress = 'office_address';
  static const String config = 'config';
  static const String guestMode = 'guest_mode';
  static const String currency = 'currency';
  static const String langKey = 'lang';
  static const String intro = 'intro';
  static const String userLogData = 'user_log_data';
  static const pi = 3.14;
  static const defaultSpread = 0.0872665;
  static const double minFilter = 0;
  static const double maxFilter = 1000000;
  static const String appleLoginEmail = 'apple_login_email';
  static const String guestCartId = 'guest_cart_id';

  // order status
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String processing = 'processing';
  static const String processed = 'processed';
  static const String delivered = 'delivered';
  static const String failed = 'failed';
  static const String returned = 'returned';
  static const String cancelled = 'canceled';
  static const String outForDelivery = 'out_for_delivery';
  static const String maintenanceModeTopic = 'maintenance_mode_start_user_app';
  static const String countryCode = 'country_code';
  static const String languageCode = 'language_code';
  static const String theme = 'theme';
  static const String topic = 'sixvalley';
  static const String demoTopic = 'demo_reset';
  static const String userAddress = 'user_address';

  static List<LanguageModel> languages = [
    LanguageModel(
        imageUrl: Images.en,
        languageName: 'English',
        countryCode: 'US',
        languageCode: 'en'),
    LanguageModel(
        imageUrl: Images.ar,
        languageName: 'Arabic',
        countryCode: 'SA',
        languageCode: 'ar'),
    LanguageModel(
        imageUrl: Images.hi,
        languageName: 'Hindi',
        countryCode: 'IN',
        languageCode: 'hi'),
    LanguageModel(
        imageUrl: Images.bn,
        languageName: 'Bangla',
        countryCode: 'BD',
        languageCode: 'bn'),
    LanguageModel(
        imageUrl: Images.es,
        languageName: 'Spanish',
        countryCode: 'ES',
        languageCode: 'es'),
    LanguageModel(
        imageUrl: Images.vi,
        languageName: 'Vietnamese',
        countryCode: 'VN',
        languageCode: 'vi'),
  ];

  static const reviewList = ['very_bad', 'bad', 'good', 'very_good', 'best'];

  static const double maxSizeOfASingleFile = 10;
  static const double maxLimitOfTotalFileSent = 5;
  static const double maxLimitOfFileSentINConversation = 25;

  static const List<String> filterTypeList = ['all', 'debit', 'credit'];

  static const List<String> loyaltyEarnTypeList = [
    'order_place',
    'point_to_wallet',
    'refund_order'
  ];

  static const List<String> walletEarnTypeList = [
    'add_fund_by_admin',
    'loyalty_point',
    'order_place',
    'order_refund',
    'added_via_payment_method',
    'earned_by_referral'
  ];

  static const List<String> videoExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'mpeg',
    'mpg',
    'm4v',
    '3gp',
    'ogv'
  ];

  static const List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'jpe',
    'jif',
    'jfif',
    'jfi',
    'png',
    'gif',
    'webp',
    'tiff',
    'tif',
    'bmp',
    'svg',
  ];

  static const List<String> documentExtensions = [
    'doc',
    'docx',
    'txt',
    'csv',
    'xls',
    'xlsx',
    'rar',
    'tar',
    'targz',
    'zip',
    'pdf',
  ];
}
