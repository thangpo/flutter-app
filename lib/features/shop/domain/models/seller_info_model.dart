import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/enums/vacation_duration_type.dart';

class SellerInfoModel {
  Seller? _seller;
  String? _avgRating;
  int? _totalReview;
  int? _totalOrder;
  int? _totalProduct;
  double? minimumOrderAmount;

  SellerInfoModel(
      {Seller? seller, String? avgRating, int? totalReview, int? totalOrder, int? totalProduct, double? minimumOrderAmount}) {
    if (seller != null) {
      _seller = seller;
    }
    if (avgRating != null) {
      _avgRating = avgRating;
    }
    if (totalReview != null) {
      _totalReview = totalReview;
    }
    if (totalOrder != null) {
      _totalOrder = totalOrder;
    }
    if (totalProduct != null) {
      _totalProduct = totalProduct;
    }
    if (minimumOrderAmount != null) {
      minimumOrderAmount = minimumOrderAmount;
    }
  }

  Seller? get seller => _seller;
  String? get avgRating => _avgRating;
  int? get totalReview => _totalReview;
  int? get totalOrder => _totalOrder;
  int? get totalProduct => _totalProduct;


  SellerInfoModel.fromJson(Map<String, dynamic> json) {
    _seller =
    json['seller'] != null ? Seller.fromJson(json['seller']) : null;
    _avgRating = json['avg_rating'].toString();
    _totalReview = json['total_review'];
    _totalOrder = json['total_order'];
    _totalProduct = json['total_product'];
    if(json['minimum_order_amount'] != null){
      try{
        minimumOrderAmount = json['minimum_order_amount'].toDouble();
      }catch(e){
        minimumOrderAmount = double.parse(json['minimum_order_amount'].toString());
      }
    }else{
      minimumOrderAmount = 0;
    }

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (_seller != null) {
      data['seller'] = _seller!.toJson();
    }
    data['avg_rating'] = _avgRating;
    data['total_review'] = _totalReview;
    data['total_order'] = _totalOrder;
    data['total_product'] = _totalProduct;
    return data;
  }
}

class Seller {
  int? _id;
  String? _fName;
  String? _lName;
  String? _phone;
  String? _image;
  Shop? _shop;

  Seller(
      {int? id,
        String? fName,
        String? lName,
        String? phone,
        String? image,
        Shop? shop}) {
    if (id != null) {
      _id = id;
    }
    if (fName != null) {
      _fName = fName;
    }
    if (lName != null) {
      _lName = lName;
    }
    if (phone != null) {
      _phone = phone;
    }
    if (image != null) {
      _image = image;
    }
    if (shop != null) {
      _shop = shop;
    }
  }

  int? get id => _id;
  String? get fName => _fName;
  String? get lName => _lName;
  String? get phone => _phone;
  String? get image => _image;
  Shop? get shop => _shop;

  Seller.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _fName = json['f_name'];
    _lName = json['l_name'];
    _phone = json['phone'];
    _image = json['image'];
    _shop = json['shop'] != null ? Shop.fromJson(json['shop']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['f_name'] = _fName;
    data['l_name'] = _lName;
    data['phone'] = _phone;
    data['image'] = _image;
    if (_shop != null) {
      data['shop'] = _shop!.toJson();
    }
    return data;
  }
}

class Shop {
  int? _id;
  int? _sellerId;
  String? _name;
  String? _address;
  String? _contact;
  String? _image;
  ImageFullUrl? _imageFullUrl;
  String? _createdAt;
  String? _updatedAt;
  String? _banner;
  bool? _temporaryClose;
  DateTime? _vacationEndDate;
  DateTime? _vacationStartDate;
  VacationDurationType? _vacationDurationType;
  bool? _vacationStatus;
  ImageFullUrl? _bannerFullUrl;

  Shop(
      {int? id,
        int? sellerId,
        String? name,
        String? address,
        String? contact,
        String? image,
        ImageFullUrl? imageFullUrl,
        String? createdAt,
        String? updatedAt,
        String? banner,
        bool? temporaryClose,
        DateTime? vacationEndDate,
        DateTime? vacationStartDate,
        VacationDurationType? vacationDurationType,
        bool? vacationStatus,
        ImageFullUrl? bannerFullUrl,

      }) {
    if (id != null) {
      _id = id;
    }
    if (sellerId != null) {
      _sellerId = sellerId;
    }
    if (name != null) {
      _name = name;
    }
    if (address != null) {
      _address = address;
    }
    if (contact != null) {
      _contact = contact;
    }
    if (image != null) {
      _image = image;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
    if (banner != null) {
      _banner = banner;
    }
    _temporaryClose = temporaryClose;
    _vacationEndDate = vacationEndDate;
    _vacationStartDate = vacationStartDate;
    _vacationDurationType = vacationDurationType;
    _vacationStatus = vacationStatus;
    _imageFullUrl = imageFullUrl;
    _bannerFullUrl = bannerFullUrl;
  }

  int? get id => _id;
  int? get sellerId => _sellerId;
  String? get name => _name;
  String? get address => _address;
  String? get contact => _contact;
  String? get image => _image;
  ImageFullUrl? get imageFullUrl => _imageFullUrl;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  String? get banner => _banner;
  bool? get temporaryClose => _temporaryClose;
  DateTime? get vacationEndDate => _vacationEndDate;
  DateTime? get vacationStartDate => _vacationStartDate;
  VacationDurationType? get vacationDurationType => _vacationDurationType;
  bool? get vacationStatus => _vacationStatus;
  ImageFullUrl? get bannerFullUrl => _bannerFullUrl;


  Shop.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _sellerId = int.parse(json['seller_id'].toString());
    _name = json['name'];
    _address = json['address'];
    _contact = json['contact'];
    _image = json['image'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _banner = json['banner'];
    _temporaryClose = json['temporary_close']??false;
    _vacationEndDate = DateTime.tryParse(json['vacation_end_date'].toString());
    _vacationStartDate = DateTime.tryParse(json['vacation_start_date'].toString());
    _vacationDurationType = json['vacation_duration_type'] != null ?  VacationDurationType.fromJson(json['vacation_duration_type']) : null;
    _vacationStatus = '${json['vacation_status']}'.contains('1') || json['vacation_status'] == true;
    _imageFullUrl = json['image_full_url'] != null
        ? ImageFullUrl.fromJson(json['image_full_url'])
        : null;
    _bannerFullUrl = json['banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['banner_full_url'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['seller_id'] = _sellerId;
    data['name'] = _name;
    data['address'] = _address;
    data['contact'] = _contact;
    data['image'] = _image;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    data['banner'] = _banner;
    data['temporary_close'] = _temporaryClose;
    data['vacation_end_date'] = _vacationEndDate;
    data['vacation_start_date'] = _vacationEndDate;
    data['vacation_status'] = _vacationStatus;

    return data;
  }
}