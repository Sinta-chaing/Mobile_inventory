import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class BIRevenueChartWidget extends StatefulWidget {
  const BIRevenueChartWidget({super.key});

  @override
  State<BIRevenueChartWidget> createState() => _BIRevenueChartWidgetState();
}

class _BIRevenueChartWidgetState extends State<BIRevenueChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final int _touchedIndex = -1;

  // 7-day revenue data (realistic variance — not a smooth upward curve)
  static final List<Map<String, dynamic>> _revenueDataMaps = [
    {'day': 'Apr 21', 'revenue': 5820.0, 'cogs': 3490.0},
    {'day': 'Apr 22', 'revenue': 7340.0, 'cogs': 4400.0},
    {'day': 'Apr 23', 'revenue': 4120.0, 'cogs': 2470.0},
    {'day': 'Apr 24', 'revenue': 8950.0, 'cogs': 5370.0},
    {'day': 'Apr 25', 'revenue': 6780.0, 'cogs': 4070.0},
    {'day': 'Apr 26', 'revenue': 9210.0, 'cogs': 5530.0},
    {'day': 'Apr 27', 'revenue': 6100.0, 'cogs': 3660.0},
  ];

  late List<_RevenuePoint> _points;

  @override
  void initState() {
    super.initState();
    _points = _revenueDataMaps
        .map(
          (m) => _RevenuePoint(
            day: m['day'] as String,
            revenue: m['revenue'] as double,
            cogs: m['cogs'] as double,
          ),
        )
        .toList();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppTheme.primary;
    final secondary = AppTheme.secondary;

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
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-Day Revenue Trend',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1B),
                    ),
                  ),
                  Text(
                    'Apr 21 – Apr 27, 2026',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _LegendDot(color: primary, label: 'Revenue'),
              const SizedBox(width: 12),
              _LegendDot(color: secondary, label: 'COGS'),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 3000,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.outlineVariant,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: 3000,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(
                              '\$${(value / 1000).toStringAsFixed(0)}k',
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
                            if (idx < 0 || idx >= _points.length) {
                              return const SizedBox.shrink();
                            }
                            final parts = _points[idx].day.split(' ');
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                parts.length > 1 ? parts[1] : parts[0],
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 10,
                                  color: AppTheme.outline,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    minX: 0,
                    maxX: (_points.length - 1).toDouble(),
                    minY: 0,
                    maxY: 12000,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: const Color(0xFF2E3130),
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            final idx = spot.x.toInt();
                            final label = spot.barIndex == 0
                                ? 'Revenue'
                                : 'COGS';
                            return LineTooltipItem(
                              '$label\n\$${spot.y.toStringAsFixed(0)}',
                              GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Revenue line
                      LineChartBarData(
                        spots: _points.asMap().entries.map((e) {
                          return FlSpot(
                            e.key.toDouble(),
                            e.value.revenue * _animation.value,
                          );
                        }).toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: primary,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 3.5,
                                color: primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              primary.withAlpha(56),
                              primary.withAlpha(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // COGS line
                      LineChartBarData(
                        spots: _points.asMap().entries.map((e) {
                          return FlSpot(
                            e.key.toDouble(),
                            e.value.cogs * _animation.value,
                          );
                        }).toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: secondary,
                        barWidth: 2,
                        dashArray: [5, 4],
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryChip(
                label: 'Total Revenue',
                value:
                    '\$${_points.fold(0.0, (s, p) => s + p.revenue).toStringAsFixed(0)}',
                color: primary,
              ),
              _SummaryChip(
                label: 'Total COGS',
                value:
                    '\$${_points.fold(0.0, (s, p) => s + p.cogs).toStringAsFixed(0)}',
                color: secondary,
              ),
              _SummaryChip(
                label: 'Gross Profit',
                value:
                    '\$${(_points.fold(0.0, (s, p) => s + p.revenue) - _points.fold(0.0, (s, p) => s + p.cogs)).toStringAsFixed(0)}',
                color: AppTheme.info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenuePoint {
  final String day;
  final double revenue;
  final double cogs;
  _RevenuePoint({required this.day, required this.revenue, required this.cogs});
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(fontSize: 11, color: AppTheme.outline),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(fontSize: 10, color: AppTheme.outline),
        ),
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}