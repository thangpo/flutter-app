import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';


class RestockProductModel {
  List<Data>? data;
  int? totalSize;
  String? limit;
  String? offset;

  RestockProductModel({this.data, this.totalSize, this.limit, this.offset});

  RestockProductModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    return data;
  }


}

class Data {
  int? id;
  int? productId;
  String? variant;
  String? createdAt;
  String? updatedAt;
  String? fcmTopic;
  int? restockProductCustomersCount;
  Product? product;

  Data(
      {this.id,
        this.productId,
        this.variant,
        this.createdAt,
        this.updatedAt,
        this.fcmTopic,
        this.restockProductCustomersCount,
        this.product});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    variant = json['variant'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    fcmTopic = json['fcm_topic'];
    restockProductCustomersCount = json['restock_product_customers_count'];
    product =
    json['product'] != null ? Product.fromJson(json['product']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['variant'] = variant;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['fcm_topic'] = fcmTopic;
    data['restock_product_customers_count'] = restockProductCustomersCount;
    return data;
  }
}




//
//
// class RestockProductModel {
//   int? id;
//   int? productId;
//   String? variant;
//   String? createdAt;
//   String? updatedAt;
//   Product? product;
//
//   RestockProductModel(
//       {this.id,
//         this.productId,
//         this.variant,
//         this.createdAt,
//         this.updatedAt,
//         this.product});
//
//   RestockProductModel.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     productId = json['product_id'];
//     variant = json['variant'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     product =
//     json['product'] != null ? new Product.fromJson(json['product']) : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['product_id'] = this.productId;
//     data['variant'] = this.variant;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     return data;
//   }
// }
