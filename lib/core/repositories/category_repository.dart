import 'package:moneo/core/interceptor/api_client.dart';
import 'package:moneo/data/models/models.dart';

class CategoryRepository {
  final ApiClient _api;

  CategoryRepository(this._api);

  Future<List<Category>> fetchCategories() async {
    final response = await _api.dio.get('/categories');
    return (response.data as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final response = await _api.dio.post('/categories', data: {
      'id': category.id,
      'name': category.name,
      'iconCode': category.iconCode,
      'colorValue': category.colorValue,
      if (category.parentId != null) 'parentId': category.parentId,
    });
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _api.dio.delete('/categories/$id');
  }
}
