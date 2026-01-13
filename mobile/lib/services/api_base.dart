// lib/services/api_base.dart
class ApiBase {
  /// Windows (backend aynı bilgisayarda)
  /// - Gerçek cihazdan bağlanacaksan: bilgisayarının LAN IP’si gerekir (127.0.0.1 olmaz)
  static const String host = 'http://127.0.0.1:8001';

  /// Backend router prefix’in
  static const String baseUrl = '$host/api/v1';

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

  // Android emulator (AVD) kullanıyorsan:
  // static const String host = 'http://10.0.2.2:8001';
  // static const String baseUrl = '$host/api/v1';
}
