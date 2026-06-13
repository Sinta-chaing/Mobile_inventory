import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum StockStatus { inStock, lowStock, outOfStock }

enum OrderStatus { draft, submitted, received, cancelled }

enum InvoiceStatus { draft, sent, paid, overdue }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 11,
  });

  factory StatusBadgeWidget.stock(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return StatusBadgeWidget(
          label: 'In Stock',
          backgroundColor: AppTheme.stockInContainer,
          textColor: AppTheme.stockIn,
        );
      case StockStatus.lowStock:
        return StatusBadgeWidget(
          label: 'Low Stock',
          backgroundColor: AppTheme.stockLowContainer,
          textColor: AppTheme.stockLow,
        );
      case StockStatus.outOfStock:
        return StatusBadgeWidget(
          label: 'Out of Stock',
          backgroundColor: AppTheme.stockOutContainer,
          textColor: AppTheme.stockOut,
        );
    }
  }

  factory StatusBadgeWidget.order(OrderStatus status) {
    switch (status) {
      case OrderStatus.draft:
        return const StatusBadgeWidget(
          label: 'Draft',
          backgroundColor: Color(0xFFE5E7EB),
          textColor: Color(0xFF374151),
        );
      case OrderStatus.submitted:
        return const StatusBadgeWidget(
          label: 'Submitted',
          backgroundColor: AppTheme.infoContainer,
          textColor: AppTheme.info,
        );
      case OrderStatus.received:
        return const StatusBadgeWidget(
          label: 'Received',
          backgroundColor: AppTheme.successContainer,
          textColor: AppTheme.success,
        );
      case OrderStatus.cancelled:
        return const StatusBadgeWidget(
          label: 'Cancelled',
          backgroundColor: AppTheme.errorContainer,
          textColor: AppTheme.error,
        );
    }
  }

  factory StatusBadgeWidget.invoice(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return const StatusBadgeWidget(
          label: 'Draft',
          backgroundColor: Color(0xFFE5E7EB),
          textColor: Color(0xFF374151),
        );
      case InvoiceStatus.sent:
        return const StatusBadgeWidget(
          label: 'Sent',
          backgroundColor: AppTheme.infoContainer,
          textColor: AppTheme.info,
        );
      case InvoiceStatus.paid:
        return const StatusBadgeWidget(
          label: 'Paid',
          backgroundColor: AppTheme.successContainer,
          textColor: AppTheme.success,
        );
      case InvoiceStatus.overdue:
        return const StatusBadgeWidget(
          label: 'Overdue',
          backgroundColor: AppTheme.errorContainer,
          textColor: AppTheme.error,
        );
    }
  }

  factory StatusBadgeWidget.product(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const StatusBadgeWidget(
          label: 'Active',
          backgroundColor: AppTheme.successContainer,
          textColor: AppTheme.success,
        );
      case 'inactive':
        return const StatusBadgeWidget(
          label: 'Inactive',
          backgroundColor: Color.fromARGB(255, 226, 33, 8),
          textColor: Color.fromARGB(255, 250, 250, 250),
        );
      case 'discount':
        return const StatusBadgeWidget(
          label: 'Discount',
          backgroundColor: AppTheme.warningContainer,
          textColor: AppTheme.warning,
        );
      default:
        return StatusBadgeWidget(
          label: status,
          backgroundColor: const Color(0xFFE5E7EB),
          textColor: const Color(0xFF374151),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
