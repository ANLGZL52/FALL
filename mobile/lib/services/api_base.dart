import 'package:flutter/foundation.dart';

class ApiBase {
  // flutter run --dart-define=API_HOST=http://192.168.1.50:8001
  // flutter build appbundle --release --dart-define=API_HOST=https://xxxx.railway.app
  static const String _definedHost = String.fromEnvironment('API_HOST', defaultValue: '');

  static String get host {
    final h = _definedHost.trim();
    if (h.isNotEmpty) return h;

    if (kReleaseMode) {
      throw StateError(
        'API_HOST tanımlı değil. Release build için '
        '--dart-define=API_HOST=https://YOUR_BACKEND_URL vermelisin.',
      );
    }

    // Debug default: Android emulator
    return 'http://10.0.2.2:8001';
  }

  /// Backend router prefix
  static String get baseUrl => '$host/api/v1';

  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  static Map<String, String> headers({String? deviceId}) {
    final h = <String, String>{...jsonHeaders};
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty) {
      h['X-Device-Id'] = d;
    }
    return h;
  }
}
