import 'package:flutter/material.dart';
import 'dart:ui';

import '../../routes/app_routes.dart';
import '../../services/order_service.dart';
import '../../services/inventory_service.dart';
import '../../services/customer_data_service.dart';
import '../../services/supplier_data_service.dart';
import '../../theme/app_theme.dart';
import '../../models/all_models.dart' as backend;

import '../../widgets/app_navigation.dart';
import '../purchase_screen/purchase_screen.dart';
import '../supplier_screen/supplier_screen.dart';
import '../inventory_screen/inventory_screen.dart';
import './widgets/bi_header_widget.dart';
import './widgets/bi_kpi_grid_widget.dart';
import './widgets/bi_low_stock_alerts_widget.dart';
import './widgets/bi_revenue_chart_widget.dart';
import './widgets/bi_top_items_chart_widget.dart';
import './widgets/bi_profitable_products_widget.dart';
import './widgets/bi_profit_breakdown_widget.dart';
import './widgets/bi_top_supplier_widget.dart';
import './widgets/bi_top_customer_widget.dart';

class BIDashboardScreen extends StatefulWidget {
  const BIDashboardScreen({super.key});

  @override
  State<BIDashboardScreen> createState() => _BIDashboardScreenState();
}

// UI-specific Customer adapter for BI Dashboard
class BiCustomer {
  final int customerId;
  final String name;
  final String phone;

  BiCustomer({
    required this.customerId,
    required this.name,
    required this.phone,
  });

  static BiCustomer fromBackend(backend.Customer customer) {
    return BiCustomer(
      customerId: customer.customerId,
      name: customer.name,
      phone: customer.phone,
    );
  }
}

class _BIDashboardScreenState extends State<BIDashboardScreen> {
  int _selectedNavIndex = 4;
  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
  ];

  // Data from other screens - converted to UI models
  late List<Order> _orders;
  late List<Customer> _customers;
  late List<Supplier> _suppliers;
  late List<StockItem> _stockItems;

  // Refresh state
  late DateTime _lastUpdated;
  bool _isRefreshing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _lastUpdated = DateTime.now();
    _loadData();
  }

  void _setLocalData({
    required List<backend.Invoice> ordersList,
    required List<StockItem> inventoryList,
    required List<backend.Customer> customersList,
    required List<backend.Source> suppliersList,
  }) {
    // Convert backend models to UI models
    _orders = ordersList.map((inv) => Order.fromBackend(inv)).toList();
    _stockItems = inventoryList;
    _customers = customersList.map((c) => Customer.fromBackend(c)).toList();

    // Compute supplier metrics from order data
    final supplierOrderTotals = <String, double>{};
    final supplierOrderCounts = <String, int>{};
    for (final order in _orders) {
      for (final item in order.items) {
        final supplierName = _stockItems
            .where((s) => s.name.toLowerCase() == item.itemName.toLowerCase())
            .map((s) => s.supplierName)
            .firstOrNull;
        if (supplierName != null && supplierName.isNotEmpty) {
          supplierOrderTotals.update(
              supplierName, (v) => v + item.lineTotal,
              ifAbsent: () => item.lineTotal);
          supplierOrderCounts.update(supplierName, (v) => v + 1,
              ifAbsent: () => 1);
        }
      }
    }
    _suppliers = suppliersList
        .map((src) => Supplier.fromBackend(src))
        .map((s) {
      s.totalOrders = supplierOrderTotals[s.name] ?? s.totalOrders;
      s.orderCount = supplierOrderCounts[s.name] ?? s.orderCount;
      return s;
    }).toList();
  }

  Future<void> _loadData() async {
    // 1. Load from local cache immediately
    try {
      final cachedResults = await Future.wait([
        OrderService.loadOrders(),
        InventoryService.loadInventory(),
        CustomerDataService.loadCustomers(),
        SupplierDataService.loadSuppliers(),
      ]);

      final cachedOrders = cachedResults[0] as List<backend.Invoice>;
      final cachedInventory = cachedResults[1] as List<StockItem>;
      final cachedCustomers = cachedResults[2] as List<backend.Customer>;
      final cachedSuppliers = cachedResults[3] as List<backend.Source>;

      if (mounted) {
        setState(() {
          _setLocalData(
            ordersList: cachedOrders,
            inventoryList: cachedInventory,
            customersList: cachedCustomers,
            suppliersList: cachedSuppliers,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cached BI data: $e');
    }

    // 2. Fetch fresh data from backend concurrently
    try {
      final freshResults = await Future.wait([
        OrderService.fetchOrders(),
        InventoryService.fetchProducts(),
        CustomerDataService.fetchCustomers(),
        SupplierDataService.fetchSuppliers(),
      ]);

      final freshOrders = freshResults[0] as List<backend.Invoice>;
      final freshInventory = freshResults[1] as List<StockItem>;
      final freshCustomers = freshResults[2] as List<backend.Customer>;
      final freshSuppliers = freshResults[3] as List<backend.Source>;

      if (mounted) {
        setState(() {
          _setLocalData(
            ordersList: freshOrders,
            inventoryList: freshInventory,
            customersList: freshCustomers,
            suppliersList: freshSuppliers,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading fresh BI data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.inventoryScreen);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.purchaseScreen);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.customerScreen);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.supplierScreen);
        break;
    }
  }

  void _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });

    // Reload data from all services
    await _loadData();

    setState(() {
      _lastUpdated = DateTime.now();
      _isRefreshing = false;
    });
  }

  List<Order> _getFilteredOrders() {
    final now = DateTime.now();
    return _orders.where((order) {
      final orderDate = order.createdDate;
      switch (_selectedPeriod) {
        case 'Today':
          return orderDate.year == now.year &&
              orderDate.month == now.month &&
              orderDate.day == now.day;
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return orderDate.isAfter(start) || orderDate.isAtSameMomentAs(start);
        case 'This Month':
          return orderDate.year == now.year && orderDate.month == now.month;
        case 'This Quarter':
          final currentQuarter = ((now.month - 1) / 3).floor() + 1;
          final orderQuarter = ((orderDate.month - 1) / 3).floor() + 1;
          return orderDate.year == now.year && orderQuarter == currentQuarter;
        default:
          return true;
      }
    }).toList();
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
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
        ),
      ),
      bottomNavigationBar: isTablet
          ? null
          : SizedBox(
              height: 76,
              child: ClipRect(
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
            ),
    );
  }

  Widget _buildPhoneLayout() {
    final filteredOrders = _getFilteredOrders();
    final paidFilteredOrders = filteredOrders.where((o) => o.status == OrderStatus.paid).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: BIHeaderWidget(
            selectedPeriod: _selectedPeriod,
            periods: _periods,
            onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
            onRefresh: _refreshDashboard,
            lastUpdated: _lastUpdated,
            isRefreshing: _isRefreshing,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BIKpiGridWidget(
              orders: filteredOrders,
              inventory: _stockItems,
              selectedPeriod: _selectedPeriod,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BIRevenueChartWidget(
              orders: _orders
                  .where((o) => o.status == OrderStatus.paid)
                  .toList(),
              stockItems: _stockItems,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BITopItemsChartWidget(
              orders: paidFilteredOrders,
              stockItems: _stockItems,
              selectedPeriod: _selectedPeriod,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BIProfitableProductsWidget(
              orders: paidFilteredOrders,
              stockItems: _stockItems,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BIProfitBreakdownWidget(
              orders: paidFilteredOrders,
              stockItems: _stockItems,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BITopSupplierWidget(suppliers: _suppliers),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BITopCustomerWidget(orders: filteredOrders, customers: _customers),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BILowStockAlertsWidget(inventory: _stockItems),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTabletLayout() {
    final filteredOrders = _getFilteredOrders();
    final paidFilteredOrders = filteredOrders.where((o) => o.status == OrderStatus.paid).toList();

    return Row(
      children: [
        AppNavigationRail(
          currentIndex: _selectedNavIndex,
          onDestinationSelected: _onNavTap,
        ),
        Container(width: 1, color: AppTheme.outlineVariant),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: BIHeaderWidget(
                  selectedPeriod: _selectedPeriod,
                  periods: _periods,
                  onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
                  onRefresh: _refreshDashboard,
                  lastUpdated: _lastUpdated,
                  isRefreshing: _isRefreshing,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: BIKpiGridWidget(
                    isTablet: true,
                    orders: filteredOrders,
                    inventory: _stockItems,
                    selectedPeriod: _selectedPeriod,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BIRevenueChartWidget(
                          orders: _orders
                              .where((o) => o.status == OrderStatus.paid)
                              .toList(),
                          stockItems: _stockItems,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BITopItemsChartWidget(
                          orders: paidFilteredOrders,
                          stockItems: _stockItems,
                          selectedPeriod: _selectedPeriod,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BIProfitableProductsWidget(
                          orders: paidFilteredOrders,
                          stockItems: _stockItems,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BITopSupplierWidget(suppliers: _suppliers),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BITopCustomerWidget(
                          orders: filteredOrders,
                          customers: _customers,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BILowStockAlertsWidget(inventory: _stockItems),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: BIProfitBreakdownWidget(
                    orders: paidFilteredOrders,
                    stockItems: _stockItems,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ],
    );
  }
}
