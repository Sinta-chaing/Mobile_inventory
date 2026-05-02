import 'package:flutter/material.dart';
import 'dart:ui';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import './widgets/inventory_app_bar_widget.dart';
import './widgets/inventory_item_form_widget.dart';
import './widgets/inventory_list_widget.dart';
import './widgets/inventory_search_filter_widget.dart';
import './widgets/inventory_stats_strip_widget.dart';

// Stock item model
enum StockStatusEnum { inStock, lowStock, outOfStock }

class StockItem {
  final String id;
  final String name;
  final String sku;
  final String category;
  int quantity;
  final int reorderLevel;
  final double unitCost;
  final double unitPrice;
  final String supplierName;
  final String imageUrl;
  final String semanticLabel;

  StockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.unitCost,
    required this.unitPrice,
    required this.supplierName,
    required this.imageUrl,
    required this.semanticLabel,
  });

  StockStatusEnum get status {
    if (quantity == 0) return StockStatusEnum.outOfStock;
    if (quantity <= reorderLevel) return StockStatusEnum.lowStock;
    return StockStatusEnum.inStock;
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as String,
      name: map['name'] as String,
      sku: map['sku'] as String,
      category: map['category'] as String,
      quantity: map['quantity'] as int,
      reorderLevel: map['reorderLevel'] as int,
      unitCost: (map['unitCost'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      supplierName: map['supplierName'] as String,
      imageUrl: map['imageUrl'] as String,
      semanticLabel: map['semanticLabel'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'quantity': quantity,
      'reorderLevel': reorderLevel,
      'unitCost': unitCost,
      'unitPrice': unitPrice,
      'supplierName': supplierName,
      'imageUrl': imageUrl,
      'semanticLabel': semanticLabel,
    };
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  final bool _isLoading = false;

  late List<StockItem> _items;

  static final List<Map<String, dynamic>> _itemMaps = [
    {
      'id': 'ITM001',
      'name': 'DeWalt 20V Cordless Drill',
      'sku': 'DW-DCD771C2',
      'category': 'Power Tools',
      'quantity': 34,
      'reorderLevel': 10,
      'unitCost': 89.50,
      'unitPrice': 149.99,
      'supplierName': 'ProTools Supply Co.',
      'imageUrl':
          'https://images.unsplash.com/photo-1572981779307-38b8cabb2407',
      'semanticLabel':
          'Yellow and black DeWalt cordless drill on white background',
    },
    {
      'id': 'ITM002',
      'name': 'Stanley FatMax Tape Measure 25ft',
      'sku': 'ST-FMHT33865',
      'category': 'Hand Tools',
      'quantity': 7,
      'reorderLevel': 15,
      'unitCost': 12.40,
      'unitPrice': 24.99,
      'supplierName': 'Meridian Hardware Dist.',
      'imageUrl':
          'https://images.unsplash.com/photo-1706101426222-feb156e9c7fe',
      'semanticLabel': 'Yellow Stanley tape measure coiled on wooden surface',
    },
    {
      'id': 'ITM003',
      'name': 'Makita Angle Grinder 4.5"',
      'sku': 'MK-9557PBX1',
      'category': 'Power Tools',
      'quantity': 0,
      'reorderLevel': 5,
      'unitCost': 54.00,
      'unitPrice': 99.95,
      'supplierName': 'ProTools Supply Co.',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1da2285a0-1773143783458.png',
      'semanticLabel':
          'Teal and black Makita angle grinder on concrete surface',
    },
    {
      'id': 'ITM004',
      'name': 'Bosch 18V Circular Saw',
      'sku': 'BS-CCS180B',
      'category': 'Power Tools',
      'quantity': 18,
      'reorderLevel': 8,
      'unitCost': 112.00,
      'unitPrice': 189.00,
      'supplierName': 'ProTools Supply Co.',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_16e4aa9e0-1772558496349.png',
      'semanticLabel': 'Blue Bosch circular saw on workshop bench',
    },
    {
      'id': 'ITM005',
      'name': 'Irwin 10" Adjustable Wrench',
      'sku': 'IW-2078609',
      'category': 'Hand Tools',
      'quantity': 52,
      'reorderLevel': 20,
      'unitCost': 8.75,
      'unitPrice': 18.49,
      'supplierName': 'Meridian Hardware Dist.',
      'imageUrl':
          'https://images.unsplash.com/photo-1611288875785-f62fb9b044a7',
      'semanticLabel': 'Silver adjustable wrench on grey background',
    },
    {
      'id': 'ITM006',
      'name': 'Milwaukee M18 Impact Driver',
      'sku': 'MW-2853-20',
      'category': 'Power Tools',
      'quantity': 5,
      'reorderLevel': 6,
      'unitCost': 135.00,
      'unitPrice': 219.00,
      'supplierName': 'ProTools Supply Co.',
      'imageUrl':
          'https://images.unsplash.com/photo-1716662383104-1dcc763a916d',
      'semanticLabel': 'Red Milwaukee impact driver on black background',
    },
    {
      'id': 'ITM007',
      'name': '3M Safety Glasses Clear Lens',
      'sku': '3M-11326-00000',
      'category': 'Safety',
      'quantity': 120,
      'reorderLevel': 30,
      'unitCost': 2.10,
      'unitPrice': 5.99,
      'supplierName': 'SafeGuard Industrial',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1e2f1668c-1765046533347.png',
      'semanticLabel': 'Clear protective safety glasses on white surface',
    },
    {
      'id': 'ITM008',
      'name': 'Klein Tools Level 24"',
      'sku': 'KL-935-24',
      'category': 'Measuring',
      'quantity': 4,
      'reorderLevel': 8,
      'unitCost': 22.00,
      'unitPrice': 42.99,
      'supplierName': 'Meridian Hardware Dist.',
      'imageUrl':
          'https://images.unsplash.com/photo-1696423284373-d836682ed2d0',
      'semanticLabel':
          'Yellow spirit level on wooden plank in construction site',
    },
    {
      'id': 'ITM009',
      'name': 'Gorilla Heavy Duty Work Gloves',
      'sku': 'GR-71594-M',
      'category': 'Safety',
      'quantity': 88,
      'reorderLevel': 25,
      'unitCost': 7.20,
      'unitPrice': 14.99,
      'supplierName': 'SafeGuard Industrial',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1027589a6-1774332019892.png',
      'semanticLabel':
          'Orange and black heavy duty work gloves on white background',
    },
    {
      'id': 'ITM010',
      'name': 'Ridgid Pipe Wrench 14"',
      'sku': 'RD-31030',
      'category': 'Hand Tools',
      'quantity': 22,
      'reorderLevel': 10,
      'unitCost': 31.50,
      'unitPrice': 58.00,
      'supplierName': 'Meridian Hardware Dist.',
      'imageUrl':
          'https://images.unsplash.com/photo-1529836349180-223cd77d8cb6',
      'semanticLabel':
          'Orange Ridgid pipe wrench on dark industrial background',
    },
    {
      'id': 'ITM011',
      'name': 'Fluke Digital Multimeter',
      'sku': 'FL-117-KIT',
      'category': 'Measuring',
      'quantity': 11,
      'reorderLevel': 5,
      'unitCost': 68.00,
      'unitPrice': 119.00,
      'supplierName': 'ElectroMart Supplies',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15ec1cdcf-1770142869318.png',
      'semanticLabel': 'Yellow Fluke digital multimeter with test probes',
    },
    {
      'id': 'ITM012',
      'name': 'Ridgid Shop Vac 9-Gallon',
      'sku': 'RD-WD09700',
      'category': 'Cleaning',
      'quantity': 3,
      'reorderLevel': 4,
      'unitCost': 58.00,
      'unitPrice': 109.99,
      'supplierName': 'Meridian Hardware Dist.',
      'imageUrl': 'https://images.unsplash.com/photo-1560833411-6889bf875858',
      'semanticLabel': 'Red and black shop vacuum cleaner in warehouse setting',
    },
  ];

  final List<String> _categories = [
    'All',
    'Power Tools',
    'Hand Tools',
    'Safety',
    'Measuring',
    'Cleaning',
  ];

  @override
  void initState() {
    super.initState();
    _items = _itemMaps.map(StockItem.fromMap).toList();
  }

  List<StockItem> get _filteredItems {
    return _items.where((item) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.purchaseScreen);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.customerScreen);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.supplierScreen);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.biDashboardScreen);
        break;
    }
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InventoryItemFormWidget(
        onSave: (newItem) {
          setState(() => _items.insert(0, newItem));
        },
      ),
    );
  }

  void _showEditItemSheet(StockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InventoryItemFormWidget(
        existingItem: item,
        onSave: (updatedItem) {
          setState(() {
            final idx = _items.indexWhere((i) => i.id == updatedItem.id);
            if (idx != -1) _items[idx] = updatedItem;
          });
        },
      ),
    );
  }

  void _deleteItem(StockItem item) {
    setState(() => _items.removeWhere((i) => i.id == item.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} removed from inventory'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppTheme.primaryLight,
          onPressed: () => setState(() => _items.add(item)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
      bottomNavigationBar: isTablet
          ? null
          : ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(220),
                      borderRadius: BorderRadius.circular(20),
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.outlineVariant.withAlpha(100),
                          width: 1,
                        ),
                      ),
                    ),
                    child: AppNavigation(
                      currentIndex: _selectedNavIndex,
                      onDestinationSelected: _onNavTap,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      children: [
        InventoryAppBarWidget(
          itemCount: _filteredItems.length,
          totalValue: _items.fold(
            0.0,
            (sum, item) => sum + item.unitCost * item.quantity,
          ),
        ),
        InventoryStatsStripWidget(items: _items),
        InventorySearchFilterWidget(
          searchQuery: _searchQuery,
          categories: _categories,
          onSearchChanged: (q) => setState(() => _searchQuery = q),
          onAddItem: _showAddItemSheet,
          onImageSearch: () {
            // Image search functionality will be implemented later
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image search coming soon!')),
            );
          },
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : InventoryListWidget(
                  items: _filteredItems,
                  onEdit: _showEditItemSheet,
                  onDelete: _deleteItem,
                ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        AppNavigationRail(
          currentIndex: _selectedNavIndex,
          onDestinationSelected: _onNavTap,
        ),
        Container(width: 1, color: AppTheme.outlineVariant),
        Expanded(
          child: Column(
            children: [
              InventoryAppBarWidget(
                itemCount: _filteredItems.length,
                totalValue: _items.fold(
                  0.0,
                  (sum, item) => sum + item.unitCost * item.quantity,
                ),
              ),
              InventoryStatsStripWidget(items: _items),
              InventorySearchFilterWidget(
                searchQuery: _searchQuery,
                categories: _categories,
                onSearchChanged: (q) => setState(() => _searchQuery = q),
                onAddItem: _showAddItemSheet,
                onImageSearch: () {
                  // Image search functionality will be implemented later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image search coming soon!')),
                  );
                },
              ),
              Expanded(
                child: InventoryListWidget(
                  items: _filteredItems,
                  onEdit: _showEditItemSheet,
                  onDelete: _deleteItem,
                  isTablet: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
