import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';

class ProfileModel {
  int? id;
  String? name;
  String? method;
  String? fName;
  String? lName;
  String? phone;
  String? image;
  ImageFullUrl? imageFullUrl;
  String? email;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;
  double? walletBalance;
  double? loyaltyPoint;
  String? referCode;
  int? referCount;
  double? totalOrder;
  int? isPhoneVerified;
  String? emailVerificationToken;

  ProfileModel(
      {this.id,
        this.name,
        this.method,
        this.fName,
        this.lName,
        this.phone,
        this.image,
        this.email,
        this.emailVerifiedAt,
        this.createdAt,
        this.updatedAt,
        this.walletBalance,
        this.loyaltyPoint,
        this.referCode,
        this.referCount,
        this.totalOrder,
        this.imageFullUrl,
        this.isPhoneVerified,
        this.emailVerificationToken
      });

  ProfileModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    method = json['_method'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    image = json['image'];
    email = json['email'];
    emailVerifiedAt = json['email_verified_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if(json['wallet_balance'] != null){
      walletBalance = json['wallet_balance'].toDouble();
    }
    if(json['loyalty_point'] != null){
      loyaltyPoint = json['loyalty_point'].toDouble();
    }else{
      loyaltyPoint = 0.0;
    }
    if(json['referral_code'] != null){
      referCode = json['referral_code'];
    }
    if(json['referral_user_count'] != null){
      try{
        referCount = json['referral_user_count'];
      }catch(e){
        referCount = int.parse(json['referral_user_count'].toString());
      }

    }
    if(json['orders_count'] != null){
      try{
        totalOrder = json['orders_count'].toDouble();
      }catch(e){
        totalOrder = double.parse(json['orders_count'].toString());
      }
    }

    imageFullUrl = json['image_full_url'] != null
      ? ImageFullUrl.fromJson(json['image_full_url'])
      : null;

    emailVerificationToken = json['email_verification_token'];
    isPhoneVerified = json['is_phone_verified'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['_method'] = method;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['image'] = image;
    data['email'] = email;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['wallet_balance'] = walletBalance;
    data['loyalty_point'] = loyaltyPoint;
    return data;
  }
}
