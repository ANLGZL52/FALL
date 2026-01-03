import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/birthchart_reading.dart';

class BirthChartApi {
  // Windows Desktop: 127.0.0.1 çalışır
  static const String baseUrl = "http://127.0.0.1:8001/api/v1";

  static Future<BirthChartReading> start({
    required String name,
    required String birthDate, // YYYY-MM-DD
    String? birthTime,         // HH:MM (opsiyonel)
    required String birthCity,
    String birthCountry = "TR",
    String topic = "genel",
    String? question,
  }) async {
    final uri = Uri.parse("$baseUrl/birthchart/start");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
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
      throw Exception("birthchart start failed: ${res.statusCode} ${res.body}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<BirthChartReading> markPaid({
    required String readingId,
    String? paymentRef,
  }) async {
    final uri = Uri.parse("$baseUrl/birthchart/$readingId/mark-paid");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception("birthchart mark-paid failed: ${res.statusCode} ${res.body}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<BirthChartReading> generate({
    required String readingId,
  }) async {
    final uri = Uri.parse("$baseUrl/birthchart/$readingId/generate");
    final res = await http.post(uri);

    if (res.statusCode != 200) {
      throw Exception("birthchart generate failed: ${res.statusCode} ${res.body}");
    }
    return BirthChartReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
