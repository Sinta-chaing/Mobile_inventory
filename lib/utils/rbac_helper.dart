import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import '../utils/user_role_constants.dart';

/// Exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

/// Widget that shows/hides based on permission with dynamic backend checking
class PermissionBasedWidget extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? requiredPermission; // e.g., 'edit_product', 'manage_users'
  final bool showErrorMessage;
  final VoidCallback? onPermissionDenied;

  const PermissionBasedWidget({
    Key? key,
    required this.child,
    this.fallback,
    this.requiredPermission,
    this.showErrorMessage = false,
    this.onPermissionDenied,
  }) : super(key: key);

  @override
  State<PermissionBasedWidget> createState() => _PermissionBasedWidgetState();
}

class _PermissionBasedWidgetState extends State<PermissionBasedWidget> {
  late UserService _userService;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    _checkPermission();
  }

  void _checkPermission() {
    if (widget.requiredPermission != null) {
      _hasPermission = Permission.getRolesWithPermission(
        widget.requiredPermission!,
      ).contains(_userService.getCurrentRole());
    } else {
      // Default: check write permission
      _hasPermission = _userService.hasWritePermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkPermission();

    if (!_hasPermission) {
      if (widget.onPermissionDenied != null) {
        widget.onPermissionDenied!();
      }
      return widget.fallback ?? const SizedBox.shrink();
    }

    return widget.child;
  }
}

/// Extension for making permission-safe API calls
extension PermissionSafeApiCalls on ApiService {
  /// Make an API call with permission checking
  /// Shows error toast if permission denied
  Future<T?> safeCall<T>({
    required Future<T> Function() apiCall,
    required VoidCallback onPermissionDenied,
    required VoidCallback onAuthError,
    required Function(String) onError,
  }) async {
    try {
      return await apiCall();
    } on PermissionDeniedException catch (e) {
      onPermissionDenied();
      onError(e.message);
      return null;
    } on AuthenticationException catch (e) {
      onAuthError();
      onError(e.message);
      return null;
    } catch (e) {
      onError(e.toString());
      return null;
    }
  }
}

/// Helper class for permission checking throughout the app
class RbacHelper {
  static final RbacHelper _instance = RbacHelper._internal();
  late UserService _userService;
  late ApiService _apiService;

  RbacHelper._internal();

  factory RbacHelper() {
    return _instance;
  }

  void init({
    required UserService userService,
    required ApiService apiService,
  }) {
    _userService = userService;
    _apiService = apiService;

    // Set API service callbacks
    _apiService.setOnPermissionDenied(_handlePermissionDenied);
    _apiService.setOnAuthenticationError(_handleAuthError);
  }

  void _handlePermissionDenied(String message) {
    print('🔒 Permission Denied: $message');
  }

  void _handleAuthError(String message) {
    print('⚠️ Authentication Error: $message');
  }

  /// Check if user can perform an action based on their role
  bool canPerform(String action) {
    final role = _userService.getCurrentRole() ?? 'staff';
    return Permission.getRolesWithPermission(action).contains(role);
  }

  /// Get user's current role
  String? getUserRole() => _userService.getCurrentRole();

  /// Check if current user is admin
  bool isAdmin() => _userService.isAdmin();

  /// Check if current user is manager
  bool isManager() => _userService.isManager();

  /// Check if current user is staff
  bool isStaff() => _userService.isStaff();

  /// Check if user has write permission (can edit/delete)
  bool hasWritePermission() => _userService.hasWritePermission();

  /// Check if user can view cost prices
  bool canViewCostPrice() => _userService.canViewCostPrice();

  /// Check if user can edit products
  bool canEditProducts() => _userService.canEditProducts();

  /// Check if user can manage users (admin only)
  bool canManageUsers() => _userService.canManageUsers();
}
