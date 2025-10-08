import 'package:flutter_sixvalley_ecommerce/features/restock/domain/repositories/restock_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/domain/services/restock_service_interface.dart';

class RestockService implements RestockServiceInterface{
  RestockRepositoryInterface restockRepositoryInterface;
  RestockService({required this.restockRepositoryInterface});

  @override
  Future reorder(String orderId) async{
    return await restockRepositoryInterface.reorder(orderId);
  }

  @override
  Future getRestockProductList(String offset, bool getAll) async{
    return await restockRepositoryInterface.getRestockProductList(offset, getAll);
  }

  @override
  Future deleteRestockProduct(String? type, String? id) async{
    return await restockRepositoryInterface.deleteRestockProduct(type, id);
  }
}