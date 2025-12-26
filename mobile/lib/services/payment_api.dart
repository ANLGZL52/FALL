import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base.dart';

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
    // backend hem payment_id hem payment_ref döndürüyor olabilir
    final pid = (j['payment_id'] ?? j['paymentId'] ?? j['payment_ref'] ?? '').toString();
    return StartPaymentResult(
      ok: (j['ok'] ?? true) as bool,
      status: (j['status'] ?? 'success').toString(),
      provider: (j['provider'] ?? 'mock').toString(),
      paymentId: pid,
      product: (j['product'] ?? 'coffee').toString(),
      readingId: (j['reading_id'] ?? j['readingId'] ?? '').toString(),
      amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : double.tryParse('${j['amount']}') ?? 0.0,
    );
  }
}

class PaymentApi {
  static Future<StartPaymentResult> startPayment({
    required String readingId,
    double? amount,
    String product = "coffee", // ✅ coffee bozulmasın, default coffee
  }) async {
    final url = Uri.parse('${ApiBase.baseUrl}/payments/start');

    final body = <String, dynamic>{
      "reading_id": readingId,
      "product": product,
    };
    if (amount != null) body["amount"] = amount;

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode >= 400) {
      throw Exception('payments/start failed: ${res.statusCode} / ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return StartPaymentResult.fromJson(decoded);
  }
}
