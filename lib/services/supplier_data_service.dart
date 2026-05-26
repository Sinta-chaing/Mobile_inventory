import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_models.dart';
import './api_service.dart';

class SupplierDataService {
  static const String _suppliersKey = 'suppliers_data';
  static late SharedPreferences _prefs;
  static late ApiService _apiService;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _apiService = ApiService();
  }

  /// Fetch suppliers from backend API
  /// Falls back to local cache if API fails
  static Future<List<Source>> fetchSuppliers() async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('⚠️ Not authenticated - using local cache');
        return await loadSuppliers();
      }

      final response = await _apiService.get(
        '/api/sources/',
        fromJson: (data) => (data as List)
            .map((item) => Source.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      // Save to local cache for offline access
      await saveSuppliers(response);
      print('✅ Fetched ${response.length} suppliers from backend');
      return response;
    } catch (e) {
      print('⚠️ Failed to fetch from API: $e - Using local cache');
      return await loadSuppliers();
    }
  }

  /// Create new supplier on backend
  static Future<Source?> createSupplier(Map<String, dynamic> data) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot create supplier on backend');
        return null;
      }

      print('📤 Creating supplier on backend: ${data['name']}');

      final payload = {
        'name': data['name'] ?? 'Unknown',
        'sourceUrl': data['sourceUrl'],
        'contactPerson': data['contactPerson'],
        'email': data['email'],
        'phone': data['phone'],
        'address': data['address'],
        'district': data['district'],
      };

      print('📋 Payload: $payload');

      final supplier = await _apiService.post(
        '/api/sources/',
        data: payload,
        fromJson: (data) => Source.fromJson(data as Map<String, dynamic>),
      );

      print(
        '✅ Supplier created on backend: ${supplier.name} (ID: ${supplier.sourceId})',
      );

      // IMPORTANT: Save new supplier to local cache immediately!
      print('💾 Adding new supplier to local cache...');
      final existingSuppliers = await loadSuppliers();
      existingSuppliers.add(supplier);
      await saveSuppliers(existingSuppliers);
      print('✅ Supplier saved to local cache');

      return supplier;
    } catch (e, stackTrace) {
      print('❌ Error creating supplier: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update supplier on backend
  static Future<bool> updateSupplier(
    int supplierId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot update supplier on backend');
        return false;
      }

      print('📤 Updating supplier on backend: $supplierId');

      final payload = {
        'name': data['name'],
        'sourceUrl': data['sourceUrl'],
        'contactPerson': data['contactPerson'],
        'email': data['email'],
        'phone': data['phone'],
        'address': data['address'],
        'district': data['district'],
      };

      await _apiService.put(
        '/api/sources/$supplierId/',
        data: payload,
        fromJson: (data) => Source.fromJson(data as Map<String, dynamic>),
      );

      print('✅ Supplier updated on backend');

      // Refresh from API to sync
      await fetchSuppliers();
      return true;
    } catch (e) {
      print('❌ Error updating supplier: $e');
      return false;
    }
  }

  /// Delete supplier from backend
  static Future<bool> deleteSupplier(int supplierId) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot delete supplier on backend');
        return false;
      }

      print('📤 Deleting supplier on backend: $supplierId');

      await _apiService.delete('/api/sources/$supplierId/');

      print('✅ Supplier deleted on backend');

      // Remove from local cache
      final suppliers = await loadSuppliers();
      suppliers.removeWhere((s) => s.sourceId == supplierId);
      await saveSuppliers(suppliers);

      print('✅ Supplier removed from local cache');
      return true;
    } catch (e) {
      print('❌ Error deleting supplier: $e');
      return false;
    }
  }

  /// Save suppliers to local cache
  static Future<void> saveSuppliers(List<Source> suppliers) async {
    try {
      final jsonData = suppliers.map((s) => s.toJson()).toList();
      await _prefs.setString(_suppliersKey, jsonEncode(jsonData));
    } catch (e) {
      print('❌ Error saving suppliers: $e');
    }
  }

  /// Load suppliers from local cache
  static Future<List<Source>> loadSuppliers() async {
    try {
      final jsonString = _prefs.getString(_suppliersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonData = jsonDecode(jsonString) as List;
      return jsonData
          .map((item) => Source.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error loading suppliers: $e');
      return [];
    }
  }
}
