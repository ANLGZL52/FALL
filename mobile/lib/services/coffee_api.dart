import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/coffee_reading.dart';
import 'api_base.dart';
import 'device_id_service.dart';

class CoffeeApi {
  static String get _base => ApiBase.baseUrl;

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 90);
  static const Duration _generateTimeout = Duration(seconds: 150);

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

  static Future<String> _resolveDeviceId(String? deviceId) async {
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty) return d;
    return await DeviceIdService.getOrCreate();
  }

  static Future<CoffeeReading> start({
    required String name,
    int? age,
    required String topic,
    required String question,
    String? relationshipStatus,
    String? bigDecision,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final uri = Uri.parse('$_base/coffee/start');
    final body = {
      "name": name,
      "age": age,
      "topic": topic,
      "question": question,
      "relationship_status": relationshipStatus,
      "big_decision": bigDecision,
    };

    final res = await http
        .post(
          uri,
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode(body),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception('coffee/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> uploadImages({
    required String readingId,
    required List<File> files,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final uri = Uri.parse('$_base/coffee/$readingId/upload-images');
    final req = http.MultipartRequest('POST', uri);

    // ✅ middleware tüm endpointlerde device id isteyebilir
    req.headers.addAll({
      "Accept": "application/json",
      "X-Device-Id": did,
    });

    for (final f in files) {
      req.files.add(await http.MultipartFile.fromPath('files', f.path));
    }

    final streamed = await req.send().timeout(_uploadTimeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('coffee/upload-images failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> uploadPhotos({
    required String readingId,
    List<File>? files,
    List<File>? imageFiles,
    String? deviceId,
  }) {
    final chosen = (files != null && files.isNotEmpty) ? files : (imageFiles ?? <File>[]);
    if (chosen.isEmpty) {
      throw Exception('uploadPhotos failed: files/imageFiles is empty');
    }
    return uploadImages(readingId: readingId, files: chosen, deviceId: deviceId);
  }

  /// ✅ LEGACY: mock akış için (TEST-...)
  static Future<CoffeeReading> markPaid({
    required String readingId,
    String? paymentRef,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final ref = (paymentRef ?? '').trim();
    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final uri = Uri.parse('$_base/coffee/$readingId/mark-paid');

    final res = await http
        .post(
          uri,
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode({"payment_ref": paymentRef}),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception('coffee/mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> generate({
    required String readingId,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final uri = Uri.parse('$_base/coffee/$readingId/generate');

    final res = await http
        .post(
          uri,
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_generateTimeout);

    if (res.statusCode != 200) {
      throw Exception('coffee/generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CoffeeReading> detail({
    required String readingId,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final uri = Uri.parse('$_base/coffee/$readingId');

    final res = await http
        .get(
          uri,
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception('coffee/detail failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> detailRaw({
    required String readingId,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final uri = Uri.parse('$_base/coffee/$readingId');

    final res = await http
        .get(
          uri,
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception('coffee/detail failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<CoffeeReading> rate({
    required String readingId,
    required int rating,
    String? deviceId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final uri = Uri.parse('$_base/coffee/$readingId/rate');

    final res = await http
        .post(
          uri,
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode({"rating": rating}),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200) {
      throw Exception('coffee/rate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return CoffeeReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
