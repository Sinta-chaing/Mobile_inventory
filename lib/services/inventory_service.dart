import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/inventory_screen/inventory_screen.dart';
import 'api_service.dart';

class InventoryService {
  static const String _inventoryKey = 'inventory_data';
  static late SharedPreferences _prefs;
  static final ApiService _apiService = ApiService();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _apiService.init();
  }

  /// Fetch products from Django backend
  static Future<List<StockItem>> fetchProductsFromAPI() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/products/',
        fromJson: (json) => (json as List).map((item) => item).toList(),
      );

      final items = response
          .where((product) {
            // Only include products that have inventory records
            final inventoryRecords = product['inventory_records'];
            return inventoryRecords != null &&
                (inventoryRecords as List).isNotEmpty;
          })
          .map((product) {
            // Safe access since we've filtered to only products with inventory
            final inventoryRecords = product['inventory_records'] as List;
            final firstInventory = inventoryRecords[0] as Map<String, dynamic>;

            // Get quantity from inventory records
            final quantity = firstInventory['quantity'] ?? 0;
            final inventoryId = firstInventory['inventoryId']?.toString() ?? '';
            final reorderLevel = firstInventory['reorderLevel'] ?? 10;

            // Safely extract supplier name from nested source object
            String supplierName = 'Unknown';
            try {
              if (product['source'] != null && product['source'] is Map) {
                supplierName = product['source']['name'] ?? 'Unknown';
              } else if (product['sourceName'] != null) {
                supplierName = product['sourceName'] ?? 'Unknown';
              }
            } catch (e) {
              print('Error parsing supplier: $e');
            }

            // Safely extract category name from nested subcategory object
            String categoryName = 'Uncategorized';
            try {
              if (product['subcategory'] != null &&
                  product['subcategory'] is Map) {
                categoryName =
                    product['subcategory']['name'] ?? 'Uncategorized';
              } else if (product['subcategoryName'] != null) {
                categoryName = product['subcategoryName'] ?? 'Uncategorized';
              }
            } catch (e) {
              print('Error parsing category: $e');
            }

            // Helper function to safely convert price to double
            double parsePrice(dynamic value) {
              if (value == null) return 0.0;
              if (value is double) return value;
              if (value is int) return value.toDouble();
              if (value is String) {
                try {
                  return double.parse(value);
                } catch (e) {
                  return 0.0;
                }
              }
              return 0.0;
            }

            return StockItem(
              id:
                  product['productId']?.toString() ??
                  product['id']?.toString() ??
                  '',
              inventoryId: inventoryId,
              name: product['productName'] ?? product['name'] ?? '',
              sku: product['skuCode'] ?? product['sku'] ?? '',
              category: categoryName,
              quantity: quantity,
              reorderLevel: reorderLevel,
              unitCost: parsePrice(
                product['costPrice'] ?? product['cost_price'],
              ),
              unitPrice: parsePrice(
                product['salePrice'] ??
                    product['sale_price'] ??
                    product['price'],
              ),
              supplierName: supplierName,
              imageUrl: product['image'] ?? '',
              semanticLabel:
                  product['productName'] ?? product['name'] ?? 'Product image',
            );
          })
          .toList();

      // Cache to local storage
      await saveInventory(items);
      return items;
    } catch (e) {
      print('Error fetching from API: $e');
      // Fallback to cached data
      return await loadInventory();
    }
  }

  /// Update product quantity using inventory ID
  static Future<bool> updateProductQuantity(
    String productId,
    String inventoryId,
    int newQuantity,
  ) async {
    try {
      // Validate inventory ID
      if (inventoryId.isEmpty) {
        print('Error: Inventory ID is empty for product $productId');
        return false;
      }

      // Update through inventory endpoint using inventory ID
      await _apiService.put(
        '/api/inventory/$inventoryId/',
        data: {'quantity': newQuantity},
        fromJson: (json) => json,
      );
      print(
        '✓ Successfully updated inventory $inventoryId with quantity $newQuantity',
      );
      return true;
    } catch (e) {
      print('✗ Error updating product: $e');
      return false;
    }
  }

  /// Create new product
  static Future<StockItem?> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      // Map frontend product fields to backend expected fields
      final backendPayload = {
        'productName': productData['name'] ?? productData['productName'] ?? '',
        'description': productData['description'] ?? productData['name'] ?? '',
        'skuCode': productData['sku'] ?? productData['skuCode'] ?? '',
        'unit': productData['unit'] ?? 'pcs',
        'costPrice': productData['unitCost'] ?? productData['costPrice'] ?? 0,
        'salePrice': productData['unitPrice'] ?? productData['salePrice'] ?? 0,
        'discount': productData['discount'] ?? 0,
        'image': productData['image'] ?? '',
        // backend requires a subcategory id; use provided subcategory or default to 1
        'subcategory': productData['subcategory'] ?? 1,
        'source': productData['source'],
        'status': productData['status'] ?? 'Active',
      };

      final response = await _apiService.post(
        '/api/products/',
        data: backendPayload,
        fromJson: (json) => json,
      );

      // Get quantity from inventory records if available
      int quantity = 0;
      if (response['inventory_records'] != null &&
          (response['inventory_records'] as List).isNotEmpty) {
        quantity = response['inventory_records'][0]['quantity'] ?? 0;
      }

      return StockItem(
        id:
            response['productId']?.toString() ??
            response['id']?.toString() ??
            '',
        inventoryId:
            response['inventory_records'] != null &&
                (response['inventory_records'] as List).isNotEmpty
            ? response['inventory_records'][0]['inventoryId']?.toString() ?? ''
            : '',
        name: response['productName'] ?? response['name'] ?? '',
        sku: response['skuCode'] ?? response['sku'] ?? '',
        category:
            response['subcategory']?['name'] ??
            response['category']?['name'] ??
            'Uncategorized',
        quantity: quantity,
        reorderLevel: response['inventory_records']?[0]?['reorderLevel'] ?? 10,
        unitCost: (response['costPrice'] ?? response['cost_price'] ?? 0)
            .toDouble(),
        unitPrice:
            (response['salePrice'] ??
                    response['sale_price'] ??
                    response['price'] ??
                    0)
                .toDouble(),
        supplierName:
            response['source']?['name'] ??
            response['supplier']?['name'] ??
            'Unknown',
        imageUrl: response['image'] ?? '',
        semanticLabel:
            response['productName'] ?? response['name'] ?? 'Product image',
      );
    } catch (e) {
      print('Error creating product: $e');
      return null;
    }
  }

  /// Delete product
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _apiService.delete('/api/products/$productId/');
      return true;
    } catch (e) {
      print('Error deleting product: $e');
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
}
