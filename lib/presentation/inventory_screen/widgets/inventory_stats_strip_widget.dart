import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../inventory_screen.dart';

class InventoryStatsStripWidget extends StatelessWidget {
  final List<StockItem> items;

  const InventoryStatsStripWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final inStock = items
        .where((i) => i.status == StockStatusEnum.inStock)
        .length;
    final lowStock = items
        .where((i) => i.status == StockStatusEnum.lowStock)
        .length;
    final outOfStock = items
        .where((i) => i.status == StockStatusEnum.outOfStock)
        .length;

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _StatChip(
            label: 'In Stock',
            count: inStock,
            color: AppTheme.stockIn,
            bgColor: AppTheme.stockInContainer,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Low Stock',
            count: lowStock,
            color: AppTheme.stockLow,
            bgColor: AppTheme.stockLowContainer,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Out of Stock',
            count: outOfStock,
            color: AppTheme.stockOut,
            bgColor: AppTheme.stockOutContainer,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
