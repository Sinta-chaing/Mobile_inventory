import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// Simple Customer model for data services
class CustomerData {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String company; // Maps to businessAddress in Django

  CustomerData({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.company,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'company': company,
    };
  }

  factory CustomerData.fromMap(Map<String, dynamic> map) {
    return CustomerData(
      id: map['customerId']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      company:
          map['businessAddress'] as String? ?? map['company'] as String? ?? '',
    );
  }
}

class CustomerDataService {
  static const String _customersKey = 'customers_data';
  static late SharedPreferences _prefs;
  static final ApiService _apiService = ApiService();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _apiService.init();
  }

  /// Fetch customers from Django backend
  static Future<List<CustomerData>> fetchCustomersFromAPI() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/customers/',
        fromJson: (json) => (json as List).map((item) => item).toList(),
      );

      final customers = response
          .map((customer) => CustomerData.fromMap(customer))
          .toList();

      // Cache to local storage
      await saveCustomers(customers);
      return customers;
    } catch (e) {
      print('Error fetching customers from API: $e');
      // Fallback to cached data
      return await loadCustomers();
    }
  }

  /// Create new customer
  static Future<CustomerData?> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/customers/',
        data: customerData,
        fromJson: (json) => json,
      );

      return CustomerData.fromMap(response);
    } catch (e) {
      print('Error creating customer: $e');
      return null;
    }
  }

  /// Update customer
  static Future<bool> updateCustomer(
    String customerId,
    Map<String, dynamic> customerData,
  ) async {
    try {
      await _apiService.put(
        '/api/customers/$customerId/',
        data: customerData,
        fromJson: (json) => json,
      );
      return true;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  /// Delete customer
  static Future<bool> deleteCustomer(String customerId) async {
    try {
      await _apiService.delete('/api/customers/$customerId/');
      return true;
    } catch (e) {
      print('Error deleting customer: $e');
      return false;
    }
  }

  /// Save customers to local cache
  static Future<void> saveCustomers(List<CustomerData> customers) async {
    try {
      final jsonData = customers.map((c) => c.toMap()).toList();
      await _prefs.setString(_customersKey, jsonEncode(jsonData));
    } catch (e) {
      print('Error saving customers: $e');
    }
  }

  /// Load customers from local cache
  static Future<List<CustomerData>> loadCustomers() async {
    try {
      final jsonString = _prefs.getString(_customersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonData = jsonDecode(jsonString) as List;
      return jsonData
          .map((item) => CustomerData.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading customers: $e');
      return [];
    }
  }
}
