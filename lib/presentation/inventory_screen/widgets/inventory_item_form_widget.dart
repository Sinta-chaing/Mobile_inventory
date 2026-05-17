import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supplier_data_service.dart';
import '../../../services/api_service.dart';
import '../../../services/user_service.dart';
import '../../../services/inventory_service.dart';
import '../../../utils/rbac_helper.dart';
import '../inventory_screen.dart';
import '../../supplier_screen/supplier_screen.dart';

class InventoryItemFormWidget extends StatefulWidget {
  final StockItem? existingItem;
  final void Function(StockItem) onSave;

  const InventoryItemFormWidget({
    super.key,
    this.existingItem,
    required this.onSave,
  });

  @override
  State<InventoryItemFormWidget> createState() =>
      _InventoryItemFormWidgetState();
}

class _InventoryItemFormWidgetState extends State<InventoryItemFormWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _canEdit = false; // Permission flag

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _quantityController;
  late TextEditingController _reorderController;
  late TextEditingController _costController;
  late TextEditingController _priceController;
  late TextEditingController _supplierController;

  String _selectedCategory = 'Power Tools';
  final List<String> _categories = [
    'Power Tools',
    'Hand Tools',
    'Safety Equipment',
    'Measuring Tools',
    'Cleaning',
    'Electrical',
    'Plumbing',
    'Other',
  ];

  // Map subcategories to main categories
  final Map<String, String> _subcategoryToCategory = {
    'Drills': 'Power Tools',
    'Saws': 'Power Tools',
    'Sanders': 'Power Tools',
    'Hammers': 'Hand Tools',
    'Wrenches': 'Hand Tools',
    'Screwdrivers': 'Hand Tools',
    'Gloves': 'Safety Equipment',
    'Eye Protection': 'Safety Equipment',
    'Respirators': 'Safety Equipment',
    'Tape Measures': 'Measuring Tools',
    'Levels': 'Measuring Tools',
    'Squares': 'Measuring Tools',
    'Cables': 'Electrical',
    'Connectors': 'Electrical',
    'Batteries': 'Electrical',
  };

  /// Map subcategory name to main category
  String _mapSubcategoryToCategory(String subcategoryName) {
    return _subcategoryToCategory[subcategoryName] ?? 'Other';
  }

  // Supplier data - initialize with empty list, will be populated in initState
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  String? _selectedSupplierId;
  bool _showSupplierDropdown = false;
  bool _supplierMissing = false;
  // Subcategory data
  List<Map<String, dynamic>> _subcategories = [];
  int? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();

    // Check edit permissions
    final rbacHelper = RbacHelper();
    _canEdit = rbacHelper.canEditProducts();

    _loadSuppliers();
    _loadSubcategories();

    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity.toString() ?? '',
    );
    _reorderController = TextEditingController(
      text: item?.reorderLevel.toString() ?? '',
    );
    _costController = TextEditingController(
      text: item?.unitCost.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: item?.unitPrice.toString() ?? '',
    );
    _supplierController = TextEditingController(text: item?.supplierName ?? '');

    // NOTE: supplier list is loaded asynchronously in _loadSuppliers().
    // Pre-selection is handled after suppliers are fetched to avoid
    // searching an empty list here.

    // Pre-select category if editing (map subcategory to main category)
    if (item != null) {
      _selectedCategory = _mapSubcategoryToCategory(item.category);
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await SupplierDataService.fetchSuppliersFromAPI();
      setState(() {
        _suppliers = suppliers;
        _filteredSuppliers = suppliers;
      });
      // If editing an existing item, try to pre-select its supplier now
      final item = widget.existingItem;
      if (item != null && item.supplierName.isNotEmpty) {
        final found = _suppliers
            .where((s) => s.name == item.supplierName)
            .toList();
        if (found.isNotEmpty) {
          final match = found.first;
          setState(() {
            _selectedSupplierId = match.id;
            _supplierController.text = match.name;
            _supplierMissing = false;
          });
        } else {
          // Supplier name exists on item but not in API — mark as missing
          setState(() {
            _selectedSupplierId = null;
            _supplierController.text = item.supplierName;
            _supplierMissing = true;
          });
        }
      }
    } catch (e) {
      print('Error loading suppliers: $e');
    }
  }

  Future<void> _loadSubcategories() async {
    try {
      final api = ApiService();
      final data = await api.get<List<dynamic>>(
        '/api/subcategories/',
        fromJson: (json) => (json as List).map((e) => e).toList(),
      );

      setState(() {
        _subcategories = data.map((s) => s as Map<String, dynamic>).toList();
      });

      // If editing an item, try to pre-select its subcategory
      final item = widget.existingItem;
      if (item != null && _selectedSubcategoryId == null) {
        // Try to find subcategory by name
        final match = _subcategories.firstWhere(
          (sc) =>
              (sc['name'] as String).toLowerCase() ==
              item.category.toLowerCase(),
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          setState(() {
            _selectedSubcategoryId = match['subcategoryId'] as int?;
          });
        }
      }
    } catch (e) {
      print('Error loading subcategories: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _reorderController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  void _filterSuppliers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers
            .where(
              (s) =>
                  (s.name.toLowerCase().contains(query.toLowerCase()) ||
                  s.category.toLowerCase().contains(query.toLowerCase())),
            )
            .toList();
      }
    });
  }

  void _selectSupplier(Supplier supplier) {
    setState(() {
      _selectedSupplierId = supplier.id;
      _supplierController.text = supplier.name;
      _showSupplierDropdown = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if user has permission to edit products
    final rbacHelper = RbacHelper();
    if (!rbacHelper.canEditProducts()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⛔ Permission denied. Only managers and admins can edit products.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isEdit = widget.existingItem != null;
      final item = StockItem(
        id:
            widget.existingItem?.id ??
            'ITM${DateTime.now().millisecondsSinceEpoch}',
        inventoryId: widget.existingItem?.inventoryId ?? '',
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().toUpperCase(),
        category: _selectedCategory,
        quantity: int.parse(_quantityController.text),
        reorderLevel: int.parse(_reorderController.text),
        unitCost: double.parse(_costController.text),
        unitPrice: double.parse(_priceController.text),
        supplierName: _supplierController.text.trim(),
        imageUrl: widget.existingItem?.imageUrl ?? '',
        semanticLabel: widget.existingItem?.semanticLabel ?? '',
      );

      // Call API to update product
      if (isEdit) {
        // Update quantity through inventory endpoint using inventoryId
        final success = await InventoryService.updateProductQuantity(
          item.id,
          item.inventoryId,
          item.quantity,
        );

        if (!mounted) return;

        if (success) {
          widget.onSave(item);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${item.name} updated successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Failed to update product. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Create new product — include supplier (source) id when available
        final Map<String, dynamic> payload = {
          'name': item.name,
          'sku': item.sku,
          'category': item.category,
          'unitCost': item.unitCost,
          'unitPrice': item.unitPrice,
          'quantity': item.quantity,
          'reorderLevel': item.reorderLevel,
          'supplierName': item.supplierName,
        };

        if (_selectedSupplierId != null &&
            _selectedSupplierId != 'custom' &&
            _selectedSupplierId!.isNotEmpty) {
          final sid = int.tryParse(_selectedSupplierId!);
          payload['source'] = sid ?? _selectedSupplierId;
        }

        final newProduct = await InventoryService.createProduct(payload);

        if (!mounted) return;

        if (newProduct != null) {
          widget.onSave(newProduct);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${item.name} added to inventory'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Failed to create product. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      print('Error saving product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  isEdit ? 'Edit Item' : 'Add New Item',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1B),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.outline,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Item Details'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name *',
                        hintText: 'e.g. DeWalt 20V Cordless Drill',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skuController,
                            decoration: const InputDecoration(
                              labelText: 'SKU *',
                              hintText: 'e.g. DW-001',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'SKU required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category *',
                            ),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _selectedCategory = v ?? _selectedCategory,
                            ),
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              color: const Color(0xFF1A1C1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Stock Levels'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Qty on Hand *',
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _reorderController,
                            decoration: const InputDecoration(
                              labelText: 'Reorder Level *',
                              hintText: '10',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Pricing'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(
                              labelText: 'Unit Cost (\$) *',
                              hintText: '0.00',
                              prefixText: '\$ ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Selling Price (\$) *',
                              hintText: '0.00',
                              prefixText: '\$ ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Supplier'),
                    const SizedBox(height: 10),
                    _buildSupplierSearchField(),
                    const SizedBox(height: 12),
                    _buildSectionLabel('Subcategory'),
                    const SizedBox(height: 10),
                    _buildSubcategoryField(),
                    const SizedBox(height: 28),

                    // Permission warning (if no permission)
                    if (!_canEdit)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Only managers and admins can edit inventory',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isSaving || !_canEdit) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canEdit
                              ? AppTheme.primary
                              : Colors.grey,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _canEdit
                                    ? (isEdit
                                          ? 'Save Changes'
                                          : 'Add to Inventory')
                                    : 'No Permission',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _canEdit
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.ibmPlexSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.outline,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSupplierSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and select field
        TextFormField(
          controller: _supplierController,
          onChanged: (value) {
            _filterSuppliers(value);
            setState(() => _showSupplierDropdown = value.isNotEmpty);
          },
          onTap: () {
            setState(() => _showSupplierDropdown = true);
            if (_supplierController.text.isEmpty) {
              _filterSuppliers('');
            }
          },
          decoration: InputDecoration(
            labelText: 'Supplier Name *',
            hintText: 'Search or select supplier...',
            prefixIcon: const Icon(Icons.local_shipping_outlined, size: 18),
            suffixIcon: _supplierController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _supplierController.clear();
                        _selectedSupplierId = null;
                        _showSupplierDropdown = false;
                      });
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.done,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Supplier is required' : null,
        ),
        // Dropdown suggestions
        if (_showSupplierDropdown && _filteredSuppliers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.outline),
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.surface,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredSuppliers.length,
                itemBuilder: (context, index) {
                  final supplier = _filteredSuppliers[index];
                  final isSelected = _selectedSupplierId == supplier.id;
                  return Material(
                    child: InkWell(
                      onTap: () => _selectSupplier(supplier),
                      child: Container(
                        color: isSelected ? AppTheme.outlineVariant : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplier.name,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1C1B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    supplier.category,
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      color: AppTheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (supplier.rating > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Chip(
                                  label: Text(
                                    '${supplier.rating}★',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFFFF3E0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else if (_showSupplierDropdown && _filteredSuppliers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                'No suppliers found in the backend. Please add the supplier in the Suppliers screen before selecting it here.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  color: AppTheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

        if (_supplierMissing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'This supplier is not present in the backend. Open Suppliers and add it to link to a product.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: Colors.orange[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubcategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: _selectedSubcategoryId,
          decoration: const InputDecoration(labelText: 'Subcategory *'),
          items: _subcategories
              .map(
                (sc) => DropdownMenuItem<int>(
                  value: sc['subcategoryId'] as int,
                  child: Text(sc['name'] ?? ''),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedSubcategoryId = v),
          validator: (v) => v == null ? 'Subcategory is required' : null,
        ),
        if (_subcategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Loading subcategories...',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}
