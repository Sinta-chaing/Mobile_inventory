import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
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

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  String? _authToken;
  String _baseUrl = 'http://127.0.0.1:8000';

  /// Callback for permission denied errors
  late Function(String message) onPermissionDenied;

  /// Callback for authentication errors (e.g., token expired)
  late Function(String message) onAuthenticationError;

  ApiService._internal() {
    _initializeDio();
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

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Token $_authToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 403 Forbidden - Permission denied
          if (error.response?.statusCode == 403) {
            final message =
                error.response?.data?['detail'] ??
                error.response?.data?['message'] ??
                'You do not have permission to perform this action';
            onPermissionDenied(message);
          }
          // Handle 401 Unauthorized - Auth token expired or invalid
          else if (error.response?.statusCode == 401) {
            final message = 'Your session has expired. Please log in again.';
            onAuthenticationError(message);
            // Optionally logout and redirect
            logout();
          }
          return handler.next(error);
        },
      ),
    );
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

  /// Login with username and password
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        _authToken = token;

        // Save token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Create User object with role information
        final user = User(
          id: response.data['user_id'],
          username: response.data['username'],
          email: response.data.containsKey('email')
              ? response.data['email']
              : '',
          role: response.data['role'] ?? 'staff',
        );

        // Save user to UserService
        final userService = UserService();
        await userService.setUser(user);

        return {'success': true, 'token': token, 'user': user.toJson()};
      }
      return {'success': false, 'error': 'Login failed'};
    } on DioException catch (e) {
      return {'success': false, 'error': e.message ?? 'Network error'};
    }
  }

  /// Register/Sign up with username, email, and password
  Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/register/',
        data: {'username': username, 'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['token'];
        _authToken = token;

        // Save token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Create User object with role information
        final user = User(
          id: response.data['user_id'],
          username: response.data['username'],
          email: email,
          role: response.data.containsKey('role')
              ? response.data['role']
              : 'staff',
        );

        // Save user to UserService
        final userService = UserService();
        await userService.setUser(user);

        return {'success': true, 'token': token, 'user': user.toJson()};
      }
      return {'success': false, 'error': 'Registration failed'};
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['detail'] ?? e.message ?? 'Network error';
      return {'success': false, 'error': errorMessage};
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
  }

  /// GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<T> post<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<T> put<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file
  Future<T> uploadFile<T>(
    String path,
    File file, {
    required T Function(dynamic) fromJson,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        ...?additionalData,
      });

      final response = await _dio.post(path, data: formData);
      return fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    // Handle 403 Forbidden - Permission denied
    if (error.response?.statusCode == 403) {
      final message =
          error.response?.data?['detail'] ??
          error.response?.data?['message'] ??
          'You do not have permission to perform this action';
      throw PermissionDeniedException(message: message, statusCode: 403);
    }

    // Handle 401 Unauthorized - Session expired
    if (error.response?.statusCode == 401) {
      final message =
          error.response?.data?['detail'] ??
          'Your session has expired. Please log in again.';
      throw AuthenticationException(message: message);
    }

    // Handle other HTTP errors
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Server took too long to respond. Please try again.';
    } else if (error.response != null) {
      return error.response?.data?['detail'] ??
          error.response?.data?['message'] ??
          'Server error (${error.response?.statusCode})';
    }
    return error.message ?? 'Unknown error occurred';
  }
}
