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
/// NEW STORE/IAP FLOW
/// POST /payments/intent
/// POST /payments/verify
/// ===============================

class PaymentIntentResult {
  final bool ok;
  final String status;
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

    return PaymentIntentResult(
      ok: ok,
      status: (j['status'] ?? 'pending').toString(),
      paymentId: (j['payment_id'] ?? j['paymentId'] ?? j['id'] ?? '').toString(),
      readingId: (j['reading_id'] ?? j['readingId'] ?? '').toString(),
      sku: (j['sku'] ?? '').toString(),
      product: (j['product'] ?? j['product_type'] ?? j['productType'] ?? '').toString(),
      amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : double.tryParse('${j['amount']}') ?? 0.0,
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

    return PaymentVerifyResult(
      ok: ok,
      verified: verified,
      paymentId: (j['payment_id'] ?? j['paymentId'] ?? j['id'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
    );
  }
}

class PurchaseApi {
  static Uri _u(String path) => Uri.parse('${ApiBase.baseUrl}$path');

  // ✅ Intent genelde hızlı
  static const Duration _intentTimeout = Duration(seconds: 30);

  // ✅ Verify bazen uzayabiliyor (network / backend / store)
  // IapService zaten kendi içinde retry yapıyor. Burada timeout'u uzun tutmak daha güvenli.
  static const Duration _verifyTimeout = Duration(seconds: 90);

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
        .timeout(_intentTimeout);

    if (res.statusCode >= 400) {
      throw Exception('payments/intent failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    final out = PaymentIntentResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);

    // ekstra güvenlik
    if (!out.ok || out.paymentId.trim().isEmpty) {
      throw Exception('payments/intent invalid response: ${res.body}');
    }

    return out;
  }

  static Future<PaymentVerifyResult> verify({
    required String deviceId,
    required String paymentId,
    required String sku,
    required String platform, // google_play | app_store
    required String transactionId,
    String? purchaseToken,
    String? receiptData,
  }) async {
    final body = <String, dynamic>{
      "payment_id": paymentId,
      "platform": platform,
      "sku": sku,
      "transaction_id": transactionId,
    };

    if (platform == "google_play") {
      final pt = (purchaseToken ?? '').trim();
      if (pt.length < 6) throw Exception("purchaseToken gerekli (google_play).");
      body["purchase_token"] = pt;
    } else if (platform == "app_store") {
      final rd = (receiptData ?? '').trim();
      if (rd.length < 20) throw Exception("receiptData gerekli (app_store).");
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
        .timeout(_verifyTimeout);

    if (res.statusCode >= 400) {
      throw Exception('payments/verify failed: ${res.statusCode} / ${_extractErrorMessage(res.body)}');
    }

    final out = PaymentVerifyResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);

    // ✅ verify false ise bunu net hata yapalım (üst katman doğru mesaj göstersin)
    if (!out.ok || !out.verified) {
      throw Exception('IAP doğrulama başarısız: status=${out.status}');
    }

    return out;
  }
}
