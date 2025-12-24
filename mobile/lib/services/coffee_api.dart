// lib/services/coffee_api.dart
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
  }) async {
    final uri = Uri.parse('$_base/coffee/start');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'age': age,
        'topic': topic,
        'question': question,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('start failed: ${res.statusCode} / ${res.body}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// 3-5 foto şart. Backend List[UploadFile] beklediği için field adı "files".
  static Future<CoffeeReading> uploadPhotos({
    required String readingId,
    required List<File> imageFiles,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/upload-images');
    final request = http.MultipartRequest('POST', uri);

    for (final f in imageFiles) {
      request.files.add(await http.MultipartFile.fromPath('files', f.path));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('upload failed: ${res.statusCode} / ${res.body}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> markPaid({
    required String readingId,
    required String paymentRef,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/mark-paid');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'payment_ref': paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception('markPaid failed: ${res.statusCode} / ${res.body}');
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
    required int rating, // 1-5
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/rate');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rating': rating}),
    );

    if (res.statusCode != 200) {
      throw Exception('rate failed: ${res.statusCode} / ${res.body}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
