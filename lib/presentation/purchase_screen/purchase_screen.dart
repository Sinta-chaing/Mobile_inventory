import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

enum PurchaseStatus { pending, received, cancelled }

class PurchaseOrder {
  final String id;
  final String poNumber;
  final String supplierName;
  final String supplierContact;
  final DateTime orderDate;
  DateTime? expectedDate;
  PurchaseStatus status;
  final List<PurchaseLineItem> items;
  String notes;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplierName,
    required this.supplierContact,
    required this.orderDate,
    this.expectedDate,
    required this.status,
    required this.items,
    this.notes = '',
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

class PurchaseLineItem {
  final String itemName;
  final String sku;
  int quantity;
  double unitCost;

  PurchaseLineItem({
    required this.itemName,
    required this.sku,
    required this.quantity,
    required this.unitCost,
  });

  double get totalPrice => quantity * unitCost;
}

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 1;
  String _searchQuery = '';
  PurchaseStatus? _filterStatus;
  late TabController _tabController;

  final List<PurchaseOrder> _orders = [
    PurchaseOrder(
      id: 'PO001',
      poNumber: 'PO-2024-001',
      supplierName: 'ProTools Supply Co.',
      supplierContact: 'sales@protools.com',
      orderDate: DateTime.now().subtract(const Duration(days: 5)),
      expectedDate: DateTime.now().add(const Duration(days: 3)),
      status: PurchaseStatus.pending,
      items: [
        PurchaseLineItem(
          itemName: 'DeWalt 20V Cordless Drill',
          sku: 'DW-DCD771C2',
          quantity: 20,
          unitCost: 89.50,
        ),
        PurchaseLineItem(
          itemName: 'Milwaukee M18 Impact Driver',
          sku: 'MW-2853-20',
          quantity: 10,
          unitCost: 135.00,
        ),
      ],
      notes: 'Urgent restock needed for Q4',
    ),
    PurchaseOrder(
      id: 'PO002',
      poNumber: 'PO-2024-002',
      supplierName: 'Meridian Hardware Dist.',
      supplierContact: 'orders@meridian.com',
      orderDate: DateTime.now().subtract(const Duration(days: 12)),
      expectedDate: DateTime.now().subtract(const Duration(days: 2)),
      status: PurchaseStatus.received,
      items: [
        PurchaseLineItem(
          itemName: 'Stanley FatMax Tape Measure',
          sku: 'ST-FMHT33865',
          quantity: 30,
          unitCost: 12.40,
        ),
        PurchaseLineItem(
          itemName: 'Irwin 10" Adjustable Wrench',
          sku: 'IW-2078609',
          quantity: 25,
          unitCost: 8.75,
        ),
        PurchaseLineItem(
          itemName: 'Klein Tools Level 24"',
          sku: 'KL-935-24',
          quantity: 15,
          unitCost: 22.00,
        ),
      ],
      notes: '',
    ),
    PurchaseOrder(
      id: 'PO003',
      poNumber: 'PO-2024-003',
      supplierName: 'SafeGuard Industrial',
      supplierContact: 'supply@safeguard.com',
      orderDate: DateTime.now().subtract(const Duration(days: 8)),
      expectedDate: DateTime.now().add(const Duration(days: 7)),
      status: PurchaseStatus.pending,
      items: [
        PurchaseLineItem(
          itemName: '3M Safety Glasses Clear Lens',
          sku: '3M-11326-00000',
          quantity: 100,
          unitCost: 2.10,
        ),
        PurchaseLineItem(
          itemName: 'Gorilla Heavy Duty Work Gloves',
          sku: 'GR-71594-M',
          quantity: 50,
          unitCost: 7.20,
        ),
      ],
      notes: 'Safety equipment restock',
    ),
    PurchaseOrder(
      id: 'PO004',
      poNumber: 'PO-2024-004',
      supplierName: 'ProTools Supply Co.',
      supplierContact: 'sales@protools.com',
      orderDate: DateTime.now().subtract(const Duration(days: 20)),
      expectedDate: DateTime.now().subtract(const Duration(days: 10)),
      status: PurchaseStatus.cancelled,
      items: [
        PurchaseLineItem(
          itemName: 'Bosch 18V Circular Saw',
          sku: 'BS-CCS180B',
          quantity: 5,
          unitCost: 112.00,
        ),
      ],
      notes: 'Cancelled due to price dispute',
    ),
  ];

  List<PurchaseOrder> get _filteredOrders {
    return _orders.where((o) {
      final matchSearch =
          _searchQuery.isEmpty ||
          o.poNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.supplierName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _filterStatus == null || o.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.inventoryScreen);
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.pending:
        return AppTheme.warning;
      case PurchaseStatus.received:
        return AppTheme.success;
      case PurchaseStatus.cancelled:
        return AppTheme.error;
    }
  }

  String _statusLabel(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.pending:
        return 'Pending';
      case PurchaseStatus.received:
        return 'Received';
      case PurchaseStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _statusIcon(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.pending:
        return Icons.schedule_rounded;
      case PurchaseStatus.received:
        return Icons.check_circle_rounded;
      case PurchaseStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildOrderList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildGlassNavBar(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildGlassNavBar() {
    return ClipRect(
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
    );
  }

  Widget _buildHeader() {
    final pending = _orders
        .where((o) => o.status == PurchaseStatus.pending)
        .length;
    final totalValue = _orders.fold<double>(0, (s, o) => s + o.totalAmount);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Orders',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C2B),
                      ),
                    ),
                    Text(
                      'Manage supplier purchases',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  '${_orders.length}',
                  Icons.receipt_long_rounded,
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '$pending',
                  Icons.schedule_rounded,
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Total Value',
                  '\$${(totalValue / 1000).toStringAsFixed(1)}k',
                  Icons.attach_money_rounded,
                  AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.simpleCardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C2B),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppTheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: AppTheme.simpleCardDecoration,
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF1A1C2B),
          ),
          decoration: InputDecoration(
            hintText: 'Search by PO number or supplier…',
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.outline,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.outline,
              size: 20,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final orders = _filteredOrders;
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: AppTheme.outline.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No purchase orders found',
              style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildOrderCard(orders[i]),
    );
  }

  Widget _buildOrderCard(PurchaseOrder order) {
    final statusColor = _statusColor(order.status);
    return GestureDetector(
      onTap: () => _showOrderDetail(order),
      child: Container(
        decoration: AppTheme.simpleCardDecoration,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.poNumber,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.supplierName,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(order.status),
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(order.status),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: AppTheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ordered: ${_formatDate(order.orderDate)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.outline,
                  ),
                ),
                if (order.expectedDate != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 12,
                    color: AppTheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expected: ${_formatDate(order.expectedDate!)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '${order.totalItems} units',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showOrderDetail(PurchaseOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(
        order: order,
        onStatusChanged: (s) {
          setState(() => order.status = s);
          Navigator.pop(context);
        },
        onDelete: () {
          setState(() => _orders.remove(order));
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showAddOrderDialog(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New PO',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddOrderDialog() {
    final poController = TextEditingController(
      text: 'PO-2024-00${_orders.length + 1}',
    );
    final supplierController = TextEditingController();
    final contactController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'New Purchase Order',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: poController,
                decoration: const InputDecoration(labelText: 'PO Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(labelText: 'Supplier Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Contact Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (supplierController.text.isNotEmpty) {
                setState(() {
                  _orders.insert(
                    0,
                    PurchaseOrder(
                      id: 'PO${DateTime.now().millisecondsSinceEpoch}',
                      poNumber: poController.text,
                      supplierName: supplierController.text,
                      supplierContact: contactController.text,
                      orderDate: DateTime.now(),
                      status: PurchaseStatus.pending,
                      items: [],
                      notes: notesController.text,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  final PurchaseOrder order;
  final ValueChanged<PurchaseStatus> onStatusChanged;
  final VoidCallback onDelete;

  const _OrderDetailSheet({
    required this.order,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.poNumber,
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            order.supplierName,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.error,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Line Items',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item.sku,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.quantity} × \$${item.unitCost.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${item.totalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Update Status',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: PurchaseStatus.values.map((s) {
                    final isSelected = order.status == s;
                    final color = s == PurchaseStatus.pending
                        ? AppTheme.warning
                        : s == PurchaseStatus.received
                        ? AppTheme.success
                        : AppTheme.error;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OutlinedButton(
                          onPressed: () => onStatusChanged(s),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected
                                ? color.withAlpha(25)
                                : null,
                            side: BorderSide(
                              color: isSelected
                                  ? color
                                  : AppTheme.outlineVariant,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            s == PurchaseStatus.pending
                                ? 'Pending'
                                : s == PurchaseStatus.received
                                ? 'Received'
                                : 'Cancel',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : AppTheme.outline,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
