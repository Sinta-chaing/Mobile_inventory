import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../purchase_screen/purchase_screen.dart';
import '../../../presentation/inventory_screen/inventory_screen.dart';

class BIKpiGridWidget extends StatefulWidget {
  final bool isTablet;
  final List<Order> orders;
  final List<StockItem> inventory;

  const BIKpiGridWidget({
    super.key,
    this.isTablet = false,
    required this.orders,
    required this.inventory,
  });

  @override
  State<BIKpiGridWidget> createState() => _BIKpiGridWidgetState();
}

class _BIKpiGridWidgetState extends State<BIKpiGridWidget>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  List<Map<String, dynamic>> _calculateKpis() {
    final now = DateTime.now();
    final isCurrentMonth = (date) =>
        date.year == now.year && date.month == now.month;

    // Calculate Revenue MTD (This Month)
    double revenueMtd = 0;
    for (var order in widget.orders) {
      if (isCurrentMonth(order.createdDate)) {
        revenueMtd += order.total;
      }
    }

    // Calculate COGS and Gross Profit from actual paid orders
    double cogs = 0;
    for (var order in widget.orders) {
      if (isCurrentMonth(order.createdDate)) {
        for (var item in order.items) {
          final stockItem = widget.inventory.cast<StockItem?>().firstWhere(
            (s) => s!.name.toLowerCase() == item.itemName.toLowerCase(),
            orElse: () => null,
          );
          cogs += item.quantity * (stockItem?.unitCost ?? 0.0);
        }
      }
    }
    double grossProfit = revenueMtd - cogs;

    double inventoryTotalCost = 0;
    for (var item in widget.inventory) {
      inventoryTotalCost += item.unitCost * item.quantity;
    }

    double inventoryValue = inventoryTotalCost;

    // Calculate Low Stock Alerts
    int lowStockCount = 0;
    for (var item in widget.inventory) {
      if (item.quantity <= item.reorderLevel) {
        lowStockCount++;
      }
    }

    // Calculate profit margin percentage
    double profitMargin = revenueMtd > 0
        ? ((grossProfit / revenueMtd) * 100)
        : 0;

    return [
      {
        'label': 'Revenue MTD',
        'value': '\$${revenueMtd.toStringAsFixed(0)}',
        'change': '+12.4%',
        'isPositive': true,
        'icon': 'trending_up',
        'iconColor': AppTheme.success,
        'bgColor': AppTheme.successContainer,
        'subtitle': widget.orders.isEmpty
            ? 'No orders yet'
            : '${widget.orders.where((o) => isCurrentMonth(o.createdDate)).length} orders this month',
      },
      {
        'label': 'Gross Profit',
        'value': '\$${grossProfit.toStringAsFixed(0)}',
        'change': '+${profitMargin.toStringAsFixed(1)}%',
        'isPositive': true,
        'icon': 'account_balance_wallet',
        'iconColor': AppTheme.primary,
        'bgColor': AppTheme.primaryContainer,
        'subtitle': '${profitMargin.toStringAsFixed(1)}% margin',
      },
      {
        'label': 'Inventory Value',
        'value': '\$${inventoryValue.toStringAsFixed(0)}',
        'change': '-3.2%',
        'isPositive': false,
        'icon': 'inventory_2',
        'iconColor': AppTheme.warning,
        'bgColor': AppTheme.warningContainer,
        'subtitle': '${widget.inventory.length} SKUs tracked',
      },
      {
        'label': 'Low Stock Alerts',
        'value': '$lowStockCount',
        'change': '+2 new',
        'isPositive': false,
        'icon': 'warning_amber',
        'iconColor': AppTheme.error,
        'bgColor': AppTheme.errorContainer,
        'subtitle': lowStockCount > 0 ? 'Require reorder' : 'All items stocked',
      },
    ];
  }

  static IconData _iconFromString(String s) {
    switch (s) {
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'warning_amber':
        return Icons.warning_amber_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  void initState() {
    super.initState();
    final kpiMaps = _calculateKpis();
    _controllers = List.generate(
      kpiMaps.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );
    _animations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = widget.isTablet ? 4 : 2;
    final kpiMaps = _calculateKpis();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: widget.isTablet ? 1.8 : 1.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: kpiMaps.length,
      itemBuilder: (context, i) {
        final kpi = kpiMaps[i];
        return FadeTransition(
          opacity: _animations[i],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(_animations[i]),
            child: _KpiCard(
              label: kpi['label'] as String,
              value: kpi['value'] as String,
              change: kpi['change'] as String,
              isPositive: kpi['isPositive'] as bool,
              icon: _iconFromString(kpi['icon'] as String),
              iconColor: kpi['iconColor'] as Color,
              bgColor: kpi['bgColor'] as Color,
              subtitle: kpi['subtitle'] as String,
            ),
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String subtitle;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppTheme.successContainer
                      : AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1B),
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
