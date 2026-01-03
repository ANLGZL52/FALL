// lib/services/api_base.dart
class ApiBase {
  // Windows (backend aynı bilgisayarda)
  static const String host = 'http://127.0.0.1:8001';

  // Backend router prefix’in
  static const String baseUrl = '$host/api/v1';

  // ✅ JSON istekleri için standart header
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // Android emulator:
  // static const String host = 'http://10.0.2.2:8001';
  // static const String baseUrl = '$host/api/v1';
}
