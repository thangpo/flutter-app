import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/data/services/data_sync_service.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';

class CartRepository extends DataSyncService implements CartRepositoryInterface {
  final DioClient dioClient;
  CartRepository({required this.dioClient, required super.dataSyncRepoInterface});

  @override
  Future<ApiResponseModel<T>> getCartData<T>({required DataSourceEnum source}) async {
    final guestToken = Provider.of<AuthController>(Get.context!, listen: false).getGuestToken();
    return await fetchData<T>('${AppConstants.getCartDataUri}?guest_id=$guestToken', source);
  }

  @override
  Future<ApiResponseModel> getList({int? offset}) async {
    try {
      final response = await dioClient.get('${AppConstants.getCartDataUri}?guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> addToCartListData(CartModelBody cart, List<ChoiceOptions> choiceOptions, List<int>? variationIndexes,
      int? buyNow, int? shippingMethodExist, int? shippingMethodId) async {
    Map<String?, dynamic> choice = {};
    for(int index=0; index<choiceOptions.length; index++){
      choice.addAll({choiceOptions[index].name: choiceOptions[index].options![variationIndexes![index]]});
    }
    Map<String?, dynamic> data = {
      'id': cart.productId,
      'guest_id' : Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
      'variant': cart.variation?.type,
      'quantity': cart.quantity,
      'buy_now': buyNow,
      'shipping_method_exist': shippingMethodExist,
      'shipping_method_id': shippingMethodId,
    };
    data.addAll(choice);
    if(cart.variant!.isNotEmpty) {
      data.addAll({'color': cart.color});
    }
    if(cart.variantKey != null){
      data.addAll({
        'variant_key': cart.variantKey,
        'digital_variation_price': cart.digitalVariantPrice
      });
    }

    try {
      final response = await dioClient.post(AppConstants.addToCartUri, data: data);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }



  @override
  Future<ApiResponseModel> restockRequest(CartModelBody cart, List<ChoiceOptions> choiceOptions, List<int>? variationIndexes,
      int? buyNow, int? shippingMethodExist, int? shippingMethodId) async {
    Map<String?, dynamic> choice = {};
    for(int index=0; index<choiceOptions.length; index++){
      choice.addAll({choiceOptions[index].name: choiceOptions[index].options![variationIndexes![index]]});
    }
    Map<String?, dynamic> data = {
      'id': cart.productId,
      'guest_id' : Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
      'variant': cart.variation?.type,
      'quantity': cart.quantity,
      'buy_now': buyNow,
      'shipping_method_exist': shippingMethodExist,
      'shipping_method_id': shippingMethodId,
    };
    data.addAll(choice);
    if(cart.variant!.isNotEmpty) {
      data.addAll({'color': cart.color});
    }
    if(cart.variantKey != null){
      data.addAll({
        'variant_key': cart.variantKey,
        'digital_variation_price': cart.digitalVariantPrice
      });
    }

    try {
      final response = await dioClient.post(AppConstants.productRestockRequest, data: data);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }




  @override
  Future<ApiResponseModel> updateQuantity(int? key,int quantity) async {
    try {
      final response = await dioClient.post(AppConstants.updateCartQuantityUri,
        data: {'_method': 'put',
          'key': key,
          'quantity': quantity,
          'guest_id' : Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
        });
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> delete(int? key) async {
    try {
      final response = await dioClient.post(AppConstants.removeFromCartUri,
          data: {'_method': 'delete',
            'guest_id' : Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
            'key': key});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> mergeGuestCart() async {
    try {
      final response = await dioClient.post(AppConstants.mergeGuestCart,
        data: {
          'cart_guest_id' : Provider.of<AuthController>(Get.context!, listen: false).getGuestCartId(),
        }
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> addRemoveCartSelectedItem(Map<String,dynamic> data) async {
    try {
      final response = await dioClient.post(AppConstants.selectCartItemsUri, data: data);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }


  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }
}
