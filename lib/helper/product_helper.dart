import 'package:flutter_sixvalley_ecommerce/features/product_details/domain/models/product_details_model.dart';

class ProductHelper{

  static ({double? end, double? start}) getProductPriceRange(ProductDetailsModel? productDetailsModel){
    double? startingPrice = 0;
    double? endingPrice;
    if(productDetailsModel?.variation?.isNotEmpty ?? false) {
      List<double?> priceList = [];
      for (var variation in productDetailsModel!.variation!) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
      if(priceList[0]! < priceList[priceList.length-1]!) {
        endingPrice = priceList[priceList.length-1];
      }
    }else {
      startingPrice = productDetailsModel?.unitPrice;
    }

    return (start: startingPrice, end: endingPrice);
  }

  static String removeIframe(String htmlString) {
    final regex =  RegExp(
      r'(</span></p>)?(</p>)?<iframe[^>]*src="https:\/\/www\.youtube\.com\/embed\/[^"]*"[^>]*><\/iframe><p[^>]*>(<strong[^>]*>\s*<\/strong>)?<span[^>]*>',
      caseSensitive: false,
      dotAll: true,
    );

    return htmlString.replaceAll(regex, '')
        .replaceAll('&nbsp;', '');
  }
}