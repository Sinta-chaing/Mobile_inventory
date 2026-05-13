import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../presentation/inventory_screen/inventory_screen.dart';

class BILowStockAlertsWidget extends StatefulWidget {
  final List<StockItem> inventory;

  const BILowStockAlertsWidget({super.key, required this.inventory});

  @override
  State<BILowStockAlertsWidget> createState() => _BILowStockAlertsWidgetState();
}

class _BILowStockAlertsWidgetState extends State<BILowStockAlertsWidget> {
  // TODO: Replace with Riverpod/Bloc for production

  late List<_AlertItem> _alerts;

  List<_AlertItem> _calculateLowStockAlerts() {
    final lowStockItems = <_AlertItem>[];

    for (var item in widget.inventory) {
      if (item.quantity <= item.reorderLevel) {
        lowStockItems.add(
          _AlertItem(
            id: item.id,
            name: item.name,
            sku: item.sku,
            category: item.category,
            quantity: item.quantity,
            reorderLevel: item.reorderLevel,
            reorderQty: (item.reorderLevel * 2)
                .toInt(), // Suggest reordering 2x the reorder level
            unitCost: item.unitCost,
            supplierName: item.supplierName,
            status: item.quantity == 0 ? 'outOfStock' : 'lowStock',
            imageUrl: item.imageUrl,
            semanticLabel: item.semanticLabel,
          ),
        );
      }
    }

    // Sort by quantity (out of stock first)
    lowStockItems.sort((a, b) => a.quantity.compareTo(b.quantity));

    return lowStockItems;
  }

  @override
  void initState() {
    super.initState();
    _alerts = _calculateLowStockAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Alerts',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1B),
                  ),
                ),
                Text(
                  '${_alerts.length} items require reorder',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Create PO',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Alert cards
        ...List.generate(_alerts.length, (i) {
          return _AnimatedAlertCard(
            alert: _alerts[i],
            index: i,
            onReorder: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reorder created for ${_alerts[i].name}'),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _AlertItem {
  final String id;
  final String name;
  final String sku;
  final String category;
  final int quantity;
  final int reorderLevel;
  final int reorderQty;
  final double unitCost;
  final String supplierName;
  final String status;
  final String imageUrl;
  final String semanticLabel;

  _AlertItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.reorderQty,
    required this.unitCost,
    required this.supplierName,
    required this.status,
    required this.imageUrl,
    required this.semanticLabel,
  });

  bool get isOutOfStock => status == 'outOfStock';

  Color get accentColor => isOutOfStock ? AppTheme.stockOut : AppTheme.stockLow;

  Color get accentContainerColor =>
      isOutOfStock ? AppTheme.stockOutContainer : AppTheme.stockLowContainer;

  double get reorderCost => reorderQty * unitCost;
}

class _AnimatedAlertCard extends StatefulWidget {
  final _AlertItem alert;
  final int index;
  final VoidCallback onReorder;

  const _AnimatedAlertCard({
    required this.alert,
    required this.index,
    required this.onReorder,
  });

  @override
  State<_AnimatedAlertCard> createState() => _AnimatedAlertCardState();
}

class _AnimatedAlertCardState extends State<_AnimatedAlertCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fadeAnim);

    final delay = (widget.index * 60).clamp(0, 360);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final stockFraction = alert.reorderLevel > 0
        ? alert.quantity / alert.reorderLevel
        : 0.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(240),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(40), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomImageWidget(
                    imageUrl: alert.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    semanticLabel: alert.semanticLabel,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              alert.name,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1C1B),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: alert.accentContainerColor.withAlpha(40),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: alert.accentColor.withAlpha(80),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              alert.isOutOfStock ? 'Out of Stock' : 'Low Stock',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: alert.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alert.sku} · ${alert.supplierName}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stock progress bar
                      Row(
                        children: [
                          Text(
                            'Stock: ',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: AppTheme.outline,
                            ),
                          ),
                          Text(
                            '${alert.quantity}',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            ' / ${alert.reorderLevel} reorder pt.',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: AppTheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stockFraction.clamp(0.0, 1.0),
                          backgroundColor: alert.accentContainerColor.withAlpha(
                            60,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            alert.accentColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Suggest Reorder: ${alert.reorderQty} units',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  color: AppTheme.outline,
                                ),
                              ),
                              Text(
                                'Est. Cost: \$${alert.reorderCost.toStringAsFixed(2)}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.secondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: widget.onReorder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Reorder',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
