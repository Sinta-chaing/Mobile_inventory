import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show File, Platform;
import '../models/user_model.dart';
import './user_service.dart';
import './config_service.dart';

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

/// API Service - Connects to Django REST API backend
/// Handles authentication, HTTP requests, and token management
class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  late ConfigService _configService;
  late SharedPreferences _prefs;
  String? _authToken;
  String? _refreshToken;

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

  /// Initialize API service with Dio configuration and load saved tokens
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _configService = ConfigService();
    await _configService.init();

    final baseUrl = _configService.djangoApiUrl;

    print('═' * 60);
    print('🔧 API Service Initialization');
    print('═' * 60);
    print('Base URL: $baseUrl');
    print('Platform: ${_getPlatformName()}');
    print('═' * 60);

    // Initialize Dio with base URL from config
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true, // Don't throw on any status code
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('📤 REQUEST: ${options.method} ${options.path}');
          if (_authToken != null) {
            options.headers['Authorization'] = 'Token $_authToken';
            print('   Auth: Token included');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '📥 RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ ERROR: ${error.message}');
          print('   Type: ${error.type}');
          print('   Status: ${error.response?.statusCode}');

          // Handle 401 responses (token expired)
          if (error.response?.statusCode == 401) {
            onAuthenticationError('Session expired. Please login again.');
            await logout();
          }
          return handler.next(error);
        },
      ),
    );

    // Load saved tokens from SharedPreferences
    _authToken = _prefs.getString('auth_token');
    _refreshToken = _prefs.getString('refresh_token');

    print('🔄 Loaded from SharedPreferences:');
    print('   Auth token: $_authToken (length: ${_authToken?.length ?? 0})');
    print(
      '   Refresh token: $_refreshToken (length: ${_refreshToken?.length ?? 0})',
    );

    print('✅ API Service initialized successfully');
  }

  /// Get current platform name for debugging
  String _getPlatformName() {
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      return 'Web/Unknown';
    }
    return 'Unknown';
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
  /// POST /api/login/
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'error': 'Username and password are required',
        };
      }

      print('\n🔐 Attempting login for user: $username');
      print('   URL: ${_configService.djangoApiUrl}/api/login/');

      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
      );

      print('   Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error =
            response.data['error'] ??
            response.data['detail'] ??
            'Login failed with status ${response.statusCode}';
        print('❌ Login error: $error');
        return {'success': false, 'error': error};
      }

      final data = response.data;
      _authToken = data['token'] ?? data['access'];
      _refreshToken = data['refresh'];

      print('   Token extracted: $_authToken');
      print('   Token length: ${_authToken?.length ?? 0}');

      // Save tokens to SharedPreferences
      await _prefs.setString('auth_token', _authToken ?? '');
      final saved = _prefs.getString('auth_token');
      print('   Saved to SharedPreferences: $saved');
      print('   Saved token length: ${saved?.length ?? 0}');
      if (_refreshToken != null) {
        await _prefs.setString('refresh_token', _refreshToken!);
      }

      // Create User object from response
      final user = User.fromJson(
        data['user'] ??
            {
              'id': data['id'] ?? data['user_id'],
              'username': username,
              'email': data['email'] ?? '',
              'role': data['role'] ?? 'staff',
            },
      );

      // Save user to UserService
      final userService = UserService();
      await userService.setUser(user);

      print('✅ Login successful: $username');
      return {'success': true, 'token': _authToken, 'user': user.toJson()};
    } on DioException catch (e) {
      final errorMsg = _formatDioError(e);
      print('❌ DioException: $errorMsg');
      return {'success': false, 'error': errorMsg};
    } catch (e) {
      print('❌ Unexpected login error: $e');
      return {'success': false, 'error': 'Login failed: $e'};
    }
  }

  /// Register/Sign up
  /// POST /api/register/
  Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        return {'success': false, 'error': 'All fields are required'};
      }

      print('\n📝 Attempting signup for user: $username');
      print('   URL: ${_configService.djangoApiUrl}/api/register/');

      final response = await _dio.post(
        '/api/register/',
        data: {'username': username, 'email': email, 'password': password},
      );

      print('   Response status: ${response.statusCode}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        final error =
            response.data['error'] ??
            response.data['detail'] ??
            'Signup failed with status ${response.statusCode}';
        print('❌ Signup error: $error');
        return {'success': false, 'error': error};
      }

      final data = response.data;
      _authToken = data['token'] ?? data['access'];
      _refreshToken = data['refresh'];

      // Save tokens to SharedPreferences
      await _prefs.setString('auth_token', _authToken ?? '');
      if (_refreshToken != null) {
        await _prefs.setString('refresh_token', _refreshToken!);
      }

      // Create User object from response
      final user = User.fromJson(
        data['user'] ??
            {
              'id': data['id'] ?? data['user_id'],
              'username': username,
              'email': email,
              'role': 'staff',
            },
      );

      // Save user to UserService
      final userService = UserService();
      await userService.setUser(user);

      print('✅ Signup successful: $username');
      return {'success': true, 'token': _authToken, 'user': user.toJson()};
    } on DioException catch (e) {
      final errorMsg = _formatDioError(e);
      print('❌ DioException: $errorMsg');
      return {'success': false, 'error': errorMsg};
    } catch (e) {
      print('❌ Unexpected signup error: $e');
      return {'success': false, 'error': 'Signup failed: $e'};
    }
  }

  /// Format DioException with helpful debugging info
  String _formatDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - Backend not responding. Is Django server running on ${_configService.djangoApiUrl}?';
      case DioExceptionType.sendTimeout:
        return 'Send timeout - Taking too long to send request';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout - Server took too long to respond';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode} - ${e.response?.data}';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.unknown:
        return 'Network error: ${e.error}. Check if backend is running and CORS is enabled.';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error';
      case DioExceptionType.connectionError:
        return 'Cannot connect to ${_configService.djangoApiUrl}. Is the server running?';
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      _authToken = null;
      _refreshToken = null;
      await _prefs.remove('auth_token');
      await _prefs.remove('refresh_token');

      // Clear user from UserService
      final userService = UserService();
      await userService.clearUser();

      print('✅ Logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  /// Generic GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (response.statusCode != 200) {
        throw Exception('GET failed: ${response.statusCode}');
      }
      return fromJson(response.data);
    } on DioException catch (e) {
      print('❌ GET request failed: $path - ${_formatDioError(e)}');
      rethrow;
    }
  }

  /// Generic POST request
  Future<T> post<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      if (response.statusCode! >= 400) {
        throw Exception('POST failed: ${response.statusCode}');
      }
      return fromJson(response.data);
    } on DioException catch (e) {
      print('❌ POST request failed: $path - ${_formatDioError(e)}');
      rethrow;
    }
  }

  /// Generic PUT request
  Future<T> put<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      if (response.statusCode! >= 400) {
        throw Exception('PUT failed: ${response.statusCode}');
      }
      return fromJson(response.data);
    } on DioException catch (e) {
      print('❌ PUT request failed: $path - ${_formatDioError(e)}');
      rethrow;
    }
  }

  /// Generic PATCH request
  Future<T> patch<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      if (response.statusCode! >= 400) {
        throw Exception('PATCH failed: ${response.statusCode}');
      }
      return fromJson(response.data);
    } on DioException catch (e) {
      print('❌ PATCH request failed: $path - ${_formatDioError(e)}');
      rethrow;
    }
  }

  /// Generic DELETE request
  Future<void> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      if (response.statusCode! >= 400) {
        throw Exception('DELETE failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DELETE request failed: $path - ${_formatDioError(e)}');
      rethrow;
    }
  }

  /// Get raw Dio instance for advanced use cases
  Dio getDio() => _dio;

  /// Check if user is authenticated
  bool isAuthenticated() => _authToken != null;

  /// Upload a file via multipart POST. Accepts [XFile] (all platforms) or [File].
  Future<T> uploadFile<T>(
    String path,
    dynamic file, {
    required T Function(dynamic) fromJson,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
  }) async {
    try {
      late MultipartFile multipart;

      if (file is XFile) {
        final bytes = await file.readAsBytes();
        final name = file.name.isNotEmpty ? file.name : 'image.jpg';
        multipart = MultipartFile.fromBytes(bytes, filename: name);
      } else if (file is File) {
        final name = file.path.split(Platform.pathSeparator).last;
        multipart = await MultipartFile.fromFile(file.path, filename: name);
      } else {
        throw ArgumentError(
          'uploadFile expects XFile or dart:io File, got ${file.runtimeType}',
        );
      }

      final map = <String, dynamic>{fieldName: multipart};
      if (extraFields != null) map.addAll(extraFields);
      final formData = FormData.fromMap(map);
      final response = await _dio.post(path, data: formData);

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception('Upload failed: ${response.statusCode}');
      }

      return fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Upload failed: $path - ${_formatDioError(e)}');
      rethrow;
    }
  }
}
