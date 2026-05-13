import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Simple Customer model for data services
class CustomerData {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String company;

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
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String? ?? '',
      company: map['company'] as String? ?? '',
    );
  }
}

class CustomerDataService {
  static const String _customersKey = 'customers_data';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static List<CustomerData> _getInitialMockData() {
    return [
      CustomerData(
        id: 'C001',
        name: 'John Doe',
        phone: '+855 12 345 678',
        email: 'john@example.com',
        company: 'Company A',
      ),
      CustomerData(
        id: 'C002',
        name: 'Jane Smith',
        phone: '+855 98 765 432',
        email: 'jane@example.com',
        company: 'Company B',
      ),
      CustomerData(
        id: 'C003',
        name: 'Mike Johnson',
        phone: '+855 77 123 456',
        email: 'mike@example.com',
        company: 'Company C',
      ),
      CustomerData(
        id: 'C004',
        name: 'Sarah Williams',
        phone: '+855 55 987 654',
        email: 'sarah@example.com',
        company: 'Company D',
      ),
      CustomerData(
        id: 'C005',
        name: 'David Brown',
        phone: '+855 66 432 109',
        email: 'david@example.com',
        company: 'Company E',
      ),
    ];
  }

  static Future<void> saveCustomers(List<CustomerData> customers) async {
    try {
      final jsonData = customers.map((c) => c.toMap()).toList();
      await _prefs.setString(_customersKey, jsonEncode(jsonData));
    } catch (e) {
      print('Error saving customers: $e');
    }
  }

  static Future<List<CustomerData>> loadCustomers() async {
    try {
      final jsonString = _prefs.getString(_customersKey);
      if (jsonString == null || jsonString.isEmpty) {
        final initialData = _getInitialMockData();
        await saveCustomers(initialData);
        return initialData;
      }
      final jsonData = jsonDecode(jsonString) as List;
      return jsonData
          .map((item) => CustomerData.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading customers: $e');
      return _getInitialMockData();
    }
  }
}
