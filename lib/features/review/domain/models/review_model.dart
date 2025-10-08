import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';

class ReviewModel {
  int? _id;
  int? _productId;
  int? _customerId;
  String? _comment;
  List<String>? _attachment;
  int? _rating;
  int? _status;
  String? _createdAt;
  String? _updatedAt;
  Customer? _customer;
  Reply? _reply;
  List<ImageFullUrl>? _attachmentFullUrl;

  ReviewModel(
      {int? id,
        int? productId,
        int? customerId,
        String? comment,
        List<String>? attachment,
        int? rating,
        int? status,
        String? createdAt,
        String? updatedAt,
        Customer? customer,
        Reply? reply,
        List<ImageFullUrl>? attachmentFullUrl}) {
    _id = id;
    _productId = productId;
    _customerId = customerId;
    _comment = comment;
    _attachment = attachment;
    _rating = rating;
    _status = status;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _customer = customer;
    _attachmentFullUrl = attachmentFullUrl;
    if (reply != null) {
      _reply = reply;
    }
  }

  int? get id => _id;
  int? get productId => _productId;
  int? get customerId => _customerId;
  String? get comment => _comment;
  List<String>? get attachment => _attachment;
  int? get rating => _rating;
  int? get status => _status;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  Customer? get customer => _customer;
  Reply? get reply => _reply;
  List<ImageFullUrl>? get attachmentFullUrl => _attachmentFullUrl;

  ReviewModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _productId = int.parse(json['product_id'].toString());
    _customerId = int.parse(json['customer_id'].toString());
    _comment = json['comment'];
    if(json['attachment'] != null && json['attachment'] is List){
      _attachment = json['attachment'].cast<String>();
    }
    _rating = json['rating'];
    _status = json['status'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _customer = json['customer'] != null
        ? Customer.fromJson(json['customer'])
        : null;
    _reply = json['reply'] != null ? Reply.fromJson(json['reply']) : null;
    if (json['attachment_full_url'] != null) {
      _attachmentFullUrl = <ImageFullUrl>[];
      json['attachment_full_url'].forEach((v) {
        _attachmentFullUrl!.add(ImageFullUrl.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['product_id'] = _productId;
    data['customer_id'] = _customerId;
    data['comment'] = _comment;
    if (_customer != null) {
      data['customer'] = _customer!.toJson();
    }
    data['rating'] = _rating;
    data['status'] = _status;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    if (_customer != null) {
      data['customer'] = _customer!.toJson();
    }
    if (_reply != null) {
      data['reply'] = _reply!.toJson();
    }
    return data;
  }
}

class Customer {
  int? _id;
  String? _name;
  String? _fName;
  String? _lName;
  String? _phone;
  String? _image;
  String? _email;
  String? _emailVerifiedAt;
  String? _createdAt;
  String? _updatedAt;
  String? _streetAddress;
  String? _country;
  String? _city;
  String? _zip;
  String? _houseNo;
  String? _apartmentNo;
  ImageFullUrl? _imageFullUrl;

  Customer(
      {int? id,
        String? name,
        String? fName,
        String? lName,
        String? phone,
        String? image,
        String? email,
        String? emailVerifiedAt,
        String? createdAt,
        String? updatedAt,
        String? streetAddress,
        String? country,
        String? city,
        String? zip,
        String? houseNo,
        String? apartmentNo,
        ImageFullUrl? imageFullUrl}) {
    _id = id;
    _name = name;
    _fName = fName;
    _lName = lName;
    _phone = phone;
    _image = image;
    _email = email;
    _emailVerifiedAt = emailVerifiedAt;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _streetAddress = streetAddress;
    _country = country;
    _city = city;
    _zip = zip;
    _houseNo = houseNo;
    _apartmentNo = apartmentNo;
    _imageFullUrl = imageFullUrl;
  }

  int? get id => _id;
  String? get name => _name;
  String? get fName => _fName;
  String? get lName => _lName;
  String? get phone => _phone;
  String? get image => _image;
  String? get email => _email;
  String? get emailVerifiedAt => _emailVerifiedAt;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  String? get streetAddress => _streetAddress;
  String? get country => _country;
  String? get city => _city;
  String? get zip => _zip;
  String? get houseNo => _houseNo;
  String? get apartmentNo => _apartmentNo;
  ImageFullUrl? get imageFullUrl => _imageFullUrl;

  Customer.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _fName = json['f_name'];
    _lName = json['l_name'];
    _phone = json['phone'];
    _image = json['image'];
    _email = json['email'];
    _emailVerifiedAt = json['email_verified_at'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _streetAddress = json['street_address'];
    _country = json['country'];
    _city = json['city'];
    _zip = json['zip'];
    _houseNo = json['house_no'];
    _apartmentNo = json['apartment_no'];
    _imageFullUrl = json['image_full_url'] != null
        ? ImageFullUrl.fromJson(json['image_full_url'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['name'] = _name;
    data['f_name'] = _fName;
    data['l_name'] = _lName;
    data['phone'] = _phone;
    data['image'] = _image;
    data['email'] = _email;
    data['email_verified_at'] = _emailVerifiedAt;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    data['street_address'] = _streetAddress;
    data['country'] = _country;
    data['city'] = _city;
    data['zip'] = _zip;
    data['house_no'] = _houseNo;
    data['apartment_no'] = _apartmentNo;
    return data;
  }
}



class Reply {
  int? _id;
  int? _reviewId;
  int? _addedById;
  String? _addedBy;
  String? _replyText;
  String? _createdAt;
  String? _updatedAt;

  Reply(
      {int? id,
        int? reviewId,
        int? addedById,
        String? addedBy,
        String? replyText,
        String? createdAt,
        String? updatedAt}) {
    if (id != null) {
      _id = id;
    }
    if (reviewId != null) {
      _reviewId = reviewId;
    }
    if (addedById != null) {
      _addedById = addedById;
    }
    if (addedBy != null) {
      _addedBy = addedBy;
    }
    if (replyText != null) {
      _replyText = replyText;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
  }

  int? get id => _id;
  set setId(int? id) => _id = id;
  int? get setReviewId => _reviewId;
  set setReviewId(int? reviewId) => _reviewId = reviewId;
  int? get addedById => _addedById;
  set setAddedById(int? addedById) => _addedById = addedById;
  String? get addedBy => _addedBy;
  set setAddedBy(String? addedBy) => _addedBy = addedBy;
  String? get replyText => _replyText;
  set setReplyText(String? replyText) => _replyText = replyText;
  String? get createdAt => _createdAt;
  set setCreatedAt(String? createdAt) => _createdAt = createdAt;
  String? get updatedAt => _updatedAt;
  set setUpdatedAt(String? updatedAt) => _updatedAt = updatedAt;

  Reply.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _reviewId = json['review_id'];
    _addedById = json['added_by_id'];
    _addedBy = json['added_by'];
    _replyText = json['reply_text'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['review_id'] = _reviewId;
    data['added_by_id'] = _addedById;
    data['added_by'] = _addedBy;
    data['reply_text'] = _replyText;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    return data;
  }
}