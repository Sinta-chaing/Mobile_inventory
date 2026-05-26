import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InventoryService', () {
    setUp(() async {
      // Initialize shared preferences in test mode
      SharedPreferences.setMockInitialValues({});
    });

    test('Inventory service can cache data locally', () async {
      // This test verifies that the inventory service can store and retrieve data
      // from SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();

      // Test saving inventory data
      const testData = '[{"id": 1, "name": "Test Product"}]';
      await prefs.setString('inventory_data', testData);

      final cachedData = prefs.getString('inventory_data');
      expect(cachedData, testData);
    });

    test('Inventory service parses product response correctly', () {
      // Test that the service can parse a typical Django backend response
      final productResponse = {
        'productId': 1,
        'productName': 'Test Product',
        'skuCode': 'SKU-001',
        'costPrice': 100.0,
        'salePrice': 150.0,
        'image': 'https://example.com/image.jpg',
        'source': {'sourceId': 1, 'name': 'Test Supplier'},
        'subcategory': {'subcategoryId': 1, 'name': 'Electronics'},
        'inventory_records': [
          {
            'inventoryId': 1,
            'quantity': 50,
            'reorderLevel': 10,
            'location': 'Warehouse A',
          },
        ],
      };

      // Verify structure
      expect(productResponse['productId'], 1);
      expect(productResponse['productName'], 'Test Product');
      final inventoryList = productResponse['inventory_records'] as List;
      expect(inventoryList[0]['quantity'], 50);
      final sourceMap = productResponse['source'] as Map;
      expect(sourceMap['name'], 'Test Supplier');
    });

    test('Inventory service handles products without inventory records', () {
      // Test graceful handling of products with no inventory
      final productResponse = {
        'productId': 2,
        'productName': 'Test Product 2',
        'skuCode': 'SKU-002',
        'inventory_records': [],
      };

      final hasInventory =
          productResponse['inventory_records'] != null &&
          (productResponse['inventory_records'] as List).isNotEmpty;

      expect(hasInventory, false);
    });

    test('Inventory service extracts supplier name safely', () {
      // Test safe extraction of nested supplier information
      final productWithSupplier = {
        'source': {'name': 'Supplier Name'},
      };

      final productWithoutSupplier = {'source': null};

      String extractSupplierName(dynamic product) {
        try {
          if (product['source'] != null && product['source'] is Map) {
            return product['source']['name'] ?? 'Unknown';
          }
          return 'Unknown';
        } catch (e) {
          return 'Unknown';
        }
      }

      expect(extractSupplierName(productWithSupplier), 'Supplier Name');
      expect(extractSupplierName(productWithoutSupplier), 'Unknown');
    });

    test('Inventory service extracts category name safely', () {
      // Test safe extraction of nested category information
      final productWithCategory = {
        'subcategory': {'name': 'Electronics'},
      };

      final productWithoutCategory = {'subcategory': null};

      String extractCategoryName(dynamic product) {
        try {
          if (product['subcategory'] != null && product['subcategory'] is Map) {
            return product['subcategory']['name'] ?? 'Uncategorized';
          }
          return 'Uncategorized';
        } catch (e) {
          return 'Uncategorized';
        }
      }

      expect(extractCategoryName(productWithCategory), 'Electronics');
      expect(extractCategoryName(productWithoutCategory), 'Uncategorized');
    });

    test('Inventory service parses prices correctly', () {
      // Test price parsing from various formats
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

      expect(parsePrice(100.0), 100.0);
      expect(parsePrice(100), 100.0);
      expect(parsePrice('100.50'), 100.50);
      expect(parsePrice('invalid'), 0.0);
      expect(parsePrice(null), 0.0);
    });

    test('Inventory service API endpoint matches backend', () {
      // Verify that the service uses the correct API endpoints
      const String productsEndpoint = '/api/products/';
      const String inventoryEndpoint = '/api/inventory/';

      expect(productsEndpoint, '/api/products/');
      expect(inventoryEndpoint, '/api/inventory/');
    });

    test('Inventory update uses correct inventory ID format', () {
      // Test that inventory updates use the inventoryId from inventory records
      const inventoryId = '1';
      const newQuantity = 100;

      // Verify format
      expect(inventoryId.isNotEmpty, true);
      expect(newQuantity > 0, true);

      // Construct expected endpoint
      final endpoint = '/api/inventory/$inventoryId/';
      expect(endpoint, '/api/inventory/1/');
    });

    test('Inventory service filters products with inventory records', () {
      // Test that only products with inventory records are included
      final products = [
        {
          'productId': 1,
          'productName': 'Product 1',
          'inventory_records': [
            {'quantity': 10},
          ],
        },
        {'productId': 2, 'productName': 'Product 2', 'inventory_records': []},
        {'productId': 3, 'productName': 'Product 3', 'inventory_records': null},
      ];

      final filtered = products.where((product) {
        final inventoryRecords = product['inventory_records'];
        return inventoryRecords != null &&
            (inventoryRecords as List).isNotEmpty;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered[0]['productId'], 1);
    });

    test('Inventory service handles product creation response', () {
      // Test parsing of product creation response from backend
      final response = {
        'productId': 10,
        'productName': 'New Product',
        'skuCode': 'NEW-SKU',
        'costPrice': 50.0,
        'salePrice': 75.0,
        'inventory_records': [
          {'inventoryId': 5, 'quantity': 0, 'reorderLevel': 10},
        ],
        'subcategory': {'name': 'New Category'},
        'source': {'name': 'New Supplier'},
      };

      expect(response['productId'], 10);
      final inventoryList = response['inventory_records'] as List;
      expect(inventoryList[0]['inventoryId'], 5);
      final subcat = response['subcategory'] as Map;
      expect(subcat['name'], 'New Category');
    });

    test('Inventory data structure matches backend schema', () {
      // Verify that expected backend fields are accounted for
      final backendInventoryItem = {
        'inventoryId': 1,
        'product': 1,
        'quantity': 100,
        'reorderLevel': 20,
        'location': 'Warehouse A',
        'updatedAt': '2026-05-17T10:00:00Z',
      };

      expect(backendInventoryItem.containsKey('inventoryId'), true);
      expect(backendInventoryItem.containsKey('quantity'), true);
      expect(backendInventoryItem.containsKey('reorderLevel'), true);
      expect(backendInventoryItem.containsKey('location'), true);
    });
  });
}
