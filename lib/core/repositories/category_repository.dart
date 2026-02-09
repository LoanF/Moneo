import 'package:moneo/core/database/app_database.dart';
import 'package:moneo/core/interceptor/api_client.dart';
import 'package:drift/drift.dart';

class CategoryRepository {
  final AppDatabase _db;
  final ApiClient _api;

  CategoryRepository(this._db, this._api);

  Stream<List<Category>> watchCategories() {
    return _db.select(_db.categories).watch();
  }

  Future<void> upsertCategories(List<Category> list) async {
    await _db.batch((batch) {
      batch.insertAll(_db.categories, list, mode: InsertMode.insertOrReplace);
    });
  }
}