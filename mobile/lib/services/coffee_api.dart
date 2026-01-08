// mobile/lib/services/coffee_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/coffee_reading.dart';
import 'api_base.dart';

class CoffeeApi {
  static String get _base => ApiBase.baseUrl;

  static Future<CoffeeReading> start({
    required String name,
    int? age,
    required String topic,
    required String question,
    String? relationshipStatus,
    String? bigDecision,
  }) async {
    final uri = Uri.parse('$_base/coffee/start');
    final body = {
      "name": name,
      "age": age,
      "topic": topic,
      "question": question,
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

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ Backend endpoint: /upload-images
  static Future<CoffeeReading> uploadImages({
    required String readingId,
    required List<File> files,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/upload-images');
    final req = http.MultipartRequest('POST', uri);

    for (final f in files) {
      req.files.add(await http.MultipartFile.fromPath('files', f.path));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('upload failed: ${res.statusCode} / ${res.body}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ ESKİ KODLAR BOZULMASIN diye ALIAS
  static Future<CoffeeReading> uploadPhotos({
    required String readingId,
    List<File>? files,
    List<File>? imageFiles,
  }) {
    final chosen = (files != null && files.isNotEmpty)
        ? files
        : (imageFiles ?? <File>[]);

    if (chosen.isEmpty) {
      throw Exception('uploadPhotos failed: files/imageFiles is empty');
    }

    return uploadImages(readingId: readingId, files: chosen);
  }

  static Future<CoffeeReading> markPaid({
    required String readingId,
    String? paymentRef,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/mark-paid');

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception('mark-paid failed: ${res.statusCode} / ${res.body}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> generate({
    required String readingId,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/generate');
    final res = await http.post(uri);

    if (res.statusCode != 200) {
      throw Exception('generate failed: ${res.statusCode} / ${res.body}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ FIX: Modelde olmayan alanlara (resultText/result/text) erişme!
  /// CoffeeReading.fromJson zaten comment veya result_text'i `comment` alanına map ediyor.
  static Future<String> generateText({
    required String readingId,
  }) async {
    final CoffeeReading reading = await generate(readingId: readingId);

    final String text = (reading.comment ?? '').trim();

    if (text.isEmpty) {
      throw Exception(
        'generateText: comment is empty (backend should return comment or result_text)',
      );
    }

    return text;
  }

  static Future<CoffeeReading> detail({
    required String readingId,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('detail failed: ${res.statusCode} / ${res.body}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> rate({
    required String readingId,
    required int rating,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/rate');

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"rating": rating}),
    );

    if (res.statusCode != 200) {
      throw Exception('rate failed: ${res.statusCode} / ${res.body}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
