import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/purchase_screen/purchase_screen.dart';
import 'api_service.dart';

class OrderService {
  static const String _ordersKey = 'orders_data';
  static late SharedPreferences _prefs;
  static final ApiService _apiService = ApiService();

  // Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _apiService.init();
  }

  /// Fetch orders/invoices from Django backend
  static Future<List<Order>> fetchOrdersFromAPI() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/invoices/',
        fromJson: (json) => (json as List).map((item) => item).toList(),
      );

      final orders = response.map((invoice) {
        return Order(
          orderId:
              invoice['invoiceNumber']?.toString() ??
              invoice['invoice_number']?.toString() ??
              invoice['invoiceId']?.toString() ??
              invoice['id']?.toString() ??
              '',
          createdDate: DateTime.parse(
            invoice['createdAt'] as String? ??
                invoice['created_at'] as String? ??
                DateTime.now().toIso8601String(),
          ),
          customerName:
              invoice['customerName'] ??
              invoice['customer']?['name'] ??
              'Unknown',
          customerPhone:
              invoice['customerPhone'] ?? invoice['customer']?['phone'] ?? '',
          paymentMethod:
              (invoice['paymentMethod'] as String?)?.toLowerCase() == 'khqr' ||
                  (invoice['payment_method'] as String?)?.toLowerCase() ==
                      'khqr'
              ? PaymentMethod.khqr
              : PaymentMethod.cash,
          total: (invoice['grandTotal'] ?? invoice['total'] ?? 0).toDouble(),
          status: (invoice['status'] as String?)?.toLowerCase() == 'paid'
              ? OrderStatus.paid
              : OrderStatus.pending,
          paidAt: invoice['paidAt'] != null
              ? DateTime.parse(invoice['paidAt'] as String)
              : null,
          createdBy:
              invoice['createdByUser']?['username'] ??
              invoice['created_by']?['username'] ??
              'System',
          items:
              (invoice['purchases'] as List? ??
                      invoice['invoice_items'] as List?)
                  ?.map(
                    (item) => OrderItem(
                      itemName:
                          item['product']?['productName'] ??
                          item['product']?['name'] ??
                          'Unknown',
                      quantity: item['quantity'] as int? ?? 0,
                      unitPrice:
                          (item['pricePerUnit'] ?? item['unit_price'] ?? 0)
                              .toDouble(),
                      discount: (item['discount'] ?? 0).toDouble(),
                    ),
                  )
                  .toList() ??
              [],
        );
      }).toList();

      // Cache to local storage
      await saveOrders(orders);
      return orders;
    } catch (e) {
      print('❌ Error fetching orders from API: $e');
      // Fallback to cached data
      return await loadOrders();
    }
  }

  /// Create new order/invoice
  static Future<Order?> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _apiService.post(
        '/api/invoices/',
        data: orderData,
        fromJson: (json) => json,
      );

      return Order(
        orderId:
            response['invoiceNumber']?.toString() ??
            response['invoice_number']?.toString() ??
            response['invoiceId']?.toString() ??
            response['id']?.toString() ??
            '',
        createdDate: DateTime.parse(
          response['createdAt'] as String? ??
              response['created_at'] as String? ??
              DateTime.now().toIso8601String(),
        ),
        customerName:
            response['customerName'] ??
            response['customer']?['name'] ??
            'Unknown',
        customerPhone:
            response['customerPhone'] ?? response['customer']?['phone'] ?? '',
        paymentMethod:
            (response['paymentMethod'] as String?)?.toLowerCase() == 'khqr' ||
                (response['payment_method'] as String?)?.toLowerCase() == 'khqr'
            ? PaymentMethod.khqr
            : PaymentMethod.cash,
        total: (response['grandTotal'] ?? response['total'] ?? 0).toDouble(),
        status: (response['status'] as String?)?.toLowerCase() == 'paid'
            ? OrderStatus.paid
            : OrderStatus.pending,
        paidAt: response['paidAt'] != null
            ? DateTime.parse(response['paidAt'] as String)
            : null,
        createdBy:
            response['createdByUser']?['username'] ??
            response['created_by']?['username'] ??
            'System',
        items: [],
      );
    } catch (e) {
      print('❌ Error creating order: $e');
      return null;
    }
  }

  /// Update order status
  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      // Capitalize status to match Django model choices (Paid, Pending, Cancelled)
      final capitalizedStatus =
          status[0].toUpperCase() + status.substring(1).toLowerCase();
      await _apiService.put(
        '/api/invoices/$orderId/',
        data: {'status': capitalizedStatus},
        fromJson: (json) => json,
      );
      return true;
    } catch (e) {
      print('❌ Error updating order: $e');
      return false;
    }
  }

  /// Mark order as paid
  static Future<bool> markOrderAsPaid(String orderId) async {
    try {
      await _apiService.put(
        '/api/invoices/$orderId/',
        data: {'status': 'Paid', 'paidAt': DateTime.now().toIso8601String()},
        fromJson: (json) => json,
      );
      return true;
    } catch (e) {
      print('❌ Error marking order as paid: $e');
      return false;
    }
  }

  // Save orders to persistent storage
  static Future<void> saveOrders(List<Order> orders) async {
    try {
      final jsonData = orders.map((order) => _orderToJson(order)).toList();
      await _prefs.setString(_ordersKey, jsonEncode(jsonData));
      print('✅ Saved ${orders.length} orders to SharedPreferences');
    } catch (e) {
      print('❌ Error saving orders: $e');
    }
  }

  // Load orders from persistent storage
  static Future<List<Order>> loadOrders() async {
    try {
      final jsonString = _prefs.getString(_ordersKey);
      print(
        '📦 Retrieved from SharedPreferences: ${jsonString?.length ?? 0} characters',
      );
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonData = jsonDecode(jsonString) as List;
      print('✅ Loaded ${jsonData.length} orders from SharedPreferences');
      return jsonData.map((item) => _orderFromJson(item)).toList();
    } catch (e) {
      print('❌ Error loading orders: $e');
      return [];
    }
  }

  // Convert Order to JSON
  static Map<String, dynamic> _orderToJson(Order order) {
    return {
      'orderId': order.orderId,
      'createdDate': order.createdDate.toIso8601String(),
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'paymentMethod': order.paymentMethod == PaymentMethod.cash
          ? 'cash'
          : 'khqr',
      'total': order.total,
      'status': order.status == OrderStatus.paid ? 'paid' : 'pending',
      'paidAt': order.paidAt?.toIso8601String(),
      'createdBy': order.createdBy,
      'items': order.items
          .map(
            (item) => {
              'itemName': item.itemName,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'discount': item.discount,
            },
          )
          .toList(),
    };
  }

  // Convert JSON to Order
  static Order _orderFromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      paymentMethod: (json['paymentMethod'] as String) == 'cash'
          ? PaymentMethod.cash
          : PaymentMethod.khqr,
      total: (json['total'] as num).toDouble(),
      status: (json['status'] as String) == 'paid'
          ? OrderStatus.paid
          : OrderStatus.pending,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      createdBy: json['createdBy'] as String,
      items: (json['items'] as List)
          .map(
            (item) => OrderItem(
              itemName: item['itemName'] as String,
              quantity: item['quantity'] as int,
              unitPrice: (item['unitPrice'] as num).toDouble(),
              discount: (item['discount'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }

  // Verify KHQR payment status
  static Future<bool> verifyKhqrPayment(String orderId, double amount) async {
    try {
      // Call Django backend to verify KHQR payment
      final response = await _apiService.post(
        '/api/invoices/$orderId/verify-payment/',
        data: {'amount': amount},
        fromJson: (json) => json,
      );

      return response['verified'] ?? false;
    } catch (e) {
      print('❌ Payment verification error: $e');
      return false;
    }
  }
}
