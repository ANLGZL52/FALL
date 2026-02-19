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

class NumerologyReading {
  final String id;
  final String topic;
  final String? question;
  final String name;
  final String birthDate;
  final String status;
  final String? resultText;
  final bool isPaid;
  final String? paymentRef;

  NumerologyReading({
    required this.id,
    required this.topic,
    required this.question,
    required this.name,
    required this.birthDate,
    required this.status,
    required this.resultText,
    required this.isPaid,
    required this.paymentRef,
  });

  factory NumerologyReading.fromJson(Map<String, dynamic> j) {
    return NumerologyReading(
      id: (j["id"] ?? "").toString(),
      topic: (j["topic"] ?? "genel").toString(),
      question: j["question"]?.toString(),
      name: (j["name"] ?? "").toString(),
      birthDate: (j["birth_date"] ?? "").toString(),
      status: (j["status"] ?? "").toString(),
      resultText: j["result_text"]?.toString(),
      isPaid: (j["is_paid"] ?? false) == true,
      paymentRef: j["payment_ref"]?.toString(),
    );
  }
}

class NumerologyApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _generateTimeout = Duration(seconds: 150);

  static Future<NumerologyReading> start({
    required String name,
    required String birthDate, // YYYY-MM-DD
    required String topic,
    String? question,
    String? deviceId,
  }) async {
    final q = (question ?? '').trim();

    final res = await http
        .post(
          _u('/numerology/start'),
          headers: ApiBase.headers(deviceId: deviceId),
          body: jsonEncode({
            "name": name,
            "birth_date": birthDate,
            "topic": topic,
            "question": q.isEmpty ? null : q,
          }),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception("numerology/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }

    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// LEGACY (mock) için kalsın.
  static Future<NumerologyReading> markPaid({
    required String readingId,
    String? paymentRef,
    String? deviceId,
  }) async {
    final ref = (paymentRef ?? '').trim();
    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final res = await http
        .post(
          _u('/numerology/$readingId/mark-paid'),
          headers: ApiBase.headers(deviceId: deviceId),
          body: jsonEncode({"payment_ref": paymentRef}),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception("numerology/mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }

    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<NumerologyReading> generate({
    required String readingId,
    String? deviceId,
  }) async {
    final res = await http
        .post(
          _u('/numerology/$readingId/generate'),
          headers: ApiBase.headers(deviceId: deviceId),
        )
        .timeout(_generateTimeout);

    if (res.statusCode != 200) {
      throw Exception("numerology/generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}");
    }

    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<String> generateText({
    required String readingId,
    String? deviceId,
  }) async {
    final r = await generate(readingId: readingId, deviceId: deviceId);
    final t = (r.resultText ?? '').trim();
    if (t.isEmpty) throw Exception("generateText: result_text empty");
    return t;
  }
}
