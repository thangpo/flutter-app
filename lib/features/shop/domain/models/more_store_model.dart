import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/domain/models/product_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/enums/vacation_duration_type.dart';



class MostPopularStoreModel {
  int? id;
  int? sellerId;
  String? name;
  String? slug;
  String? address;
  String? contact;
  String? image;
  String? bottomBanner;
  String? offerBanner;
  DateTime? vacationStartDate;
  DateTime? vacationEndDate;
  VacationDurationType? vacationDurationType;
  String? vacationNote;
  bool? vacationStatus;
  bool? temporaryClose;
  String? createdAt;
  String? updatedAt;
  String? banner;
  int? productsCount;
  List<Products>? products;
  int? ordersCount;
  List<CouponList>? couponList;
  double? averageRating;
  int? reviewCount;
  int? totalRating;
  double? positiveReview;
  int? isVacationModeNow;
  ThumbnailFullUrl? imageFullUrl;
  ThumbnailFullUrl? bottomBannerFullUrl;
  OfferBannerFullUrl? offerBannerFullUrl;
  ThumbnailFullUrl? bannerFullUrl;
  List<Storage>? storage;
  Seller? seller;

  MostPopularStoreModel(
      {this.id,
        this.sellerId,
        this.name,
        this.slug,
        this.address,
        this.contact,
        this.image,
        this.bottomBanner,
        this.offerBanner,
        this.vacationStartDate,
        this.vacationEndDate,
        this.vacationNote,
        this.vacationStatus,
        this.temporaryClose,
        this.createdAt,
        this.updatedAt,
        this.banner,
        this.productsCount,
        this.products,
        this.ordersCount,
        this.couponList,
        this.averageRating,
        this.reviewCount,
        this.totalRating,
        this.positiveReview,
        this.isVacationModeNow,
        this.imageFullUrl,
        this.bottomBannerFullUrl,
        this.offerBannerFullUrl,
        this.bannerFullUrl,
        this.storage,
        this.seller,
        this.vacationDurationType,
      });

  MostPopularStoreModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sellerId = json['seller_id'];
    name = json['name'];
    slug = json['slug'];
    address = json['address'];
    contact = json['contact'];
    image = json['image'];
    bottomBanner = json['bottom_banner'];
    offerBanner = json['offer_banner'];
    vacationStartDate = DateTime.tryParse(json['vacation_start_date'].toString());
    vacationEndDate = DateTime.tryParse(json['vacation_end_date'].toString());
    vacationNote = json['vacation_note'];
    vacationStatus = '${json['vacation_status']}'.contains('1') || json['vacation_status'] == true;
    temporaryClose = json['temporary_close'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    banner = json['banner'];
    productsCount = json['products_count'];
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        //products!.add(new Products.fromJson(v));
      });
    }
    ordersCount = json['orders_count'];
    if (json['coupon_list'] != null) {
      couponList = <CouponList>[];
      json['coupon_list'].forEach((v) {
        couponList!.add(CouponList.fromJson(v));
      });
    }
    averageRating = double.tryParse(json['average_rating'].toString());
    reviewCount = json['review_count'];
    totalRating = json['total_rating'];
    positiveReview = double.tryParse(json['positive_review'].toString());
    isVacationModeNow = json['is_vacation_mode_now'];
    imageFullUrl = json['image_full_url'] != null
        ? ThumbnailFullUrl.fromJson(json['image_full_url'])
        : null;
    bottomBannerFullUrl = json['bottom_banner_full_url'] != null
        ? ThumbnailFullUrl.fromJson(json['bottom_banner_full_url'])
        : null;
    offerBannerFullUrl = json['offer_banner_full_url'] != null
        ? OfferBannerFullUrl.fromJson(json['offer_banner_full_url'])
        : null;
    bannerFullUrl = json['banner_full_url'] != null
        ? ThumbnailFullUrl.fromJson(json['banner_full_url'])
        : null;
    if (json['storage'] != null) {
      storage = <Storage>[];
      json['storage'].forEach((v) {
        storage!.add(Storage.fromJson(v));
      });
    }
    seller =
    json['seller'] != null ? Seller.fromJson(json['seller']) : null;

    if (json['vacation_duration_type'] != null) {
      vacationDurationType = VacationDurationType.fromJson(json['vacation_duration_type']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['seller_id'] = sellerId;
    data['name'] = name;
    data['slug'] = slug;
    data['address'] = address;
    data['contact'] = contact;
    data['image'] = image;
    data['bottom_banner'] = bottomBanner;
    data['offer_banner'] = offerBanner;
    data['vacation_start_date'] = vacationStartDate;
    data['vacation_end_date'] = vacationEndDate;
    data['vacation_note'] = vacationNote;
    data['vacation_status'] = vacationStatus;
    data['temporary_close'] = temporaryClose;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['banner'] = banner;
    data['products_count'] = productsCount;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    data['orders_count'] = ordersCount;
    if (couponList != null) {
      data['coupon_list'] = couponList!.map((v) => v.toJson()).toList();
    }
    data['average_rating'] = averageRating;
    data['review_count'] = reviewCount;
    data['total_rating'] = totalRating;
    data['positive_review'] = positiveReview;
    data['is_vacation_mode_now'] = isVacationModeNow;
    if (imageFullUrl != null) {
      data['image_full_url'] = imageFullUrl!.toJson();
    }
    if (bottomBannerFullUrl != null) {
      data['bottom_banner_full_url'] = bottomBannerFullUrl!.toJson();
    }
    if (offerBannerFullUrl != null) {
      data['offer_banner_full_url'] = offerBannerFullUrl!.toJson();
    }
    if (bannerFullUrl != null) {
      data['banner_full_url'] = bannerFullUrl!.toJson();
    }
    if (storage != null) {
      data['storage'] = storage!.map((v) => v.toJson()).toList();
    }
    if (seller != null) {
      data['seller'] = seller!.toJson();
    }
    return data;
  }
}

class Products {
  int? id;
  String? addedBy;
  int? userId;
  String? name;
  String? slug;
  String? productType;
  String? categoryIds;
  int? categoryId;
  int? subCategoryId;
  Null subSubCategoryId;
  int? brandId;
  String? unit;
  int? minQty;
  int? refundable;
  String? digitalProductType;
  String? digitalFileReady;
  String? images;
  String? colorImage;
  String? thumbnail;
  int? featured;
  Null flashDeal;
  String? videoProvider;
  String? videoUrl;
  String? colors;
  int? variantProduct;
  String? attributes;
  String? choiceOptions;
  String? variation;
  List<String>? digitalProductFileTypes;
  List<Null>? digitalProductExtensions;
  int? published;
  double? unitPrice;
  int? purchasePrice;
  int? tax;
  String? taxType;
  String? taxModel;
  double? discount;
  String? discountType;
  int? currentStock;
  int? minimumOrderQty;
  String? details;
  int? freeShipping;
  Null attachment;
  String? createdAt;
  String? updatedAt;
  int? status;
  int? featuredStatus;
  String? metaTitle;
  String? metaDescription;
  String? metaImage;
  int? requestStatus;
  Null deniedNote;
  int? shippingCost;
  int? multiplyQty;
  double? tempShippingCost;
  int? isShippingCostUpdated;
  String? code;
  int? isShopTemporaryClose;
  ThumbnailFullUrl? thumbnailFullUrl;
  List<ColorImagesFullUrl>? colorImagesFullUrl;
  ThumbnailFullUrl? metaImageFullUrl;
  List<ImageFullUrl>? imagesFullUrl;
  ThumbnailFullUrl? digitalFileReadyFullUrl;
  List<Null>? translations;
  List<Storage>? storage;
  SeoInfo? seoInfo;
  List<Reviews>? reviews;

  Products(
      {this.id,
        this.addedBy,
        this.userId,
        this.name,
        this.slug,
        this.productType,
        this.categoryIds,
        this.categoryId,
        this.subCategoryId,
        this.subSubCategoryId,
        this.brandId,
        this.unit,
        this.minQty,
        this.refundable,
        this.digitalProductType,
        this.digitalFileReady,
        this.images,
        this.colorImage,
        this.thumbnail,
        this.featured,
        this.flashDeal,
        this.videoProvider,
        this.videoUrl,
        this.colors,
        this.variantProduct,
        this.attributes,
        this.choiceOptions,
        this.variation,
        this.digitalProductFileTypes,
        this.digitalProductExtensions,
        this.published,
        this.unitPrice,
        this.purchasePrice,
        this.tax,
        this.taxType,
        this.taxModel,
        this.discount,
        this.discountType,
        this.currentStock,
        this.minimumOrderQty,
        this.details,
        this.freeShipping,
        this.attachment,
        this.createdAt,
        this.updatedAt,
        this.status,
        this.featuredStatus,
        this.metaTitle,
        this.metaDescription,
        this.metaImage,
        this.requestStatus,
        this.deniedNote,
        this.shippingCost,
        this.multiplyQty,
        this.tempShippingCost,
        this.isShippingCostUpdated,
        this.code,
        this.isShopTemporaryClose,
        this.thumbnailFullUrl,
        this.colorImagesFullUrl,
        this.metaImageFullUrl,
        this.imagesFullUrl,
        this.digitalFileReadyFullUrl,
        this.translations,
        this.storage,
        this.seoInfo,
        this.reviews});

  Products.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    addedBy = json['added_by'];
    userId = json['user_id'];
    name = json['name'];
    slug = json['slug'];
    productType = json['product_type'];
    categoryIds = json['category_ids'];
    categoryId = json['category_id'];
    subCategoryId = json['sub_category_id'];
    subSubCategoryId = json['sub_sub_category_id'];
    brandId = json['brand_id'];
    unit = json['unit'];
    minQty = json['min_qty'];
    refundable = json['refundable'];
    digitalProductType = json['digital_product_type'];
    digitalFileReady = json['digital_file_ready'];
    images = json['images'];
    colorImage = json['color_image'];
    thumbnail = json['thumbnail'];
    featured = json['featured'];
    flashDeal = json['flash_deal'];
    videoProvider = json['video_provider'];
    videoUrl = json['video_url'];
    colors = json['colors'];
    variantProduct = json['variant_product'];
    attributes = json['attributes'];
    choiceOptions = json['choice_options'];
    variation = json['variation'];
    digitalProductFileTypes = json['digital_product_file_types'].cast<String>();
    published = json['published'];
    unitPrice = json['unit_price'];
    purchasePrice = json['purchase_price'];
    tax = json['tax'];
    taxType = json['tax_type'];
    taxModel = json['tax_model'];
    discount = json['discount'];
    discountType = json['discount_type'];
    currentStock = json['current_stock'];
    minimumOrderQty = json['minimum_order_qty'];
    details = json['details'];
    freeShipping = json['free_shipping'];
    attachment = json['attachment'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    status = json['status'];
    featuredStatus = json['featured_status'];
    metaTitle = json['meta_title'];
    metaDescription = json['meta_description'];
    metaImage = json['meta_image'];
    requestStatus = json['request_status'];
    deniedNote = json['denied_note'];
    shippingCost = json['shipping_cost'];
    multiplyQty = json['multiply_qty'];
    tempShippingCost = json['temp_shipping_cost'];
    isShippingCostUpdated = json['is_shipping_cost_updated'];
    code = json['code'];
    isShopTemporaryClose = json['is_shop_temporary_close'];
    thumbnailFullUrl = json['thumbnail_full_url'] != null
        ? ThumbnailFullUrl.fromJson(json['thumbnail_full_url'])
        : null;
    if (json['color_images_full_url'] != null) {
      colorImagesFullUrl = <ColorImagesFullUrl>[];
      json['color_images_full_url'].forEach((v) {
        colorImagesFullUrl!.add(ColorImagesFullUrl.fromJson(v));
      });
    }
    metaImageFullUrl = json['meta_image_full_url'] != null
        ? ThumbnailFullUrl.fromJson(json['meta_image_full_url'])
        : null;
    if (json['images_full_url'] != null) {
      imagesFullUrl = <ImageFullUrl>[];
      json['images_full_url'].forEach((v) {
        imagesFullUrl!.add(ImageFullUrl.fromJson(v));
      });
    }
    digitalFileReadyFullUrl = json['digital_file_ready_full_url'] != null
        ? ThumbnailFullUrl.fromJson(json['digital_file_ready_full_url'])
        : null;
    if (json['storage'] != null) {
      storage = <Storage>[];
      json['storage'].forEach((v) {
        storage!.add(Storage.fromJson(v));
      });
    }
    seoInfo = json['seo_info'] != null
        ? SeoInfo.fromJson(json['seo_info'])
        : null;
    if (json['reviews'] != null) {
      reviews = <Reviews>[];
      json['reviews'].forEach((v) {
        reviews!.add(Reviews.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['added_by'] = addedBy;
    data['user_id'] = userId;
    data['name'] = name;
    data['slug'] = slug;
    data['product_type'] = productType;
    data['category_ids'] = categoryIds;
    data['category_id'] = categoryId;
    data['sub_category_id'] = subCategoryId;
    data['sub_sub_category_id'] = subSubCategoryId;
    data['brand_id'] = brandId;
    data['unit'] = unit;
    data['min_qty'] = minQty;
    data['refundable'] = refundable;
    data['digital_product_type'] = digitalProductType;
    data['digital_file_ready'] = digitalFileReady;
    data['images'] = images;
    data['color_image'] = colorImage;
    data['thumbnail'] = thumbnail;
    data['featured'] = featured;
    data['flash_deal'] = flashDeal;
    data['video_provider'] = videoProvider;
    data['video_url'] = videoUrl;
    data['colors'] = colors;
    data['variant_product'] = variantProduct;
    data['attributes'] = attributes;
    data['choice_options'] = choiceOptions;
    data['variation'] = variation;
    data['digital_product_file_types'] = digitalProductFileTypes;
    data['published'] = published;
    data['unit_price'] = unitPrice;
    data['purchase_price'] = purchasePrice;
    data['tax'] = tax;
    data['tax_type'] = taxType;
    data['tax_model'] = taxModel;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['current_stock'] = currentStock;
    data['minimum_order_qty'] = minimumOrderQty;
    data['details'] = details;
    data['free_shipping'] = freeShipping;
    data['attachment'] = attachment;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['status'] = status;
    data['featured_status'] = featuredStatus;
    data['meta_title'] = metaTitle;
    data['meta_description'] = metaDescription;
    data['meta_image'] = metaImage;
    data['request_status'] = requestStatus;
    data['denied_note'] = deniedNote;
    data['shipping_cost'] = shippingCost;
    data['multiply_qty'] = multiplyQty;
    data['temp_shipping_cost'] = tempShippingCost;
    data['is_shipping_cost_updated'] = isShippingCostUpdated;
    data['code'] = code;
    data['is_shop_temporary_close'] = isShopTemporaryClose;
    if (thumbnailFullUrl != null) {
      data['thumbnail_full_url'] = thumbnailFullUrl!.toJson();
    }
    if (colorImagesFullUrl != null) {
      data['color_images_full_url'] =
          colorImagesFullUrl!.map((v) => v.toJson()).toList();
    }
    if (metaImageFullUrl != null) {
      data['meta_image_full_url'] = metaImageFullUrl!.toJson();
    }
    if (imagesFullUrl != null) {
      data['images_full_url'] =
          imagesFullUrl!.map((v) => v.toJson()).toList();
    }
    if (digitalFileReadyFullUrl != null) {
      data['digital_file_ready_full_url'] =
          digitalFileReadyFullUrl!.toJson();
    }
    if (storage != null) {
      data['storage'] = storage!.map((v) => v.toJson()).toList();
    }
    if (seoInfo != null) {
      data['seo_info'] = seoInfo!.toJson();
    }
    if (reviews != null) {
      data['reviews'] = reviews!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ThumbnailFullUrl {
  String? key;
  String? path;
  int? status;

  ThumbnailFullUrl({this.key, this.path, this.status});

  ThumbnailFullUrl.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    path = json['path'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['path'] = path;
    data['status'] = status;
    return data;
  }
}



class Storage {
  int? id;
  String? dataType;
  String? dataId;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Storage(
      {this.id,
        this.dataType,
        this.dataId,
        this.key,
        this.value,
        this.createdAt,
        this.updatedAt});

  Storage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dataType = json['data_type'];
    dataId = json['data_id'];
    key = json['key'];
    value = json['value'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['data_type'] = dataType;
    data['data_id'] = dataId;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class SeoInfo {
  int? id;
  int? productId;
  String? title;
  String? description;
  String? index;
  String? noFollow;
  String? noImageIndex;
  String? noArchive;
  String? noSnippet;
  String? maxSnippet;
  String? maxSnippetValue;
  String? maxVideoPreview;
  String? maxVideoPreviewValue;
  String? maxImagePreview;
  String? maxImagePreviewValue;
  String? image;
  String? createdAt;
  String? updatedAt;
  ThumbnailFullUrl? imageFullUrl;
  List<Storage>? storage;

  SeoInfo(
      {this.id,
        this.productId,
        this.title,
        this.description,
        this.index,
        this.noFollow,
        this.noImageIndex,
        this.noArchive,
        this.noSnippet,
        this.maxSnippet,
        this.maxSnippetValue,
        this.maxVideoPreview,
        this.maxVideoPreviewValue,
        this.maxImagePreview,
        this.maxImagePreviewValue,
        this.image,
        this.createdAt,
        this.updatedAt,
        this.imageFullUrl,
        this.storage});

  SeoInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    title = json['title'];
    description = json['description'];
    index = json['index'];
    noFollow = json['no_follow'];
    noImageIndex = json['no_image_index'];
    noArchive = json['no_archive'];
    noSnippet = json['no_snippet'];
    maxSnippet = json['max_snippet'];
    maxSnippetValue = json['max_snippet_value'];
    maxVideoPreview = json['max_video_preview'];
    maxVideoPreviewValue = json['max_video_preview_value'];
    maxImagePreview = json['max_image_preview'];
    maxImagePreviewValue = json['max_image_preview_value'];
    image = json['image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    imageFullUrl = json['image_full_url'] != null
        ? ThumbnailFullUrl.fromJson(json['image_full_url'])
        : null;
    if (json['storage'] != null) {
      storage = <Storage>[];
      json['storage'].forEach((v) {
        storage!.add(Storage.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['title'] = title;
    data['description'] = description;
    data['index'] = index;
    data['no_follow'] = noFollow;
    data['no_image_index'] = noImageIndex;
    data['no_archive'] = noArchive;
    data['no_snippet'] = noSnippet;
    data['max_snippet'] = maxSnippet;
    data['max_snippet_value'] = maxSnippetValue;
    data['max_video_preview'] = maxVideoPreview;
    data['max_video_preview_value'] = maxVideoPreviewValue;
    data['max_image_preview'] = maxImagePreview;
    data['max_image_preview_value'] = maxImagePreviewValue;
    data['image'] = image;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (imageFullUrl != null) {
      data['image_full_url'] = imageFullUrl!.toJson();
    }
    if (storage != null) {
      data['storage'] = storage!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Reviews {
  int? id;
  int? productId;
  int? customerId;
  Null deliveryManId;
  int? orderId;
  String? comment;
  List<Attachment>? attachment;
  int? rating;
  int? status;
  bool? isSaved;
  String? createdAt;
  String? updatedAt;
  List<Storage>? storage;

  Reviews(
      {this.id,
        this.productId,
        this.customerId,
        this.deliveryManId,
        this.orderId,
        this.comment,
        this.attachment,
        this.rating,
        this.status,
        this.isSaved,
        this.createdAt,
        this.updatedAt,
        this.storage});

  Reviews.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    customerId = json['customer_id'];
    deliveryManId = json['delivery_man_id'];
    orderId = json['order_id'];
    comment = json['comment'];
    if (json['attachment'] != null) {
      attachment = <Attachment>[];
      json['attachment'].forEach((v) {
        attachment!.add(Attachment.fromJson(v));
      });
    }
    rating = json['rating'];
    status = json['status'];
    isSaved = json['is_saved'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['storage'] != null) {
      storage = <Storage>[];
      json['storage'].forEach((v) {
        storage!.add(Storage.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['customer_id'] = customerId;
    data['delivery_man_id'] = deliveryManId;
    data['order_id'] = orderId;
    data['comment'] = comment;
    if (attachment != null) {
      data['attachment'] = attachment!.map((v) => v.toJson()).toList();
    }
    data['rating'] = rating;
    data['status'] = status;
    data['is_saved'] = isSaved;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (storage != null) {
      data['storage'] = storage!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Attachment {
  String? fileName;
  String? storage;

  Attachment({this.fileName, this.storage});

  Attachment.fromJson(Map<String, dynamic> json) {
    fileName = json['file_name'];
    storage = json['storage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['file_name'] = fileName;
    data['storage'] = storage;
    return data;
  }
}

class CouponList {
  int? id;
  String? addedBy;
  String? couponType;
  String? couponBearer;
  int? sellerId;
  int? customerId;
  String? title;
  String? code;
  String? startDate;
  String? expireDate;
  int? minPurchase;
  int? maxDiscount;
  int? discount;
  String? discountType;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? limit;

  CouponList(
      {this.id,
        this.addedBy,
        this.couponType,
        this.couponBearer,
        this.sellerId,
        this.customerId,
        this.title,
        this.code,
        this.startDate,
        this.expireDate,
        this.minPurchase,
        this.maxDiscount,
        this.discount,
        this.discountType,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.limit});

  CouponList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    addedBy = json['added_by'];
    couponType = json['coupon_type'];
    couponBearer = json['coupon_bearer'];
    sellerId = json['seller_id'];
    customerId = json['customer_id'];
    title = json['title'];
    code = json['code'];
    startDate = json['start_date'];
    expireDate = json['expire_date'];
    minPurchase = json['min_purchase'];
    maxDiscount = json['max_discount'];
    discount = json['discount'];
    discountType = json['discount_type'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    limit = json['limit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['added_by'] = addedBy;
    data['coupon_type'] = couponType;
    data['coupon_bearer'] = couponBearer;
    data['seller_id'] = sellerId;
    data['customer_id'] = customerId;
    data['title'] = title;
    data['code'] = code;
    data['start_date'] = startDate;
    data['expire_date'] = expireDate;
    data['min_purchase'] = minPurchase;
    data['max_discount'] = maxDiscount;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['limit'] = limit;
    return data;
  }
}

class OfferBannerFullUrl {
  String? key;
  String? path;
  int? status;

  OfferBannerFullUrl({this.key, this.path, this.status});

  OfferBannerFullUrl.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    path = json['path'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['path'] = path;
    data['status'] = status;
    return data;
  }
}

class Seller {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? image;
  String? email;
  String? password;
  String? status;
  String? rememberToken;
  String? createdAt;
  String? updatedAt;
  String? bankName;
  String? branch;
  String? accountNo;
  String? authToken;
  int? salesCommissionPercentage;
  String? gst;
  String? cmFirebaseToken;
  int? posStatus;
  double? minimumOrderAmount;
  int? freeDeliveryStatus;
  int? freeDeliveryOverAmount;
  String? appLanguage;
  int? ordersCount;
  ThumbnailFullUrl? imageFullUrl;
  List<Storage>? storage;

  Seller(
      {this.id,
        this.fName,
        this.lName,
        this.phone,
        this.image,
        this.email,
        this.password,
        this.status,
        this.rememberToken,
        this.createdAt,
        this.updatedAt,
        this.bankName,
        this.branch,
        this.accountNo,
        this.authToken,
        this.salesCommissionPercentage,
        this.gst,
        this.cmFirebaseToken,
        this.posStatus,
        this.minimumOrderAmount,
        this.freeDeliveryStatus,
        this.freeDeliveryOverAmount,
        this.appLanguage,
        this.ordersCount,
        this.imageFullUrl,
        this.storage
      });

  Seller.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    image = json['image'];
    email = json['email'];
    password = json['password'];
    status = json['status'];
    rememberToken = json['remember_token'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    bankName = json['bank_name'];
    branch = json['branch'];
    accountNo = json['account_no'];
    authToken = json['auth_token'];
    if(json['sales_commission_percentage'] != null) {
      salesCommissionPercentage = json['sales_commission_percentage'];
    }
    gst = json['gst'];
    cmFirebaseToken = json['cm_firebase_token'];
    posStatus = json['pos_status'];
    minimumOrderAmount = double.tryParse(json['minimum_order_amount'].toString());
    freeDeliveryStatus = json['free_delivery_status'];
    freeDeliveryOverAmount = json['free_delivery_over_amount'];
    appLanguage = json['app_language'];
    ordersCount = json['orders_count'];
    imageFullUrl = json['image_full_url'] != null
        ? ThumbnailFullUrl.fromJson(json['image_full_url'])
        : null;
    if (json['storage'] != null) {
      storage = <Storage>[];
      json['storage'].forEach((v) {
        storage!.add(Storage.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['image'] = image;
    data['email'] = email;
    data['password'] = password;
    data['status'] = status;
    data['remember_token'] = rememberToken;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['bank_name'] = bankName;
    data['branch'] = branch;
    data['account_no'] = accountNo;
    data['auth_token'] = authToken;
    data['sales_commission_percentage'] = salesCommissionPercentage;
    data['gst'] = gst;
    data['cm_firebase_token'] = cmFirebaseToken;
    data['pos_status'] = posStatus;
    data['minimum_order_amount'] = minimumOrderAmount;
    data['free_delivery_status'] = freeDeliveryStatus;
    data['free_delivery_over_amount'] = freeDeliveryOverAmount;
    data['app_language'] = appLanguage;
    data['orders_count'] = ordersCount;
    if (imageFullUrl != null) {
      data['image_full_url'] = imageFullUrl!.toJson();
    }
    if (storage != null) {
      data['storage'] = storage!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

