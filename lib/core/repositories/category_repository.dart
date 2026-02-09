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

  Future<void> upsertCategory(CategoriesCompanion entry) async {
    await _db.into(_db.categories).insertOnConflictUpdate(entry);

    try {
      await _api.dio.post('/categories', data: {
        'id': entry.id.value,
        'name': entry.name.value,
        'iconCode': entry.iconCode.value,
        'colorValue': entry.colorValue.value,
        'parentId': entry.parentId.value,
      });
    } catch (_) {}
  }

  Future<void> deleteCategory(String id) async {
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
    try {
      await _api.dio.delete('/categories/$id');
    } catch (_) {}
  }
}