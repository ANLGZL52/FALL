// lib/services/api_base.dart
import 'package:flutter/foundation.dart';

class ApiBase {
  // 🔑 Derleme sırasında dışarıdan vereceğimiz değer:
  // flutter run --dart-define=API_HOST=http://192.168.1.50:8001
  // flutter build appbundle --release --dart-define=API_HOST=https://xxxx.onrender.com
  static const String _definedHost =
      String.fromEnvironment('API_HOST', defaultValue: '');

  // ✅ Ortama göre varsayılanlar
  // - Release: hata vermesin diye boş bırakıyoruz (zorunlu olsun istiyoruz)
  // - Debug: emulator için 10.0.2.2 en mantıklısı
  static String get host {
    if (_definedHost.trim().isNotEmpty) return _definedHost.trim();

    if (kReleaseMode) {
      // Release'te API_HOST vermezsen bilinçli olarak patlatıyoruz ki
      // yanlışlıkla 127.0.0.1 ile store'a gitmeyesin.
      throw StateError(
        'API_HOST tanımlı değil. Release build için '
        '--dart-define=API_HOST=https://YOUR_BACKEND_URL vermelisin.',
      );
    }

    // Debug default: Android emulator
    return 'http://10.0.2.2:8001';
  }

  /// Backend router prefix’in
  static String get baseUrl => '$host/api/v1';

  /// Standart JSON header
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// ✅ Device header opsiyonel ekleyen helper
  static Map<String, String> headers({String? deviceId}) {
    final h = <String, String>{...jsonHeaders};
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty) {
      h['X-Device-Id'] = d;
    }
    return h;
  }
}
