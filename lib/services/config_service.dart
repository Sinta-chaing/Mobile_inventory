import 'dart:convert';
import 'package:flutter/services.dart';

/// Service to load and manage application configuration from env.json
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  late Map<String, dynamic> _config;
  bool _initialized = false;

  ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  /// Initialize configuration from assets/env.json
  Future<void> init() async {
    if (_initialized) return;

    try {
      // For Flutter web, use just the filename; for native, use assets/filename
      final jsonString = await rootBundle.loadString('env.json');
      _config = jsonDecode(jsonString);
      _initialized = true;
      print('✅ Configuration loaded successfully');
    } catch (e) {
      print('❌ Error loading configuration: $e');
      // Set default values if loading fails
      _config = {
        'DJANGO_API_URL': 'http://127.0.0.1:8000/',
        'SUPABASE_URL': 'https://dummy.supabase.co',
        'SUPABASE_ANON_KEY': 'dummykey',
      };
      _initialized = true;
    }
  }

  /// Get the Django API base URL
  String get djangoApiUrl {
    final url = _config['DJANGO_API_URL'] ?? 'http://127.0.0.1:8000/';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Turn a relative media path or partial URL into a loadable image URL.
  String resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$djangoApiUrl$path';
  }

  /// Get API endpoint URL
  String getApiEndpoint(String endpoint) {
    return '${djangoApiUrl}/api/$endpoint';
  }

  /// Get configuration value by key
  dynamic getConfig(String key) {
    return _config[key];
  }

  /// Check if configuration is initialized
  bool get isInitialized => _initialized;
}
