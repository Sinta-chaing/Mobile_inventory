import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/status_badge_widget.dart';
import '../inventory_screen.dart';

class InventoryItemCardWidget extends StatelessWidget {
  final StockItem item;
  final VoidCallback onTap;

  const InventoryItemCardWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  StockStatus _mapStatus(StockStatusEnum s) {
    switch (s) {
      case StockStatusEnum.inStock:
        return StockStatus.inStock;
      case StockStatusEnum.lowStock:
        return StockStatus.lowStock;
      case StockStatusEnum.outOfStock:
        return StockStatus.outOfStock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.primary.withAlpha(20),
        highlightColor: AppTheme.primary.withAlpha(10),
        child: Container(
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
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: item.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  semanticLabel: item.semanticLabel,
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
                            item.name,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1C1B),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadgeWidget.stock(_mapStatus(item.status)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.sku} · ${item.category}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetaItem(
                          icon: Icons.inventory_2_outlined,
                          label: 'Qty',
                          value: item.quantity.toString(),
                          valueColor: item.status == StockStatusEnum.outOfStock
                              ? AppTheme.error
                              : item.status == StockStatusEnum.lowStock
                              ? AppTheme.warning
                              : const Color(0xFF1A1C1B),
                        ),
                        const SizedBox(width: 16),
                        _MetaItem(
                          icon: Icons.warning_amber_outlined,
                          label: 'Reorder',
                          value: item.reorderLevel.toString(),
                          valueColor: AppTheme.outline,
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${item.unitPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              'Cost: \$${item.unitCost.toStringAsFixed(2)}',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.outline,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.outline),
        const SizedBox(width: 3),
        Text(
          '$label: ',
          style: GoogleFonts.ibmPlexSans(fontSize: 11, color: AppTheme.outline),
        ),
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
