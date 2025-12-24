// lib/services/payment_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_base.dart';

class PaymentStartResult {
  final bool ok;
  final String paymentId;
  final String provider;

  PaymentStartResult({
    required this.ok,
    required this.paymentId,
    required this.provider,
  });

  factory PaymentStartResult.fromJson(Map<String, dynamic> json) {
    return PaymentStartResult(
      ok: (json['status']?.toString() ?? '') == 'success',
      paymentId: json['payment_id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
    );
  }
}

class PaymentApi {
  static String get _base => ApiBase.baseUrl;

  /// Mock ödeme başlatır -> {payment_id, status, provider}
  static Future<PaymentStartResult> startPayment({
    required String readingId,
    required double amount,
  }) async {
    final uri = Uri.parse('$_base/payments/start');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reading_id': readingId,
        'amount': amount,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('payment start failed: ${res.statusCode} / ${res.body}');
    }

    return PaymentStartResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
