import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/inventory_screen/inventory_screen.dart';

class InventoryService {
  static const String _inventoryKey = 'inventory_data';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static List<StockItem> _getInitialMockData() {
    return [
      StockItem(
        id: 'ITM001',
        name: 'DeWalt 20V Cordless Drill',
        sku: 'DW-DCD771C2',
        category: 'Power Tools',
        quantity: 34,
        reorderLevel: 10,
        unitCost: 89.50,
        unitPrice: 149.99,
        supplierName: 'ProTools Supply Co.',
        imageUrl:
            'https://images.unsplash.com/photo-1572981779307-38b8cabb2407',
        semanticLabel:
            'Yellow and black DeWalt cordless drill on white background',
      ),
      StockItem(
        id: 'ITM002',
        name: 'Stanley FatMax Tape Measure 25ft',
        sku: 'ST-FMHT33865',
        category: 'Hand Tools',
        quantity: 7,
        reorderLevel: 15,
        unitCost: 12.40,
        unitPrice: 24.99,
        supplierName: 'Meridian Hardware Dist.',
        imageUrl:
            'https://images.unsplash.com/photo-1706101426222-feb156e9c7fe',
        semanticLabel: 'Yellow Stanley tape measure coiled on wooden surface',
      ),
      StockItem(
        id: 'ITM003',
        name: 'Makita Angle Grinder 4.5"',
        sku: 'MK-9557PBX1',
        category: 'Power Tools',
        quantity: 0,
        reorderLevel: 5,
        unitCost: 54.00,
        unitPrice: 99.95,
        supplierName: 'ProTools Supply Co.',
        imageUrl:
            'https://img.rocket.new/generatedImages/rocket_gen_img_1da2285a0-1773143783458.png',
        semanticLabel:
            'Teal and black Makita angle grinder on concrete surface',
      ),
      StockItem(
        id: 'ITM004',
        name: 'Bosch 18V Circular Saw',
        sku: 'BS-CCS180B',
        category: 'Power Tools',
        quantity: 18,
        reorderLevel: 8,
        unitCost: 112.00,
        unitPrice: 199.99,
        supplierName: 'ProTools Supply Co.',
        imageUrl:
            'https://images.unsplash.com/photo-1587210019033-d2c0cf35fde2',
        semanticLabel:
            'Blue Bosch circular saw with black base on wooden surface',
      ),
      StockItem(
        id: 'ITM005',
        name: '3M Safety Glasses',
        sku: '3M-90966-80025',
        category: 'Safety Equipment',
        quantity: 200,
        reorderLevel: 50,
        unitCost: 1.20,
        unitPrice: 2.50,
        supplierName: 'SafeGuard Industrial',
        imageUrl:
            'https://images.unsplash.com/photo-1572981779307-38b8cabb2407',
        semanticLabel: 'Clear 3M safety glasses on white background',
      ),
      StockItem(
        id: 'ITM006',
        name: 'Work Gloves',
        sku: 'WG-LEATHER-LG',
        category: 'Safety Equipment',
        quantity: 150,
        reorderLevel: 30,
        unitCost: 3.50,
        unitPrice: 8.99,
        supplierName: 'SafeGuard Industrial',
        imageUrl:
            'https://images.unsplash.com/photo-1572981779307-38b8cabb2407',
        semanticLabel: 'Brown leather work gloves on white background',
      ),
    ];
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
        final initialData = _getInitialMockData();
        await saveInventory(initialData);
        return initialData;
      }
      final jsonData = jsonDecode(jsonString) as List;
      return jsonData
          .map((item) => StockItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading inventory: $e');
      return _getInitialMockData();
    }
  }
}
