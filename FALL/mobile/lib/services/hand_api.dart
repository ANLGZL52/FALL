import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/hand_reading.dart';
import 'api_base.dart';
import 'device_id_service.dart';

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

class HandApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  static const Duration _timeout = Duration(seconds: 45);
  static const Duration _generateTimeout = Duration(seconds: 180);

  static Future<String> _resolveDeviceId(String? deviceId) async {
    final d = (deviceId ?? '').trim();
    if (d.isNotEmpty && d.length >= 8) return d;
    return await DeviceIdService.getOrCreate();
  }

  static Future<HandReading> start({
    String? deviceId,
    required String topic,
    required String question,
    required String name,
    int? age,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final body = {
      "topic": topic,
      "question": question,
      "name": name,
      "age": age,
    };

    final res = await http
        .post(
          _u('/hand/start'),
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (res.statusCode >= 400) {
      throw Exception('hand/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> uploadImages({
    String? deviceId,
    required String readingId,
    required List<File> imageFiles,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final req = http.MultipartRequest('POST', _u('/hand/$readingId/upload-images'));
    req.headers.addAll(ApiBase.headers(deviceId: did));

    for (final f in imageFiles) {
      req.files.add(await http.MultipartFile.fromPath('files', f.path));
    }

    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 400) {
      throw Exception('hand/upload-images failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> detail({
    String? deviceId,
    required String readingId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .get(
          _u('/hand/$readingId'),
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_timeout);

    if (res.statusCode >= 400) {
      throw Exception('hand/detail failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> generate({
    String? deviceId,
    required String readingId,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .post(
          _u('/hand/$readingId/generate'),
          headers: ApiBase.headers(deviceId: did),
        )
        .timeout(_generateTimeout);

    if (res.statusCode >= 400) {
      throw Exception('hand/generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<HandReading> rate({
    String? deviceId,
    required String readingId,
    required int rating,
  }) async {
    final did = await _resolveDeviceId(deviceId);

    final res = await http
        .post(
          _u('/hand/$readingId/rate'),
          headers: ApiBase.headers(deviceId: did),
          body: jsonEncode({"rating": rating}),
        )
        .timeout(_timeout);

    if (res.statusCode >= 400) {
      throw Exception('hand/rate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return HandReading.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
