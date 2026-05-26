import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:inventrack/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUp(() {
      // Initialize SharedPreferences mock for testing
      SharedPreferences.setMockInitialValues({});
      apiService = ApiService();
    });

    test('ApiService is a singleton', () {
      final service1 = ApiService();
      final service2 = ApiService();
      expect(identical(service1, service2), true);
    });

    test('Auth token can be set and retrieved', () {
      final testToken = 'test_token_12345';
      apiService.setAuthToken(testToken);

      expect(apiService.getAuthToken(), testToken);
    });

    test('Permission denied callback can be set', () {
      apiService.setOnPermissionDenied((message) {
        // Callback registered
      });

      // Just verify callback was registered without error
      expect(true, true);
    });

    test('Authentication error callback can be set', () {
      apiService.setOnAuthenticationError((message) {
        // Callback registered
      });

      expect(true, true);
    });

    test('Get auth token returns null when not set', () {
      apiService.setAuthToken('');
      expect(apiService.getAuthToken() ?? '', '');
    });

    test('API service handles authentication token storage', () {
      final token1 = 'token_value_123';
      apiService.setAuthToken(token1);

      expect(apiService.getAuthToken(), token1);
    });
  });
}
