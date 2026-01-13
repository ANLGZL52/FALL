// lib/services/iap_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'device_id_service.dart';
import 'payment_api.dart';

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Completer<PaymentVerifyResult>? _verifyCompleter;
  String? _activePaymentId;
  String? _activeSku;

  /// Pending’de sonsuza kadar kalmasın
  static const Duration _defaultTimeout = Duration(minutes: 2);

  bool get _hasActiveFlow => _verifyCompleter != null;

  Future<void> _ensureListener(String deviceId) async {
    _sub ??= _iap.purchaseStream.listen(
      (purchases) async {
        for (final p in purchases) {
          await _handlePurchaseUpdate(deviceId, p);
        }
      },
      onError: (e) {
        _fail("purchaseStream error: $e");
      },
    );
  }

  Future<Map<String, ProductDetails>> loadProducts(Set<String> skus) async {
    final available = await _iap.isAvailable();
    if (!available) throw Exception("Store kullanılamıyor (IAP not available).");

    final resp = await _iap.queryProductDetails(skus);
    if (resp.error != null) {
      throw Exception("Product query error: ${resp.error}");
    }

    final map = <String, ProductDetails>{};
    for (final p in resp.productDetails) {
      map[p.id] = p;
    }
    return map;
  }

  /// intent -> store purchase -> verify
  Future<PaymentVerifyResult> buyAndVerify({
    required String readingId,
    required String sku,
    Duration timeout = _defaultTimeout,
  }) async {
    if (_hasActiveFlow) {
      throw Exception("Zaten devam eden bir ödeme var.");
    }

    final deviceId = await DeviceIdService.getOrCreate();

    // 1) Intent
    final intent = await PurchaseApi.createIntent(
      deviceId: deviceId,
      readingId: readingId,
      sku: sku,
    );

    _activePaymentId = intent.paymentId;
    _activeSku = sku;

    // 2) Purchase stream (tek kez)
    _verifyCompleter = Completer<PaymentVerifyResult>();
    await _ensureListener(deviceId);

    // 3) Buy (consumable: her kullanımda ödeme)
    final products = await loadProducts({sku});
    final pd = products[sku];
    if (pd == null) {
      _fail("SKU store’da bulunamadı: $sku");
      throw Exception("SKU store’da bulunamadı: $sku");
    }

    final ok = await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: pd),
      autoConsume: true,
    );

    if (!ok) {
      _fail("Satın alma başlatılamadı (buyConsumable false).");
      throw Exception("Satın alma başlatılamadı.");
    }

    // 4) Timeout ile bekle
    try {
      return await _verifyCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          _fail("Ödeme zaman aşımına uğradı. (pending çok uzun sürdü)");
          throw Exception("Ödeme zaman aşımı.");
        },
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _handlePurchaseUpdate(String deviceId, PurchaseDetails p) async {
    // Active flow yoksa gelen eventleri ignore et (restore vb.)
    if (_activeSku == null || _activePaymentId == null || _verifyCompleter == null) return;

    // Bu event bizim beklediğimiz SKU değilse ignore
    if (p.productID != _activeSku) return;

    // pending -> bekle
    if (p.status == PurchaseStatus.pending) return;

    // canceled
    if (p.status == PurchaseStatus.canceled) {
      _fail("Satın alma iptal edildi.");
      return;
    }

    // error
    if (p.status == PurchaseStatus.error) {
      _fail("Satın alma hatası: ${p.error}");
      return;
    }

    if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
      try {
        final platform = Platform.isIOS ? "app_store" : "google_play";

        // purchaseID bazen null gelebiliyor -> fallback üret
        final transactionId = (p.purchaseID != null && p.purchaseID!.trim().isNotEmpty)
            ? p.purchaseID!.trim()
            : "TXN-${DateTime.now().millisecondsSinceEpoch}";

        // InAppPurchase plugin: iOS’ta çoğu zaman serverVerificationData daha güvenilir
        final localData = p.verificationData.localVerificationData;
        final serverData = p.verificationData.serverVerificationData;

        String? purchaseToken;
        String? receiptData;

        if (platform == "google_play") {
          // Android: localData genelde JSON (purchaseToken vs)
          purchaseToken = _extractAndroidPurchaseToken(localData) ??
              _extractAndroidPurchaseToken(serverData) ??
              localData;

          if ((purchaseToken ?? '').trim().length < 6) {
            throw Exception("Android purchaseToken alınamadı.");
          }
        } else {
          // iOS: receipt çoğu zaman serverData’da gelir; fallback local
          receiptData = (serverData.trim().length >= 20) ? serverData : localData;
          if ((receiptData).trim().length < 20) {
            throw Exception("iOS receiptData alınamadı.");
          }
        }

        // ✅ Backend verify (server-side unlock)
        final res = await PurchaseApi.verify(
          deviceId: deviceId,
          paymentId: _activePaymentId!,
          sku: _activeSku!,
          platform: platform,
          transactionId: transactionId,
          purchaseToken: purchaseToken,
          receiptData: receiptData,
        );

        if (!res.verified) {
          _fail("Backend verify başarısız: ${res.status}");
          return;
        }

        // ✅ Transaction’ı tamamla (deliver content -> then completePurchase)
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }

        _success(res);
      } catch (e) {
        _fail("Verify exception: $e");
      }
    }
  }

  String? _extractAndroidPurchaseToken(String raw) {
    try {
      final obj = jsonDecode(raw);
      if (obj is Map<String, dynamic>) {
        final t = obj["purchaseToken"] ?? obj["token"];
        if (t != null) return t.toString();
      }
    } catch (_) {}
    return null;
  }

  void _success(PaymentVerifyResult res) {
    if (_verifyCompleter != null && !_verifyCompleter!.isCompleted) {
      _verifyCompleter!.complete(res);
    }
    _cleanup();
  }

  void _fail(String msg) {
    if (_verifyCompleter != null && !_verifyCompleter!.isCompleted) {
      _verifyCompleter!.completeError(Exception(msg));
    }
    _cleanup();
  }

  void _cleanup() {
    _verifyCompleter = null;
    _activePaymentId = null;
    _activeSku = null;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
