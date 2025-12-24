class ApiBase {
  // Windows (backend aynı bilgisayarda)
  static const String host = 'http://127.0.0.1:8001';

  // Backend router prefix’in (çoğu projede /api/v1)
  static const String baseUrl = '$host/api/v1';

  // Android emulator kullanırsan:
  // static const String host = 'http://10.0.2.2:8001';
  // static const String baseUrl = '$host/api/v1';
}
