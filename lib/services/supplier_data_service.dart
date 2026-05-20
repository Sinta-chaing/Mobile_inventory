import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_models.dart';

class SupplierDataService {
  static const String _suppliersKey = 'suppliers_data';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Fetch suppliers from local cache
  /// (Backend API integration removed - using local storage only)
  static Future<List<Source>> fetchSuppliers() async {
    return await loadSuppliers();
  }

  /// Create a new supplier and save to local storage
  static Future<Source?> createSupplier(Map<String, dynamic> data) async {
    try {
      final supplier = Source(
        sourceId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        name: data['name'] ?? 'Unknown',
        sourceUrl: data['sourceUrl'],
        contactPerson: data['contactPerson'],
        email: data['email'],
        phone: data['phone'],
        address: data['address'],
        district: data['district'],
        createdAt: DateTime.now(),
      );

      // Load existing suppliers and add new one
      final suppliers = await loadSuppliers();
      suppliers.add(supplier);

      // Save to local storage
      await saveSuppliers(suppliers);
      print('✅ Supplier created locally: ${supplier.name}');

      return supplier;
    } catch (e) {
      print('❌ Error creating supplier: $e');
      return null;
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
