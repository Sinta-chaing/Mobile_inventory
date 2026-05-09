import 'package:flutter/material.dart';
import 'dart:ui';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
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
  late List<Order> _orders;
  late List<Customer> _customers;
  late List<Supplier> _suppliers;
  late List<StockItem> _stockItems;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize orders from purchase screen data
    _orders = [
      Order(
        orderId: 'ORD-2024-001',
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        customerName: 'John Doe',
        customerPhone: '+855 12 345 678',
        paymentMethod: PaymentMethod.khqr,
        total: 2999.80,
        status: OrderStatus.paid,
        paidAt: DateTime.now().subtract(const Duration(days: 4)),
        createdBy: 'Admin User',
        items: [
          OrderItem(
            itemName: 'DeWalt 20V Cordless Drill',
            quantity: 20,
            unitPrice: 149.99,
          ),
        ],
      ),
      Order(
        orderId: 'ORD-2024-002',
        createdDate: DateTime.now().subtract(const Duration(days: 2)),
        customerName: 'Jane Smith',
        customerPhone: '+855 98 765 432',
        paymentMethod: PaymentMethod.cash,
        total: 799.70,
        status: OrderStatus.pending,
        paidAt: null,
        createdBy: 'Staff Member',
        items: [
          OrderItem(
            itemName: 'Stanley FatMax Tape Measure 25ft',
            quantity: 30,
            unitPrice: 24.99,
          ),
          OrderItem(
            itemName: 'Makita Angle Grinder 4.5"',
            quantity: 5,
            unitPrice: 99.95,
          ),
        ],
      ),
      Order(
        orderId: 'ORD-2024-003',
        createdDate: DateTime.now().subtract(const Duration(hours: 3)),
        customerName: 'Mike Johnson',
        customerPhone: '+855 77 123 456',
        paymentMethod: PaymentMethod.khqr,
        total: 699.50,
        status: OrderStatus.paid,
        paidAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdBy: 'Admin User',
        items: [
          OrderItem(
            itemName: '3M Safety Glasses',
            quantity: 100,
            unitPrice: 2.50,
          ),
          OrderItem(itemName: 'Work Gloves', quantity: 50, unitPrice: 8.99),
        ],
      ),
    ];

    // Initialize customers from purchase screen
    _customers = [
      Customer(id: 'C001', name: 'John Doe', phone: '+855 12 345 678'),
      Customer(id: 'C002', name: 'Jane Smith', phone: '+855 98 765 432'),
      Customer(id: 'C003', name: 'Mike Johnson', phone: '+855 77 123 456'),
      Customer(id: 'C004', name: 'Sarah Williams', phone: '+855 55 987 654'),
      Customer(id: 'C005', name: 'David Brown', phone: '+855 66 432 109'),
    ];

    // Initialize suppliers from supplier screen
    _suppliers = [
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

    // Initialize stock items from inventory screen
    _stockItems = [
      StockItem(
        id: 'ITM001',
        name: 'DeWalt 20V Cordless Drill',
        sku: 'DW-DCD771C2',
        category: 'Power Tools',
        quantity: 34,
        reorderLevel: 10,
        unitCost: 89.50,
        unitPrice: 149.99,
        supplierName: 'ProTools Supply Co.',
        imageUrl:
            'https://images.unsplash.com/photo-1572981779307-38b8cabb2407',
        semanticLabel:
            'Yellow and black DeWalt cordless drill on white background',
      ),
      StockItem(
        id: 'ITM002',
        name: 'Stanley FatMax Tape Measure 25ft',
        sku: 'ST-FMHT33865',
        category: 'Hand Tools',
        quantity: 7,
        reorderLevel: 15,
        unitCost: 12.40,
        unitPrice: 24.99,
        supplierName: 'Meridian Hardware Dist.',
        imageUrl:
            'https://images.unsplash.com/photo-1706101426222-feb156e9c7fe',
        semanticLabel: 'Yellow Stanley tape measure coiled on wooden surface',
      ),
      StockItem(
        id: 'ITM003',
        name: 'Makita Angle Grinder 4.5"',
        sku: 'MK-9557PBX1',
        category: 'Power Tools',
        quantity: 0,
        reorderLevel: 5,
        unitCost: 54.00,
        unitPrice: 99.95,
        supplierName: 'ProTools Supply Co.',
        imageUrl:
            'https://img.rocket.new/generatedImages/rocket_gen_img_1da2285a0-1773143783458.png',
        semanticLabel:
            'Teal and black Makita angle grinder on concrete surface',
      ),
      StockItem(
        id: 'ITM004',
        name: 'Bosch 18V Circular Saw',
        sku: 'BS-CCS180B',
        category: 'Power Tools',
        quantity: 18,
        reorderLevel: 8,
        unitCost: 112.00,
        unitPrice: 199.99,
        supplierName: 'ProTools Supply Co.',
        imageUrl:
            'https://images.unsplash.com/photo-1587210019033-d2c0cf35fde2',
        semanticLabel:
            'Blue Bosch circular saw with black base on wooden surface',
      ),
      StockItem(
        id: 'ITM005',
        name: '3M Safety Glasses',
        sku: '3M-90966-80025',
        category: 'Safety Equipment',
        quantity: 200,
        reorderLevel: 50,
        unitCost: 1.20,
        unitPrice: 2.50,
        supplierName: 'SafeGuard Industrial',
        imageUrl:
            'https://images.unsplash.com/photo-1572981779307-38b8cabb2407',
        semanticLabel: 'Clear 3M safety glasses on white background',
      ),
      StockItem(
        id: 'ITM006',
        name: 'Work Gloves',
        sku: 'WG-LEATHER-LG',
        category: 'Safety Equipment',
        quantity: 150,
        reorderLevel: 30,
        unitCost: 3.50,
        unitPrice: 8.99,
        supplierName: 'SafeGuard Industrial',
        imageUrl:
            'https://images.unsplash.com/photo-1572981779307-38b8cabb2407',
        semanticLabel: 'Brown leather work gloves on white background',
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

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
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BIKpiGridWidget(),
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
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BILowStockAlertsWidget(),
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
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: BIKpiGridWidget(isTablet: true),
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
                      Expanded(child: BILowStockAlertsWidget()),
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
