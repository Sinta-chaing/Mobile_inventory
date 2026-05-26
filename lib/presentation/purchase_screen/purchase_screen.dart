import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../services/order_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/invoice_pdf_generator.dart';
import '../../utils/khqr_config.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/profile_menu_widget.dart';
import 'package:khqr_sdk/khqr_sdk.dart';
import 'package:khqr_widget/khqr_widget.dart';
import '../inventory_screen/inventory_screen.dart';
import '../../models/all_models.dart' as backend;

enum PaymentMethod { cash, khqr }

enum OrderStatus { pending, paid }

class Customer {
  final int customerId;
  final String name;
  final String phone;

  Customer({required this.customerId, required this.name, required this.phone});

  /// Map from backend Customer model
  static Customer fromBackend(backend.Customer customer) {
    return Customer(
      customerId: customer.customerId,
      name: customer.name,
      phone: customer.phone,
    );
  }
}

class Product {
  final int productId;
  final String name;
  final double sellingPrice;

  Product({
    required this.productId,
    required this.name,
    required this.sellingPrice,
  });
}

class Order {
  final int invoiceId;
  final DateTime createdDate;
  final String customerName;
  final String customerPhone;
  final PaymentMethod paymentMethod;
  final double total;
  OrderStatus status;
  DateTime? paidAt;
  final int? createdByUserId;
  final String createdBy; // For UI display
  final List<OrderItem> items;
  String? khqrCode; // KHQR code generated when payment method is KHQR

  Order({
    required this.invoiceId,
    required this.createdDate,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
    required this.total,
    required this.status,
    this.paidAt,
    this.createdByUserId,
    this.createdBy = 'App',
    required this.items,
    this.khqrCode,
  });

  /// Map from backend Invoice model
  static Order fromBackend(backend.Invoice invoice) {
    final method = invoice.paymentMethod.toLowerCase() == 'cash'
        ? PaymentMethod.cash
        : PaymentMethod.khqr;
    final status = invoice.status.toLowerCase() == 'paid'
        ? OrderStatus.paid
        : OrderStatus.pending;

    final items = invoice.purchases
        .map(
          (p) => OrderItem(
            itemName: 'Product ${p.productId}',
            quantity: p.quantity,
            unitPrice: p.pricePerUnit,
            discount: p.discount,
          ),
        )
        .toList();

    return Order(
      invoiceId: invoice.invoiceId,
      createdDate: invoice.createdAt,
      customerName: invoice.customerName,
      customerPhone: invoice.customerPhone ?? '',
      paymentMethod: method,
      total: invoice.grandTotal,
      status: status,
      paidAt: invoice.paidAt,
      createdByUserId: invoice.createdByUserId,
      createdBy: 'User ${invoice.createdByUserId ?? 0}',
      items: items,
    );
  }
}

class OrderItem {
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double discount; // Discount percentage

  OrderItem({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
  });

  double get subtotal => quantity * unitPrice;
  double get discountAmount => (subtotal * discount) / 100;
  double get lineTotal => subtotal - discountAmount;
}

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  int _selectedNavIndex = 1;
  String _searchQuery = '';
  bool _isLoading = true;

  // Customer and product data loaded from API
  List<Customer> _customers = [];
  List<Product> _products = [];

  late List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load customers from backend
      final backendCustomers = await CustomerDataService.fetchCustomers();
      final customers = backendCustomers
          .map((c) => Customer.fromBackend(c))
          .toList();

      // Load products from inventory service
      final inventory = await InventoryService.fetchProducts();
      final products = inventory
          .map(
            (stock) => Product(
              productId: int.parse(stock.id),
              name: stock.name,
              sellingPrice: stock.unitPrice,
            ),
          )
          .toList();

      // Load orders
      final backendInvoices = await OrderService.loadOrders();
      final loadedOrders = backendInvoices
          .map((inv) => Order.fromBackend(inv))
          .toList();
      print('🔄 Purchase screen loaded ${loadedOrders.length} orders');

      setState(() {
        _customers = customers;
        _products = products;
        _orders = loadedOrders;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading data in purchase screen: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveOrders() async {
    try {
      await OrderService.saveOrders(_orders);
      print('💾 Purchase screen saved ${_orders.length} orders');
    } catch (e) {
      print('❌ Error saving orders: $e');
    }
  }

  Future<Map<String, dynamic>> _checkInventorySufficiency(
    List<OrderItem> items,
  ) async {
    try {
      final inventory = await InventoryService.loadInventory();
      final insufficientItems = <String>[];

      for (var orderItem in items) {
        final stockItem = inventory.firstWhere(
          (s) => s.name.toLowerCase() == orderItem.itemName.toLowerCase(),
          orElse: () => StockItem(
            id: '',
            inventoryId: '',
            name: orderItem.itemName,
            sku: '',
            category: '',
            quantity: 0,
            reorderLevel: 0,
            unitCost: 0.0,
            unitPrice: 0.0,
            supplierName: '',
            imageUrl: '',
            semanticLabel: '',
          ),
        );

        if (stockItem.quantity < orderItem.quantity) {
          insufficientItems.add(
            '${orderItem.itemName} (Available: ${stockItem.quantity}, Required: ${orderItem.quantity})',
          );
        }
      }

      return {
        'sufficient': insufficientItems.isEmpty,
        'insufficientItems': insufficientItems,
      };
    } catch (e) {
      print('Error checking inventory: $e');
      return {'sufficient': true, 'insufficientItems': []};
    }
  }

  Future<void> _deductInventory(List<OrderItem> items) async {
    try {
      final inventory = await InventoryService.loadInventory();

      for (var orderItem in items) {
        final stockItemIndex = inventory.indexWhere(
          (s) => s.name.toLowerCase() == orderItem.itemName.toLowerCase(),
        );

        if (stockItemIndex != -1) {
          inventory[stockItemIndex].quantity -= orderItem.quantity;
          if (inventory[stockItemIndex].quantity < 0) {
            inventory[stockItemIndex].quantity = 0;
          }
        }
      }

      await InventoryService.saveInventory(inventory);
    } catch (e) {
      print('Error deducting inventory: $e');
    }
  }

  String _generateNextOrderId() {
    int maxNumber = 0;
    for (var order in _orders) {
      if (order.invoiceId > maxNumber) {
        maxNumber = order.invoiceId;
      }
    }
    return 'ORD-2024-${(maxNumber + 1).toString().padLeft(3, '0')}';
  }

  String? _generateKhqrCode(double amountInUsd) {
    try {
      // Expire in 10 hours from now
      final expire = DateTime.now().millisecondsSinceEpoch + (10 * 3600000);

      // Create merchant info
      final info = KhqrConfig.merchantInfo(
        amountInUsd: amountInUsd,
        expirationTimestamp: expire,
        merchantName: KhqrConfig.storeLabel(),
      );

      // Generate KHQR
      final res = KhqrSdk.generateMerchant(info);
      return res.data?.qr;
    } catch (e) {
      print('Error generating KHQR code: $e');
      return null;
    }
  }

  List<Order> get _filteredOrders {
    return _orders.where((o) {
      final matchSearch =
          _searchQuery.isEmpty ||
          o.invoiceId.toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          o.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchSearch;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
    final totalOrders = _orders.length;
    final paidOrders = _orders
        .where((o) => o.status == OrderStatus.paid)
        .length;
    final pendingOrders = _orders
        .where((o) => o.status == OrderStatus.pending)
        .length;

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
                  Icons.receipt_long_rounded,
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
                      'Invoices',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C2B),
                      ),
                    ),
                    Text(
                      'Create & manage orders',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const ProfileMenuWidget(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  '$totalOrders',
                  Icons.receipt_long_rounded,
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Paid',
                  '$paidOrders',
                  Icons.check_circle_rounded,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '$pendingOrders',
                  Icons.hourglass_bottom_rounded,
                  AppTheme.warning,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF1A1C2B),
          ),
          decoration: InputDecoration(
            hintText: 'Search by order # or customer…',
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
              Icons.receipt_long_outlined,
              size: 56,
              color: AppTheme.outline.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No orders found',
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

  Widget _buildOrderCard(Order order) {
    final statusColor = order.status == OrderStatus.paid
        ? AppTheme.success
        : AppTheme.warning;
    final statusLabel = order.status == OrderStatus.paid ? 'Paid' : 'Pending';
    final paymentLabel = order.paymentMethod == PaymentMethod.cash
        ? 'Cash'
        : 'KHQR';

    return GestureDetector(
      onTap: () => _showOrderDetail(order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Order ID and Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.invoiceId}',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdDate)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Customer Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1C2B),
                              ),
                            ),
                            Text(
                              order.customerPhone,
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Payment and Total Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: order.paymentMethod == PaymentMethod.cash
                              ? Colors.green.withAlpha(25)
                              : Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paymentLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: order.paymentMethod == PaymentMethod.cash
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Additional Info Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created by',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppTheme.outline,
                      ),
                    ),
                    Text(
                      order.createdBy,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1C2B),
                      ),
                    ),
                  ],
                ),
                if (order.status == OrderStatus.paid && order.paidAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Paid at',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppTheme.outline,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(order.paidAt!),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Payment Status Toggle Button - Only visible when pending
            if (order.status == OrderStatus.pending)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  this.setState(() {
                    order.status = OrderStatus.paid;
                    order.paidAt = DateTime.now();
                  });
                  _saveOrders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order marked as paid'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mark as Paid',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(
        order: order,
        onMarkPaid: () {
          setState(() {
            order.status = OrderStatus.paid;
          });
          _saveOrders();
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Order marked as paid')));
        },
        onDelete: () {
          // Remove the order from the list
          setState(() => _orders.remove(order));
          // Save the updated orders
          _saveOrders();
          // Close the bottom sheet
          Navigator.pop(context);
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
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
        onPressed: () => _showCreateOrderDialog(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Order',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showCreateOrderDialog() {
    Customer? selectedCustomer;
    Product? selectedProduct;
    final itemNameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final sellingPriceController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    PaymentMethod selectedPayment = PaymentMethod.cash;
    final createdByController = TextEditingController(text: 'Current User');
    List<OrderItem> addedItems = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Create New Order',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Selection
                          Text(
                            'Customer Information',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButton<Customer>(
                              isExpanded: true,
                              hint: const Text('Select Customer'),
                              value: selectedCustomer,
                              underline: const SizedBox(),
                              items: _customers.map((customer) {
                                return DropdownMenuItem<Customer>(
                                  value: customer,
                                  child: Text(
                                    '${customer.name} (${customer.phone})',
                                  ),
                                );
                              }).toList(),
                              onChanged: (customer) {
                                setState(() => selectedCustomer = customer);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Product Selection with Filtering
                          Text(
                            'Order Items',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: itemNameController,
                            decoration: InputDecoration(
                              labelText: 'Product Name',
                              hintText: 'Type to filter products...',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: selectedProduct != null
                                      ? AppTheme.primary
                                      : Colors.grey,
                                  width: selectedProduct != null ? 2 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: selectedProduct != null
                                      ? AppTheme.primary
                                      : Colors.grey,
                                  width: selectedProduct != null ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: selectedProduct != null,
                              fillColor: selectedProduct != null
                                  ? AppTheme.primary.withAlpha(20)
                                  : Colors.transparent,
                              suffixIcon: selectedProduct != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: AppTheme.primary,
                                            size: 24,
                                          ),
                                          if (itemNameController
                                              .text
                                              .isNotEmpty)
                                            IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                itemNameController.clear();
                                                setState(() {
                                                  selectedProduct = null;
                                                  sellingPriceController
                                                      .clear();
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                    )
                                  : itemNameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        itemNameController.clear();
                                        setState(() {
                                          selectedProduct = null;
                                          sellingPriceController.clear();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  selectedProduct = null;
                                  sellingPriceController.clear();
                                }
                              });
                            },
                          ),
                          // Product Filter Results
                          if (itemNameController.text.isNotEmpty &&
                              selectedProduct == null) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Builder(
                                builder: (context) {
                                  final filteredProducts = _products
                                      .where(
                                        (p) => p.name.toLowerCase().contains(
                                          itemNameController.text.toLowerCase(),
                                        ),
                                      )
                                      .toList();

                                  if (filteredProducts.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withAlpha(25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Product does not exist',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      children: filteredProducts.map((product) {
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedProduct = product;
                                              itemNameController.text =
                                                  product.name;
                                              sellingPriceController.text =
                                                  product.sellingPrice
                                                      .toStringAsFixed(2);
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '\$${product.sellingPrice.toStringAsFixed(2)}',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Quantity and Selling Price
                          if (selectedProduct != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: quantityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      // Prevent negative numbers
                                      if (value.isNotEmpty &&
                                          value.startsWith('-')) {
                                        quantityController.text = value
                                            .substring(1);
                                        quantityController.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset: quantityController
                                                    .text
                                                    .length,
                                              ),
                                            );
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: sellingPriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Selling Price',
                                      border: OutlineInputBorder(),
                                    ),
                                    readOnly: true,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Discount Field
                            TextField(
                              controller: discountController,
                              decoration: const InputDecoration(
                                labelText: 'Discount (%)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                // Prevent negative numbers
                                if (value.isNotEmpty && value.startsWith('-')) {
                                  discountController.text = value.substring(1);
                                  discountController
                                      .selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: discountController.text.length,
                                    ),
                                  );
                                }
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 12),
                            // Add Item Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  final quantity =
                                      int.tryParse(quantityController.text) ??
                                      0;
                                  if (quantity <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Quantity must be greater than 0',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final discount =
                                      double.tryParse(
                                        discountController.text,
                                      ) ??
                                      0.0;
                                  if (discount < 0 || discount > 100) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Discount must be between 0 and 100',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    addedItems.add(
                                      OrderItem(
                                        itemName: selectedProduct!.name,
                                        quantity: quantity,
                                        unitPrice:
                                            selectedProduct!.sellingPrice,
                                        discount: discount,
                                      ),
                                    );
                                    // Reset for next item
                                    selectedProduct = null;
                                    itemNameController.clear();
                                    quantityController.text = '1';
                                    sellingPriceController.clear();
                                    discountController.text = '0';
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Added Items List
                          if (addedItems.isNotEmpty) ...[
                            Text(
                              'Added Items (${addedItems.length})',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: addedItems.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: Colors.grey[300]),
                                itemBuilder: (context, index) {
                                  final item = addedItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.itemName,
                                                style: GoogleFonts.dmSans(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'Qty: ${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (item.discount > 0)
                                                Text(
                                                  'Discount: ${item.discount.toStringAsFixed(0)}% (-\$${item.discountAmount.toStringAsFixed(2)})',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 11,
                                                    color: Colors.orange[700],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              Text(
                                                'Total: \$${item.lineTotal.toStringAsFixed(2)}',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => addedItems.removeAt(index),
                                            );
                                          },
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Total Display
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total:',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '\$${_calculateInvoiceTotal(addedItems).toStringAsFixed(2)}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Payment Method
                          Text(
                            'Payment Method',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<PaymentMethod>(
                                  title: const Text('Cash'),
                                  value: PaymentMethod.cash,
                                  groupValue: selectedPayment,
                                  onChanged: (value) {
                                    setState(() => selectedPayment = value!);
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<PaymentMethod>(
                                  title: const Text('KHQR'),
                                  value: PaymentMethod.khqr,
                                  groupValue: selectedPayment,
                                  onChanged: (value) {
                                    setState(() => selectedPayment = value!);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          // Validation
                          if (selectedCustomer == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a customer'),
                              ),
                            );
                            return;
                          }
                          if (addedItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please add at least one item'),
                              ),
                            );
                            return;
                          }

                          // Check inventory availability
                          final inventoryCheck =
                              await _checkInventorySufficiency(addedItems);

                          if (!inventoryCheck['sufficient']) {
                            final insufficientItems =
                                inventoryCheck['insufficientItems']
                                    as List<String>;
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Insufficient Inventory'),
                                icon: const Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red,
                                  size: 32,
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'The following items do not have sufficient inventory:',
                                    ),
                                    const SizedBox(height: 12),
                                    ...insufficientItems.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          '• $item',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          final total = _calculateInvoiceTotal(addedItems);

                          // Generate KHQR code if KHQR payment method is selected
                          String? khqrCode;
                          if (selectedPayment == PaymentMethod.khqr) {
                            khqrCode = _generateKhqrCode(total);
                          }

                          this.setState(() {
                            _orders.insert(
                              0,
                              Order(
                                orderId: _generateNextOrderId(),
                                createdDate: DateTime.now(),
                                customerName: selectedCustomer!.name,
                                customerPhone: selectedCustomer!.phone,
                                paymentMethod: selectedPayment,
                                total: total,
                                status: OrderStatus.pending,
                                paidAt: null,
                                createdBy: createdByController.text,
                                items: addedItems,
                                khqrCode: khqrCode,
                              ),
                            );
                          });
                          await _saveOrders();

                          // Deduct inventory after order is created
                          await _deductInventory(addedItems);

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order created successfully'),
                            ),
                          );
                        },
                        child: const Text('Create Order'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _calculateInvoiceTotal(List<OrderItem> items) {
    double total = 0;
    for (var item in items) {
      total += item.lineTotal;
    }
    return total;
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final Order order;
  final VoidCallback onMarkPaid;
  final VoidCallback onDelete;

  const _OrderDetailSheet({
    required this.order,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  bool _isCheckingPayment = false;

  Order get order => widget.order;
  VoidCallback get onMarkPaid => widget.onMarkPaid;
  VoidCallback get onDelete => widget.onDelete;

  Future<void> _checkPaymentStatus() async {
    setState(() => _isCheckingPayment = true);

    try {
      // Call the OrderService to verify payment with payment gateway
      final paymentVerified = await OrderService.verifyKhqrPayment(
        order.invoiceId.toString(),
        order.total,
      );

      if (!mounted) return;

      if (paymentVerified) {
        // Payment was verified - mark as paid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment verified! Order marked as paid.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Mark as paid
        onMarkPaid();
      } else {
        // Payment not yet received
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Payment not received yet. Please try again later.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error checking payment: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
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
                  // Order Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.invoiceId}',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy HH:mm',
                            ).format(order.createdDate),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppTheme.outline,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: order.status == OrderStatus.paid
                              ? AppTheme.success.withAlpha(25)
                              : AppTheme.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order.status == OrderStatus.paid ? 'Paid' : 'Pending',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: order.status == OrderStatus.paid
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Customer Section
                  Text(
                    'Customer Information',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Name:',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                            Text(
                              order.customerName,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Phone:',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                            Text(
                              order.customerPhone,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Payment Info Section
                  Text(
                    'Payment Information',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Method:',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                            Text(
                              order.paymentMethod == PaymentMethod.cash
                                  ? 'Cash'
                                  : 'KHQR',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (order.status == OrderStatus.paid &&
                            order.paidAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Paid At:',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppTheme.outline,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMM dd, HH:mm',
                                ).format(order.paidAt!),
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // KHQR Payment Card - Display if payment method is KHQR and order is pending
                  if (order.paymentMethod == PaymentMethod.khqr &&
                      order.status == OrderStatus.pending &&
                      order.khqrCode != null &&
                      order.khqrCode!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KHQR Payment',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Refresh button to check payment status
                            if (_isCheckingPayment)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded),
                                onPressed: _checkPaymentStatus,
                                tooltip: 'Check if payment received',
                                color: AppTheme.primary,
                                iconSize: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: KhqrWidget(
                            width: 300,
                            receiverName: 'Oun Mengheang',
                            amount: order.total.toStringAsFixed(2),
                            currency: 'USD',
                            qr: order.khqrCode!,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  // Items Section
                  Text(
                    'Order Items',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppTheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.lineTotal.toStringAsFixed(2)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Additional Info
                  Text(
                    'Additional Information',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Created By:',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                        ),
                        Text(
                          order.createdBy,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  if (order.status == OrderStatus.pending)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onMarkPaid,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                        ),
                        child: Text(
                          'Mark as Paid',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (order.status == OrderStatus.pending)
                    const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        InvoicePdfGenerator.generateAndPreviewPdf(
                          context,
                          order,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.file_download_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Export as PDF',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        onDelete();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(
                          color: AppTheme.error,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Delete Order',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
