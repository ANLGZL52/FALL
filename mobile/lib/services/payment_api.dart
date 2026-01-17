import 'dart:convert';
import 'package:http/http.dart' as http;

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

/// ===============================
/// LEGACY START (bozulmasın)
/// POST /payments/start
/// ===============================

class StartPaymentResult {
  final bool ok;
  final String status;
  final String provider;
  final String paymentId;
  final String product;
  final String readingId;
  final double amount;

  StartPaymentResult({
    required this.ok,
    required this.status,
    required this.provider,
    required this.paymentId,
    required this.product,
    required this.readingId,
    required this.amount,
  });

  factory StartPaymentResult.fromJson(Map<String, dynamic> j) {
    final pid = (j['payment_id'] ?? j['paymentId'] ?? j['payment_ref'] ?? j['paymentRef'] ?? '').toString();
    final okVal = j.containsKey('ok') ? j['ok'] : true;
    final ok = okVal is bool ? okVal : (okVal.toString().toLowerCase() == 'true');

    return StartPaymentResult(
      ok: ok,
      status: (j['status'] ?? 'success').toString(),
      provider: (j['provider'] ?? 'mock').toString(),
      paymentId: pid,
      product: (j['product'] ?? j['product_type'] ?? j['productType'] ?? '').toString(),
      readingId: (j['reading_id'] ?? j['readingId'] ?? '').toString(),
      amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : double.tryParse('${j['amount']}') ?? 0.0,
    );
  }
}

class PaymentApi {
  static Future<StartPaymentResult> startPayment({
    required String readingId,
    double? amount,
    required String product,
    String? deviceId,
  }) async {
    final url = Uri.parse('${ApiBase.baseUrl}/payments/start');

    final body = <String, dynamic>{
      "reading_id": readingId,
      "product": product,
    };
    if (amount != null) body["amount"] = amount;

    final res = await http
        .post(url, headers: ApiBase.headers(deviceId: deviceId), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    if (res.statusCode >= 400) {
      throw Exception('payments/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    return StartPaymentResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
