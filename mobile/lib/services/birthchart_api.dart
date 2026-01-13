import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/birthchart_reading.dart';
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

  static Future<BirthChartReading> start({
    required String name,
    required String birthDate, // YYYY-MM-DD
    String? birthTime, // HH:MM (opsiyonel)
    required String birthCity,
    String birthCountry = "TR",
    String topic = "genel",
    String? question,
    String? deviceId, // ✅ opsiyonel
  }) async {
    final res = await http.post(
      _u('/birthchart/start'),
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode({
        "name": name,
        "birth_date": birthDate,
        "birth_time": (birthTime == null || birthTime.trim().isEmpty) ? null : birthTime.trim(),
        "birth_city": birthCity,
        "birth_country": birthCountry,
        "topic": topic,
        "question": (question == null || question.trim().isEmpty) ? null : question.trim(),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("birthchart/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ LEGACY (mock) için kalsın.
  /// Real ödeme: /payments/verify server-side unlock yapıyor, burada çağırma.
  static Future<BirthChartReading> markPaid({
    required String readingId,
    String? paymentRef,
    String? deviceId, // ✅ opsiyonel
  }) async {
    final ref = (paymentRef ?? '').trim();

    // Coffee/Hand/Numerology ile aynı kural
    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final res = await http.post(
      _u('/birthchart/$readingId/mark-paid'),
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception("birthchart/mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<BirthChartReading> generate({
    required String readingId,
    String? deviceId, // ✅ opsiyonel
  }) async {
    final res = await http.post(
      _u('/birthchart/$readingId/generate'),
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode != 200) {
      throw Exception("birthchart/generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<BirthChartReading> detail({
    required String readingId,
    String? deviceId,
  }) async {
    final res = await http.get(
      _u('/birthchart/$readingId'),
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode != 200) {
      throw Exception("birthchart/detail failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
