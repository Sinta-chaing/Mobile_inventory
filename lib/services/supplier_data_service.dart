import 'dart:convert';
import '../presentation/supplier_screen/supplier_screen.dart';
import 'api_service.dart';

class SupplierDataService {
  static final ApiService _apiService = ApiService();

  static Future<void> init() async {
    await _apiService.init();
  }

  /// Fetch suppliers from Django backend. Throws on network/API errors.
  static Future<List<Supplier>> fetchSuppliersFromAPI() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/sources/',
        fromJson: (json) => (json as List).map((item) => item).toList(),
      );

      final suppliers = response.map((source) {
        return Supplier(
          id: source['sourceId']?.toString() ?? source['id']?.toString() ?? '',
          name: source['name'] ?? 'Unknown',
          contactPerson: source['contactPerson'] ?? '',
          email: source['email'] ?? '',
          phone: source['phone'] ?? '',
          address: source['address'] ?? '',
          category: source['category'] ?? '',
          totalOrders: 0.0,
          orderCount: 0,
          rating: 4.0,
          leadTimeDays: 7,
          notes: source['notes'] ?? '',
        );
      }).toList();

      return suppliers;
    } catch (e) {
      print('Error fetching suppliers from API: $e');
      rethrow;
    }
  }

  /// Create a new supplier on the backend. Returns created Supplier or null if API call fails.
  static Future<Supplier?> createSupplierOnAPI(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/sources/',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final supplier = Supplier(
        id:
            response['sourceId']?.toString() ??
            response['id']?.toString() ??
            '',
        name: response['name'] ?? data['name'] ?? 'Unknown',
        contactPerson: response['contactPerson'] ?? data['contactPerson'] ?? '',
        email: response['email'] ?? data['email'] ?? '',
        phone: response['phone'] ?? data['phone'] ?? '',
        address: response['address'] ?? data['address'] ?? '',
        category: response['category'] ?? data['category'] ?? '',
        totalOrders: 0.0,
        orderCount: 0,
        rating: 4.0,
        leadTimeDays: 7,
        notes: response['notes'] ?? data['notes'] ?? '',
      );

      return supplier;
    } catch (e) {
      print('Error creating supplier on API: $e');
      return null;
    }
  }
}
