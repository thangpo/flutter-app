import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ApiService {
  final String apiUrl = "https://api.accesstrade.vn/v1/datafeeds?domain=shopee.vn";
  final String apiToken = "1BGRHzGp3M28xaur7UPWVY4-xRIMQ1zy";

  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        "Authorization": "Token $apiToken",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final products = (data["data"] as List).toList();

      products.shuffle(Random());

      final randomProducts = products.take(40).toList();

      return randomProducts;
    } else {
      throw Exception("Lỗi khi load sản phẩm: ${response.statusCode}");
    }
  }
}
