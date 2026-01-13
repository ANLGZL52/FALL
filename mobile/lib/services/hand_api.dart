// mobile/lib/services/hand_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/hand_reading.dart';
import 'api_base.dart';

class HandApi {
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

  static Future<HandReading> start({
    required String name,
    int? age,
    required String topic,
    required String question,
    String? dominantHand, // right/left
    String? photoHand, // right/left
    String? relationshipStatus,
    String? bigDecision,
    String? deviceId,
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
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('hand/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> uploadImages({
    required String readingId,
    required List<File> files,
    String? deviceId,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId/upload-images');
    final req = http.MultipartRequest('POST', uri);

    // multipart headers
    final headers = <String, String>{"Accept": "application/json"};
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty) headers["X-Device-Id"] = d;
    req.headers.addAll(headers);

    for (final f in files) {
      req.files.add(await http.MultipartFile.fromPath('files', f.path));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('hand/upload-images failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ LEGACY: mock akış için (TEST-...)
  /// Real ödeme: /payments/verify server-side unlock yapıyor, burada çağırma.
  static Future<HandReading> markPaid({
    required String readingId,
    String? paymentRef,
    String? deviceId,
  }) async {
    final ref = (paymentRef ?? '').trim();

    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final uri = Uri.parse('$_base/hand/$readingId/mark-paid');

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode({"payment_ref": paymentRef}),
    );

    if (res.statusCode != 200) {
      throw Exception('hand/mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> generate({
    required String readingId,
    String? deviceId,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId/generate');

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode != 200) {
      throw Exception('hand/generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> detail({
    required String readingId,
    String? deviceId,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId');

    final res = await http.get(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode != 200) {
      throw Exception('hand/detail failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> rate({
    required String readingId,
    required int rating,
    String? deviceId,
  }) async {
    final uri = Uri.parse('$_base/hand/$readingId/rate');

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode({"rating": rating}),
    );

    if (res.statusCode != 200) {
      throw Exception('hand/rate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
