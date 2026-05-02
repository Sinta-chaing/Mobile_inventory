import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class InventoryAppBarWidget extends StatelessWidget {
  final int itemCount;
  final double totalValue;

  const InventoryAppBarWidget({
    super.key,
    required this.itemCount,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1B),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                '$itemCount items · \$${totalValue.toStringAsFixed(0)} value',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            color: AppTheme.outline,
            tooltip: 'Alerts',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
            color: AppTheme.outline,
            tooltip: 'Sort',
          ),
        ],
      ),
    );
  }
}
