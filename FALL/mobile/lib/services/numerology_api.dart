import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base.dart';
import 'device_id_service.dart';
import '../models/numerology_reading.dart';

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

class NumerologyApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _generateTimeout = Duration(seconds: 150);

  static Future<String> _resolveDeviceId(String? deviceId) async {
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty && d.length >= 8) return d;
    return await DeviceIdService.getOrCreate();
  }

  static Future<NumerologyReading> start({
    required String name,
    required String birthDate, // YYYY-MM-DD
    required String topic,
    String? question,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .post(
          _u('/numerology/start'),
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode({
            "name": name,
            "birth_date": birthDate,
            "topic": topic,
            "question": (question == null || question.trim().isEmpty) ? null : question.trim(),
          }),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode >= 400) {
      throw Exception("numerology/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<NumerologyReading> get({
    required String readingId,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .get(
          _u('/numerology/$readingId'),
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode >= 400) {
      throw Exception("numerology/get failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ DEBUG / legacy: backend sadece "TEST-..." ile kabul eder.
  static Future<NumerologyReading> markPaid({
    required String readingId,
    required String paymentRef, // "TEST-..."
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .post(
          _u('/numerology/$readingId/mark-paid'),
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode({"payment_ref": paymentRef}),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode >= 400) {
      throw Exception("numerology/mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<NumerologyReading> generate({
    required String readingId,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .post(
          _u('/numerology/$readingId/generate'),
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_generateTimeout);

    if (res.statusCode >= 400) {
      throw Exception("numerology/generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
