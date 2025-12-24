// lib/services/api_base.dart
import 'dart:io';

class ApiBase {
  // Windows/macOS/Linux desktop: 127.0.0.1
  // Android emulator: 10.0.2.2
  // iOS simulator: 127.0.0.1
  static String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://127.0.0.1:8000/api/v1';
  }
}
