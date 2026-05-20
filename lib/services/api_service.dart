import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import './user_service.dart';

/// Exception for permission denied errors
class PermissionDeniedException implements Exception {
  final String message;
  final int statusCode;

  PermissionDeniedException({required this.message, this.statusCode = 403});

  @override
  String toString() => message;
}

/// Exception for authentication errors
class AuthenticationException implements Exception {
  final String message;

  AuthenticationException({required this.message});

  @override
  String toString() => message;
}

/// Simplified API Service - No backend integration
/// All functionality is local-storage based
class ApiService {
  static final ApiService _instance = ApiService._internal();
  String? _authToken;

  /// Callback for permission denied errors
  late Function(String message) onPermissionDenied;

  /// Callback for authentication errors (e.g., token expired)
  late Function(String message) onAuthenticationError;

  ApiService._internal() {
    // Set default callbacks (can be overridden)
    onPermissionDenied = (message) => print('Permission denied: $message');
    onAuthenticationError = (message) => print('Auth error: $message');
  }

  factory ApiService() {
    return _instance;
  }

  /// Set callback for permission denied errors
  void setOnPermissionDenied(Function(String) callback) {
    onPermissionDenied = callback;
  }

  /// Set callback for authentication errors
  void setOnAuthenticationError(Function(String) callback) {
    onAuthenticationError = callback;
  }

  /// Initialize API service with token from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Get the current auth token
  String? getAuthToken() {
    return _authToken;
  }

  /// Login with username and password (Local only - no backend)
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      // Simple local validation
      if (username.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'error': 'Username and password are required',
        };
      }

      // Generate a token (in real app, would come from backend)
      final token = _generateToken();
      _authToken = token;

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Create User object with default role
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch,
        username: username,
        email: '$username@local.app',
        role: 'staff',
      );

      // Save user to UserService
      final userService = UserService();
      await userService.setUser(user);

      print('✅ Local login successful: $username');
      return {'success': true, 'token': token, 'user': user.toJson()};
    } catch (e) {
      return {'success': false, 'error': 'Login failed: $e'};
    }
  }

  /// Register/Sign up (Local only - no backend)
  Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Simple local validation
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        return {'success': false, 'error': 'All fields are required'};
      }

      // Generate a token
      final token = _generateToken();
      _authToken = token;

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Create User object with default role
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch,
        username: username,
        email: email,
        role: 'staff',
      );

      // Save user to UserService
      final userService = UserService();
      await userService.setUser(user);

      print('✅ Local signup successful: $username');
      return {'success': true, 'token': token, 'user': user.toJson()};
    } catch (e) {
      return {'success': false, 'error': 'Registration failed: $e'};
    }
  }

  /// Logout
  Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    // Clear user from UserService
    final userService = UserService();
    await userService.clearUser();

    print('✅ Logged out successfully');
  }

  /// Generate a token (simulated)
  String _generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'local_token_$timestamp';
  }

  /// Stub methods for backward compatibility
  /// All return empty/error responses since there's no backend

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    throw Exception('Backend API is not available. Using local storage only.');
  }

  Future<T> post<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(dynamic) fromJson,
  }) async {
    throw Exception('Backend API is not available. Using local storage only.');
  }

  Future<T> put<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(dynamic) fromJson,
  }) async {
    throw Exception('Backend API is not available. Using local storage only.');
  }

  Future<void> delete(String path) async {
    throw Exception('Backend API is not available. Using local storage only.');
  }

  /// Upload file stub - not functional since there's no backend
  Future<T> uploadFile<T>(
    String path,
    dynamic file, {
    required T Function(dynamic) fromJson,
  }) async {
    throw Exception('File upload not available. Backend API is disabled.');
  }
}
