// lib/services/synastry_api.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/synastry_models.dart';
import 'api_base.dart';

class SynastryApi {
  Future<SynastryStartResponse> start(SynastryStartRequest req) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/start');

    final res = await http.post(
      uri,
      headers: ApiBase.jsonHeaders,
      body: jsonEncode(req.toJson()),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Synastry start failed: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SynastryStartResponse.fromJson(data);
  }

  Future<void> markPaid(String id, {String? paymentRef}) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/$id/mark-paid');

    final body = SynastryMarkPaidRequest(paymentRef: paymentRef).toJson();

    final res = await http.post(
      uri,
      headers: ApiBase.jsonHeaders,
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Synastry mark-paid failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> generate(String id) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/$id/generate');

    final res = await http.post(uri, headers: ApiBase.jsonHeaders);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Synastry generate failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<SynastryStatusResponse> getStatus(String id) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/$id');

    final res = await http.get(uri, headers: ApiBase.jsonHeaders);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Synastry status failed: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SynastryStatusResponse.fromJson(data);
  }

  Future<Uint8List> downloadPdf(String id) async {
    final uri = Uri.parse('${ApiBase.baseUrl}/synastry/$id/pdf');

    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PDF download failed: ${res.statusCode} ${res.body}');
    }
    return res.bodyBytes;
  }
}
