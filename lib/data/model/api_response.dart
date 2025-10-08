
class ApiResponseModel<T> {
  final T? response;
  final dynamic error;
  final bool isSuccess;

  ApiResponseModel(this.response, this.error, this.isSuccess);

  ApiResponseModel.withError(dynamic errorValue, {T? responseValue}) : response = responseValue, error = errorValue, isSuccess = false;

  ApiResponseModel.withSuccess(T? responseValue)
      : response = responseValue,
        error = null, isSuccess = true;
}
