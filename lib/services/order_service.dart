import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/purchase_screen/purchase_screen.dart';

class OrderService {
  static const String _ordersKey = 'orders_data';
  static late SharedPreferences _prefs;

  // Initialize the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get initial mock data
  static List<Order> _getInitialMockData() {
    return [
      Order(
        orderId: 'ORD-2024-001',
        createdDate: DateTime.now().subtract(const Duration(days: 5)),
        customerName: 'John Doe',
        customerPhone: '+855 12 345 678',
        paymentMethod: PaymentMethod.khqr,
        total: 2999.80,
        status: OrderStatus.paid,
        paidAt: DateTime.now().subtract(const Duration(days: 4)),
        createdBy: 'Admin User',
        items: [
          OrderItem(
            itemName: 'DeWalt 20V Cordless Drill',
            quantity: 20,
            unitPrice: 149.99,
          ),
        ],
      ),
      Order(
        orderId: 'ORD-2024-002',
        createdDate: DateTime.now().subtract(const Duration(days: 2)),
        customerName: 'Jane Smith',
        customerPhone: '+855 98 765 432',
        paymentMethod: PaymentMethod.cash,
        total: 799.70,
        status: OrderStatus.pending,
        paidAt: null,
        createdBy: 'Staff Member',
        items: [
          OrderItem(
            itemName: 'Stanley FatMax Tape Measure 25ft',
            quantity: 30,
            unitPrice: 24.99,
          ),
          OrderItem(
            itemName: 'Makita Angle Grinder 4.5"',
            quantity: 5,
            unitPrice: 99.95,
          ),
        ],
      ),
      Order(
        orderId: 'ORD-2024-003',
        createdDate: DateTime.now().subtract(const Duration(hours: 3)),
        customerName: 'Mike Johnson',
        customerPhone: '+855 77 123 456',
        paymentMethod: PaymentMethod.khqr,
        total: 699.50,
        status: OrderStatus.paid,
        paidAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdBy: 'Admin User',
        items: [
          OrderItem(
            itemName: '3M Safety Glasses',
            quantity: 100,
            unitPrice: 2.50,
          ),
          OrderItem(itemName: 'Work Gloves', quantity: 50, unitPrice: 8.99),
        ],
      ),
    ];
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
        // Return initial mock data on first run
        final initialData = _getInitialMockData();
        print(
          '📝 No saved data found, returning ${initialData.length} mock orders',
        );
        await saveOrders(initialData);
        return initialData;
      }
      final jsonData = jsonDecode(jsonString) as List;
      print('✅ Loaded ${jsonData.length} orders from SharedPreferences');
      return jsonData.map((item) => _orderFromJson(item)).toList();
    } catch (e) {
      print('❌ Error loading orders: $e');
      // Return initial mock data on error
      return _getInitialMockData();
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
  // In a real app, this would call your payment gateway API to verify the payment
  static Future<bool> verifyKhqrPayment(String orderId, double amount) async {
    try {
      // Simulate API call to payment gateway
      // In production, replace this with actual API call to verify payment
      // Example: Check with KHQR provider, MD5 verification, transaction lookup
      await Future.delayed(const Duration(seconds: 2));

      // This simulates checking payment status
      // In real app:
      // 1. Generate MD5 hash of payment details
      // 2. Call payment provider API to verify transaction
      // 3. Match transaction amount and order details
      // 4. Confirm payment was received

      // For now, simulate that payment needs to be received
      // Return false to indicate payment not verified yet
      // You would replace this with actual verification logic
      print(
        '🔍 Checking KHQR payment for order: $orderId, amount: $amount USD',
      );

      // Simulate API response - in real scenario this would check actual payment status
      // Currently returning false to show that payment wasn't received yet
      // This should be replaced with real payment gateway integration
      return false; // Payment not yet received - verification failed
    } catch (e) {
      print('❌ Payment verification error: $e');
      return false;
    }
  }
}
