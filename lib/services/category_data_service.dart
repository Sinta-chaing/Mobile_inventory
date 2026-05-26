import '../models/all_models.dart';
import './api_service.dart';

class CategoryDataService {
  static final ApiService _api = ApiService();

  static Future<List<Category>> fetchCategories() async {
    try {
      return await _api.get(
        '/api/categories/',
        fromJson: (data) => (data as List)
            .map((item) => Category.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  static Future<List<SubCategory>> fetchSubcategories() async {
    try {
      return await _api.get(
        '/api/subcategories/',
        fromJson: (data) => (data as List)
            .map((item) => SubCategory.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      print('Error fetching subcategories: $e');
      return [];
    }
  }

  static Future<Category?> createCategory(String name) async {
    try {
      return await _api.post(
        '/api/categories/',
        data: {'name': name.trim()},
        fromJson: (data) => Category.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  static Future<SubCategory?> createSubcategory({
    required String name,
    required int categoryId,
  }) async {
    try {
      return await _api.post(
        '/api/subcategories/',
        data: {'name': name.trim(), 'category': categoryId},
        fromJson: (data) => SubCategory.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      print('Error creating subcategory: $e');
      rethrow;
    }
  }
}
