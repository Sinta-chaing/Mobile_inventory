import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../presentation/purchase_screen/purchase_screen.dart';

class InvoicePdfGenerator {
  static Future<void> generateAndPreviewPdf(
    BuildContext context,
    Order order,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with company info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'InvenTrack',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Invoice #: ${order.orderId}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(order.createdDate)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Status: ${order.status == OrderStatus.paid ? 'PAID' : 'PENDING'}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: order.status == OrderStatus.paid
                              ? PdfColors.green
                              : PdfColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Customer and Payment Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        order.customerName,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        order.customerPhone,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Method:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        order.paymentMethod == PaymentMethod.cash
                            ? 'Cash'
                            : 'KHQR',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Created By:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        order.createdBy,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('Description', bold: true),
                      _buildTableCell(
                        'Qty',
                        bold: true,
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        'Unit Price',
                        bold: true,
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        'Discount',
                        bold: true,
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        'Total',
                        bold: true,
                        align: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  // Items
                  ...order.items.map((item) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(item.itemName),
                        _buildTableCell(
                          item.quantity.toString(),
                          align: pw.TextAlign.center,
                        ),
                        _buildTableCell(
                          '\$${item.unitPrice.toStringAsFixed(2)}',
                          align: pw.TextAlign.center,
                        ),
                        _buildTableCell(
                          '${item.discount.toStringAsFixed(1)}%',
                          align: pw.TextAlign.center,
                        ),
                        _buildTableCell(
                          '\$${item.lineTotal.toStringAsFixed(2)}',
                          align: pw.TextAlign.center,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 250,
                  child: pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Subtotal:',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${_calculateSubtotal(order.items).toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Total Discount:',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '-\$${_calculateTotalDiscount(order.items).toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(color: PdfColors.red),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Total:',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Footer
              if (order.status == OrderStatus.paid && order.paidAt != null)
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Paid on ${DateFormat('MMM dd, yyyy HH:mm').format(order.paidAt!)}',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.green,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    // Show PDF preview using Printing package (works on all platforms)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${order.orderId}.pdf',
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: bold
            ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)
            : const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static double _calculateSubtotal(List<OrderItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  static double _calculateTotalDiscount(List<OrderItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.discountAmount);
  }
}
