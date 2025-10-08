import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'cache_response.g.dart';

class CacheResponse extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endPoint => text().unique()();
  TextColumn get header => text()();
  TextColumn get response => text()();
  BoolColumn get isSuccess => boolean().withDefault(const Constant(true))(); // Change to BoolColumn
}


@DriftDatabase(tables: [CacheResponse])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cache_response_new_db');
  }

  Future<int> insertCacheResponse(CacheResponseCompanion entry) async {
    // final existing = await (select(cacheResponse)..where((tbl) => tbl.endPoint.equals(entry.endPoint as String))).getSingleOrNull();
    // if (existing == null) {
    //   return await into(cacheResponse).insert(entry);
    // } else {
    //   await update(cacheResponse).replace(entry);
    // }
    return await into(cacheResponse).insert(entry);
  }


  Future<List<CacheResponseData>> getAllCacheResponses() async {
    return await select(cacheResponse).get();
  }


  Future<CacheResponseData?> getCacheResponseById(String endPoint) async {
    return await (select(cacheResponse)..where((tbl) => tbl.endPoint.equals(endPoint)))
        .getSingleOrNull();
  }


  Future<int> updateCacheResponse(String endPoint, CacheResponseCompanion entry) async {
    return await (update(cacheResponse)..where((tbl) => tbl.endPoint.equals(endPoint)))
        .write(entry);
  }


  Future<int> deleteCacheResponse(int id) async {
    return await (delete(cacheResponse)..where((tbl) => tbl.id.equals(id)))
        .go();
  }


  Future<int> clearCacheResponses() async {
    return await delete(cacheResponse).go();
  }



}