import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

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
  /// Windows Desktop: 127.0.0.1 çalışır.
  /// Android Emulator: 10.0.2.2 kullanmalısın.
  /// Gerçek telefon: PC'nin LAN IP'si (örn 192.168.1.xx)
  static const String baseUrl = "http://127.0.0.1:8001/api/v1";

  static Future<PersonalityReading> start({
    required String name,
    required String birthDate, // YYYY-MM-DD
    String? birthTime, // HH:MM (ops)
    required String birthCity,
    required String birthCountry,
    required String topic,
    String? question,
  }) async {
    final uri = Uri.parse("$baseUrl/personality/start");
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
      throw Exception("personality start failed: ${res.statusCode} ${res.body}");
    }
    return PersonalityReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<PersonalityReading> markPaid({
    required String readingId,
    String? paymentRef,
  }) async {
    final uri = Uri.parse("$baseUrl/personality/$readingId/mark-paid");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception("personality mark-paid failed: ${res.statusCode} ${res.body}");
    }
    return PersonalityReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<PersonalityReading> generate({
    required String readingId,
  }) async {
    final uri = Uri.parse("$baseUrl/personality/$readingId/generate");
    final res = await http.post(uri);

    if (res.statusCode != 200) {
      throw Exception("personality generate failed: ${res.statusCode} ${res.body}");
    }
    return PersonalityReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Uint8List> downloadPdfBytes({
    required String readingId,
  }) async {
    final uri = Uri.parse("$baseUrl/personality/$readingId/pdf");
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception("personality pdf failed: ${res.statusCode} ${res.body}");
    }
    return res.bodyBytes;
  }
}
