import 'dart:convert';
import 'package:http/http.dart' as http;

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
  // Windows desktop: 127.0.0.1 çalışır
  static const String baseUrl = "http://127.0.0.1:8001/api/v1";

  static Future<NumerologyReading> start({
    required String name,
    required String birthDate, // YYYY-MM-DD
    required String topic,
    String? question,
  }) async {
    final uri = Uri.parse("$baseUrl/numerology/start");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "birth_date": birthDate,
        "topic": topic,
        "question": question,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("start failed: ${res.statusCode} ${res.body}");
    }
    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<NumerologyReading> markPaid({
    required String readingId,
    String? paymentRef,
  }) async {
    final uri = Uri.parse("$baseUrl/numerology/$readingId/mark-paid");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception("mark-paid failed: ${res.statusCode} ${res.body}");
    }
    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<NumerologyReading> generate({
    required String readingId,
  }) async {
    final uri = Uri.parse("$baseUrl/numerology/$readingId/generate");
    final res = await http.post(uri);

    if (res.statusCode != 200) {
      throw Exception("generate failed: ${res.statusCode} ${res.body}");
    }
    return NumerologyReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
