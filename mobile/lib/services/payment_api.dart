// lib/services/payment_api.dart
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
/// LEGACY START (bozulmasın diye duruyor)
/// POST /payments/start
/// ===============================

class StartPaymentResult {
  final bool ok;
  final String status; // success
  final String provider; // mock
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
      amount: (j['amount'] is num)
          ? (j['amount'] as num).toDouble()
          : double.tryParse('${j['amount']}') ?? 0.0,
    );
  }
}

class PaymentApi {
  /// ✅ LEGACY START (mock) — mevcut akışı bozmaz.
  static Future<StartPaymentResult> startPayment({
    required String readingId,
    double? amount,
    required String product, // coffee | hand | tarot | ...
    String? deviceId,
  }) async {
    final url = Uri.parse('${ApiBase.baseUrl}/payments/start');

    final body = <String, dynamic>{
      "reading_id": readingId,
      "product": product,
    };
    if (amount != null) body["amount"] = amount;

    final res = await http
        .post(
          url,
          headers: ApiBase.headers(deviceId: deviceId),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode >= 400) {
      throw Exception('payments/start failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return StartPaymentResult.fromJson(decoded);
  }
}

/// ===============================
/// NEW STORE/IAP FLOW (intent + verify)
/// POST /payments/intent
/// POST /payments/verify
/// ===============================

class PaymentIntentResult {
  final bool ok;
  final String status; // pending
  final String paymentId;
  final String readingId;
  final String sku;
  final String product;
  final double amount;
  final String currency;

  PaymentIntentResult({
    required this.ok,
    required this.status,
    required this.paymentId,
    required this.readingId,
    required this.sku,
    required this.product,
    required this.amount,
    required this.currency,
  });

  factory PaymentIntentResult.fromJson(Map<String, dynamic> j) {
    final okVal = j.containsKey('ok') ? j['ok'] : true;
    final ok = okVal is bool ? okVal : (okVal.toString().toLowerCase() == 'true');

    // Fallback: snake_case + camelCase + id
    final paymentId = (j['payment_id'] ?? j['paymentId'] ?? j['id'] ?? '').toString();
    final readingId = (j['reading_id'] ?? j['readingId'] ?? '').toString();
    final product = (j['product'] ?? j['product_type'] ?? j['productType'] ?? '').toString();

    return PaymentIntentResult(
      ok: ok,
      status: (j['status'] ?? 'pending').toString(),
      paymentId: paymentId,
      readingId: readingId,
      sku: (j['sku'] ?? '').toString(),
      product: product,
      amount: (j['amount'] is num)
          ? (j['amount'] as num).toDouble()
          : double.tryParse('${j['amount']}') ?? 0.0,
      currency: (j['currency'] ?? 'TRY').toString(),
    );
  }
}

class PaymentVerifyResult {
  final bool ok;
  final bool verified;
  final String paymentId;
  final String status;

  PaymentVerifyResult({
    required this.ok,
    required this.verified,
    required this.paymentId,
    required this.status,
  });

  factory PaymentVerifyResult.fromJson(Map<String, dynamic> j) {
    final okVal = j.containsKey('ok') ? j['ok'] : true;
    final ok = okVal is bool ? okVal : (okVal.toString().toLowerCase() == 'true');

    final verVal = j.containsKey('verified') ? j['verified'] : false;
    final verified = verVal is bool ? verVal : (verVal.toString().toLowerCase() == 'true');

    // Fallback: snake_case + camelCase + id
    final paymentId = (j['payment_id'] ?? j['paymentId'] ?? j['id'] ?? '').toString();

    return PaymentVerifyResult(
      ok: ok,
      verified: verified,
      paymentId: paymentId,
      status: (j['status'] ?? '').toString(),
    );
  }
}

class PurchaseApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  /// ✅ /payments/intent
  static Future<PaymentIntentResult> createIntent({
    required String deviceId,
    required String readingId,
    required String sku,
  }) async {
    final body = <String, dynamic>{
      "reading_id": readingId,
      "sku": sku,
    };

    final res = await http
        .post(
          _u('/payments/intent'),
          headers: ApiBase.headers(deviceId: deviceId),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode >= 400) {
      throw Exception('payments/intent failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return PaymentIntentResult.fromJson(decoded);
  }

  /// ✅ /payments/verify
  static Future<PaymentVerifyResult> verify({
    required String deviceId,
    required String paymentId,
    required String sku,
    required String platform, // "google_play" | "app_store"
    required String transactionId,
    String? purchaseToken, // google
    String? receiptData, // apple (base64)
  }) async {
    final body = <String, dynamic>{
      "payment_id": paymentId,
      "platform": platform,
      "sku": sku,
      "transaction_id": transactionId,
    };

    final pt = (purchaseToken ?? '').trim();
    final rd = (receiptData ?? '').trim();

    if (platform == "google_play") {
      if (pt.length < 6) {
        throw Exception("purchaseToken gerekli (google_play) ve en az 6 karakter olmalı.");
      }
      body["purchase_token"] = pt;
    } else if (platform == "app_store") {
      if (rd.length < 20) {
        throw Exception("receiptData gerekli (app_store) ve en az 20 karakter olmalı.");
      }
      body["receipt_data"] = rd;
    } else {
      throw Exception('platform geçersiz: $platform');
    }

    final res = await http
        .post(
          _u('/payments/verify'),
          headers: ApiBase.headers(deviceId: deviceId),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode >= 400) {
      throw Exception('payments/verify failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return PaymentVerifyResult.fromJson(decoded);
  }
}
