// lib/data/model/response/product_model.dart
class Product {
  final String sku;
  final String domain;
  final String name;
  final String image;
  final double price;
  final String desc;
  final String shopName;
  final String affLink;
  final String url;

  Product({
    required this.sku,
    required this.domain,
    required this.name,
    required this.image,
    required this.price,
    required this.desc,
    required this.shopName,
    required this.affLink,
    required this.url,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      sku: json["sku"] ?? "",
      domain: json["domain"] ?? "",
      name: json["name"] ?? "",
      image: json["image"] ?? "",
      price: (json["price"] ?? 0).toDouble(),
      desc: json["desc"] ?? "",
      shopName: json["shop_name"] ?? "",
      affLink: json["aff_link"] ?? "",
      url: json["url"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "sku": sku,
      "domain": domain,
      "name": name,
      "image": image,
      "price": price,
      "desc": desc,
      "shop_name": shopName,
      "aff_link": affLink,
      "url": url,
    };
  }
}
