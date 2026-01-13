import 'dart:convert';
import 'dart:typed_data';
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

class PersonalityReading {
  final String id;
  final String name;
  final String birthDate;
  final String? birthTime;
  final String birthCity;
  final String birthCountry;

  final String topic;
  final String? question;

  final String status;
  final String? resultText;

  final bool isPaid;
  final String? paymentRef;

  PersonalityReading({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.birthTime,
    required this.birthCity,
    required this.birthCountry,
    required this.topic,
    required this.question,
    required this.status,
    required this.resultText,
    required this.isPaid,
    required this.paymentRef,
  });

  factory PersonalityReading.fromJson(Map<String, dynamic> j) {
    return PersonalityReading(
      id: (j["id"] ?? "").toString(),
      name: (j["name"] ?? "").toString(),
      birthDate: (j["birth_date"] ?? "").toString(),
      birthTime: j["birth_time"]?.toString(),
      birthCity: (j["birth_city"] ?? "").toString(),
      birthCountry: (j["birth_country"] ?? "TR").toString(),
      topic: (j["topic"] ?? "genel").toString(),
      question: j["question"]?.toString(),
      status: (j["status"] ?? "").toString(),
      resultText: j["result_text"]?.toString(),
      isPaid: (j["is_paid"] ?? false) == true,
      paymentRef: j["payment_ref"]?.toString(),
    );
  }
}

class PersonalityApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  static Future<PersonalityReading> start({
    required String name,
    required String birthDate, // YYYY-MM-DD
    String? birthTime, // HH:MM
    required String birthCity,
    String birthCountry = "TR",
    String topic = "genel",
    String? question,
    String? deviceId,
  }) async {
    final res = await http.post(
      _u('/personality/start'),
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

    if (res.statusCode >= 400) {
      throw Exception('personality start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return PersonalityReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ LEGACY only (bozulmasın diye kalsın)
  static Future<PersonalityReading> markPaid({
    required String readingId,
    String? paymentRef,
    String? deviceId,
  }) async {
    final ref = (paymentRef ?? '').trim();
    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final res = await http.post(
      _u('/personality/$readingId/mark-paid'),
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode >= 400) {
      throw Exception('personality mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return PersonalityReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<PersonalityReading> generate({
    required String readingId,
    String? deviceId,
  }) async {
    final res = await http.post(
      _u('/personality/$readingId/generate'),
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode >= 400) {
      throw Exception('personality generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return PersonalityReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Uint8List> downloadPdfBytes({
    required String readingId,
    String? deviceId,
  }) async {
    final res = await http.get(
      _u('/personality/$readingId/pdf'),
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode >= 400) {
      throw Exception('personality pdf failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return res.bodyBytes;
  }
}
