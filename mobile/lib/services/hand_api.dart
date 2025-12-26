// mobile/lib/services/hand_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/hand_reading.dart';
import 'api_base.dart';

class HandApi {
  static String get _base => ApiBase.baseUrl;

  static Future<HandReading> start({
    required String name,
    int? age,
    required String topic,
    required String question,
    String? dominantHand, // right/left
    String? photoHand,    // right/left
    String? relationshipStatus,
    String? bigDecision,
  }) async {
    final uri = Uri.parse('$_base/hand/start');
    final body = {
      "name": name,
      "age": age,
      "topic": topic,
      "question": question,
      "dominant_hand": dominantHand,
      "photo_hand": photoHand,
      "relationship_status": relationshipStatus,
      "big_decision": bigDecision,
    };

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('start failed: ${res.statusCode} / ${res.body}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> uploadImages({
    required String readingId,
    required List<File> files,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId/upload-images');
    final req = http.MultipartRequest('POST', uri);

    for (final f in files) {
      req.files.add(await http.MultipartFile.fromPath('files', f.path));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('upload failed: ${res.statusCode} / ${res.body}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> markPaid({
    required String readingId,
    String? paymentRef,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId/mark-paid');

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception('mark-paid failed: ${res.statusCode} / ${res.body}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> generate({
    required String readingId,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId/generate');

    final res = await http.post(uri);

    if (res.statusCode != 200) {
      throw Exception('generate failed: ${res.statusCode} / ${res.body}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> detail({
    required String readingId,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('detail failed: ${res.statusCode} / ${res.body}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> rate({
    required String readingId,
    required int rating,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId/rate');

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"rating": rating}),
    );

    if (res.statusCode != 200) {
      throw Exception('rate failed: ${res.statusCode} / ${res.body}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
