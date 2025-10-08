import 'package:flutter_sixvalley_ecommerce/data/model/image_full_url.dart';


class Brand {
  int? totalSize;
  int? limit;
  int? offset;
  List<BrandModel>? brands;

  Brand({this.totalSize, this.limit, this.offset, this.brands});

  Brand.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    if (json['brands'] != null) {
      brands = <BrandModel>[];
      json['brands'].forEach((v) {
        brands!.add(BrandModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    return data;
  }
}



class BrandModel {
  int? _id;
  String? _name;
  String? _image;
  int? _status;
  String? _createdAt;
  String? _updatedAt;
  int? _brandProductsCount;
  bool? checked;
  ImageFullUrl? _imageFullUrl;


  BrandModel(
      {int? id,
        String? name,
        String? image,
        int? status,
        String? createdAt,
        String? updatedAt,
        int? brandProductsCount,
        bool? checked,
        ImageFullUrl? imageFullUrl,
      }) {
    _id = id;
    _name = name;
    _image = image;
    _status = status;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _brandProductsCount = brandProductsCount;
    _imageFullUrl = imageFullUrl;
    checked = checked;

  }

  int? get id => _id;
  String? get name => _name;
  String? get image => _image;
  int? get status => _status;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  int? get brandProductsCount => _brandProductsCount;
  ImageFullUrl? get imageFullUrl => _imageFullUrl;


  BrandModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _image = json['image'];
    _status = json['status'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _brandProductsCount = json['brand_products_count'];
    _imageFullUrl = json['image_full_url'] != null
        ? ImageFullUrl.fromJson(json['image_full_url'])
        : null;
    checked = false;

  }

}
