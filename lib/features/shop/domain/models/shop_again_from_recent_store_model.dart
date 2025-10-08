import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';

class ShopAgainFromRecentStoreModel {
  int? id;
  String? name;
  String? slug;
  String? thumbnail;
  ImageFullUrl? thumbnailFullUrl;
  double? unitPrice;
  int? userId;
  int? reviewsCount;
  Seller? seller;
  bool? isAddedByAdmin;


  ShopAgainFromRecentStoreModel(
      {this.id,
        this.name,
        this.slug,
        this.thumbnail,
        this.thumbnailFullUrl,
        this.unitPrice,
        this.userId,
        this.reviewsCount,
        this.seller,
        this.isAddedByAdmin,
       });

  ShopAgainFromRecentStoreModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    thumbnail = json['thumbnail'];
    unitPrice = json['unit_price'].toDouble();
    userId = json['user_id'];
    reviewsCount = int.parse(json['reviews_count'].toString());
    seller = json['seller'] != null ? Seller.fromJson(json['seller']) : null;
    thumbnailFullUrl = json['thumbnail_full_url'] != null
      ? ImageFullUrl.fromJson(json['thumbnail_full_url'])
      : null;
    isAddedByAdmin = json['added_by'] == 'admin';
  }
}

