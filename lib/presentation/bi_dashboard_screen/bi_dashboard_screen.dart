import 'package:flutter/material.dart';
import 'dart:ui';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import './widgets/bi_header_widget.dart';
import './widgets/bi_kpi_grid_widget.dart';
import './widgets/bi_low_stock_alerts_widget.dart';
import './widgets/bi_revenue_chart_widget.dart';
import './widgets/bi_top_items_chart_widget.dart';

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
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
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
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BIRevenueChartWidget(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: BITopItemsChartWidget(),
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
                    children: const [
                      Expanded(child: BIRevenueChartWidget()),
                      SizedBox(width: 16),
                      Expanded(child: BITopItemsChartWidget()),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: BILowStockAlertsWidget(),
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
