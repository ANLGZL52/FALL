class ApiBase {
  // Varsayılan: Railway production. Lokal test için: --dart-define=API_HOST=http://localhost:8001
  static const String _railwayHost = 'https://fall-production.up.railway.app';
  static const String _definedHost = String.fromEnvironment('API_HOST', defaultValue: _railwayHost);

  static String get host {
    final h = _definedHost.trim();
    if (h.isNotEmpty) return h;
    return _railwayHost;
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
