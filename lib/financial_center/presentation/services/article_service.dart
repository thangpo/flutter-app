import 'dart:convert';
import 'package:http/http.dart' as http;

class ArticleService {
  static const String baseUrl = 'https://vietnamtoure.com/api/news';

  static Future<List<dynamic>> fetchArticles() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == true && body['data'] != null) {
        return body['data'];
      }
    }
    return [];
  }
}
