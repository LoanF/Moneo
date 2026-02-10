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

  Future<void> createCategory(CategoriesCompanion entry) async {
    await _db.into(_db.categories).insert(entry, mode: InsertMode.insertOrReplace);

    try {
      await _api.dio.post(
        '/categories',
        data: {
          'id': entry.id.value,
          'name': entry.name.value,
          'iconCode': entry.iconCode.value,
          'colorValue': entry.colorValue.value,
          if (entry.parentId.present) 'parentId': entry.parentId.value,
        },
      );
    } catch (e) {
      // Hors-ligne
    }
  }

  Future<void> deleteCategory(String id) async {
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();

    try {
      await _api.dio.delete('/categories/$id');
    } catch (_) {
      // Hors-ligne : la donnée est déjà supprimée en local, 
    }
  }
}