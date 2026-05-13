import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/supplier_screen/supplier_screen.dart';

class SupplierDataService {
  static const String _suppliersKey = 'suppliers_data';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static List<Supplier> _getInitialMockData() {
    return [
      Supplier(
        id: 'S001',
        name: 'ProTools Supply Co.',
        contactPerson: 'James Wilson',
        email: 'sales@protools.com',
        phone: '+1 (555) 100-2000',
        address: '100 Industrial Way, Chicago, IL 60601',
        category: 'Power Tools',
        status: SupplierStatus.active,
        totalOrders: 125400.00,
        orderCount: 28,
        rating: 4.8,
        leadTimeDays: 5,
        notes: 'Preferred supplier for power tools',
      ),
      Supplier(
        id: 'S002',
        name: 'Meridian Hardware Dist.',
        contactPerson: 'Patricia Lee',
        email: 'orders@meridian.com',
        phone: '+1 (555) 200-3000',
        address: '200 Commerce Blvd, Detroit, MI 48201',
        category: 'Hand Tools',
        status: SupplierStatus.active,
        totalOrders: 67800.50,
        orderCount: 19,
        rating: 4.5,
        leadTimeDays: 7,
        notes: '',
      ),
      Supplier(
        id: 'S003',
        name: 'SafeGuard Industrial',
        contactPerson: 'Thomas Brown',
        email: 'supply@safeguard.com',
        phone: '+1 (555) 300-4000',
        address: '300 Safety Pkwy, Cleveland, OH 44101',
        category: 'Safety Equipment',
        status: SupplierStatus.active,
        totalOrders: 34200.00,
        orderCount: 12,
        rating: 4.2,
        leadTimeDays: 10,
        notes: 'Certified safety equipment supplier',
      ),
      Supplier(
        id: 'S004',
        name: 'TechMeasure Solutions',
        contactPerson: 'Angela Davis',
        email: 'info@techmeasure.com',
        phone: '+1 (555) 400-5000',
        address: '400 Tech Drive, Columbus, OH 43201',
        category: 'Measuring Tools',
        status: SupplierStatus.onHold,
        totalOrders: 18900.00,
        orderCount: 8,
        rating: 3.8,
        leadTimeDays: 14,
        notes: 'On hold pending contract renewal',
      ),
      Supplier(
        id: 'S005',
        name: 'FastFix Distributors',
        contactPerson: 'Michael Scott',
        email: 'orders@fastfix.com',
        phone: '+1 (555) 500-6000',
        address: '500 Logistics Ave, Indianapolis, IN 46201',
        category: 'General Hardware',
        status: SupplierStatus.inactive,
        totalOrders: 5600.00,
        orderCount: 4,
        rating: 3.2,
        leadTimeDays: 21,
        notes: 'Inactive - poor delivery performance',
      ),
    ];
  }

  static Map<String, dynamic> _supplierToMap(Supplier supplier) {
    return {
      'id': supplier.id,
      'name': supplier.name,
      'contactPerson': supplier.contactPerson,
      'email': supplier.email,
      'phone': supplier.phone,
      'address': supplier.address,
      'category': supplier.category,
      'status': supplier.status == SupplierStatus.active
          ? 'active'
          : supplier.status == SupplierStatus.inactive
          ? 'inactive'
          : 'onHold',
      'totalOrders': supplier.totalOrders,
      'orderCount': supplier.orderCount,
      'rating': supplier.rating,
      'leadTimeDays': supplier.leadTimeDays,
      'notes': supplier.notes,
    };
  }

  static Supplier _mapToSupplier(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      contactPerson: map['contactPerson'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      category: map['category'] as String,
      status: _statusFromString(map['status'] as String),
      totalOrders: (map['totalOrders'] as num).toDouble(),
      orderCount: map['orderCount'] as int,
      rating: (map['rating'] as num).toDouble(),
      leadTimeDays: map['leadTimeDays'] as int,
      notes: map['notes'] as String? ?? '',
    );
  }

  static SupplierStatus _statusFromString(String status) {
    switch (status) {
      case 'active':
        return SupplierStatus.active;
      case 'inactive':
        return SupplierStatus.inactive;
      case 'onHold':
        return SupplierStatus.onHold;
      default:
        return SupplierStatus.active;
    }
  }

  static Future<void> saveSuppliers(List<Supplier> suppliers) async {
    try {
      final jsonData = suppliers.map((s) => _supplierToMap(s)).toList();
      await _prefs.setString(_suppliersKey, jsonEncode(jsonData));
    } catch (e) {
      print('Error saving suppliers: $e');
    }
  }

  static Future<List<Supplier>> loadSuppliers() async {
    try {
      final jsonString = _prefs.getString(_suppliersKey);
      if (jsonString == null || jsonString.isEmpty) {
        final initialData = _getInitialMockData();
        await saveSuppliers(initialData);
        return initialData;
      }
      final jsonData = jsonDecode(jsonString) as List;
      return jsonData
          .map((item) => _mapToSupplier(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading suppliers: $e');
      return _getInitialMockData();
    }
  }
}
