import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../supplier_screen/supplier_screen.dart';

class BITopSupplierWidget extends StatefulWidget {
  final List<Supplier> suppliers;

  const BITopSupplierWidget({super.key, required this.suppliers});

  @override
  State<BITopSupplierWidget> createState() => _BITopSupplierWidgetState();
}

class _BITopSupplierWidgetState extends State<BITopSupplierWidget> {
  late List<_TopSupplier> _suppliers;

  @override
  void initState() {
    super.initState();
    // Sort suppliers by total orders and take top 5
    final sorted = List<Supplier>.from(widget.suppliers)
      ..sort((a, b) => b.totalOrders.compareTo(a.totalOrders));

    _suppliers = sorted
        .take(5)
        .map(
          (supplier) => _TopSupplier(
            name: supplier.name,
            totalOrders: supplier.totalOrders,
            orderCount: supplier.orderCount,
            rating: supplier.rating,
          ),
        )
        .toList();
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
            'Top Suppliers',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1B),
            ),
          ),
          Text(
            'By total order value · All time',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          // Suppliers list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suppliers.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppTheme.outlineVariant),
            itemBuilder: (context, index) {
              final supplier = _suppliers[index];
              final totalPercentage =
                  supplier.totalOrders / _suppliers[0].totalOrders;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${supplier.name}',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1C1B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${supplier.orderCount} orders',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 10,
                                      color: AppTheme.outline,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < supplier.rating.floor()
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 12,
                                        color: const Color(0xFFFFB800),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${supplier.totalOrders.toStringAsFixed(0)}',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalPercentage,
                        minHeight: 6,
                        backgroundColor: AppTheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary.withAlpha(
                            (179 - (index * 20)).toInt().clamp(0, 255),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopSupplier {
  final String name;
  final double totalOrders;
  final int orderCount;
  final double rating;

  _TopSupplier({
    required this.name,
    required this.totalOrders,
    required this.orderCount,
    required this.rating,
  });
}
