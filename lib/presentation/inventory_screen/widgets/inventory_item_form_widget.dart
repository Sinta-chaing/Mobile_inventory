import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../services/config_service.dart';
import '../../../widgets/picked_image_preview.dart';
import '../../../services/supplier_data_service.dart';
import '../../../services/api_service.dart';
import '../../../services/inventory_service.dart';
import '../../../services/category_data_service.dart';
import '../../../utils/rbac_helper.dart';
import '../../../models/all_models.dart' as backend;
import '../inventory_screen.dart';

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

  List<backend.Category> _categories = [];
  List<backend.SubCategory> _subcategories = [];
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  bool _loadingCategories = true;

  // Supplier data - initialize with empty list, will be populated in initState
  List<backend.Source> _suppliers = [];
  List<backend.Source> _filteredSuppliers = [];
  int? _selectedSupplierId;
  bool _showSupplierDropdown = false;
  bool _supplierMissing = false;

  List<backend.SubCategory> get _filteredSubcategories {
    if (_selectedCategoryId == null) return [];
    return _subcategories
        .where((sc) => sc.categoryId == _selectedCategoryId)
        .toList();
  }

  // Image picker data (XFile + bytes — works on web and mobile)
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedStatus = 'Active';

  @override
  void initState() {
    super.initState();

    // Check edit permissions
    final rbacHelper = RbacHelper();
    _canEdit = rbacHelper.canEditProducts();

    _loadSuppliers();
    _loadCategoryData();

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
    _selectedStatus = item?.productStatus ?? 'Active';
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await SupplierDataService.fetchSuppliers();
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
            _selectedSupplierId = match.sourceId;
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

  Future<void> _loadCategoryData() async {
    setState(() => _loadingCategories = true);
    try {
      final results = await Future.wait([
        CategoryDataService.fetchCategories(),
        CategoryDataService.fetchSubcategories(),
      ]);
      final categories = results[0] as List<backend.Category>;
      final subcategories = results[1] as List<backend.SubCategory>;

      int? categoryId = _selectedCategoryId;
      int? subcategoryId = _selectedSubcategoryId;

      final item = widget.existingItem;
      if (item != null && subcategoryId == null) {
        final match = subcategories.where(
          (sc) => sc.name.toLowerCase() == item.category.toLowerCase(),
        );
        if (match.isNotEmpty) {
          final sc = match.first;
          subcategoryId = sc.subcategoryId;
          categoryId = sc.categoryId;
        }
      }

      if (categoryId == null && categories.isNotEmpty) {
        categoryId = categories.first.categoryId;
      }

      if (subcategoryId != null &&
          !subcategories.any((sc) => sc.subcategoryId == subcategoryId)) {
        subcategoryId = null;
      }

      if (subcategoryId == null && categoryId != null) {
        final forCategory = subcategories
            .where((sc) => sc.categoryId == categoryId)
            .toList();
        if (forCategory.isNotEmpty) {
          subcategoryId = forCategory.first.subcategoryId;
        }
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _subcategories = subcategories;
        _selectedCategoryId = categoryId;
        _selectedSubcategoryId = subcategoryId;
        _loadingCategories = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  String? _selectedSubcategoryName() {
    if (_selectedSubcategoryId == null) return null;
    for (final sc in _subcategories) {
      if (sc.subcategoryId == _selectedSubcategoryId) return sc.name;
    }
    return null;
  }

  String? _selectedCategoryName() {
    if (_selectedCategoryId == null) return null;
    for (final cat in _categories) {
      if (cat.categoryId == _selectedCategoryId) return cat.name;
    }
    return null;
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final created = await showDialog<backend.Category>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category name',
            hintText: 'e.g. Power Tools',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                final category = await CategoryDataService.createCategory(name);
                if (ctx.mounted) Navigator.pop(ctx, category);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add category: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || created == null) return;
    setState(() {
      _categories = [..._categories, created];
      _selectedCategoryId = created.categoryId;
      _selectedSubcategoryId = null;
    });
  }

  Future<void> _showAddSubcategoryDialog() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a category first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final created = await showDialog<backend.SubCategory>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subcategory'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subcategory name',
            hintText: 'e.g. Drills',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                final subcategory = await CategoryDataService.createSubcategory(
                  name: name,
                  categoryId: _selectedCategoryId!,
                );
                if (ctx.mounted) Navigator.pop(ctx, subcategory);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add subcategory: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || created == null) return;
    setState(() {
      _subcategories = [..._subcategories, created];
      _selectedSubcategoryId = created.subcategoryId;
    });
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
                  (s.address?.toLowerCase().contains(query.toLowerCase()) ??
                      false)),
            )
            .toList();
      }
    });
  }

  void _selectSupplier(backend.Source supplier) {
    setState(() {
      _selectedSupplierId = supplier.sourceId;
      _supplierController.text = supplier.name;
      _showSupplierDropdown = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await readImageBytes(pickedFile);
        if (!mounted) return;
        if (bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read the selected image'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          _selectedImage = pickedFile;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
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

      if (_selectedSubcategoryId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select or add a subcategory'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      final categoryLabel = _selectedCategoryName() ?? 'Uncategorized';
      final subcategoryLabel = _selectedSubcategoryName() ?? 'Uncategorized';

      // Upload image if selected
      String imageUrl = widget.existingItem?.imageUrl ?? '';
      if (_selectedImage != null) {
        print('Uploading image: ${_selectedImage!.name}');
        try {
          final apiService = ApiService();
          final uploadedUrl = await apiService.uploadFile<Map<String, dynamic>>(
            '/api/upload/',
            _selectedImage!,
            fromJson: (json) => json as Map<String, dynamic>,
          );

          // Extract image URL from response
          if (uploadedUrl.containsKey('image')) {
            imageUrl = uploadedUrl['image'] as String;
            print('✓ Image uploaded successfully: $imageUrl');
          } else if (uploadedUrl.containsKey('url')) {
            imageUrl = uploadedUrl['url'] as String;
            print('✓ Image uploaded successfully: $imageUrl');
          }
        } catch (e) {
          print('Warning: Image upload failed: $e');
          // Continue without image if upload fails
        }
      }

      final item = StockItem(
        id:
            widget.existingItem?.id ??
            'ITM${DateTime.now().millisecondsSinceEpoch}',
        inventoryId: widget.existingItem?.inventoryId ?? '',
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().toUpperCase(),
        category: categoryLabel,
        subCategory: subcategoryLabel,
        quantity: int.parse(_quantityController.text),
        reorderLevel: int.parse(_reorderController.text),
        unitCost: double.parse(_costController.text),
        unitPrice: double.parse(_priceController.text),
        supplierName: _supplierController.text.trim(),
        imageUrl: imageUrl,
        semanticLabel: _nameController.text.trim(),
        productStatus: _selectedStatus,
      );

      // Call API to update product
      if (isEdit) {
        // Update full product details (name, SKU, prices, etc.)
        final Map<String, dynamic> updatePayload = {
          'name': item.name,
          'sku': item.sku,
          'unitCost': item.unitCost,
          'unitPrice': item.unitPrice,
          'supplierName': item.supplierName,
          'status': item.productStatus,
        };

        print('=== FORM WIDGET UPDATE DEBUG ===');
        print(
          'Item unitCost: ${item.unitCost} (type: ${item.unitCost.runtimeType})',
        );
        print(
          'Item unitPrice: ${item.unitPrice} (type: ${item.unitPrice.runtimeType})',
        );
        print('costController text: ${_costController.text}');
        print('priceController text: ${_priceController.text}');
        updatePayload['subcategoryId'] = _selectedSubcategoryId;

        // Include supplier/source ID if selected
        if (_selectedSupplierId != null) {
          updatePayload['sourceId'] = _selectedSupplierId;
        }

        // Only include image if it was updated
        if (imageUrl.isNotEmpty && imageUrl != widget.existingItem?.imageUrl) {
          updatePayload['image'] = imageUrl;
        }

        final success = await InventoryService.updateProduct(
          item.id,
          updatePayload,
        );

        if (!mounted) return;

        if (success) {
          // Also update quantity through inventory endpoint if it changed
          if (widget.existingItem!.quantity != item.quantity &&
              item.inventoryId.isNotEmpty) {
            await InventoryService.updateProductQuantity(
              item.id,
              item.inventoryId,
              item.quantity,
            );
          }

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
          'status': item.productStatus,
        };

        payload['subcategoryId'] = _selectedSubcategoryId;

        if (imageUrl.isNotEmpty) {
          payload['image'] = imageUrl;
        }

        if (_selectedSupplierId != null) {
          payload['sourceId'] = _selectedSupplierId;
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
                    const SizedBox(height: 16),
                    // Image picker section
                    _buildImagePickerSection(),
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryField(),
                    const SizedBox(height: 12),
                    _buildStatusField(),
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
                    const SizedBox(height: 4),
                    Text(
                      'Subcategories are grouped under the selected category.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: AppTheme.outline,
                      ),
                    ),
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

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Product Image'),
        const SizedBox(height: 10),
        // Image preview
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedImageBytes != null
                  ? AppTheme.primary
                  : AppTheme.outline,
              width: _selectedImageBytes != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.background,
          ),
          child: _selectedImageBytes != null
              ? Stack(
                  alignment: Alignment.topRight,
                  children: [
                    PickedImagePreview(
                      imageBytes: _selectedImageBytes!,
                      height: 120,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _clearImage,
                          icon: const Icon(Icons.close, size: 20),
                          color: AppTheme.error,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : widget.existingItem?.imageUrl != null &&
                    widget.existingItem!.imageUrl.isNotEmpty
              ? Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        ConfigService().resolveMediaUrl(
                          widget.existingItem!.imageUrl,
                        ),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: AppTheme.outline,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit, size: 20),
                          color: AppTheme.primary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add Product Image',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to select from gallery',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
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
                  final isSelected = _selectedSupplierId == supplier.sourceId;
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
                                  if (supplier.contactPerson != null)
                                    Text(
                                      supplier.contactPerson!,
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 12,
                                        color: AppTheme.outline,
                                      ),
                                    ),
                                ],
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

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _categories.any((c) => c.categoryId == _selectedCategoryId)
                    ? _selectedCategoryId
                    : null,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.categoryId,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: _loadingCategories
                    ? null
                    : (v) {
                        setState(() {
                          _selectedCategoryId = v;
                          final next = _subcategories
                              .where((sc) => sc.categoryId == v)
                              .toList();
                          _selectedSubcategoryId = next.isNotEmpty
                              ? next.first.subcategoryId
                              : null;
                        });
                      },
                validator: (v) => v == null ? 'Category is required' : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _canEdit && !_loadingCategories
                  ? _showAddCategoryDialog
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primary,
              tooltip: 'Add category',
            ),
          ],
        ),
        if (_loadingCategories)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Loading categories...',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
          )
        else if (_categories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No categories yet. Tap + to add one.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubcategoryField() {
    final filtered = _filteredSubcategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: filtered.any(
                      (sc) => sc.subcategoryId == _selectedSubcategoryId,
                    )
                    ? _selectedSubcategoryId
                    : null,
                decoration: const InputDecoration(labelText: 'Subcategory *'),
                items: filtered
                    .map(
                      (sc) => DropdownMenuItem<int>(
                        value: sc.subcategoryId,
                        child: Text(sc.name),
                      ),
                    )
                    .toList(),
                onChanged: _selectedCategoryId == null || _loadingCategories
                    ? null
                    : (v) => setState(() => _selectedSubcategoryId = v),
                validator: (v) => v == null ? 'Subcategory is required' : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _canEdit && !_loadingCategories && _selectedCategoryId != null
                  ? _showAddSubcategoryDialog
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primary,
              tooltip: 'Add subcategory',
            ),
          ],
        ),
        if (_loadingCategories)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Loading subcategories...',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
          )
        else if (_selectedCategoryId != null && filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No subcategories for this category. Tap + to add one.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusField() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: const InputDecoration(labelText: 'Status *'),
      items: const [
        DropdownMenuItem(value: 'Active', child: Text('Active')),
        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
        DropdownMenuItem(value: 'Discount', child: Text('Discount')),
      ],
      onChanged: (v) {
        if (v != null) {
          setState(() {
            _selectedStatus = v;
          });
        }
      },
      validator: (v) => v == null ? 'Status is required' : null,
    );
  }
}
