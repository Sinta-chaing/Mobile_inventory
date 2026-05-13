import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../presentation/purchase_screen/purchase_screen.dart';

class BIDashboardPdfGenerator {
  static Future<void> generateAndSharePdf(
    BuildContext context,
    String selectedPeriod,
    List<Order> orders,
    List<dynamic> inventory,
    List<dynamic> customers,
    List<dynamic> suppliers,
    DateTime? generatedAt,
  ) async {
    try {
      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating PDF Report...'),
              ],
            ),
          ),
        );
      }

      final pdf = pw.Document();
      final now = generatedAt ?? DateTime.now();
      final formattedDate = DateFormat('MMM dd, yyyy · HH:mm a').format(now);

      // Calculate metrics
      final totalOrders = orders.length;
      final totalOrderValue = orders.fold<double>(
        0.0,
        (sum, order) =>
            sum +
            order.items.fold<double>(
              0.0,
              (itemSum, item) => itemSum + (item.unitPrice * item.quantity),
            ),
      );
      final totalInventoryValue = inventory.fold<double>(
        0.0,
        (sum, item) => sum + (item.unitCost * item.quantity),
      );
      final totalCustomers = customers.length;
      final totalSuppliers = suppliers.length;

      // Calculate revenue by item
      Map<String, double> itemRevenue = {};
      for (var order in orders) {
        for (var item in order.items) {
          itemRevenue[item.itemName] =
              (itemRevenue[item.itemName] ?? 0) +
              (item.unitPrice * item.quantity);
        }
      }

      // Calculate inventory status
      int inStock = 0;
      int lowStock = 0;
      int outOfStock = 0;
      for (var item in inventory) {
        if (item.quantity == 0) {
          outOfStock++;
        } else if (item.quantity <= item.reorderLevel) {
          lowStock++;
        } else {
          inStock++;
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BUSINESS INTELLIGENCE',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Dashboard Report',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'InvenTrack',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          formattedDate,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Period and Filters
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Period: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(selectedPeriod),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Key Metrics
                pw.Text(
                  'KEY METRICS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    _buildMetricBox('Total Orders', '$totalOrders'),
                    pw.SizedBox(width: 16),
                    _buildMetricBox(
                      'Order Value',
                      '\$${totalOrderValue.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    _buildMetricBox(
                      'Inventory Value',
                      '\$${totalInventoryValue.toStringAsFixed(0)}',
                    ),
                    pw.SizedBox(width: 16),
                    _buildMetricBox('Total Customers', '$totalCustomers'),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Inventory Status
                pw.Text(
                  'INVENTORY STATUS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    _buildStatusBox('In Stock', '$inStock', '00AA00'),
                    pw.SizedBox(width: 16),
                    _buildStatusBox('Low Stock', '$lowStock', 'FF9800'),
                    pw.SizedBox(width: 16),
                    _buildStatusBox('Out of Stock', '$outOfStock', 'FF0000'),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Revenue by Item
                if (itemRevenue.isNotEmpty) ...[
                  pw.Text(
                    'REVENUE BY ITEM',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 1,
                    ),
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Item Name',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Revenue',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      ...itemRevenue.entries.map(
                        (entry) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(entry.key),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                '\$${entry.value.toStringAsFixed(2)}',
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                ],

                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SUMMARY',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Total Suppliers: $totalSuppliers',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Total Customers: $totalCustomers',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Active Orders: $totalOrders',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF and share
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      final bytes = await pdf.save();

      if (context.mounted) {
        // Use printing package's built-in share for web compatibility
        await Printing.sharePdf(
          bytes: bytes,
          filename:
              'BI_Dashboard_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf',
        );
      }
    } catch (e) {
      print('PDF Generation Error: $e');
      if (context.mounted) {
        // Try to close dialog if still open
        try {
          Navigator.of(context).pop();
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static pw.Widget _buildMetricBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildStatusBox(String label, String count, String color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromHex(color)),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex(color)),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              count,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
