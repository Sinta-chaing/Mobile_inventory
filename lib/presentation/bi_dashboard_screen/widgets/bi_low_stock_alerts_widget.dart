import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class BILowStockAlertsWidget extends StatefulWidget {
  const BILowStockAlertsWidget({super.key});

  @override
  State<BILowStockAlertsWidget> createState() => _BILowStockAlertsWidgetState();
}

class _BILowStockAlertsWidgetState extends State<BILowStockAlertsWidget> {
  // TODO: Replace with Riverpod/Bloc for production

  static final List<Map<String, dynamic>> _alertMaps = [
    {
      'id': 'ITM003',
      'name': 'Makita Angle Grinder 4.5"',
      'sku': 'MK-9557PBX1',
      'category': 'Power Tools',
      'quantity': 0,
      'reorderLevel': 5,
      'reorderQty': 10,
      'unitCost': 54.00,
      'supplierName': 'ProTools Supply Co.',
      'status': 'outOfStock',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1da2285a0-1773143783458.png',
      'semanticLabel':
          'Teal and black Makita angle grinder on concrete surface',
    },
    {
      'id': 'ITM002',
      'name': 'Stanley FatMax Tape Measure 25ft',
      'sku': 'ST-FMHT33865',
      'category': 'Hand Tools',
      'quantity': 7,
      'reorderLevel': 15,
      'reorderQty': 25,
      'unitCost': 12.40,
      'supplierName': 'Meridian Hardware Dist.',
      'status': 'lowStock',
      'imageUrl':
          'https://images.unsplash.com/photo-1706101426222-feb156e9c7fe',
      'semanticLabel': 'Yellow Stanley tape measure coiled on wooden surface',
    },
    {
      'id': 'ITM006',
      'name': 'Milwaukee M18 Impact Driver',
      'sku': 'MW-2853-20',
      'category': 'Power Tools',
      'quantity': 5,
      'reorderLevel': 6,
      'reorderQty': 12,
      'unitCost': 135.00,
      'supplierName': 'ProTools Supply Co.',
      'status': 'lowStock',
      'imageUrl':
          'https://images.unsplash.com/photo-1716662383104-1dcc763a916d',
      'semanticLabel': 'Red Milwaukee impact driver on black background',
    },
    {
      'id': 'ITM008',
      'name': 'Klein Tools Level 24"',
      'sku': 'KL-935-24',
      'category': 'Measuring',
      'quantity': 4,
      'reorderLevel': 8,
      'reorderQty': 15,
      'unitCost': 22.00,
      'supplierName': 'Meridian Hardware Dist.',
      'status': 'lowStock',
      'imageUrl':
          'https://images.unsplash.com/photo-1696423284373-d836682ed2d0',
      'semanticLabel':
          'Yellow spirit level on wooden plank in construction site',
    },
    {
      'id': 'ITM012',
      'name': 'Ridgid Shop Vac 9-Gallon',
      'sku': 'RD-WD09700',
      'category': 'Cleaning',
      'quantity': 3,
      'reorderLevel': 4,
      'reorderQty': 8,
      'unitCost': 58.00,
      'supplierName': 'Meridian Hardware Dist.',
      'status': 'lowStock',
      'imageUrl':
          'https://images.unsplash.com/photo-1560833411-6889bf875858',
      'semanticLabel': 'Red and black shop vacuum cleaner in warehouse setting',
    },
    {
      'id': 'ITM011',
      'name': 'Fluke Digital Multimeter',
      'sku': 'FL-117-KIT',
      'category': 'Measuring',
      'quantity': 11,
      'reorderLevel': 5,
      'reorderQty': 10,
      'unitCost': 68.00,
      'supplierName': 'ElectroMart Supplies',
      'status': 'lowStock',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15ec1cdcf-1770142869318.png',
      'semanticLabel': 'Yellow Fluke digital multimeter with test probes',
    },
  ];

  late List<_AlertItem> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = _alertMaps.map((m) => _AlertItem.fromMap(m)).toList();
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

  factory _AlertItem.fromMap(Map<String, dynamic> m) {
    return _AlertItem(
      id: m['id'] as String,
      name: m['name'] as String,
      sku: m['sku'] as String,
      category: m['category'] as String,
      quantity: m['quantity'] as int,
      reorderLevel: m['reorderLevel'] as int,
      reorderQty: m['reorderQty'] as int,
      unitCost: (m['unitCost'] as num).toDouble(),
      supplierName: m['supplierName'] as String,
      status: m['status'] as String,
      imageUrl: m['imageUrl'] as String,
      semanticLabel: m['semanticLabel'] as String,
    );
  }

  bool get isOutOfStock => status == 'outOfStock';

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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: alert.isOutOfStock ? AppTheme.error : AppTheme.warning,
                width: 3,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: alert.imageUrl,
                  width: 48,
                  height: 48,
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
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: alert.isOutOfStock
                                ? AppTheme.errorContainer
                                : AppTheme.warningContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            alert.isOutOfStock ? 'Out of Stock' : 'Low Stock',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: alert.isOutOfStock
                                  ? AppTheme.error
                                  : AppTheme.warning,
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
                            color: alert.isOutOfStock
                                ? AppTheme.error
                                : AppTheme.warning,
                            fontFeatures: const [FontFeature.tabularFigures()],
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
                        backgroundColor: AppTheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          alert.isOutOfStock
                              ? AppTheme.error
                              : AppTheme.warning,
                        ),
                        minHeight: 5,
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
                                color: AppTheme.primary,
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
                              backgroundColor: alert.isOutOfStock
                                  ? AppTheme.error
                                  : AppTheme.primary,
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
    );
  }
}
