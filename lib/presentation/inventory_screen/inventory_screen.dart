import 'package:flutter/material.dart';
import 'dart:ui';

import '../../routes/app_routes.dart';
import '../../services/inventory_service.dart';
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
  bool _isLoading = true;

  late List<StockItem> _items;

  // Unused mock data - removed to fix analyzer warning
  // static final List<Map<String, dynamic>> _itemMaps = [ ... ];

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
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final items = await InventoryService.loadInventory();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading inventory: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshInventory() async {
    setState(() {
      _isLoading = true;
    });
    await _loadInventory();
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          onRefresh: _refreshInventory,
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
                onRefresh: _refreshInventory,
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
