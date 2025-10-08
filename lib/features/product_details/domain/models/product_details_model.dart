import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';

class ProductDetailsModel {
  int? _id;
  String? _addedBy;
  int? _userId;
  String? _name;
  String? _slug;
  String? _productType;
  List<CategoryIds>? _categoryIds;
  int? _brandId;
  String? _unit;
  int? _minQty;
  int? _refundable;
  String? _digitalProductType;
  String? _digitalFileReady;
  List<String>? _images;
  List<ImageFullUrl>? _imagesFullUrl;
  List<ColorImage>? _colorImage;
  List<ColorImagesFullUrl>? _colorImagesFullUrl;
  String? _thumbnail;
  ImageFullUrl? _thumbnailFullUrl;
  int? _featured;
  String? _videoProvider;
  String? _videoUrl;
  List<ColorModel>? _colors;
  int? _variantProduct;
  List<int>? _attributes;
  List<ChoiceOptions>? _choiceOptions;
  List<Variation>? _variation;
  int? _published;
  double? _unitPrice;
  double? _purchasePrice;
  double? _tax;
  String? _taxModel;
  String? _taxType;
  double? _discount;
  String? _discountType;
  int? _currentStock;
  int? _minimumOrderQty;
  String? _details;
  int? _freeShipping;
  String? _createdAt;
  String? _updatedAt;
  int? _status;
  int? _featuredStatus;
  String? _metaTitle;
  String? _metaDescription;
  String? _metaImage;
  int? _requestStatus;
  String? _deniedNote;
  double? _shippingCost;
  int? _multiplyQty;
  String? _code;
  int? _reviewsCount;
  String? _averageReview;
  List<Reviews>? _reviews;
  Seller? _seller;
  int? wishList;
  List<String>? _digitalProductFileTypes;
  Map<String, dynamic>? _digitalProductExtensions;
  List<DigitalVariation>? _digitalVariation;
  bool? _productImagesNull;
  ImageFullUrl? _previewFileFullUrl;
  List<String?>? _authors;
  List<String?>? _publishingHouse;

  List<String?>? restockRequestedList;
  int? isRestockRequested;
  ClearanceSale? clearanceSale;

  ProductDetailsModel(
      {int? id,
        String? addedBy,
        int? userId,
        String? name,
        String? slug,
        String? productType,
        List<CategoryIds>? categoryIds,
        int? brandId,
        String? unit,
        int? minQty,
        int? refundable,
        String? digitalProductType,
        String? digitalFileReady,
        List<String>? images,
        List<ImageFullUrl>? imagesFullUrl,
        List<ColorImage>? colorImage,
        List<ColorImagesFullUrl>? colorImagesFullUrl,
        String? thumbnail,
        ImageFullUrl? thumbnailFullUrl,
        int? featured,
        String? videoProvider,
        String? videoUrl,
        List<ColorModel>? colors,
        int? variantProduct,
        List<int>? attributes,
        List<ChoiceOptions>? choiceOptions,
        List<Variation>? variation,
        int? published,
        double? unitPrice,
        double? purchasePrice,
        double? tax,
        String? taxModel,
        String? taxType,
        double? discount,
        String? discountType,
        int? currentStock,
        int? minimumOrderQty,
        String? details,
        int? freeShipping,
        String? createdAt,
        String? updatedAt,
        int? status,
        int? featuredStatus,
        String? metaTitle,
        String? metaDescription,
        String? metaImage,
        int? requestStatus,
        String? deniedNote,
        double? shippingCost,
        int? multiplyQty,
        String? code,
        int? reviewsCount,
        String? averageReview,
        List<Reviews>? reviews,
        Seller? seller,
        int? wishList,
        List<String>? digitalProductFileTypes,
        Map<String, dynamic>? digitalProductExtensions,
        List<DigitalVariation>? digitalVariation,
        bool? productImagesNull,
        ImageFullUrl? previewFileFullUrl,
        List<String?>? authors,
        List<String?>? publishingHouse,

        this.restockRequestedList,
        this.isRestockRequested,
        this.clearanceSale
      }) {
    if (id != null) {
      _id = id;
    }
    if (addedBy != null) {
      _addedBy = addedBy;
    }
    if (userId != null) {
      _userId = userId;
    }
    if (name != null) {
      _name = name;
    }
    if (slug != null) {
      _slug = slug;
    }
    if (productType != null) {
      _productType = productType;
    }
    if (categoryIds != null) {
      _categoryIds = categoryIds;
    }
    if (brandId != null) {
      _brandId = brandId;
    }
    if (unit != null) {
      _unit = unit;
    }
    if (minQty != null) {
      _minQty = minQty;
    }
    if (refundable != null) {
      _refundable = refundable;
    }
    if (digitalProductType != null) {
      _digitalProductType = digitalProductType;
    }
    if (digitalFileReady != null) {
      _digitalFileReady = digitalFileReady;
    }
    if (images != null) {
      _images = images;
    }
    _imagesFullUrl = imagesFullUrl;
    if (colorImage != null) {
      _colorImage = colorImage;
    }

    if (colorImagesFullUrl != null) {
      _colorImagesFullUrl = colorImagesFullUrl;
    }
    if (thumbnail != null) {
      _thumbnail = thumbnail;
    }
    _thumbnailFullUrl = thumbnailFullUrl;
    if (featured != null) {
      _featured = featured;
    }

    if (videoProvider != null) {
      _videoProvider = videoProvider;
    }
    if (videoUrl != null) {
      _videoUrl = videoUrl;
    }
    if (colors != null) {
      _colors = colors;
    }
    if (variantProduct != null) {
      _variantProduct = variantProduct;
    }
    if (attributes != null) {
      _attributes = attributes;
    }
    if (choiceOptions != null) {
      _choiceOptions = choiceOptions;
    }
    if (variation != null) {
      _variation = variation;
    }
    if (published != null) {
      _published = published;
    }
    if (unitPrice != null) {
      _unitPrice = unitPrice;
    }
    if (purchasePrice != null) {
      _purchasePrice = purchasePrice;
    }
    if (tax != null) {
      _tax = tax;
    }
    if (taxModel != null) {
      _taxModel = taxModel;
    }
    if (taxType != null) {
      _taxType = taxType;
    }
    if (discount != null) {
      _discount = discount;
    }
    if (discountType != null) {
      _discountType = discountType;
    }
    if (currentStock != null) {
      _currentStock = currentStock;
    }
    if (minimumOrderQty != null) {
      _minimumOrderQty = minimumOrderQty;
    }
    if (details != null) {
      _details = details;
    }
    if (freeShipping != null) {
      _freeShipping = freeShipping;
    }

    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
    if (status != null) {
      _status = status;
    }
    if (featuredStatus != null) {
      _featuredStatus = featuredStatus;
    }
    if (metaTitle != null) {
      _metaTitle = metaTitle;
    }
    if (metaDescription != null) {
      _metaDescription = metaDescription;
    }
    if (metaImage != null) {
      _metaImage = metaImage;
    }
    if (requestStatus != null) {
      _requestStatus = requestStatus;
    }
    if (deniedNote != null) {
      _deniedNote = deniedNote;
    }
    if (shippingCost != null) {
      _shippingCost = shippingCost;
    }
    if (multiplyQty != null) {
      _multiplyQty = multiplyQty;
    }
    if (code != null) {
      _code = code;
    }
    if (reviewsCount != null) {
      _reviewsCount = reviewsCount;
    }
    if (averageReview != null) {
      _averageReview = averageReview;
    }
    if (reviews != null) {
      _reviews = reviews;
    }
    if (seller != null) {
      _seller = seller;
    }
    if (digitalProductFileTypes != null) {
      _digitalProductFileTypes = digitalProductFileTypes;
    }

    if (digitalProductExtensions != null) {
      _digitalProductExtensions = digitalProductExtensions;
    }

    if (digitalVariation != null) {
      _digitalVariation = digitalVariation;
    }

    if (productImagesNull != null) {
      _productImagesNull = productImagesNull;
    }

    if(previewFileFullUrl != null){
      _previewFileFullUrl = previewFileFullUrl;
    }

    if(authors != null){
      _authors = authors;
    }

    if(publishingHouse != null){
      _publishingHouse = publishingHouse;
    }

    this.wishList;
    clearanceSale;
  }

  int? get id => _id;
  String? get addedBy => _addedBy;
  int? get userId => _userId;
  String? get name => _name;
  String? get slug => _slug;
  String? get productType => _productType;
  List<CategoryIds>? get categoryIds => _categoryIds;
  int? get brandId => _brandId;
  String? get unit => _unit;
  int? get minQty => _minQty;
  int? get refundable => _refundable;
  String? get digitalProductType => _digitalProductType;
  String? get digitalFileReady => _digitalFileReady;
  List<String>? get images => _images;
  List<ImageFullUrl>? get imagesFullUrl => _imagesFullUrl;
  List<ColorImage>? get colorImage => _colorImage;
  List<ColorImagesFullUrl>? get colorImagesFullUrl => _colorImagesFullUrl;
  String? get thumbnail => _thumbnail;
  ImageFullUrl? get thumbnailFullUrl => _thumbnailFullUrl;
  int? get featured => _featured;
  String? get videoProvider => _videoProvider;
  String? get videoUrl => _videoUrl;
  List<ColorModel>? get colors => _colors;
  int? get variantProduct => _variantProduct;
  List<int>? get attributes => _attributes;
  List<ChoiceOptions>? get choiceOptions => _choiceOptions;
  List<Variation>? get variation => _variation;
  int? get published => _published;
  double? get unitPrice => _unitPrice;
  double? get purchasePrice => _purchasePrice;
  double? get tax => _tax;
  String? get taxModel => _taxModel;
  String? get taxType => _taxType;
  double? get discount => _discount;
  String? get discountType => _discountType;
  int? get currentStock => _currentStock;
  int? get minimumOrderQty => _minimumOrderQty;
  String? get details => _details;
  int? get freeShipping => _freeShipping;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  int? get status => _status;
  int? get featuredStatus => _featuredStatus;
  String? get metaTitle => _metaTitle;
  String? get metaDescription => _metaDescription;
  String? get metaImage => _metaImage;
  int? get requestStatus => _requestStatus;
  String? get deniedNote => _deniedNote;
  double? get shippingCost => _shippingCost;
  int? get multiplyQty => _multiplyQty;
  String? get code => _code;
  int? get reviewsCount => _reviewsCount;
  String? get averageReview => _averageReview;
  List<Reviews>? get reviews => _reviews;
  Seller? get seller => _seller;
  List<String>? get digitalProductFileTypes => _digitalProductFileTypes;
  Map<String, dynamic>? get digitalProductExtensions => _digitalProductExtensions;
  List<DigitalVariation>? get digitalVariation => _digitalVariation;
  bool? get productImagesNull => _productImagesNull;
  ImageFullUrl? get previewFileFullUrl => _previewFileFullUrl;
  List<String?>? get authors => _authors;
  List<String?>? get publishingHouse => _publishingHouse;

  ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _addedBy = json['added_by'];
    _userId = json['user_id'];
    _name = json['name'];
    _slug = json['slug'];
    _productType = json['product_type'];
    if (json['category_ids'] != null) {
      _categoryIds = <CategoryIds>[];
      json['category_ids'].forEach((v) {
        _categoryIds!.add(CategoryIds.fromJson(v));
      });
    }
    _brandId = json['brand_id'];
    _unit = json['unit'];
    _minQty = json['min_qty'];
    _refundable = json['refundable'];
    _digitalProductType = json['digital_product_type'];
    _digitalFileReady = json['digital_file_ready'];
    // _images = json['images'].cast<String>();
    if (json['images_full_url'] != null) {
      _imagesFullUrl = <ImageFullUrl>[];
      _productImagesNull = true;
      json['images_full_url'].forEach((v) {
        ImageFullUrl img = ImageFullUrl.fromJson(v);
        if(img.path !='' && _productImagesNull == true ){
          _productImagesNull = false;
        }
        _imagesFullUrl!.add(img);
      });
    }
    _thumbnailFullUrl = json['thumbnail_full_url'] != null
        ? ImageFullUrl.fromJson(json['thumbnail_full_url'])
        : null;
    // if (json['color_image'] != null) {
    //   _colorImage = <ColorImage>[];
    //   json['color_image'].forEach((v) {
    //     _colorImage!.add(ColorImage.fromJson(v));
    //   });
    // }
    _thumbnail = json['thumbnail'];
    _featured = json['featured'];
    _videoProvider = json['video_provider'];
    _videoUrl = json['video_url'];
    if (json['colors_formatted'] != null) {
      _colors = <ColorModel>[];
      json['colors_formatted'].forEach((v) {
        _colors!.add(ColorModel.fromJson(v));
      });
    }
    _variantProduct = int.parse(json['variant_product'].toString());
    _attributes = json['attributes'].cast<int>();
    if (json['choice_options'] != null) {
      _choiceOptions = <ChoiceOptions>[];
      json['choice_options'].forEach((v) {
        _choiceOptions!.add(ChoiceOptions.fromJson(v));
      });
    }
    if (json['variation'] != null) {
      _variation = <Variation>[];
      json['variation'].forEach((v) {
        _variation!.add(Variation.fromJson(v));
      });
    }

    if(json['digital_product_file_types'] != null) {
      _digitalProductFileTypes = json['digital_product_file_types'].cast<String>();
    }else {
      _digitalProductFileTypes = [];
    }

    if(json['digital_product_extensions'] != null && json['digital_product_extensions'] is !List) {
      _digitalProductExtensions = (json['digital_product_extensions'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
      );
    }
    if (json['digital_variation'] != null) {
      _digitalVariation = <DigitalVariation>[];
      json['digital_variation'].forEach((v) {
        _digitalVariation!.add(DigitalVariation.fromJson(v));
      });
    } else {
      _digitalVariation = [];
    }

    _published = json['published'];
    _unitPrice = json['unit_price'].toDouble();
    _purchasePrice = json['purchase_price'].toDouble();
    _tax = json['tax'].toDouble();
    _taxModel = json['tax_model'];
    _taxType = json['tax_type'];
    _discount = json['discount'].toDouble();
    _discountType = json['discount_type'];
    _currentStock = json['current_stock'];
    if(json['minimum_order_qty'] != null){
      _minimumOrderQty = int.parse(json['minimum_order_qty'].toString());
    }else{
      _minimumOrderQty = 1;
    }

    _details = json['details'];
    _freeShipping = json['free_shipping'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _status = json['status'];
    _featuredStatus = json['featured_status'];
    _metaTitle = json['meta_title'];
    _metaDescription = json['meta_description'];
    _metaImage = json['meta_image'];
    _requestStatus = int.parse(json['request_status'].toString());
    _deniedNote = json['denied_note'];
    _shippingCost = json['shipping_cost'].toDouble();
    _multiplyQty = json['multiply_qty'];
    _code = json['code'];
    if(json['reviews_count'] != null){
      _reviewsCount = int.parse(json['reviews_count'].toString());
    }else{
      _reviewsCount = 0;
    }

    _averageReview = json['average_review'].toString();
    if (json['reviews'] != null) {
      _reviews = <Reviews>[];
      json['reviews'].forEach((v) {
        _reviews!.add(Reviews.fromJson(v));
      });
    }
    _seller = json['seller'] != null ? Seller.fromJson(json['seller']) : null;
    if(json['wish_list_count'] != null){
      try{
        wishList = json['wish_list_count'];
      }catch(e){
        wishList = int.parse(json['wish_list_count'].toString());
      }
    }

    if (json['color_images_full_url'] != null) {
      _colorImagesFullUrl = <ColorImagesFullUrl>[];
      json['color_images_full_url'].forEach((v) {
        if(v['color'] != null) {
          _colorImagesFullUrl!.add(ColorImagesFullUrl.fromJson(v));
        }
      });
    }

    _previewFileFullUrl  = json['preview_file_full_url'] != null
        ? ImageFullUrl.fromJson(json['preview_file_full_url'])
        : null;


    if(json['digital_product_authors_names'] != null && json['digital_product_authors_names'] is !String && json['digital_product_authors_names'] is List){
      _authors = json['digital_product_authors_names'] != null ? json['digital_product_authors_names'].cast<String>() : [];
    }

    if(json['digital_product_publishing_house_names'] != null && json['digital_product_publishing_house_names'] is !String && json['digital_product_publishing_house_names'] is List){
      _publishingHouse = json['digital_product_publishing_house_names'] != null ? json['digital_product_publishing_house_names'].cast<String>() : [];
    }


    if(json['restock_requested_list'] != null) {
      restockRequestedList = (json['restock_requested_list'] as List<dynamic>?)
        ?.where((element) => element != null).map((element) => element as String).toList();
    }else {
      restockRequestedList = [];
    }

    isRestockRequested = json['is_restock_requested'];

    clearanceSale = json['clearance_sale'] != null
      ? ClearanceSale.fromJson(json['clearance_sale'])
      : null;

  }
}

class CategoryIds {
  String? _id;
  int? _position;

  CategoryIds({String? id, int? position}) {
    if (id != null) {
      _id = id;
    }
    if (position != null) {
      _position = position;
    }
  }

  String? get id => _id;
  int? get position => _position;


  CategoryIds.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _position = json['position'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['position'] = _position;
    return data;
  }
}

class ColorModel {
  String? _name;
  String? _code;

  String? get name => _name;
  String? get code => _code;


  ColorModel.fromJson(Map<String, dynamic> json) {
    _name = json['name'];
    _code = json['code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = _name;
    data['code'] = _code;
    return data;
  }
}



class Reviews {
  int? _id;
  int? _productId;
  int? _customerId;
  String? _comment;
  String? _attachment;
  int? _rating;
  int? _status;
  String? _createdAt;
  String? _updatedAt;
  Customer? _customer;
  List<ImageFullUrl>? _attachmentFullUrl;


  Reviews(
      {int? id,
        int? productId,
        int? customerId,
        String? comment,
        String? attachment,
        int? rating,
        int? status,
        String? createdAt,
        String? updatedAt,
        Customer? customer,
        List<ImageFullUrl>? attachmentFullUrl}) {
    if (id != null) {
      _id = id;
    }
    if (productId != null) {
      _productId = productId;
    }
    if (customerId != null) {
      _customerId = customerId;
    }
    if (comment != null) {
      _comment = comment;
    }
    if (attachment != null) {
      _attachment = attachment;
    }
    if (rating != null) {
      _rating = rating;
    }
    if (status != null) {
      _status = status;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
    if (customer != null) {
      _customer = customer;
    }
    if(attachmentFullUrl != null) {
      _attachmentFullUrl = attachmentFullUrl;
    }
  }

  int? get id => _id;
  int? get productId => _productId;
  int? get customerId => _customerId;
  String? get comment => _comment;
  String? get attachment => _attachment;
  int? get rating => _rating;
  int? get status => _status;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  Customer? get customer => _customer;
  List<ImageFullUrl>? get attachmentFullUrl => _attachmentFullUrl;


  Reviews.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _productId = int.parse(json['product_id'].toString());
    _customerId = int.parse(json['customer_id'].toString());
    _comment = json['comment'];

    if(json['attachment'] != null && json['attachment'] is !List){
      //_attachment = json['attachment'];
    }
    _rating = json['rating'];
    _status = json['status'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _customer = json['customer'] != null
      ? Customer.fromJson(json['customer'])
      : null;
    if (json['attachment_images_full_url'] != null) {
      _attachmentFullUrl = <ImageFullUrl>[];
      json['attachment_images_full_url'].forEach((v) {
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
    data['attachment'] = _attachment;
    data['rating'] = _rating;
    data['status'] = _status;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    if (_customer != null) {
      data['customer'] = _customer!.toJson();
    }
    return data;
  }
}

class Customer {
  int? _id;
  String? _fName;
  String? _lName;
  String? _phone;
  String? _image;
  String? _email;

  Customer(
      {int? id,
        String? fName,
        String? lName,
        String? phone,
        String? image,
        String? email,
      }) {
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
    if (email != null) {
      _email = email;
    }

  }

  int? get id => _id;
  String? get fName => _fName;
  String? get lName => _lName;
  String? get phone => _phone;
  String? get image => _image;
  String? get email => _email;


  Customer.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _fName = json['f_name'];
    _lName = json['l_name'];
    _phone = json['phone'];
    _image = json['image'];
    _email = json['email'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['f_name'] = _fName;
    data['l_name'] = _lName;
    data['phone'] = _phone;
    data['image'] = _image;
    data['email'] = _email;

    return data;
  }
}


class ColorImage {
  String? color;
  String? imageName;

  ColorImage({String? color, String? imageName}) {
    if (color != null) {
      color = color;
    }
    if (imageName != null) {
      imageName = imageName;
    }
  }

  ColorImage.fromJson(Map<String, dynamic> json) {
    color = json['color'];
    imageName = json['image_name'];
  }

}


class ColorImagesFullUrl {
  String? color;
  ImageFullUrl? imageName;

  ColorImagesFullUrl({this.color, this.imageName});

  ColorImagesFullUrl.fromJson(Map<String, dynamic> json) {
    color = json['color'];
    imageName = json['image_name'] != null
        ? ImageFullUrl.fromJson(json['image_name'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['color'] = color;
    if (imageName != null) {
      data['image_name'] = imageName!.toJson();
    }
    return data;
  }
}


class DigitalVariation {
  int? id;
  int? productId;
  String? variantKey;
  String? sku;
  int? price;
  String? file;
  String? createdAt;
  String? updatedAt;

  DigitalVariation(
      {this.id,
        this.productId,
        this.variantKey,
        this.sku,
        this.price,
        this.file,
        this.createdAt,
        this.updatedAt
      });

  DigitalVariation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    variantKey = json['variant_key'];
    sku = json['sku'];
    price = json['price'];
    file = json['file'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['variant_key'] = variantKey;
    data['sku'] = sku;
    data['price'] = price;
    data['file'] = file;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}