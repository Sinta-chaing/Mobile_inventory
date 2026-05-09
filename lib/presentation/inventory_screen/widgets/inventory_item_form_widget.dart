import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
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
  // TODO: Replace with Riverpod/Bloc for production
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

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
    'Safety',
    'Measuring',
    'Cleaning',
    'Electrical',
    'Plumbing',
    'Other',
  ];

  // Supplier data - initialize with empty list, will be populated in initState
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  String? _selectedSupplierId;
  bool _showSupplierDropdown = false;

  // Sample suppliers data - replace with API call in production
  List<Supplier> _initializeSuppliers() {
    return [
      Supplier(
        id: 'S001',
        name: 'ProTools Supply Co.',
        contactPerson: 'James Wilson',
        email: 'sales@protools.com',
        phone: '+1 (555) 100-2000',
        address: '100 Industrial Way, Chicago, IL 60601',
        category: 'Power Tools',
        status: SupplierStatus.active,
        totalOrders: 125400.00,
        orderCount: 28,
        rating: 4.8,
        leadTimeDays: 5,
        notes: 'Preferred supplier for power tools',
      ),
      Supplier(
        id: 'S002',
        name: 'Meridian Hardware Dist.',
        contactPerson: 'Patricia Lee',
        email: 'orders@meridian.com',
        phone: '+1 (555) 200-3000',
        address: '200 Commerce Blvd, Detroit, MI 48201',
        category: 'Hand Tools',
        status: SupplierStatus.active,
        totalOrders: 67800.50,
        orderCount: 19,
        rating: 4.5,
        leadTimeDays: 7,
        notes: '',
      ),
      Supplier(
        id: 'S003',
        name: 'SafeGuard Industrial',
        contactPerson: 'Thomas Brown',
        email: 'supply@safeguard.com',
        phone: '+1 (555) 300-4000',
        address: '300 Safety Pkwy, Cleveland, OH 44101',
        category: 'Safety Equipment',
        status: SupplierStatus.active,
        totalOrders: 34200.00,
        orderCount: 12,
        rating: 4.2,
        leadTimeDays: 10,
        notes: 'Certified safety equipment supplier',
      ),
      Supplier(
        id: 'S004',
        name: 'TechMeasure Solutions',
        contactPerson: 'Angela Davis',
        email: 'info@techmeasure.com',
        phone: '+1 (555) 400-5000',
        address: '400 Tech Drive, Columbus, OH 43201',
        category: 'Measuring Tools',
        status: SupplierStatus.onHold,
        totalOrders: 18900.00,
        orderCount: 8,
        rating: 3.8,
        leadTimeDays: 14,
        notes: 'On hold pending contract renewal',
      ),
      Supplier(
        id: 'S005',
        name: 'FastFix Distributors',
        contactPerson: 'Michael Scott',
        email: 'orders@fastfix.com',
        phone: '+1 (555) 500-6000',
        address: '500 Logistics Ave, Indianapolis, IN 46201',
        category: 'General Hardware',
        status: SupplierStatus.inactive,
        totalOrders: 5600.00,
        orderCount: 4,
        rating: 3.2,
        leadTimeDays: 21,
        notes: 'Inactive - poor delivery performance',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _suppliers = _initializeSuppliers();
    _filteredSuppliers = _suppliers
        .where((s) => s.status == SupplierStatus.active)
        .toList();

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

    // Pre-select supplier if editing
    if (item != null && item.supplierName.isNotEmpty) {
      final supplier = _suppliers.firstWhere(
        (s) => s.name == item.supplierName,
        orElse: () => Supplier(
          id: 'custom',
          name: item.supplierName,
          contactPerson: '',
          email: '',
          phone: '',
          address: '',
          category: '',
          status: SupplierStatus.active,
          totalOrders: 0,
          orderCount: 0,
          rating: 0,
          leadTimeDays: 0,
        ),
      );
      _selectedSupplierId = supplier.id;
    }

    if (item != null) _selectedCategory = item.category;
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
        _filteredSuppliers = _suppliers
            .where((s) => s.status == SupplierStatus.active)
            .toList();
      } else {
        _filteredSuppliers = _suppliers
            .where(
              (s) =>
                  s.status == SupplierStatus.active &&
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
    // TODO: Replace with real API call for production
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final isEdit = widget.existingItem != null;
    final item = StockItem(
      id:
          widget.existingItem?.id ??
          'ITM${DateTime.now().millisecondsSinceEpoch}',
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

    widget.onSave(item);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? '${item.name} updated successfully'
              : '${item.name} added to inventory',
        ),
      ),
    );
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
                    const SizedBox(height: 28),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
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
                                isEdit ? 'Save Changes' : 'Add to Inventory',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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
                'No suppliers found. You can enter a custom supplier name.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  color: AppTheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
