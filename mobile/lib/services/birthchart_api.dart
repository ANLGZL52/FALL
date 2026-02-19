import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/birthchart_reading.dart';
import '../services/device_id_service.dart';
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

class BirthChartApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _generateTimeout = Duration(seconds: 150);

  static Future<String> _device(String? deviceId) async {
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty) return d;
    return DeviceIdService.getOrCreate();
  }

  static Future<BirthChartReading> start({
    required String name,
    required String birthDate,
    String? birthTime,
    required String birthCity,
    String birthCountry = "TR",
    String topic = "genel",
    String? question,
    String? deviceId,
  }) async {
    final d = await _device(deviceId);

    final res = await http
        .post(
          _u('/birthchart/start'),
          headers: ApiBase.headers(deviceId: d),
          body: jsonEncode({
            "name": name,
            "birth_date": birthDate,
            "birth_time": (birthTime == null || birthTime.trim().isEmpty) ? null : birthTime.trim(),
            "birth_city": birthCity,
            "birth_country": birthCountry,
            "topic": topic,
            "question": (question == null || question.trim().isEmpty) ? null : question.trim(),
          }),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception("birthchart/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<BirthChartReading> markPaid({
    required String readingId,
    String? paymentRef,
    String? deviceId,
  }) async {
    final d = await _device(deviceId);

    final ref = (paymentRef ?? '').trim();
    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final res = await http
        .post(
          _u('/birthchart/$readingId/mark-paid'),
          headers: ApiBase.headers(deviceId: d),
          body: jsonEncode({"payment_ref": paymentRef}),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception("birthchart/mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<BirthChartReading> generate({
    required String readingId,
    String? deviceId,
  }) async {
    final d = await _device(deviceId);

    final res = await http
        .post(
          _u('/birthchart/$readingId/generate'),
          headers: ApiBase.headers(deviceId: d),
        )
        .timeout(_generateTimeout);

    if (res.statusCode != 200) {
      throw Exception("birthchart/generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<BirthChartReading> detail({
    required String readingId,
    String? deviceId,
  }) async {
    final d = await _device(deviceId);

    final res = await http
        .get(
          _u('/birthchart/$readingId'),
          headers: ApiBase.headers(deviceId: d),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception("birthchart/detail failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
