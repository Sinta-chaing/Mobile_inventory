import 'package:flutter/material.dart';

import '../presentation/bi_dashboard_screen/bi_dashboard_screen.dart';
import '../presentation/inventory_screen/inventory_screen.dart';
import '../presentation/purchase_screen/purchase_screen.dart';
import '../presentation/customer_screen/customer_screen.dart';
import '../presentation/supplier_screen/supplier_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';

class AppRoutes {
  static const String initial = '/sign-up-login-screen';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String inventoryScreen = '/inventory-screen';
  static const String purchaseScreen = '/purchase-screen';
  static const String customerScreen = '/customer-screen';
  static const String supplierScreen = '/supplier-screen';
  static const String biDashboardScreen = '/bi-dashboard-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SignUpLoginScreen(),
    signUpLoginScreen: (context) => const SignUpLoginScreen(),
    inventoryScreen: (context) => const InventoryScreen(),
    purchaseScreen: (context) => const PurchaseScreen(),
    customerScreen: (context) => const CustomerScreen(),
    supplierScreen: (context) => const SupplierScreen(),
    biDashboardScreen: (context) => const BIDashboardScreen(),
  };
}
