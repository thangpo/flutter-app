import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/local_caches_type_enum.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/reposotories/data_sync_repo_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/db_helper.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DataSyncRepo implements DataSyncRepoInterface{
  final DioClient dioClient;
  final SharedPreferences? sharedPreferences;

  DataSyncRepo({required this.dioClient, required this.sharedPreferences});

  @override
  Future<ApiResponseModel<T>> fetchData<T>(String uri, DataSourceEnum source) async {
    try {
      return source == DataSourceEnum.client || _isACachesDisable() ? await _fetchFromClient<T>(uri) : await _fetchFromLocalCache<T>(uri);
    } catch (e) {
      debugPrint('DataSyncRepo: ===> $source $e ($uri)');

      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<T>> _fetchFromClient<T>(String uri) async {
    final response = await dioClient.get(uri);

    // Prepare the cache data
    final cacheData = CacheResponseCompanion(
      endPoint: Value(uri),
      header: Value(jsonEncode(dioClient.dio?.options.headers)),
      response: Value(jsonEncode(response.data)),
      isSuccess: Value(response.statusCode == 200),
    );

    // Cache the data based on the platform
    if (kIsWeb && _isWebCachesActive()) {
      _cacheResponseWeb(uri, cacheData);
    }

    if(!kIsWeb && _isAppCachesActive()) {
      await DbHelper.insertOrUpdate(id: uri, data: cacheData);
    }

    return ApiResponseModel.withSuccess(response as T);
  }

  bool _isWebCachesActive()=> (AppConstants.cachesType == LocalCachesTypeEnum.all || AppConstants.cachesType == LocalCachesTypeEnum.web);
  bool _isAppCachesActive()=> (AppConstants.cachesType == LocalCachesTypeEnum.all || AppConstants.cachesType == LocalCachesTypeEnum.app);
  bool _isACachesDisable() => AppConstants.cachesType == LocalCachesTypeEnum.none;

  void _cacheResponseWeb(String uri, CacheResponseCompanion cacheData) {
    final cacheJson = CacheResponseData(
      id: 0,
      endPoint: cacheData.endPoint.value,
      header: cacheData.header.value,
      response: cacheData.response.value,
      isSuccess: true,
    ).toJson();
    sharedPreferences?.setString(uri, jsonEncode(cacheJson));
  }

  Future<ApiResponseModel<T>> _fetchFromLocalCache<T>(String uri) async {
    CacheResponseData? cacheData;

    if (kIsWeb) {
      final cachedJson = sharedPreferences?.getString(uri);
      if (cachedJson != null) {
        cacheData = CacheResponseData.fromJson(jsonDecode(cachedJson));
      }
    } else {
      cacheData = await database.getCacheResponseById(uri);
    }

    if (cacheData != null && cacheData.isSuccess) {
      return ApiResponseModel.withSuccess(cacheData as T);
    } else {
      return ApiResponseModel.withError("No local data found for $uri");
    }
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }



}
