import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_models.dart';

class OrderService {
  static const String _ordersKey = 'orders_data';
  static late SharedPreferences _prefs;

  // Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Fetch orders from local cache
  /// (Backend API integration removed - using local storage only)
  static Future<List<Invoice>> fetchOrders() async {
    return await loadOrders();
  }

  /// Create new order and save to local storage
  static Future<Invoice?> createOrder(Map<String, dynamic> orderData) async {
    try {
      final purchases = (orderData['items'] ?? []) as List;
      final purchasesList = purchases
          .asMap()
          .entries
          .map(
            (e) => Purchase(
              purchaseId: e.key,
              invoiceId: 0, // Will be set when added to invoice
              productId: e.value['productId'],
              quantity: e.value['quantity'] ?? 0,
              pricePerUnit: (e.value['pricePerUnit'] ?? 0).toDouble(),
              discount: (e.value['discount'] ?? 0).toDouble(),
              subtotal: (e.value['subtotal'] ?? 0).toDouble(),
              createdAt: DateTime.now(),
            ),
          )
          .toList();

      final invoice = Invoice(
        invoiceId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        invoiceNumber: orderData['invoiceNumber'],
        customerId: orderData['customerId'],
        customerName: orderData['customerName'] ?? 'Unknown',
        customerPhone: orderData['customerPhone'],
        createdByUserId: orderData['createdByUserId'],
        totalBeforeDiscount: (orderData['totalBeforeDiscount'] ?? 0).toDouble(),
        discount: (orderData['discount'] ?? 0).toDouble(),
        tax: (orderData['tax'] ?? 0).toDouble(),
        grandTotal: (orderData['grandTotal'] ?? 0).toDouble(),
        paymentMethod: orderData['paymentMethod'] ?? 'Cash',
        note: orderData['note'],
        status: 'Pending',
        paidAt: null,
        createdAt: DateTime.now(),
        purchases: purchasesList,
      );

      // Load existing invoices and add new one
      final invoices = await loadOrders();
      invoices.add(invoice);

      // Save to local storage
      await saveOrders(invoices);
      print('✅ Invoice created locally: ${invoice.invoiceNumber}');

      return invoice;
    } catch (e) {
      print('❌ Error creating invoice: $e');
      return null;
    }
  }

  /// Update order status in local storage
  static Future<bool> updateOrderStatus(int invoiceId, String status) async {
    try {
      final invoices = await loadOrders();
      final index = invoices.indexWhere((inv) => inv.invoiceId == invoiceId);

      if (index == -1) {
        print('❌ Invoice not found: $invoiceId');
        return false;
      }

      // Update status
      final invoice = invoices[index];
      final newStatus = status.toLowerCase() == 'paid' ? 'Paid' : 'Pending';

      invoices[index] = Invoice(
        invoiceId: invoice.invoiceId,
        invoiceNumber: invoice.invoiceNumber,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        createdByUserId: invoice.createdByUserId,
        totalBeforeDiscount: invoice.totalBeforeDiscount,
        discount: invoice.discount,
        tax: invoice.tax,
        grandTotal: invoice.grandTotal,
        paymentMethod: invoice.paymentMethod,
        note: invoice.note,
        status: newStatus,
        paidAt: newStatus == 'Paid' ? DateTime.now() : invoice.paidAt,
        khqrCodeString: invoice.khqrCodeString,
        khqrMd5: invoice.khqrMd5,
        khqrTransactionHash: invoice.khqrTransactionHash,
        khqrShortHash: invoice.khqrShortHash,
        khqrDeeplink: invoice.khqrDeeplink,
        khqrLastCheckedAt: invoice.khqrLastCheckedAt,
        khqrPaymentData: invoice.khqrPaymentData,
        createdAt: invoice.createdAt,
        purchases: invoice.purchases,
      );

      // Save updated invoices
      await saveOrders(invoices);
      print('✅ Invoice status updated: $invoiceId -> $status');
      return true;
    } catch (e) {
      print('❌ Error updating invoice: $e');
      return false;
    }
  }

  /// Mark order as paid in local storage
  static Future<bool> markOrderAsPaid(int invoiceId) async {
    return updateOrderStatus(invoiceId, 'paid');
  }

  // Save orders to persistent storage
  static Future<void> saveOrders(List<Invoice> invoices) async {
    try {
      final jsonData = invoices.map((invoice) => invoice.toJson()).toList();
      await _prefs.setString(_ordersKey, jsonEncode(jsonData));
      print('✅ Saved ${invoices.length} invoices to SharedPreferences');
    } catch (e) {
      print('❌ Error saving invoices: $e');
    }
  }

  // Load orders from persistent storage
  static Future<List<Invoice>> loadOrders() async {
    try {
      final jsonString = _prefs.getString(_ordersKey);
      print(
        '📦 Retrieved from SharedPreferences: ${jsonString?.length ?? 0} characters',
      );
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonData = jsonDecode(jsonString) as List;
      print('✅ Loaded ${jsonData.length} invoices from SharedPreferences');
      return jsonData
          .map((item) => Invoice.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error loading invoices: $e');
      return [];
    }
  }

  /// Verify payment status with KHQR payment gateway (Stub - not functional)
  /// Since there's no backend API, this always returns false
  static Future<bool> verifyKhqrPayment(String orderId, double amount) async {
    print(
      '⚠️ Payment verification stub called for order $orderId (amount: $amount)',
    );
    return false;
  }
}
