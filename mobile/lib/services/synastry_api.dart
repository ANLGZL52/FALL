import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/synastry_models.dart';
import 'api_base.dart';

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

class SynastryApi {
  Future<SynastryStartResponse> start(
    SynastryStartRequest req, {
    String? deviceId,
  }) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/start');

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode(req.toJson()),
    );

    if (res.statusCode >= 400) {
      throw Exception('Synastry start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SynastryStartResponse.fromJson(data);
  }

  /// ✅ LEGACY only
  Future<void> markPaid(
    String id, {
    String? paymentRef,
    String? deviceId,
  }) async {
    final ref = (paymentRef ?? '').trim();
    if (ref.isNotEmpty && !ref.startsWith("TEST-")) {
      throw Exception("markPaid legacy only. Real payments use /payments/verify.");
    }

    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/$id/mark-paid');

    final body = SynastryMarkPaidRequest(paymentRef: paymentRef).toJson();

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
      body: jsonEncode(body),
    );

    if (res.statusCode >= 400) {
      throw Exception('Synastry mark-paid failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
  }

  Future<void> generate(
    String id, {
    String? deviceId,
  }) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/$id/generate');

    final res = await http.post(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode >= 400) {
      throw Exception('Synastry generate failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
  }

  Future<SynastryStatusResponse> getStatus(
    String id, {
    String? deviceId,
  }) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/$id');

    final res = await http.get(
      uri,
      headers: ApiBase.headers(deviceId: deviceId),
    );

    if (res.statusCode >= 400) {
      throw Exception('Synastry status failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SynastryStatusResponse.fromJson(data);
  }

  Future<Uint8List> downloadPdf(
    String id, {
    String? deviceId,
  }) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/$id/pdf');

    final res = await http.get(uri, headers: ApiBase.headers(deviceId: deviceId));
    if (res.statusCode >= 400) {
      throw Exception('PDF download failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }
    return res.bodyBytes;
  }
}
