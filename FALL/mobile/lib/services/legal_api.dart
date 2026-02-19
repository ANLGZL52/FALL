import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base.dart';

String _extractErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail;
      return decoded.toString();
    }
  } catch (_) {}
  return body;
}

class LegalApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  /// Yasal metin onayını PostgreSQL'e kaydeder.
  static Future<void> recordConsent({
    required String deviceId,
    String documentType = 'terms',
    String? documentVersion,
  }) async {
    final body = <String, dynamic>{
      'document_type': documentType,
      if (documentVersion != null && documentVersion.isNotEmpty) 'document_version': documentVersion,
    };
    final res = await http
        .post(
          _u('/legal/consent'),
          headers: ApiBase.headers(deviceId: deviceId),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode >= 400) {
      throw Exception('legal/consent POST failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
  }

  /// Bu cihaz için onay durumunu döner.
  static Future<bool> getConsentStatus({
    required String deviceId,
    String documentType = 'terms',
  }) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/legal/consent/status?document_type=$documentType');
    final res = await http
        .get(uri, headers: ApiBase.headers(deviceId: deviceId))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode >= 400) {
      return false;
    }
    try {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return map['accepted'] == true;
    } catch (_) {
      return false;
    }
  }
}
