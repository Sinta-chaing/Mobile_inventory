import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../purchase_screen/purchase_screen.dart';
import '../../inventory_screen/inventory_screen.dart';

class BIProfitableProductsWidget extends StatefulWidget {
  final List<Order> orders;
  final List<StockItem> stockItems;

  const BIProfitableProductsWidget({
    super.key,
    required this.orders,
    required this.stockItems,
  });

  @override
  State<BIProfitableProductsWidget> createState() =>
      _BIProfitableProductsWidgetState();
}

class _BIProfitableProductsWidgetState extends State<BIProfitableProductsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<_ProfitableProduct> _items;
  int _touchedIndex = -1;

  static const List<Color> _barColors = [
    AppTheme.primary,
    AppTheme.primaryLight,
    Color(0xFF2D8A74),
    Color(0xFF3AA88E),
    AppTheme.outline,
  ];

  @override
  void initState() {
    super.initState();
    _generateProfitableProducts();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant BIProfitableProductsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders ||
        oldWidget.stockItems != widget.stockItems) {
      setState(() {
        _generateProfitableProducts();
      });
    }
  }

  void _generateProfitableProducts() {
    final productProfits = <String, Map<String, dynamic>>{};

    // Calculate profit for each product from paid orders
    for (final order in widget.orders) {
      if (order.status != OrderStatus.paid) continue;
      for (final item in order.items) {
        final stockItem = widget.stockItems
            .where((s) => s.name.toLowerCase() == item.itemName.toLowerCase())
            .cast<StockItem?>()
            .firstWhere((_) => true, orElse: () => null);
        final costPrice = stockItem?.unitCost ?? 0.0;
        final subtotal = item.quantity * item.unitPrice;
        final discountAmount = (subtotal * item.discount) / 100;
        final revenue = subtotal - discountAmount;
        final totalCost = item.quantity * costPrice;
        final profit = revenue - totalCost;

        if (!productProfits.containsKey(item.itemName)) {
          productProfits[item.itemName] = {
            'profit': 0.0,
            'revenue': 0.0,
            'units': 0,
          };
        }
        productProfits[item.itemName]!['profit'] += profit;
        productProfits[item.itemName]!['revenue'] += revenue;
        productProfits[item.itemName]!['units'] += item.quantity;
      }
    }

    // Convert to list and sort by profit descending
    final products = productProfits.entries.map((e) {
      final profit = e.value['profit'] as double;
      final revenue = e.value['revenue'] as double;
      final units = e.value['units'] as int;
      final margin = revenue > 0 ? profit / revenue : 0.0;

      return _ProfitableProduct(
        name: e.key,
        profit: profit,
        units: units,
        margin: margin,
      );
    }).toList();

    products.sort((a, b) => b.profit.compareTo(a.profit));
    _items = products.take(5).toList();
  }

  double get _maxY {
    if (_items.isEmpty) return 1000;
    final maxProfit = _items
        .map((e) => e.profit)
        .reduce((a, b) => a > b ? a : b);
    return ((maxProfit * 1.2) / 1000).ceil() * 1000;
  }

  double get _yInterval => (_maxY / 4).clamp(250, 5000);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Text(
            'Top 5 Profitable Products',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1B),
            ),
          ),
          Text(
            'Month to date · Apr 2026',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: const Color(0xFF2E3130),
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${_items[groupIndex].name}\n\$${rod.toY.toStringAsFixed(0)}\n${(_items[groupIndex].margin * 100).toStringAsFixed(0)}% margin',
                            GoogleFonts.ibmPlexMono(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                      touchCallback: (event, response) {
                        setState(() {
                          if (response == null ||
                              response.spot == null ||
                              event is FlTapUpEvent == false) {
                            _touchedIndex = -1;
                          } else {
                            _touchedIndex = response.spot!.touchedBarGroupIndex;
                          }
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: _yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            final formatted = value >= 1000
                                ? (value % 1000 == 0
                                    ? '\$${(value / 1000).toStringAsFixed(0)}k'
                                    : '\$${(value / 1000).toStringAsFixed(1)}k')
                                : '\$${value.toStringAsFixed(0)}';
                            return Text(
                              formatted,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 10,
                                color: AppTheme.outline,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= _items.length) {
                              return const SizedBox.shrink();
                            }
                            final parts = _items[idx].name.split(' ');
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                parts.first,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 9,
                                  color: AppTheme.outline,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _yInterval,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.outlineVariant,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _items.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedIndex;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.profit * _animation.value,
                            color: isTouched
                                ? _barColors[e.key].withAlpha(179)
                                : _barColors[e.key],
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: _maxY,
                              color: AppTheme.surfaceVariant,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Legend
          if (_items.isEmpty)
            Text(
              'No paid invoice data for profitable products.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _items.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _barColors[e.key],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${e.value.name} (\$${e.value.profit.toStringAsFixed(0)})',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: const Color(0xFF1A1C1B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfitableProduct {
  final String name;
  final double profit;
  final int units;
  final double margin;

  _ProfitableProduct({
    required this.name,
    required this.profit,
    required this.units,
    required this.margin,
  });
}
