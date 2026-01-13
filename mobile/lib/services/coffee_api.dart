// mobile/lib/services/coffee_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/coffee_reading.dart';
import 'api_base.dart';

class CoffeeApi {
  static String get _base => ApiBase.baseUrl;

  static String _extractErrorMessage(String body) {
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

  static Future<CoffeeReading> start({
    required String name,
    int? age,
    required String topic,
    required String question,
    String? relationshipStatus,
    String? bigDecision,
    String? deviceId, // opsiyonel
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
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('coffee/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ Backend endpoint: /upload-images
  static Future<CoffeeReading> uploadImages({
    required String readingId,
    required List<File> files,
    String? deviceId, // opsiyonel
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/upload-images');
    final req = http.MultipartRequest('POST', uri);

    // Header'lar (multipart'ta Content-Type'ı paket ayarlar; biz sadece accept + device ekleyelim)
    final headers = <String, String>{};
    headers.addAll({"Accept": "application/json"});
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty) headers["X-Device-Id"] = d;
    req.headers.addAll(headers);

    for (final f in files) {
      req.files.add(await http.MultipartFile.fromPath('files', f.path));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('coffee/upload-images failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ ESKİ KODLAR BOZULMASIN diye ALIAS
  static Future<CoffeeReading> uploadPhotos({
    required String readingId,
    List<File>? files,
    List<File>? imageFiles,
    String? deviceId,
  }) {
    final chosen = (files != null && files.isNotEmpty)
        ? files
        : (imageFiles ?? <File>[]);

    if (chosen.isEmpty) {
      throw Exception('uploadPhotos failed: files/imageFiles is empty');
    }

    return uploadImages(readingId: readingId, files: chosen, deviceId: deviceId);
  }

  /// ✅ LEGACY: mock akış için (TEST-...)
  /// Real ödeme: /payments/verify server-side unlock yapıyor, burada çağırma.
  static Future<CoffeeReading> markPaid({
    required String readingId,
    String? paymentRef,
    String? deviceId, // opsiyonel
  }) async {
    final ref = (paymentRef ?? '').trim();

    // UI kazası önle: gerçek ödeme ref'leri burada kullanılmasın
    // (backend zaten 403 döner, biz daha hızlı feedback veriyoruz)
    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final uri = Uri.parse('$_base/coffee/$readingId/mark-paid');

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception('coffee/mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> generate({
    required String readingId,
    String? deviceId, // opsiyonel
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/generate');

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode != 200) {
      throw Exception('coffee/generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ CoffeeReading.fromJson zaten comment/result_text'i `comment` alanına map ediyor.
  static Future<String> generateText({
    required String readingId,
    String? deviceId,
  }) async {
    final CoffeeReading reading = await generate(readingId: readingId, deviceId: deviceId);

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
    String? deviceId,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId');

    final res = await http.get(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode != 200) {
      throw Exception('coffee/detail failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> rate({
    required String readingId,
    required int rating,
    String? deviceId,
  }) async {
    final uri = Uri.parse('$_base/coffee/$readingId/rate');

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode({"rating": rating}),
    );

    if (res.statusCode != 200) {
      throw Exception('coffee/rate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
