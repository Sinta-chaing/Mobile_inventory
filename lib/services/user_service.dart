import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

/// Service for managing user authentication state and role
class UserService {
  static final UserService _instance = UserService._internal();
  static const String _userKey = 'current_user';

  User? _currentUser;
  late SharedPreferences _prefs;

  UserService._internal();

  factory UserService() {
    return _instance;
  }

  /// Initialize the service with SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadUserFromStorage();
  }

  /// Load user from SharedPreferences
  void _loadUserFromStorage() {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        _currentUser = User.fromJson(userMap);
      }
    } catch (e) {
      print('Error loading user from storage: $e');
      _currentUser = null;
    }
  }

  /// Set current user and save to storage
  Future<void> setUser(User user) async {
    _currentUser = user;
    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs.setString(_userKey, userJson);
    } catch (e) {
      print('Error saving user to storage: $e');
    }
  }

  /// Get current user
  User? getUser() => _currentUser;

  /// Check if user is logged in
  bool isLoggedIn() => _currentUser != null;

  /// Get current user's role
  String? getCurrentRole() => _currentUser?.role;

  /// Check if current user is admin
  bool isAdmin() => _currentUser?.isAdmin ?? false;

  /// Check if current user is manager
  bool isManager() => _currentUser?.isManager ?? false;

  /// Check if current user is staff
  bool isStaff() => _currentUser?.isStaff ?? false;

  /// Check if current user has write permissions
  bool hasWritePermission() => _currentUser?.hasWritePermission ?? false;

  /// Check if current user can edit products (admin/manager only)
  bool canEditProducts() => hasWritePermission();

  /// Check if current user can view cost price (admin/manager only, not staff)
  bool canViewCostPrice() => hasWritePermission();

  /// Check if current user can manage users (admin only)
  bool canManageUsers() => isAdmin();

  /// Clear current user (logout)
  Future<void> clearUser() async {
    _currentUser = null;
    try {
      await _prefs.remove(_userKey);
    } catch (e) {
      print('Error clearing user from storage: $e');
    }
  }

  /// Get user info for display
  String getUserDisplayName() => _currentUser?.fullName ?? 'User';

  /// Get user's role display name (formatted)
  String getRoleDisplayName() {
    switch (_currentUser?.role) {
      case 'administrator':
        return 'Administrator';
      case 'manager':
        return 'Manager';
      case 'staff':
        return 'Staff';
      default:
        return 'Unknown';
    }
  }
}
