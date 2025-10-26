import 'dart:io';

abstract class ProductDetailsServiceInterface {
  Future<dynamic> get(String productID);
  Future<dynamic> getCount(String productID);
  Future<dynamic> getSharableLink(String productID);
  Future<dynamic> getById(String productID);
  Future<HttpClientResponse> previewDownload(String url);
}
