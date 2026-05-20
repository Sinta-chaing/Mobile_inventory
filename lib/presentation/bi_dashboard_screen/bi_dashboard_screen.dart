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

  // Data from other screens
  late List<backend.Invoice> _orders;
  late List<BiCustomer> _customers;
  late List<backend.Source> _suppliers;
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

  Future<void> _loadData() async {
    try {
      final orders = await OrderService.loadOrders();
      final inventory = await InventoryService.loadInventory();
      final customersData = await CustomerDataService.loadCustomers();
      final suppliers = await SupplierDataService.fetchSuppliers();

      if (mounted) {
        setState(() {
          _orders = orders;
          _stockItems = inventory;
          // Convert backend Customer to BiCustomer for BI dashboard
          _customers = customersData
              .map((c) => BiCustomer.fromBackend(c))
              .toList();
          _suppliers = suppliers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading BI data: $e');
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
            child: BIKpiGridWidget(orders: _orders, inventory: _stockItems),
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
            child: BIProfitableProductsWidget(
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
            child: BIProfitBreakdownWidget(
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
            child: BITopSupplierWidget(suppliers: _suppliers),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BITopCustomerWidget(orders: _orders, customers: _customers),
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
                    orders: _orders,
                    inventory: _stockItems,
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
                          orders: _orders
                              .where((o) => o.status == OrderStatus.paid)
                              .toList(),
                          stockItems: _stockItems,
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
                          orders: _orders
                              .where((o) => o.status == OrderStatus.paid)
                              .toList(),
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
                          orders: _orders,
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
                    orders: _orders
                        .where((o) => o.status == OrderStatus.paid)
                        .toList(),
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
