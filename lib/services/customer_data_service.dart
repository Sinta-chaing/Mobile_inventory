import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_models.dart';
import './api_service.dart';

class CustomerDataService {
  static const String _customersKey = 'customers_data';
  static late SharedPreferences _prefs;
  static late ApiService _apiService;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _apiService = ApiService();
  }

  /// Fetch customers from backend API
  /// Falls back to local cache if API fails
  static Future<List<Customer>> fetchCustomers() async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('⚠️ Not authenticated - using local cache');
        return await loadCustomers();
      }

      final response = await _apiService.get(
        '/api/customers/',
        fromJson: (data) => (data as List)
            .map((item) => Customer.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      // Save to local cache for offline access
      await saveCustomers(response);
      print('✅ Fetched ${response.length} customers from backend');
      return response;
    } catch (e) {
      print('⚠️ Failed to fetch from API: $e - Using local cache');
      return await loadCustomers();
    }
  }

  /// Create new customer on backend
  static Future<Customer?> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final isAuth = _apiService.isAuthenticated();
      final token = _apiService.getAuthToken();
      print(
        '🔐 Auth check: isAuthenticated=$isAuth, token=${token?.substring(0, 10)}...',
      );

      if (!isAuth) {
        print('❌ Not authenticated - cannot create customer on backend');
        return null;
      }

      print('📤 Creating customer on backend: ${customerData['name']}');

      final payload = {
        'name': customerData['name'] ?? '',
        'email': customerData['email'] ?? '',
        'phone': customerData['phone'] ?? '',
        'businessAddress':
            customerData['businessAddress'] ?? customerData['company'] ?? '',
        'customerType': customerData['customerType'] ?? 'Individual',
      };

      print('📋 Payload: $payload');

      final customer = await _apiService.post(
        '/api/customers/',
        data: payload,
        fromJson: (data) => Customer.fromJson(data as Map<String, dynamic>),
      );

      print(
        '✅ Customer created on backend: ${customer.name} (ID: ${customer.customerId})',
      );

      // IMPORTANT: Save new customer to local cache immediately!
      print('💾 Adding new customer to local cache...');
      final existingCustomers = await loadCustomers();
      existingCustomers.add(customer);
      await saveCustomers(existingCustomers);
      print('✅ Customer saved to local cache');

      // Also refresh from API in background to ensure sync
      print('🔄 Syncing with backend cache...');
      try {
        await fetchCustomers();
        print('✅ Backend sync completed');
      } catch (e) {
        print('⚠️ Backend sync failed (but local cache has the customer): $e');
      }

      return customer;
    } catch (e, stackTrace) {
      print('❌ Error creating customer: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update customer on backend
  static Future<bool> updateCustomer(
    int customerId,
    Map<String, dynamic> customerData,
  ) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot update customer on backend');
        return false;
      }

      print('📤 Updating customer on backend: $customerId');

      final payload = {
        'name': customerData['name'],
        'email': customerData['email'],
        'phone': customerData['phone'],
        'businessAddress': customerData['businessAddress'],
        'customerType': customerData['customerType'],
      };

      await _apiService.put(
        '/api/customers/$customerId/',
        data: payload,
        fromJson: (data) => Customer.fromJson(data as Map<String, dynamic>),
      );

      print('✅ Customer updated on backend: $customerId');

      // Update local cache immediately
      print('💾 Updating local cache...');
      final customers = await loadCustomers();
      final index = customers.indexWhere((c) => c.customerId == customerId);
      if (index != -1) {
        // Update the existing customer in cache
        customers[index] = Customer(
          customerId: customerId,
          name: payload['name'],
          email: payload['email'],
          phone: payload['phone'],
          businessAddress: payload['businessAddress'],
          customerType: payload['customerType'],
          firstPurchaseDate: customers[index].firstPurchaseDate,
          createdAt: customers[index].createdAt,
        );
        await saveCustomers(customers);
        print('✅ Customer updated in local cache');
      }

      // Refresh from API in background
      try {
        await fetchCustomers();
      } catch (e) {
        print('⚠️ Backend sync failed: $e');
      }

      return true;
    } catch (e) {
      print('❌ Error updating customer: $e');
      return false;
    }
  }

  /// Delete customer from backend
  static Future<bool> deleteCustomer(int customerId) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot delete customer on backend');
        return false;
      }

      print('📤 Deleting customer on backend: $customerId');

      await _apiService.delete('/api/customers/$customerId/');

      print('✅ Customer deleted on backend: $customerId');

      // Delete from local cache immediately
      print('💾 Removing from local cache...');
      final customers = await loadCustomers();
      customers.removeWhere((c) => c.customerId == customerId);
      await saveCustomers(customers);
      print('✅ Customer removed from local cache');

      // Refresh from API in background
      try {
        await fetchCustomers();
      } catch (e) {
        print('⚠️ Backend sync failed: $e');
      }

      return true;
    } catch (e) {
      print('❌ Error deleting customer: $e');
      return false;
    }
  }

  /// Get single customer by ID
  static Future<Customer?> getCustomer(int customerId) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('⚠️ Not authenticated - searching local cache');
        final customers = await loadCustomers();
        return customers.firstWhere((c) => c.customerId == customerId);
      }

      final customer = await _apiService.get(
        '/api/customers/$customerId/',
        fromJson: (data) => Customer.fromJson(data as Map<String, dynamic>),
      );

      return customer;
    } catch (e) {
      print('⚠️ Failed to fetch customer: $e');
      try {
        final customers = await loadCustomers();
        return customers.firstWhere((c) => c.customerId == customerId);
      } catch (_) {
        return null;
      }
    }
  }

  /// Save customers to local cache (offline storage)
  static Future<void> saveCustomers(List<Customer> customers) async {
    try {
      final jsonData = customers.map((c) => c.toJson()).toList();
      await _prefs.setString(_customersKey, jsonEncode(jsonData));
      print('💾 Saved ${customers.length} customers to local cache');
    } catch (e) {
      print('Error saving customers: $e');
    }
  }

  /// Load customers from local cache (offline storage)
  static Future<List<Customer>> loadCustomers() async {
    try {
      final jsonString = _prefs.getString(_customersKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonData = jsonDecode(jsonString) as List;
      final customers = jsonData
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();
      print('📖 Loaded ${customers.length} customers from local cache');
      return customers;
    } catch (e) {
      print('Error loading customers: $e');
      return [];
    }
  }

  /// Sync local changes with backend (useful for offline-first apps)
  static Future<void> syncWithBackend() async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('⚠️ Not authenticated - cannot sync with backend');
        return;
      }

      print('🔄 Syncing customers with backend...');
      await fetchCustomers();
      print('✅ Sync complete');
    } catch (e) {
      print('❌ Error syncing with backend: $e');
    }
  }
}
