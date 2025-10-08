import 'package:flutter/foundation.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/enums/vacation_duration_type.dart';

class ConfigModel {
  String? brandSetting;
  String? digitalProductSetting;
  int? systemDefaultCurrency;
  bool? digitalPayment;
  bool? cashOnDelivery;
  String? sellerRegistration;
  String? posActive;
  String? companyPhone;
  String? companyEmail;
  ImageFullUrl? companyLogo;
  ImageFullUrl? companyCoverImage;
  String? companyIcon;
  String? companyName;
  int? deliveryCountryRestriction;
  int? deliveryZipCodeAreaRestriction;
  BaseUrls? baseUrls;
  StaticUrls? staticUrls;
  String? aboutUs;
  String? privacyPolicy;
  List<Faq>? faq;
  String? termsConditions;
  RefundPolicy? refundPolicy;
  RefundPolicy? returnPolicy;
  RefundPolicy? cancellationPolicy;
  RefundPolicy? shippingPolicy;
  List<CurrencyList>? currencyList;
  String? currencySymbolPosition;
  String? businessMode;
  bool? maintenanceMode;
  List<Language>? language;
  List<ColorsModel>? colors;
  List<String>? unit;
  String? shippingMethod;
  bool? emailVerification;
  bool? phoneVerification;
  bool? firebaseVerification;
  String? countryCode;
  List<SocialLogin>? socialLogin;
  String? currencyModel;
  String? forgotPasswordVerification;
  Announcement? announcement;
  String? softwareVersion;
  int? decimalPointSettings;
  String? inhouseSelectedShippingType;
  int? billingInputByCustomer;
  int? minimumOrderLimit;
  int? walletStatus;
  int? loyaltyPointStatus;
  double? loyaltyPointExchangeRate;
  int? loyaltyPointMinimumPoint;
  List<PaymentMethods>? paymentMethods;
  OfflinePayment? offlinePayment;
  String? paymentMethodImagePath;
  String? refEarningStatus;
  String? activeTheme;
  List<PopularTags>? popularTags;
  int? guestCheckOut;
  int? addFundsToWallet;
  double? minimumAddFundAmount;
  double? maximumAddFundAmount;
  String? refSignup;
  int? orderVerification;
  InhouseTemporaryClose? inhouseTemporaryClose;
  InhouseVacationAdd? inhouseVacationAdd;
  int? mapApiStatus;
  DefaultLocation? defaultLocation;
  UserAppVersionControl? userAppVersionControl;
  ImageFullUrl? companyFavIcon;
  String? primaryColorCode;
  String? secondaryColorCode;
  MaintenanceMode? maintenanceModeData;
  CustomerLogin? customerLogin;
  CustomerVerification? customerVerification;
  int? refundDayLimit;
  int? otpResendTime;
  bool? hasLocaldb;
  bool? localMaintenanceMode;
  String? blogUrl;
  InHouseShop? inHouseShop;

  ConfigModel(
      {this.brandSetting,
        this.digitalProductSetting,
        this.systemDefaultCurrency,
        this.digitalPayment,
        this.cashOnDelivery,
        this.sellerRegistration,
        this.posActive,
        this.companyPhone,
        this.companyEmail,
        this.companyLogo,
        this.companyCoverImage,
        this.companyIcon,
        this.companyName,
        this.deliveryCountryRestriction,
        this.deliveryZipCodeAreaRestriction,
        this.baseUrls,
        this.staticUrls,
        this.aboutUs,
        this.privacyPolicy,
        this.faq,
        this.termsConditions,
        this.refundPolicy,
        this.returnPolicy,
        this.cancellationPolicy,
        this.shippingPolicy,
        this.currencyList,
        this.currencySymbolPosition,
        this.businessMode,
        this.maintenanceMode,
        this.language,
        this.colors,
        this.unit,
        this.shippingMethod,
        this.emailVerification,
        this.phoneVerification,
        this.firebaseVerification,
        this.countryCode,
        this.socialLogin,
        this.currencyModel,
        this.forgotPasswordVerification,
        this.announcement,
        this.softwareVersion,
        this.decimalPointSettings,
        this.inhouseSelectedShippingType,
        this.billingInputByCustomer,
        this.minimumOrderLimit,
        this.walletStatus,
        this.loyaltyPointStatus,
        this.loyaltyPointExchangeRate,
        this.loyaltyPointMinimumPoint,
        this.paymentMethods,
        this.offlinePayment,
        this.paymentMethodImagePath,
        this.refEarningStatus,
        this.activeTheme,
        this.popularTags,
        this.guestCheckOut,
        this.addFundsToWallet,
        this.minimumAddFundAmount,
        this.maximumAddFundAmount,
        this.refSignup,
        this.orderVerification,
        this.inhouseTemporaryClose,
        this.inhouseVacationAdd,
        this.mapApiStatus,
        this.defaultLocation,
        this.userAppVersionControl,
        this.companyFavIcon,
        this.primaryColorCode,
        this.secondaryColorCode,
        this.maintenanceModeData,
        this.customerLogin,
        this.customerVerification,
        this.refundDayLimit,
        this.otpResendTime,
        this.hasLocaldb,
        this.localMaintenanceMode,
        this.blogUrl,
        this.inHouseShop,
      });

  ConfigModel.fromJson(Map<String, dynamic> json) {
    brandSetting = json['brand_setting'];
    digitalProductSetting = json['digital_product_setting'];
    systemDefaultCurrency = json['system_default_currency'];
    digitalPayment = json['digital_payment'];
    cashOnDelivery = json['cash_on_delivery'];
    sellerRegistration = json['seller_registration'];
    posActive = json['pos_active'];
    companyPhone = json['company_phone'].toString();
    companyEmail = json['company_email'];
    companyLogo = json['company_cover_image'] != null
      ? ImageFullUrl.fromJson(json['company_cover_image'])
      : null;
    companyCoverImage = json['company_logo'] != null
        ? ImageFullUrl.fromJson(json['company_logo'])
        : null;
    // companyIcon = json['company_fav_icon'];
    companyName = json['company_name'];
    if(json['delivery_country_restriction'] != null){
      deliveryCountryRestriction = json['delivery_country_restriction'];
    }else{
      deliveryCountryRestriction = 0;
    }

    if(json['delivery_zip_code_area_restriction'] != null){
      deliveryZipCodeAreaRestriction = json['delivery_zip_code_area_restriction'];
    }else{
      deliveryZipCodeAreaRestriction = 0;
    }

    baseUrls = json['base_urls'] != null ? BaseUrls.fromJson(json['base_urls']) : null;
    staticUrls = json['static_urls'] != null ? StaticUrls.fromJson(json['static_urls']) : null;
    aboutUs = json['about_us'];
    privacyPolicy = json['privacy_policy'];
    if (json['faq'] != null) {
      faq = <Faq>[];
      json['faq'].forEach((v) {
        faq!.add(Faq.fromJson(v));
      });
    }
    termsConditions = json['terms_&_conditions'];
    refundPolicy = json['refund_policy'] != null ? RefundPolicy.fromJson(json['refund_policy']) : null;
    returnPolicy = json['return_policy'] != null ? RefundPolicy.fromJson(json['return_policy']) : null;
    cancellationPolicy = json['cancellation_policy'] != null ? RefundPolicy.fromJson(json['cancellation_policy']) : null;
    shippingPolicy = json['shipping_policy'] != null ? RefundPolicy.fromJson(json['shipping_policy']) : null;
    if (json['currency_list'] != null) {
      currencyList = <CurrencyList>[];
      json['currency_list'].forEach((v) {
        currencyList!.add(CurrencyList.fromJson(v));
      });
    }
    currencySymbolPosition = json['currency_symbol_position'];
    businessMode = json['business_mode'];
    // maintenanceMode = json['maintenance_mode'];
    if (json['language'] != null) {
      language = <Language>[];
      json['language'].forEach((v) {
        language!.add(Language.fromJson(v));
      });
    }
    if (json['colors'] != null) {
      colors = <ColorsModel>[];
      json['colors'].forEach((v) {
        colors!.add(ColorsModel.fromJson(v));
      });
    }
    unit = json['unit'].cast<String>();
    shippingMethod = json['shipping_method'];
    emailVerification = json['email_verification'];
    phoneVerification = json['phone_verification'];
    firebaseVerification = json['firebase_verification'];
    countryCode = json['country_code'];
    if (json['social_login'] != null) {
      socialLogin = <SocialLogin>[];
      json['social_login'].forEach((v) {
        socialLogin!.add(SocialLogin.fromJson(v));
      });
    }
    currencyModel = json['currency_model'];
    forgotPasswordVerification = json['forgot_password_verification'];
    announcement = json['announcement'] != null ? Announcement.fromJson(json['announcement']) : null;
    softwareVersion = json['software_version'];
    if(json['decimal_point_settings'] != null){
      decimalPointSettings = int.parse(json['decimal_point_settings'].toString());
    }else{
      decimalPointSettings = 1;
    }

    inhouseSelectedShippingType = json['inhouse_selected_shipping_type'];
    billingInputByCustomer = json['billing_input_by_customer'];
    minimumOrderLimit = json['minimum_order_limit'];
    walletStatus = json['wallet_status'];
    loyaltyPointStatus = json['loyalty_point_status'];
    if(json['loyalty_point_exchange_rate'] != null){
      loyaltyPointExchangeRate =  double.parse(json['loyalty_point_exchange_rate'].toString());
    }else{
      loyaltyPointExchangeRate = 1;
    }

    loyaltyPointMinimumPoint = json['loyalty_point_minimum_point'];
    if (json['payment_methods'] != null) {
      paymentMethods = <PaymentMethods>[];
      json['payment_methods'].forEach((v) {
        paymentMethods!.add(PaymentMethods.fromJson(v));
      });
    }
    offlinePayment = json['offline_payment'] != null ? OfflinePayment.fromJson(json['offline_payment']) : null;
    paymentMethodImagePath = json['payment_method_image_path'];
    refEarningStatus = json['ref_earning_status'].toString();
    activeTheme = json['active_theme'];
    //activeTheme = 'theme_lifestyle';
    if (json['popular_tags'] != null) {
      popularTags = <PopularTags>[];
      json['popular_tags'].forEach((v) {
        popularTags!.add(PopularTags.fromJson(v));
      });
    }
    if(json['guest_checkout'] != null){
      guestCheckOut = int.parse(json['guest_checkout'].toString());
    }else{
      guestCheckOut = 0;
    }
    if(json['add_funds_to_wallet'] != null){
      addFundsToWallet = int.tryParse(json['add_funds_to_wallet'].toString()) ?? 0;
    }else{
      addFundsToWallet = 0;
    }
    if(json['minimum_add_fund_amount'] != null){
      minimumAddFundAmount = double.parse(json['minimum_add_fund_amount'].toString());
    }else{
      minimumAddFundAmount = 0;
    }

    if(json['maximum_add_fund_amount'] != null){
      maximumAddFundAmount = double.parse(json['maximum_add_fund_amount'].toString());
    }else{
      maximumAddFundAmount = 0;
    }
    refSignup = json['referral_customer_signup_url'];

    if(json['order_verification'] != null){
      try{
        orderVerification = json['order_verification'];
      }catch(e){
        orderVerification = int.parse(json['order_verification'].toString());
      }
    }

    inhouseTemporaryClose = json['inhouse_temporary_close'] != null
        ? InhouseTemporaryClose.fromJson(json['inhouse_temporary_close'])
        : null;
    inhouseVacationAdd = json['inhouse_vacation_add'] != null
        ? InhouseVacationAdd.fromJson(json['inhouse_vacation_add'])
        : null;
    mapApiStatus = json['map_api_status'] != null ? int.parse(json['map_api_status'].toString()) : null;

    defaultLocation = json['default_location'] != null
      ? DefaultLocation.fromJson(json['default_location'])
      : null;

    userAppVersionControl = json['user_app_version_control'] != null
      ? UserAppVersionControl.fromJson(json['user_app_version_control'])
      : null;

    // companyFavIcon
    companyFavIcon = json['company_fav_icon'] != null
      ? ImageFullUrl.fromJson(json['company_fav_icon'])
      : null;
    primaryColorCode = json['primary_color'];
    secondaryColorCode = json['secondary_color'];
    maintenanceModeData = json['maintenance_mode'] != null ? MaintenanceMode.fromJson(json['maintenance_mode']) : null;

    customerLogin = json['customer_login'] != null
      ? CustomerLogin.fromJson(json['customer_login'])
      : null;
    customerVerification = json['customer_verification'] != null
      ? CustomerVerification.fromJson(json['customer_verification'])
      : null;
    if(json['refund_day_limit'] != null){
      refundDayLimit = int.tryParse(json['refund_day_limit'].toString());
    }
    otpResendTime = int.tryParse(json['otp_resend_time'].toString());
     hasLocaldb = json['has_local_db'];
    localMaintenanceMode = json['local_m_mode'];

    if (kDebugMode) {
      print('-----blog----${json['blog_page']}');
    }

    blogUrl = json['blog_page'];

    if(json['in_house_shop'] != null){
      inHouseShop = InHouseShop.fromJson(json['in_house_shop']);
    }
  }

}

class BaseUrls {
  String? productImageUrl;
  String? productThumbnailUrl;
  String? digitalProductUrl;
  String? brandImageUrl;
  String? customerImageUrl;
  String? bannerImageUrl;
  String? categoryImageUrl;
  String? reviewImageUrl;
  String? sellerImageUrl;
  String? shopImageUrl;
  String? notificationImageUrl;
  String? deliveryManImageUrl;

  BaseUrls(
      {this.productImageUrl,
        this.productThumbnailUrl,
        this.digitalProductUrl,
        this.brandImageUrl,
        this.customerImageUrl,
        this.bannerImageUrl,
        this.categoryImageUrl,
        this.reviewImageUrl,
        this.sellerImageUrl,
        this.shopImageUrl,
        this.notificationImageUrl,
        this.deliveryManImageUrl});

  BaseUrls.fromJson(Map<String, dynamic> json) {
    productImageUrl = json['product_image_url'];
    productThumbnailUrl = json['product_thumbnail_url'];
    digitalProductUrl = json['digital_product_url'];
    brandImageUrl = json['brand_image_url'];
    customerImageUrl = json['customer_image_url'];
    bannerImageUrl = json['banner_image_url'];
    categoryImageUrl = json['category_image_url'];
    reviewImageUrl = json['review_image_url'];
    sellerImageUrl = json['seller_image_url'];
    shopImageUrl = json['shop_image_url'];
    notificationImageUrl = json['notification_image_url'];
    deliveryManImageUrl = json['delivery_man_image_url'];
  }

}

class StaticUrls {
  String? contactUs;
  String? brands;
  String? categories;
  String? customerAccount;

  StaticUrls(
      {this.contactUs, this.brands, this.categories, this.customerAccount});

  StaticUrls.fromJson(Map<String, dynamic> json) {
    contactUs = json['contact_us'];
    brands = json['brands'];
    categories = json['categories'];
    customerAccount = json['customer_account'];
  }
}

class Faq {
  int? id;
  String? question;
  String? answer;
  int? ranking;
  int? status;
  String? createdAt;
  String? updatedAt;

  Faq(
      {this.id,
        this.question,
        this.answer,
        this.ranking,
        this.status,
        this.createdAt,
        this.updatedAt});

  Faq.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    question = json['question'];
    answer = json['answer'];
    ranking = json['ranking'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

}

class RefundPolicy {
  int? status;
  String? content;

  RefundPolicy({this.status, this.content});

  RefundPolicy.fromJson(Map<String, dynamic> json) {
    if(json['status'] != null){
      try{
        status = json['status'];
      }catch(e){
        status = int.parse(json['status'].toString());
      }
    }

    content = json['content'];
  }

}

class CurrencyList {
  int? id;
  String? name;
  String? symbol;
  String? code;
  bool? status;
  double? exchangeRate;
  String? createdAt;
  String? updatedAt;

  CurrencyList(
      {this.id,
        this.name,
        this.symbol,
        this.code,
        this.status,
        this.exchangeRate,
        this.createdAt,
        this.updatedAt});

  CurrencyList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    symbol = json['symbol'];
    code = json['code'];
    status = json['status'];
    if(json['exchange_rate'] != null){
      try{
        exchangeRate = json['exchange_rate'].toDouble();
      }catch(e){
        exchangeRate = double.parse(json['exchange_rate'].toString());
      }
    }

    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

}

class Language {
  String? code;
  String? name;

  Language({this.code, this.name});

  Language.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
  }
}

class ColorsModel {
  int? id;
  String? name;
  String? code;
  String? createdAt;
  String? updatedAt;

  ColorsModel({this.id, this.name, this.code, this.createdAt, this.updatedAt});

  ColorsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

}

class SocialLogin {
  String? loginMedium;
  bool? status;

  SocialLogin({this.loginMedium, this.status});

  SocialLogin.fromJson(Map<String, dynamic> json) {
    loginMedium = json['login_medium'];
    status = json['status'];
  }

}

class Announcement {
  String? status;
  String? color;
  String? textColor;
  String? announcement;

  Announcement({this.status, this.color, this.textColor, this.announcement});

  Announcement.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    color = json['color'];
    textColor = json['text_color'];
    announcement = json['announcement'];
  }

}

class PaymentMethods {
  String? keyName;
  AdditionalDatas? additionalDatas;

  PaymentMethods({this.keyName, this.additionalDatas});

  PaymentMethods.fromJson(Map<String, dynamic> json) {
    keyName = json['key_name'];
    additionalDatas = json['additional_datas'] != null ? AdditionalDatas.fromJson(json['additional_datas']) : null;
  }

}

class AdditionalDatas {
  String? gatewayTitle;
  String? gatewayImage;

  AdditionalDatas({this.gatewayTitle, this.gatewayImage});

  AdditionalDatas.fromJson(Map<String, dynamic> json) {
    gatewayTitle = json['gateway_title'];
    gatewayImage = json['gateway_image'];
  }

}

class OfflinePayment {
  String? name;
  String? image;

  OfflinePayment({this.name, this.image});

  OfflinePayment.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    image = json['image'];
  }

}

class PopularTags {
  int? id;
  String? tag;
  String? createdAt;
  String? updatedAt;

  PopularTags(
      {this.id, this.tag,  this.createdAt, this.updatedAt});

  PopularTags.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tag = json['tag'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

}


class InhouseTemporaryClose {
  bool? status;
  InhouseTemporaryClose({this.status});

  InhouseTemporaryClose.fromJson(Map<String, dynamic> json) {
    status = '${json['status']}'.contains('1') || json['status'] == true;
  }
}

class InhouseVacationAdd {
  bool? status;
  DateTime? vacationStartDate;
  DateTime? vacationEndDate;
  VacationDurationType? vacationDurationType;
  String? vacationNote;

  InhouseVacationAdd(
      {this.status,
        this.vacationStartDate,
        this.vacationEndDate,
        this.vacationNote,
        this.vacationDurationType,
      });

  InhouseVacationAdd.fromJson(Map<String, dynamic> json) {
    status = '${json['status']}'.contains('1');
    vacationStartDate = DateTime.tryParse(json['vacation_start_date'].toString());
    vacationEndDate = DateTime.tryParse(json['vacation_end_date'].toString());
    vacationNote = json['vacation_note'];
    if (json['vacation_duration_type'] != null) {
      vacationDurationType = VacationDurationType.fromJson(json['vacation_duration_type']);
    }
  }
}


class DefaultLocation {
  String? lat;
  String? lng;

  DefaultLocation({this.lat, this.lng});

  DefaultLocation.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lng = json['lng'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}


class UserAppVersionControl {
  ForAndroid? forAndroid;
  ForAndroid? forIos;

  UserAppVersionControl({this.forAndroid, this.forIos});

  UserAppVersionControl.fromJson(Map<String, dynamic> json) {
    forAndroid = json['for_android'] != null
      ? ForAndroid.fromJson(json['for_android'])
      : null;
    forIos = json['for_ios'] != null
      ? ForAndroid.fromJson(json['for_ios'])
      : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    if (forAndroid != null) {
      data['for_android'] = forAndroid!.toJson();
    }
    if (forIos != null) {
      data['for_ios'] = forIos!.toJson();
    }
    return data;
  }
}

class ForAndroid {
  int? status;
  String? version;
  String? link;

  ForAndroid({this.status, this.version, this.link});

  ForAndroid.fromJson(Map<String, dynamic> json) {
    status = int.parse(json['status'].toString());
    version = json['version'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['version'] = version;
    data['link'] = link;
    return data;
  }
}


class MaintenanceMode {
  int? maintenanceStatus;
  SelectedMaintenanceSystem? selectedMaintenanceSystem;
  MaintenanceMessages? maintenanceMessages;
  MaintenanceTypeAndDuration? maintenanceTypeAndDuration;

  MaintenanceMode(
      {this.maintenanceStatus,
        this.selectedMaintenanceSystem,
        this.maintenanceMessages, this.maintenanceTypeAndDuration});

  MaintenanceMode.fromJson(Map<String, dynamic> json) {
    maintenanceStatus = int.tryParse(json['maintenance_status'].toString());
    selectedMaintenanceSystem = json['selected_maintenance_system'] != null
        ? SelectedMaintenanceSystem.fromJson(
        json['selected_maintenance_system'])
        : null;
    maintenanceMessages = json['maintenance_messages'] != null
        ? MaintenanceMessages.fromJson(json['maintenance_messages'])
        : null;

    maintenanceTypeAndDuration = json['maintenance_type_and_duration'] != null
        ? MaintenanceTypeAndDuration.fromJson(
        json['maintenance_type_and_duration'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['maintenance_status'] = maintenanceStatus;
    if (selectedMaintenanceSystem != null) {
      data['selected_maintenance_system'] =
          selectedMaintenanceSystem!.toJson();
    }
    if (maintenanceMessages != null) {
      data['maintenance_messages'] = maintenanceMessages!.toJson();
    }
    if (maintenanceTypeAndDuration != null) {
      data['maintenance_type_and_duration'] =
          maintenanceTypeAndDuration!.toJson();
    }
    return data;
  }
}

class SelectedMaintenanceSystem {
  int? branchPanel;
  int? customerApp;
  int? webApp;
  int? deliverymanApp;

  SelectedMaintenanceSystem(
      {this.branchPanel, this.customerApp, this.webApp, this.deliverymanApp});

  SelectedMaintenanceSystem.fromJson(Map<String, dynamic> json) {
    customerApp = int.tryParse(json['user_app'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['branch_panel'] = branchPanel;
    data['customer_app'] = customerApp;
    data['web_app'] = webApp;
    data['deliveryman_app'] = deliverymanApp;
    return data;
  }
}

class MaintenanceMessages {
  int? businessNumber;
  int? businessEmail;
  String? maintenanceMessage;
  String? messageBody;

  MaintenanceMessages(
      {this.businessNumber,
        this.businessEmail,
        this.maintenanceMessage,
        this.messageBody});

  MaintenanceMessages.fromJson(Map<String, dynamic> json) {
    businessNumber = json['business_number'];
    businessEmail = json['business_email'];
    maintenanceMessage = json['maintenance_message'];
    messageBody = json['message_body'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['business_number'] = businessNumber;
    data['business_email'] = businessEmail;
    data['maintenance_message'] = maintenanceMessage;
    data['message_body'] = messageBody;
    return data;
  }
}

class MaintenanceTypeAndDuration {
  String? _maintenanceDuration;
  String? _startDate;
  String? _endDate;

  MaintenanceTypeAndDuration(
      {String? maintenanceDuration, String? startDate, String? endDate}) {
    if (maintenanceDuration != null) {
      _maintenanceDuration = maintenanceDuration;
    }
    if (startDate != null) {
      _startDate = startDate;
    }
    if (endDate != null) {
      _endDate = endDate;
    }
  }

  String? get maintenanceDuration => _maintenanceDuration;
  set setMaintenanceDuration(String? maintenanceDuration) =>
      _maintenanceDuration = maintenanceDuration;
  String? get startDate => _startDate;
  set setStartDate(String? startDate) => _startDate = startDate;
  String? get setEndDate => _endDate;
  set endDate(String? endDate) => _endDate = endDate;

  MaintenanceTypeAndDuration.fromJson(Map<String, dynamic> json) {
    _maintenanceDuration = json['maintenance_duration'];
    _startDate = json['start_date'];
    _endDate = json['end_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['maintenance_duration'] = _maintenanceDuration;
    data['start_date'] = _startDate;
    data['end_date'] = _endDate;
    return data;
  }
}

class CustomerLogin {
  LoginOption? loginOption;
  SocialMediaLoginOptions? socialMediaLoginOptions;

  CustomerLogin({this.loginOption, this.socialMediaLoginOptions});

  CustomerLogin.fromJson(Map<String, dynamic> json) {
    loginOption = json['login_option'] != null
        ? LoginOption.fromJson(json['login_option'])
        : null;
    socialMediaLoginOptions = json['social_media_login_options'] != null
        ? SocialMediaLoginOptions.fromJson(
        json['social_media_login_options'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (loginOption != null) {
      data['login_option'] = loginOption!.toJson();
    }
    if (socialMediaLoginOptions != null) {
      data['social_media_login_options'] =
          socialMediaLoginOptions!.toJson();
    }
    return data;
  }
}

class LoginOption {
  int? manualLogin;
  int? otpLogin;
  int? socialMediaLogin;

  LoginOption({this.manualLogin, this.otpLogin, this.socialMediaLogin});

  LoginOption.fromJson(Map<String, dynamic> json) {
    manualLogin = int.tryParse(json['manual_login'].toString());
    otpLogin = int.tryParse(json['otp_login'].toString());
    socialMediaLogin =  int.tryParse(json['social_login'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['manual_login'] = manualLogin;
    data['otp_login'] = otpLogin;
    data['social_media_login'] = socialMediaLogin;
    return data;
  }
}

class SocialMediaLoginOptions {
  int? google;
  int? facebook;
  int? apple;

  SocialMediaLoginOptions({this.google, this.facebook, this.apple});

  SocialMediaLoginOptions.fromJson(Map<String, dynamic> json) {
    google = int.tryParse(json['google'].toString());
    facebook = int.tryParse(json['facebook'].toString());
    apple = int.tryParse(json['apple'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['google'] = google;
    data['facebook'] = facebook;
    data['apple'] = apple;
    return data;
  }
}


class CustomerVerification {
  int? status;
  int? phone;
  int? email;
  int? firebase;

  CustomerVerification({this.status, this.phone, this.email, this.firebase});

  CustomerVerification.fromJson(Map<String, dynamic> json) {
    status = int.tryParse(json['status'].toString());
    phone =  int.tryParse(json['phone'].toString());
    email = int.tryParse(json['email'].toString());
    firebase = int.tryParse(json['firebase'].toString());

    // status = 1;
    // firebase = 1;
    // email = 0;
    // phone =  0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['phone'] = phone;
    data['email'] = email;
    data['firebase'] = firebase;
    return data;
  }
}


class InHouseShop {
  final int? id;
  final int? sellerId;
  final String? authorType;
  final String? name;
  final String? slug;
  final String? contact;
  final String? address;
  final String? image;
  final String? imageStorageType;
  final String? banner;
  final String? bannerStorageType;
  final String? offerBanner;
  final String? offerBannerStorageType;
  final String? bottomBanner;
  final String? bottomBannerStorageType;
  final int? vacationDurationType;
  final String? vacationStartDate;
  final String? vacationEndDate;
  final String? vacationNote;
  final bool? vacationStatus;
  final bool? temporaryClose;
  final String? updatedAt;
  final String? createdAt;

  final ImageFullUrl? imageFullUrl;
  final ImageFullUrl? bannerFullUrl;
  final ImageFullUrl? offerBannerFullUrl;
  final ImageFullUrl? bottomBannerFullUrl;
  final ImageFullUrl? tinCertificateFullUrl;

  InHouseShop({
    this.id,
    this.sellerId,
    this.authorType,
    this.name,
    this.slug,
    this.contact,
    this.address,
    this.image,
    this.imageStorageType,
    this.banner,
    this.bannerStorageType,
    this.offerBanner,
    this.offerBannerStorageType,
    this.bottomBanner,
    this.bottomBannerStorageType,
    this.vacationDurationType,
    this.vacationStartDate,
    this.vacationEndDate,
    this.vacationNote,
    this.vacationStatus,
    this.temporaryClose,
    this.updatedAt,
    this.createdAt,
    this.imageFullUrl,
    this.bannerFullUrl,
    this.offerBannerFullUrl,
    this.bottomBannerFullUrl,
    this.tinCertificateFullUrl,
  });

  factory InHouseShop.fromJson(Map<String, dynamic> json) => InHouseShop(
    id: json['id'],
    sellerId: json['seller_id'],
    authorType: json['author_type'],
    name: json['name'],
    slug: json['slug'],
    contact: json['contact'],
    address: json['address'],
    image: json['image'],
    imageStorageType: json['image_storage_type'],
    banner: json['banner'],
    bannerStorageType: json['banner_storage_type'],
    offerBanner: json['offer_banner'],
    offerBannerStorageType: json['offer_banner_storage_type'],
    bottomBanner: json['bottom_banner'],
    bottomBannerStorageType: json['bottom_banner_storage_type'],
    vacationDurationType: int.tryParse(json['vacation_duration_type'].toString()),
    vacationStartDate: json['vacation_start_date'],
    vacationEndDate: json['vacation_end_date'],
    vacationNote: json['vacation_note'],
    vacationStatus: json['vacation_status'],
    temporaryClose: json['temporary_close'],
    updatedAt: json['updated_at'],
    createdAt: json['created_at'],
    imageFullUrl: json['image_full_url'] != null
        ? ImageFullUrl.fromJson(json['image_full_url'])
        : null,
    bannerFullUrl: json['banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['banner_full_url'])
        : null,
    offerBannerFullUrl: json['offer_banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['offer_banner_full_url'])
        : null,
    bottomBannerFullUrl: json['bottom_banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['bottom_banner_full_url'])
        : null,
    tinCertificateFullUrl: json['tin_certificate_full_url'] != null
        ? ImageFullUrl.fromJson(json['tin_certificate_full_url'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'author_type': authorType,
    'name': name,
    'slug': slug,
    'contact': contact,
    'address': address,
    'image': image,
    'image_storage_type': imageStorageType,
    'banner': banner,
    'banner_storage_type': bannerStorageType,
    'offer_banner': offerBanner,
    'offer_banner_storage_type': offerBannerStorageType,
    'bottom_banner': bottomBanner,
    'bottom_banner_storage_type': bottomBannerStorageType,
    'vacation_duration_type': vacationDurationType,
    'vacation_start_date': vacationStartDate,
    'vacation_end_date': vacationEndDate,
    'vacation_note': vacationNote,
    'vacation_status': vacationStatus,
    'temporary_close': temporaryClose,
    'updated_at': updatedAt,
    'created_at': createdAt,
    'image_full_url': imageFullUrl?.toJson(),
    'banner_full_url': bannerFullUrl?.toJson(),
    'offer_banner_full_url': offerBannerFullUrl?.toJson(),
    'bottom_banner_full_url': bottomBannerFullUrl?.toJson(),
    'tin_certificate_full_url': tinCertificateFullUrl?.toJson(),
  };
}