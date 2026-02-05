import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base.dart';
import 'device_id_service.dart';

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

class TarotApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _generateTimeout = Duration(seconds: 150);

  static Future<String> _resolveDeviceId(String? deviceId) async {
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty && d.length >= 8) return d;
    return await DeviceIdService.getOrCreate();
  }

  static Future<Map<String, dynamic>> start({
    required String topic,
    required String question,
    String? name,
    int? age,
    required String spreadType, // three/six/twelve
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .post(
          _u('/tarot/start'),
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode({
            "topic": topic,
            "question": question,
            "name": name,
            "age": age,
            "spread_type": spreadType,
          }),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode >= 400) {
      throw Exception('Tarot start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> selectCards({
    required String readingId,
    required List<String> cards,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .post(
          _u('/tarot/$readingId/select-cards'),
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode({"cards": cards}),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode >= 400) {
      throw Exception('select-cards failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// ✅ LEGACY ONLY (mock)
  static Future<Map<String, dynamic>> markPaid({
    required String readingId,
    required String paymentRef,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final ref = paymentRef.trim();
    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final res = await http
        .post(
          _u('/tarot/$readingId/mark-paid'),
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode({"payment_ref": paymentRef}),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode >= 400) {
      throw Exception('mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> generate({
    required String readingId,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .post(
          _u('/tarot/$readingId/generate'),
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_generateTimeout);

    if (res.statusCode >= 400) {
      throw Exception('generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> detail({
    required String readingId,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .get(
          _u('/tarot/$readingId'),
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode >= 400) {
      throw Exception('detail failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
