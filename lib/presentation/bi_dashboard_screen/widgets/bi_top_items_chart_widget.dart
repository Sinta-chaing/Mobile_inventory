import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../purchase_screen/purchase_screen.dart';
import '../../inventory_screen/inventory_screen.dart';

class BITopItemsChartWidget extends StatefulWidget {
  final List<Order> orders;
  final List<StockItem> stockItems;
  final String selectedPeriod;

  const BITopItemsChartWidget({
    super.key,
    required this.orders,
    required this.stockItems,
    required this.selectedPeriod,
  });

  @override
  State<BITopItemsChartWidget> createState() => _BITopItemsChartWidgetState();
}

class _BITopItemsChartWidgetState extends State<BITopItemsChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  late List<_TopItem> _items;

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
    _items = _buildTopItems();

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
  void didUpdateWidget(covariant BITopItemsChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders ||
        oldWidget.stockItems != widget.stockItems) {
      setState(() {
        _items = _buildTopItems();
      });
    }
  }

  List<_TopItem> _buildTopItems() {
    final itemMap = <String, Map<String, dynamic>>{};

    for (final order in widget.orders) {
      if (order.status != OrderStatus.paid) continue;
      for (final item in order.items) {
        final subtotal = item.quantity * item.unitPrice;
        final discountAmount = (subtotal * item.discount) / 100;
        final revenue = subtotal - discountAmount;

        if (!itemMap.containsKey(item.itemName)) {
          final stockItem = widget.stockItems
              .where((s) => s.name.toLowerCase() == item.itemName.toLowerCase())
              .cast<StockItem?>()
              .firstWhere((_) => true, orElse: () => null);
          itemMap[item.itemName] = {
            'sku': stockItem?.sku ?? '-',
            'revenue': 0.0,
            'units': 0,
          };
        }

        itemMap[item.itemName]!['revenue'] += revenue;
        itemMap[item.itemName]!['units'] += item.quantity;
      }
    }

    final items = itemMap.entries
        .map(
          (e) => _TopItem(
            name: e.key,
            sku: e.value['sku'] as String,
            revenue: e.value['revenue'] as double,
            units: e.value['units'] as int,
          ),
        )
        .toList();

    items.sort((a, b) => b.revenue.compareTo(a.revenue));
    return items.take(5).toList();
  }

  double get _maxY {
    if (_items.isEmpty) return 1000;
    final maxRevenue = _items
        .map((e) => e.revenue)
        .reduce((a, b) => a > b ? a : b);
    return ((maxRevenue * 1.2) / 1000).ceil() * 1000;
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
            'Top 5 Items by Revenue',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1B),
            ),
          ),
          Text(
            widget.selectedPeriod,
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
                            '${_items[groupIndex].name}\n\$${rod.toY.toStringAsFixed(0)}',
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
                                parts.last,
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
                            toY: e.value.revenue * _animation.value,
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
          // Item legend list
          if (_items.isEmpty)
            Text(
              'No paid invoice data for top items.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
          ...List.generate(_items.length, (i) {
            final item = _items[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _barColors[i],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        color: const Color(0xFF1A1C1B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.units} units',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '\$${item.revenue.toStringAsFixed(0)}',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _barColors[i],
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TopItem {
  final String name;
  final String sku;
  final double revenue;
  final int units;
  _TopItem({
    required this.name,
    required this.sku,
    required this.revenue,
    required this.units,
  });
}
