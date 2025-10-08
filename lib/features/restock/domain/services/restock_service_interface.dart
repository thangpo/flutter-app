abstract class RestockServiceInterface{

  Future<dynamic> reorder(String orderId);

  Future<dynamic> getRestockProductList(String offset, bool getAll);

  Future<dynamic> deleteRestockProduct(String? type, String? id);

}