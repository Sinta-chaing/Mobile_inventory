import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/all_models.dart';
import './api_service.dart';

class OrderService {
  static const String _ordersKey = 'orders_data';
  static late SharedPreferences _prefs;
  static late ApiService _apiService;

  // Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _apiService = ApiService();
  }

  /// Fetch invoices from backend API
  /// Falls back to local cache if API fails
  static Future<List<Invoice>> fetchOrders() async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('⚠️ Not authenticated - using local cache');
        return await loadOrders();
      }

      final response = await _apiService.get(
        '/api/invoices/',
        fromJson: (data) => (data as List)
            .map((item) => Invoice.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      // Save to local cache for offline access
      await saveOrders(response);
      print('✅ Fetched ${response.length} invoices from backend');
      return response;
    } catch (e) {
      print('⚠️ Failed to fetch from API: $e - Using local cache');
      return await loadOrders();
    }
  }

  /// Create new invoice on backend
  static Future<Invoice?> createOrder(Map<String, dynamic> orderData) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot create order on backend');
        return null;
      }

      print('📤 Creating invoice on backend...');

      // Build lineItems from the order data if provided
      final lineItems = orderData['lineItems'] ?? [];

      // Build payload with correct field names - backend will calculate totals
      final payload = {
        // Don't send invoiceNumber - backend auto-generates it
        'customer': orderData['customerId'], // Use 'customer' not 'customerId'
        'customerName': orderData['customerName'] ?? 'Guest',
        'customerPhone': orderData['customerPhone'],
        'paymentMethod': orderData['paymentMethod'] ?? 'Cash',
        'note': orderData['note'],
        'taxPercentage': orderData['taxPercentage'] ?? 0,
        // Don't send totalBeforeDiscount, discount, grandTotal - backend calculates them
        'lineItems': lineItems, // Include purchases/line items
      };

      print('📋 Payload: $payload');

      final invoice = await _apiService.post(
        '/api/invoices/',
        data: payload,
        fromJson: (data) => Invoice.fromJson(data as Map<String, dynamic>),
      );

      print(
        '✅ Invoice created on backend: ${invoice.invoiceNumber} (ID: ${invoice.invoiceId})',
      );

      // IMPORTANT: Save to local cache immediately!
      print('💾 Adding invoice to local cache...');
      final invoices = await loadOrders();
      invoices.add(invoice);
      await saveOrders(invoices);
      print('✅ Invoice saved to local cache');

      return invoice;
    } catch (e, stackTrace) {
      print('❌ Error creating invoice: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update invoice status on backend
  static Future<bool> updateOrderStatus(int invoiceId, String status) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot update invoice on backend');
        return false;
      }

      print('📤 Updating invoice status on backend: $invoiceId -> $status');

      final newStatus = status.toLowerCase() == 'paid'
          ? 'Paid'
          : (status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'canceled')
              ? 'Cancelled'
              : 'Pending';
      final payload = {'status': newStatus};

      await _apiService.patch(
        '/api/invoices/$invoiceId/',
        data: payload,
        fromJson: (data) => data,
      );

      print('✅ Invoice status updated on backend');

      // Update local cache directly without doing a slow GET fetch Orders API request
      await _updateOrderStatusLocal(invoiceId, status);
      return true;
    } catch (e) {
      print('❌ Error updating invoice: $e');
      // Fallback to local update
      return await _updateOrderStatusLocal(invoiceId, status);
    }
  }

  /// Local fallback for updating invoice status
  static Future<bool> _updateOrderStatusLocal(
    int invoiceId,
    String status,
  ) async {
    try {
      final invoices = await loadOrders();
      final index = invoices.indexWhere((inv) => inv.invoiceId == invoiceId);

      if (index == -1) {
        print('❌ Invoice not found: $invoiceId');
        return false;
      }

      final invoice = invoices[index];
      final newStatus = status.toLowerCase() == 'paid'
          ? 'Paid'
          : (status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'canceled')
              ? 'Cancelled'
              : 'Pending';

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
      print('✅ Invoice status updated locally: $invoiceId -> $status');
      return true;
    } catch (e) {
      print('❌ Error updating invoice locally: $e');
      return false;
    }
  }

  /// Mark order as paid in local storage
  static Future<bool> markOrderAsPaid(int invoiceId) async {
    return updateOrderStatus(invoiceId, 'paid');
  }

  /// Delete order/invoice from backend
  static Future<bool> deleteOrder(int invoiceId) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot delete order on backend');
        return false;
      }

      print('📤 Deleting invoice on backend: $invoiceId');

      await _apiService.delete('/api/invoices/$invoiceId/');

      print('✅ Invoice deleted on backend');

      // Remove from local cache
      final invoices = await loadOrders();
      final index = invoices.indexWhere((inv) => inv.invoiceId == invoiceId);
      if (index != -1) {
        invoices.removeAt(index);
        await saveOrders(invoices);
        print('💾 Invoice removed from local cache');
      }

      return true;
    } catch (e) {
      print('❌ Error deleting invoice: $e');
      return false;
    }
  }

  /// Local fallback for deleting order
  static Future<bool> _deleteOrderLocal(int invoiceId) async {
    try {
      final invoices = await loadOrders();
      final index = invoices.indexWhere((inv) => inv.invoiceId == invoiceId);

      if (index == -1) {
        print('❌ Invoice not found: $invoiceId');
        return false;
      }

      invoices.removeAt(index);
      await saveOrders(invoices);
      print('✓ Invoice deleted locally: $invoiceId');
      return true;
    } catch (e) {
      print('❌ Error deleting invoice locally: $e');
      return false;
    }
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

  /// Fetch or generate KHQR for a pending invoice via the backend API.
  static Future<String?> fetchKhqrCode(int invoiceId) async {
    try {
      if (!_apiService.isAuthenticated()) {
        return null;
      }

      final response = await _apiService.post(
        '/api/invoices/$invoiceId/generate_khqr/',
        data: {},
        fromJson: (data) => data as Map<String, dynamic>,
      );

      final qr = response['qr_string'] as String?;
      if (qr == null || qr.isEmpty) return null;

      final invoices = await loadOrders();
      final index = invoices.indexWhere((inv) => inv.invoiceId == invoiceId);
      if (index != -1) {
        final invoice = invoices[index];
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
          status: invoice.status,
          paidAt: invoice.paidAt,
          khqrCodeString: qr,
          khqrMd5: response['md5_hash'] as String? ?? invoice.khqrMd5,
          khqrTransactionHash: invoice.khqrTransactionHash,
          khqrShortHash: invoice.khqrShortHash,
          khqrDeeplink:
              response['deeplink'] as String? ?? invoice.khqrDeeplink,
          khqrLastCheckedAt: invoice.khqrLastCheckedAt,
          khqrPaymentData: invoice.khqrPaymentData,
          createdAt: invoice.createdAt,
          purchases: invoice.purchases,
        );
        await saveOrders(invoices);
      }

      return qr;
    } catch (e) {
      print('⚠️ Failed to fetch KHQR from backend for invoice $invoiceId: $e');
      return null;
    }
  }

  /// Verify payment status with KHQR backend API
  static Future<bool> verifyKhqrPayment(int invoiceId) async {
    try {
      if (!_apiService.isAuthenticated()) {
        print('❌ Not authenticated - cannot verify payment');
        return false;
      }

      print('📤 Checking payment for invoice #$invoiceId...');

      final response = await _apiService.post(
        '/api/invoices/$invoiceId/check_payment/',
        data: {},
        fromJson: (data) => data as Map<String, dynamic>,
      );

      final paid = response['paid'] == true;
      print('✅ Payment check for invoice #$invoiceId: paid=$paid');

      if (paid) {
        // Payment confirmed - refresh cached orders from backend
        await fetchOrders();
      }

      return paid;
    } catch (e) {
      print('⚠️ Payment verification failed for invoice $invoiceId: $e');
      return false;
    }
  }
}
