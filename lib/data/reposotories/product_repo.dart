import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/data/model/product_model.dart';

class ProductRepo {
  final String apiToken = "1BGRHzGp3M28xaur7UPWVY4-xRIMQ1zy";

  /// Lấy chi tiết sản phẩm theo domain + sku
  Future<Product> getProductBySku({
    required String domain,
    required String sku,
  }) async {
    final url = "https://api.accesstrade.vn/v1/datafeeds?domain=$domain&sku=$sku";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Token $apiToken"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = data["data"] as List<dynamic>;
      if (list.isNotEmpty) {
        return Product.fromJson(list[0]);
      }
      throw Exception("Không tìm thấy sản phẩm");
    } else {
      throw Exception("Lỗi API: ${response.statusCode}");
    }
  }

  /// Lấy danh sách sản phẩm theo shopName (cùng domain)
  Future<List<Product>> getProductsByShop({
    required String domain,
    required String shopName,
  }) async {
    final url = "https://api.accesstrade.vn/v1/datafeeds?domain=$domain&shop_name=$shopName";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Token $apiToken"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = data["data"] as List<dynamic>;
      return list.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Lỗi API: ${response.statusCode}");
    }
  }
}
