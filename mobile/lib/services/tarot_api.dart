import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base.dart';

class TarotApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  static Future<Map<String, dynamic>> start({
    required String topic,
    required String question,
    String? name,
    int? age,
    required String spreadType, // three/six/twelve
  }) async {
    final res = await http.post(
      _u('/tarot/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "topic": topic,
        "question": question,
        "name": name,
        "age": age,
        "spread_type": spreadType,
      }),
    );

    if (res.statusCode >= 400) {
      throw Exception('Tarot start failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> selectCards({
    required String readingId,
    required List<String> cards, // id listesi (ör: major_18_moon|R)
  }) async {
    final res = await http.post(
      _u('/tarot/$readingId/select-cards'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"cards": cards}),
    );

    if (res.statusCode >= 400) {
      throw Exception('select-cards failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> markPaid({
    required String readingId,
    required String paymentRef,
  }) async {
    final res = await http.post(
      _u('/tarot/$readingId/mark-paid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode >= 400) {
      throw Exception('mark-paid failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> generate({
    required String readingId,
  }) async {
    final res = await http.post(
      _u('/tarot/$readingId/generate'),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode >= 400) {
      throw Exception('generate failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> detail({
    required String readingId,
  }) async {
    final res = await http.get(
      _u('/tarot/$readingId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode >= 400) {
      throw Exception('detail failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
