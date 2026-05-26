import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../presentation/inventory_screen/inventory_screen.dart';
import './api_service.dart';
import './config_service.dart';

class InventoryService {
  static const String _inventoryKey = 'inventory_data';
  static late SharedPreferences _prefs;
  static late ApiService _apiService;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _apiService = ApiService();
  }

  static Future<Map<String, dynamic>> searchProductsByImage(
    XFile imageFile, {
    Map<String, int>? cropRect,
    double scoreThreshold = 0.3,
  }) async {
    try {
      final extraFields = <String, dynamic>{};
      if (cropRect != null) {
        extraFields['crop'] = json.encode(cropRect);
      }
      extraFields['score_threshold'] = scoreThreshold.toStringAsFixed(2);
      final response = await _apiService.uploadFile(
        '/api/search-products/',
        imageFile,
        fromJson: (data) => data,
        fieldName: 'file',
        extraFields: extraFields,
      );
      final List results = response['results'] ?? [];
      final List detections = response['detections'] ?? [];
      return {
        'productIds': results.map((r) => r['product_id'] as int).toList(),
        'scores': results.map((r) => (r['similarity_score'] as num).toDouble()).toList(),
        'detections': detections,
      };
    } catch (e) {
      print('❌ Image search failed: $e');
      return {
        'productIds': <int>[],
        'scores': <double>[],
        'detections': <Map<String, dynamic>>[],
      };
    }
  }

  static StockItem _mapInventoryToStockItem(Map<String, dynamic> map) {
    final config = ConfigService();
    final rawImage = (map['productImage'] ?? map['image'] ?? '').toString();

    return StockItem(
      id: map['product']?.toString() ?? '',
      inventoryId: map['inventoryId']?.toString() ?? '',
      name: map['productName'] ?? 'Unknown Product',
      sku: map['productSku'] ?? '',
      category: 'Stock',
      quantity: map['quantity'] ?? 0,
      reorderLevel: map['reorderLevel'] ?? 10,
      unitCost: _parseDouble(map['costPrice'] ?? 0),
      unitPrice: _parseDouble(map['salePrice'] ?? 0),
      supplierName: map['supplierName'] ?? '',
      imageUrl: config.resolveMediaUrl(rawImage),
      semanticLabel: map['productName'] ?? 'Product',
    );
  }

  /// Fetch inventory from backend API
  /// Falls back to local cache if API fails
  static Future<List<StockItem>> fetchProducts() async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('⚠️ Not authenticated - using local cache');
        return await loadInventory();
      }

      final response = await _apiService.get(
        '/api/inventory/',
        fromJson: (data) => (data as List)
            .map(
              (item) => _mapInventoryToStockItem(item as Map<String, dynamic>),
            )
            .toList(),
      );

      await saveInventory(response);
      print('✅ Fetched ${response.length} inventory items from backend');
      return response;
    } catch (e) {
      print('⚠️ Failed to fetch from API: $e - Using local cache');
      return await loadInventory();
    }
  }

  /// Update product quantity on backend
  static Future<bool> updateProductQuantity(
    String productId,
    String inventoryId,
    int newQuantity,
  ) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot update inventory on backend');
        return false;
      }

      print('📤 Updating inventory on backend: $inventoryId');

      await _apiService.patch(
        '/api/inventory/$inventoryId/',
        data: {'quantity': newQuantity},
        fromJson: (data) => data,
      );

      print('✅ Inventory updated on backend');
      await fetchProducts();
      return true;
    } catch (e) {
      print('❌ Error updating inventory: $e');
      return await _updateInventoryLocal(productId, newQuantity);
    }
  }

  static Future<bool> _updateInventoryLocal(
    String productId,
    int newQuantity,
  ) async {
    try {
      final items = await loadInventory();
      final index = items.indexWhere((item) => item.id == productId);
      if (index == -1) {
        print('✗ Product not found: $productId');
        return false;
      }

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
      await saveInventory(items);
      return true;
    } catch (e) {
      print('✗ Error updating product: $e');
      return false;
    }
  }

  static Future<StockItem?> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot create product on backend');
        return null;
      }

      final imageUrl = productData['image']?.toString() ?? '';

      final productPayload = <String, dynamic>{
        'productName': productData['name'] ?? productData['productName'] ?? '',
        'description': productData['description'] ?? '',
        'skuCode': productData['sku'] ?? productData['skuCode'] ?? '',
        'unit': productData['unit'] ?? 'pcs',
        'costPrice': _parseDouble(
          productData['unitCost'] ?? productData['costPrice'] ?? 0,
        ),
        'salePrice': _parseDouble(
          productData['unitPrice'] ?? productData['salePrice'] ?? 0,
        ),
        'subcategory': productData['subcategoryId'],
        'source': productData['sourceId'],
      };
      if (imageUrl.isNotEmpty) {
        productPayload['image'] = imageUrl;
      }

      final productId = await _apiService.post(
        '/api/products/',
        data: productPayload,
        fromJson: (data) => (data as Map<String, dynamic>)['productId'] as int?,
      );

      if (productId == null) {
        print('❌ Failed to create product - no ID returned');
        return null;
      }

      final inventoryPayload = {
        'product': productId,
        'quantity': productData['quantity'] ?? 0,
        'reorderLevel': productData['reorderLevel'] ?? 10,
        'location': productData['location'] ?? 'Main Warehouse',
      };

      final response = await _apiService.post(
        '/api/inventory/',
        data: inventoryPayload,
        fromJson: (data) {
          final item = _mapInventoryToStockItem(data as Map<String, dynamic>);
          if (item.imageUrl.isEmpty && imageUrl.isNotEmpty) {
            return StockItem(
              id: productId.toString(),
              inventoryId: item.inventoryId,
              name: item.name,
              sku: item.sku,
              category: item.category,
              quantity: item.quantity,
              reorderLevel: item.reorderLevel,
              unitCost: item.unitCost,
              unitPrice: item.unitPrice,
              supplierName: item.supplierName,
              imageUrl: ConfigService().resolveMediaUrl(imageUrl),
              semanticLabel: item.semanticLabel,
            );
          }
          return StockItem(
            id: productId.toString(),
            inventoryId: item.inventoryId,
            name: item.name,
            sku: item.sku,
            category: item.category,
            quantity: item.quantity,
            reorderLevel: item.reorderLevel,
            unitCost: item.unitCost,
            unitPrice: item.unitPrice,
            supplierName: item.supplierName,
            imageUrl: item.imageUrl,
            semanticLabel: item.semanticLabel,
          );
        },
      );

      final items = await loadInventory();
      items.add(response);
      await saveInventory(items);
      return response;
    } catch (e) {
      print('❌ Error creating product: $e');
      return await _createProductLocal(productData);
    }
  }

  static Future<StockItem?> _createProductLocal(
    Map<String, dynamic> productData,
  ) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final image = productData['image']?.toString() ?? '';

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
        imageUrl: ConfigService().resolveMediaUrl(image),
        semanticLabel: productData['name'] ?? 'Product',
      );

      final items = await loadInventory();
      items.add(newItem);
      await saveInventory(items);
      return newItem;
    } catch (e) {
      print('✗ Error creating product locally: $e');
      return null;
    }
  }

  /// Update product on backend (including image URL) and sync local cache.
  static Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    var apiSucceeded = false;
    try {
      if (_apiService.isAuthenticated() && productId.isNotEmpty) {
        final payload = <String, dynamic>{};

        if (productData['name'] != null) {
          payload['productName'] = productData['name'];
        }
        if (productData['sku'] != null) {
          payload['skuCode'] = productData['sku'];
        }
        if (productData['unitCost'] != null) {
          payload['costPrice'] = productData['unitCost'];
        }
        if (productData['unitPrice'] != null) {
          payload['salePrice'] = productData['unitPrice'];
        }
        if (productData['subcategoryId'] != null) {
          payload['subcategory'] = productData['subcategoryId'];
        }
        if (productData['sourceId'] != null) {
          payload['source'] = productData['sourceId'];
        }
        if (productData['image'] != null &&
            productData['image'].toString().isNotEmpty) {
          payload['image'] = productData['image'];
        }

        if (payload.isNotEmpty) {
          print('📤 Updating product #$productId on backend: $payload');
          await _apiService.patch(
            '/api/products/$productId/',
            data: payload,
            fromJson: (data) => data,
          );
          print('✅ Product #$productId updated on backend');
        }

        // Re-fetch to sync cache with backend
        await fetchProducts();
        apiSucceeded = true;
        return true;
      }
    } catch (e) {
      print('❌ API update failed for product #$productId: $e');
      print('❌ Will fall back to local cache update only');
    }

    // Local fallback (keeps changes visible even if backend is down)
    final localResult = await _updateProductLocal(productId, productData);
    if (localResult) {
      print(
        '💾 Product #$productId updated in local cache only (API: ${apiSucceeded ? "OK" : "FAILED"})',
      );
    }
    return localResult;
  }

  static Future<bool> _updateProductLocal(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      final items = await loadInventory();
      final index = items.indexWhere((item) => item.id == productId);
      if (index == -1) {
        print('✗ Product not found: $productId');
        return false;
      }

      final image = productData['image']?.toString();
      items[index] = StockItem(
        id: items[index].id,
        inventoryId: items[index].inventoryId,
        name: productData['name'] ?? items[index].name,
        sku: productData['sku'] ?? items[index].sku,
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
        imageUrl: image != null && image.isNotEmpty
            ? ConfigService().resolveMediaUrl(image)
            : items[index].imageUrl,
        semanticLabel: items[index].semanticLabel,
      );

      await saveInventory(items);
      return true;
    } catch (e) {
      print('✗ Error updating product locally: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(String inventoryId) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot delete product on backend');
        return false;
      }

      await _apiService.delete('/api/inventory/$inventoryId/');

      final items = await loadInventory();
      items.removeWhere((item) => item.inventoryId == inventoryId);
      await saveInventory(items);
      return true;
    } catch (e) {
      print('❌ Error deleting product: $e');
      return await _deleteProductLocalByInventoryId(inventoryId);
    }
  }

  static Future<bool> _deleteProductLocalByInventoryId(String inventoryId) async {
    try {
      final items = await loadInventory();
      items.removeWhere((item) => item.inventoryId == inventoryId);
      await saveInventory(items);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveInventory(List<StockItem> items) async {
    try {
      final jsonData = items.map((item) => item.toMap()).toList();
      await _prefs.setString(_inventoryKey, jsonEncode(jsonData));
    } catch (e) {
      print('Error saving inventory: $e');
    }
  }

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

  static double _parseDouble(dynamic value) {
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
}
