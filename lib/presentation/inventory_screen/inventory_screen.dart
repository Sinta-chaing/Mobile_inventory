import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_routes.dart';
import '../../services/inventory_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import './widgets/inventory_app_bar_widget.dart';
import './widgets/inventory_item_form_widget.dart';
import './widgets/inventory_list_widget.dart';
import './widgets/inventory_search_filter_widget.dart';
import './widgets/inventory_stats_strip_widget.dart';
import './widgets/image_crop_screen.dart';

// Stock item model
enum StockStatusEnum { inStock, lowStock, outOfStock }

class StockItem {
  final String id; // Product ID
  final String inventoryId; // Inventory ID (used for API updates)
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
    required this.inventoryId,
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
      inventoryId:
          map['inventoryId'] as String? ??
          '', // Use first inventory ID if available
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
      'inventoryId': inventoryId,
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
  bool _isImageSearchActive = false;
  final Set<int> _imageSearchProductIds = {};
  List<Map<String, dynamic>>? _searchDetections;
  double _searchThreshold = 0.3;
  XFile? _lastSearchImage;
  final Map<int, double> _productScores = {};

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
      // Fetch products from local storage
      final items = await InventoryService.fetchProducts();
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
      if (!matchesSearch) return false;
      if (_isImageSearchActive) {
        return _imageSearchProductIds.contains(int.tryParse(item.id) ?? -1);
      }
      return true;
    }).toList();
  }

  Future<void> _performImageSearch() async {
    // Step 1: Pick image source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search by Image',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked == null || !mounted) return;
    _lastSearchImage = picked;

    // Step 2: Show search settings with threshold slider + mode
    double threshold = _searchThreshold;
    String? mode;
    final settingsResult = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SearchSettingsSheet(initialThreshold: threshold),
    );
    if (settingsResult == null || !mounted) return;
    mode = settingsResult['mode'] as String;
    threshold = settingsResult['threshold'] as double;

    Map<String, int>? cropCoords;
    if (mode == 'draw') {
      final cropRect = await Navigator.push<Rect>(
        context,
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(imageFile: picked),
          fullscreenDialog: true,
        ),
      );
      if (!mounted) return;
      if (cropRect != null) {
        cropCoords = {
          'x1': cropRect.left.toInt(),
          'y1': cropRect.top.toInt(),
          'x2': cropRect.right.toInt(),
          'y2': cropRect.bottom.toInt(),
        };
      }
    }

    setState(() {
      _isImageSearchActive = true;
      _imageSearchProductIds.clear();
      _searchDetections = [];
      _productScores.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Searching by image...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    final result = await InventoryService.searchProductsByImage(
      picked,
      cropRect: cropCoords,
      scoreThreshold: threshold,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final ids = (result['productIds'] as List).cast<int>();
    final scores = (result['scores'] as List?)?.cast<double>() ?? <double>[];
    final detections = (result['detections'] as List).cast<Map<String, dynamic>>();

    setState(() {
      _searchThreshold = threshold;
      _imageSearchProductIds.addAll(ids);
      for (int i = 0; i < ids.length && i < scores.length; i++) {
        _productScores[ids[i]] = scores[i];
      }
      _searchDetections = detections;
    });

    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching products found')),
      );
    }
  }

  Future<void> _reSearch(XFile image) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SearchSettingsSheet(
        initialThreshold: _searchThreshold,
      ),
    );
    if (result == null || !mounted) return;
    final threshold = result['threshold'] as double;

    setState(() {
      _imageSearchProductIds.clear();
      _searchDetections = [];
      _productScores.clear();
      _searchThreshold = threshold;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Re-searching...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    final searchResult = await InventoryService.searchProductsByImage(
      image,
      scoreThreshold: threshold,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final ids = (searchResult['productIds'] as List).cast<int>();
    final scores = (searchResult['scores'] as List?)?.cast<double>() ?? <double>[];
    final detections = (searchResult['detections'] as List).cast<Map<String, dynamic>>();

    setState(() {
      _imageSearchProductIds.addAll(ids);
      for (int i = 0; i < ids.length && i < scores.length; i++) {
        _productScores[ids[i]] = scores[i];
      }
      _searchDetections = detections;
    });
  }

  void _clearImageSearch() {
    setState(() {
      _isImageSearchActive = false;
      _imageSearchProductIds.clear();
      _searchDetections = [];
      _productScores.clear();
    });
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

    // Call API to delete from backend
    _deleteItemFromBackend(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} removed from inventory'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppTheme.primaryLight,
          onPressed: () {
            setState(() => _items.add(item));
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _deleteItemFromBackend(StockItem item) async {
    try {
      final success = await InventoryService.deleteProduct(item.inventoryId);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${item.name} deleted from backend'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Re-add the item if deletion failed
        setState(() => _items.add(item));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Failed to delete ${item.name}. Item restored.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Re-add the item if there was an error
      setState(() => _items.add(item));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Error deleting item: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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

  int get _imageMatchedCount => _items.where(
    (item) => _imageSearchProductIds.contains(int.tryParse(item.id) ?? -1),
  ).length;

  String get _detectionLabels {
    final dets = _searchDetections;
    if (dets == null || dets.isEmpty) return '';
    final names = dets.map((d) => d['class_name'] as String).toSet().toList();
    return 'Detected: ${names.join(', ')}';
  }

  Widget _buildImageSearchBanner() {
    if (!_isImageSearchActive) return const SizedBox.shrink();
    final matched = _imageMatchedCount;
    final labels = _detectionLabels;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_search_rounded, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  matched == 0
                      ? 'No matches found'
                      : '$matched product${matched == 1 ? '' : 's'} matched',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                if (labels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      labels,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_searchThreshold.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
              SizedBox(
                height: 22,
                width: 22,
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  color: AppTheme.primary,
                  padding: EdgeInsets.zero,
                  onPressed: _lastSearchImage != null ? () => _reSearch(_lastSearchImage!) : null,
                  tooltip: 'Adjust threshold',
                ),
              ),
            ],
          ),
          SizedBox(
            height: 28,
            width: 28,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              color: AppTheme.primary,
              padding: EdgeInsets.zero,
              onPressed: _clearImageSearch,
            ),
          ),
        ],
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
          onImageSearch: _performImageSearch,
        ),
        _buildImageSearchBanner(),
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
                onImageSearch: _performImageSearch,
              ),
              _buildImageSearchBanner(),
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

class _SearchSettingsSheet extends StatefulWidget {
  final double initialThreshold;
  const _SearchSettingsSheet({required this.initialThreshold});

  @override
  State<_SearchSettingsSheet> createState() => _SearchSettingsSheetState();
}

class _SearchSettingsSheetState extends State<_SearchSettingsSheet> {
  late double _threshold;

  @override
  void initState() {
    super.initState();
    _threshold = widget.initialThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search Settings',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Similarity Threshold',
                          style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _threshold.toStringAsFixed(2),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _threshold,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: AppTheme.primary,
                      label: _threshold.toStringAsFixed(2),
                      onChanged: (v) => setState(() => _threshold = v),
                    ),
                    Text(
                      _threshold < 0.3
                          ? 'Lower = more results, less precise'
                          : _threshold > 0.7
                              ? 'Higher = fewer results, more precise'
                              : 'Balanced accuracy',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.auto_fix_high_rounded, color: AppTheme.primary),
                title: const Text('Auto Detect'),
                subtitle: const Text('Let AI find objects automatically'),
                onTap: () => Navigator.pop(context, {'mode': 'auto', 'threshold': _threshold}),
              ),
              ListTile(
                leading: const Icon(Icons.draw_rounded, color: AppTheme.primary),
                title: const Text('Draw Object'),
                subtitle: const Text('Manually select the object area'),
                onTap: () => Navigator.pop(context, {'mode': 'draw', 'threshold': _threshold}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
