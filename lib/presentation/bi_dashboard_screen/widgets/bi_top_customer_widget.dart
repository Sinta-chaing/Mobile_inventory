import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../purchase_screen/purchase_screen.dart';

class BITopCustomerWidget extends StatefulWidget {
  final List<Order> orders;
  final List<Customer> customers;

  const BITopCustomerWidget({
    super.key,
    required this.orders,
    required this.customers,
  });

  @override
  State<BITopCustomerWidget> createState() => _BITopCustomerWidgetState();
}

class _BITopCustomerWidgetState extends State<BITopCustomerWidget> {
  late List<_TopCustomer> _customers;

  @override
  void initState() {
    super.initState();
    _generateCustomerStats();
  }

  void _generateCustomerStats() {
    // Group orders by customer and calculate total spent and order count
    final customerMap = <String, Map<String, dynamic>>{};

    for (final order in widget.orders) {
      if (!customerMap.containsKey(order.customerName)) {
        customerMap[order.customerName] = {
          'name': order.customerName,
          'phone': order.customerPhone,
          'totalSpent': 0.0,
          'orderCount': 0,
        };
      }
      customerMap[order.customerName]!['totalSpent'] += order.total;
      customerMap[order.customerName]!['orderCount']++;
    }

    // Convert to list and sort by totalSpent descending
    final customerList = customerMap.values.toList();
    customerList.sort(
      (a, b) =>
          (b['totalSpent'] as double).compareTo(a['totalSpent'] as double),
    );

    // Take top 5 and convert to _TopCustomer
    _customers = customerList
        .take(5)
        .map(
          (m) => _TopCustomer(
            name: m['name'] as String,
            totalSpent: m['totalSpent'] as double,
            orderCount: m['orderCount'] as int,
            phone: m['phone'] as String,
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
            'Top Customers',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1B),
            ),
          ),
          Text(
            'By total spending · All time',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          // Customers list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _customers.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppTheme.outlineVariant),
            itemBuilder: (context, index) {
              final customer = _customers[index];
              final totalPercentage =
                  customer.totalSpent / _customers[0].totalSpent;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(
                              (230 - (index * 40)).toInt().clamp(0, 255),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1C1B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${customer.orderCount} orders',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 10,
                                  color: AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${customer.totalSpent.toStringAsFixed(0)}',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.phone,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 9,
                                color: AppTheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                          const Color(0xFF2D8A74).withAlpha(
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

class _TopCustomer {
  final String name;
  final double totalSpent;
  final int orderCount;
  final String phone;

  _TopCustomer({
    required this.name,
    required this.totalSpent,
    required this.orderCount,
    required this.phone,
  });
}
