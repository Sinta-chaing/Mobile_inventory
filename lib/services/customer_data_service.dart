import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_models.dart';

class CustomerDataService {
  static const String _customersKey = 'customers_data';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Fetch customers from local cache
  /// (Backend API integration removed - using local storage only)
  static Future<List<Customer>> fetchCustomers() async {
    return await loadCustomers();
  }

  /// Create new customer in local cache
  static Future<Customer?> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final customer = Customer(
        customerId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        name: customerData['name'] ?? '',
        businessAddress:
            customerData['businessAddress'] ?? customerData['company'] ?? '',
        phone: customerData['phone'] ?? '',
        email: customerData['email'],
        customerType: customerData['customerType'] ?? 'Individual',
        firstPurchaseDate: null,
        createdAt: DateTime.now(),
      );

      // Load existing customers and add new one
      final customers = await loadCustomers();
      customers.add(customer);

      // Save to local storage
      await saveCustomers(customers);
      print('✅ Customer created locally: ${customer.name}');

      return customer;
    } catch (e) {
      print('❌ Error creating customer: $e');
      return null;
    }
  }

  /// Update customer in local cache
  static Future<bool> updateCustomer(
    int customerId,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final customers = await loadCustomers();
      final index = customers.indexWhere((c) => c.customerId == customerId);

      if (index == -1) {
        print('❌ Customer not found: $customerId');
        return false;
      }

      // Update customer
      final existing = customers[index];
      customers[index] = Customer(
        customerId: customerId,
        name: customerData['name'] ?? existing.name,
        businessAddress:
            customerData['businessAddress'] ??
            customerData['company'] ??
            existing.businessAddress,
        phone: customerData['phone'] ?? existing.phone,
        email: customerData['email'] ?? existing.email,
        customerType: customerData['customerType'] ?? existing.customerType,
        firstPurchaseDate: customerData['firstPurchaseDate'] != null
            ? DateTime.parse(customerData['firstPurchaseDate'])
            : existing.firstPurchaseDate,
        createdAt: existing.createdAt,
      );

      // Save updated customers
      await saveCustomers(customers);
      print('✅ Customer updated: $customerId');
      return true;
    } catch (e) {
      print('❌ Error updating customer: $e');
      return false;
    }
  }

  /// Delete customer from local cache
  static Future<bool> deleteCustomer(int customerId) async {
    try {
      final customers = await loadCustomers();
      final index = customers.indexWhere((c) => c.customerId == customerId);

      if (index == -1) {
        print('❌ Customer not found: $customerId');
        return false;
      }

      customers.removeAt(index);

      // Save updated customers
      await saveCustomers(customers);
      print('✅ Customer deleted: $customerId');
      return true;
    } catch (e) {
      print('❌ Error deleting customer: $e');
      return false;
    }
  }

  /// Save customers to local cache
  static Future<void> saveCustomers(List<Customer> customers) async {
    try {
      final jsonData = customers.map((c) => c.toJson()).toList();
      await _prefs.setString(_customersKey, jsonEncode(jsonData));
    } catch (e) {
      print('Error saving customers: $e');
    }
  }

  /// Load customers from local cache
  static Future<List<Customer>> loadCustomers() async {
    try {
      final jsonString = _prefs.getString(_customersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonData = jsonDecode(jsonString) as List;
      return jsonData
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading customers: $e');
      return [];
    }
  }
}
