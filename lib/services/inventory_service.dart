import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/inventory_screen/inventory_screen.dart';

class InventoryService {
  static const String _inventoryKey = 'inventory_data';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Fetch products from local cache
  /// (Backend API integration removed - using local storage only)
  static Future<List<StockItem>> fetchProducts() async {
    return await loadInventory();
  }

  /// Update product quantity in local cache
  static Future<bool> updateProductQuantity(
    String productId,
    String inventoryId,
    int newQuantity,
  ) async {
    try {
      // Load current inventory
      final items = await loadInventory();

      // Find and update the product
      final index = items.indexWhere((item) => item.id == productId);
      if (index == -1) {
        print('✗ Product not found: $productId');
        return false;
      }

      // Update quantity
      final updatedItem = StockItem(
        id: items[index].id,
        inventoryId: items[index].inventoryId,
        name: items[index].name,
        sku: items[index].sku,
        category: items[index].category,
        quantity: newQuantity,
        reorderLevel: items[index].reorderLevel,
        unitCost: items[index].unitCost,
        unitPrice: items[index].unitPrice,
        supplierName: items[index].supplierName,
        imageUrl: items[index].imageUrl,
        semanticLabel: items[index].semanticLabel,
      );
      items[index] = updatedItem;

      // Save updated inventory
      await saveInventory(items);
      print(
        '✓ Successfully updated product $productId with quantity $newQuantity',
      );
      return true;
    } catch (e) {
      print('✗ Error updating product: $e');
      return false;
    }
  }

  /// Create new product in local cache
  static Future<StockItem?> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      // Generate a unique ID based on timestamp
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final newItem = StockItem(
        id: id,
        inventoryId: id,
        name: productData['name'] ?? productData['productName'] ?? '',
        sku: productData['sku'] ?? productData['skuCode'] ?? '',
        category: productData['category'] ?? 'Uncategorized',
        quantity: productData['quantity'] ?? 0,
        reorderLevel: productData['reorderLevel'] ?? 10,
        unitCost: _parseDouble(
          productData['unitCost'] ?? productData['costPrice'] ?? 0,
        ),
        unitPrice: _parseDouble(
          productData['unitPrice'] ?? productData['salePrice'] ?? 0,
        ),
        supplierName: productData['supplierName'] ?? '',
        imageUrl: productData['image'] ?? '',
        semanticLabel: productData['name'] ?? 'Product',
      );

      // Load existing items and add new one
      final items = await loadInventory();
      items.add(newItem);

      // Save to local storage
      await saveInventory(items);
      print('✓ Product created locally: ${newItem.name}');

      return newItem;
    } catch (e) {
      print('✗ Error creating product: $e');
      return null;
    }
  }

  /// Update product details in local cache
  static Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      // Load current inventory
      final items = await loadInventory();

      // Find product index
      final index = items.indexWhere((item) => item.id == productId);
      if (index == -1) {
        print('✗ Product not found: $productId');
        return false;
      }

      // Update product with new data
      final updatedItem = StockItem(
        id: items[index].id,
        inventoryId: items[index].inventoryId,
        name:
            productData['name'] ??
            productData['productName'] ??
            items[index].name,
        sku: productData['sku'] ?? productData['skuCode'] ?? items[index].sku,
        category: productData['category'] ?? items[index].category,
        quantity: items[index].quantity,
        reorderLevel: productData['reorderLevel'] ?? items[index].reorderLevel,
        unitCost: _parseDouble(
          productData['unitCost'] ?? items[index].unitCost,
        ),
        unitPrice: _parseDouble(
          productData['unitPrice'] ?? items[index].unitPrice,
        ),
        supplierName: productData['supplierName'] ?? items[index].supplierName,
        imageUrl: productData['image'] ?? items[index].imageUrl,
        semanticLabel: items[index].semanticLabel,
      );
      items[index] = updatedItem;

      // Save to local storage
      await saveInventory(items);
      print('✓ Successfully updated product $productId');
      return true;
    } catch (e) {
      print('✗ Error updating product: $e');
      return false;
    }
  }

  /// Delete product from local cache
  static Future<bool> deleteProduct(String productId) async {
    try {
      // Load current inventory
      final items = await loadInventory();

      // Find and remove product
      final index = items.indexWhere((item) => item.id == productId);
      if (index == -1) {
        print('✗ Product not found: $productId');
        return false;
      }

      items.removeAt(index);

      // Save updated inventory
      await saveInventory(items);
      print('✓ Successfully deleted product $productId');
      return true;
    } catch (e) {
      print('✗ Error deleting product: $e');
      return false;
    }
  }

  /// Save inventory to local cache
  static Future<void> saveInventory(List<StockItem> items) async {
    try {
      final jsonData = items.map((item) => item.toMap()).toList();
      await _prefs.setString(_inventoryKey, jsonEncode(jsonData));
    } catch (e) {
      print('Error saving inventory: $e');
    }
  }

  /// Load inventory from local cache
  static Future<List<StockItem>> loadInventory() async {
    try {
      final jsonString = _prefs.getString(_inventoryKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonData = jsonDecode(jsonString) as List;
      return jsonData
          .map((item) => StockItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading inventory: $e');
      return [];
    }
  }

  /// Safely parse a value to double, handling strings, numbers, and null
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double from string "$value": $e');
        return 0.0;
      }
    }
    return 0.0;
  }
}
