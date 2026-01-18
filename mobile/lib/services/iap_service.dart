import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'device_id_service.dart';
import 'purchase_api.dart';

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Completer<PaymentVerifyResult>? _verifyCompleter;
  String? _activePaymentId;
  String? _activeSku;

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

    // 2) Stream
    _verifyCompleter = Completer<PaymentVerifyResult>();
    await _ensureListener(deviceId);

    // 3) Buy (consumable)
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

    // 4) Wait with timeout
    return await _verifyCompleter!.future.timeout(
      timeout,
      onTimeout: () {
        _fail("Ödeme zaman aşımına uğradı. (pending çok uzun sürdü)");
        throw Exception("Ödeme zaman aşımı.");
      },
    );
  }

  Future<void> _handlePurchaseUpdate(String deviceId, PurchaseDetails p) async {
    if (_activeSku == null || _activePaymentId == null || _verifyCompleter == null) return;
    if (p.productID != _activeSku) return;

    if (p.status == PurchaseStatus.pending) return;

    if (p.status == PurchaseStatus.canceled) {
      _fail("Satın alma iptal edildi.");
      return;
    }

    if (p.status == PurchaseStatus.error) {
      _fail("Satın alma hatası: ${p.error}");
      return;
    }

    if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
      try {
        final platform = Platform.isIOS ? "app_store" : "google_play";

        String? transactionId;
        String? purchaseToken;
        String? receiptData;

        // -------------------------
        // ANDROID (Google Play)
        // -------------------------
        if (platform == "google_play") {
          // ✅ En güvenilir kaynak: GooglePlayPurchaseDetails -> billingClientPurchase
          if (p is GooglePlayPurchaseDetails) {
            final orderId = (p.billingClientPurchase.orderId ?? '').trim();
            final token = (p.billingClientPurchase.purchaseToken ?? '').trim();
            final purchaseTime = p.billingClientPurchase.purchaseTime ?? 0;

            if (token.isNotEmpty) {
              purchaseToken = token;
            }

            // ✅ transaction_id: orderId varsa direkt kullan
            if (orderId.isNotEmpty) {
              transactionId = orderId;
            } else if (token.isNotEmpty) {
              // orderId boşsa token + time ile stabil bir id üret (random değil)
              final head = token.substring(0, token.length >= 16 ? 16 : token.length);
              transactionId = "GP-$head-$purchaseTime";
            }
          }

          // Fallback: verificationData
          final localData = (p.verificationData.localVerificationData).trim();
          final serverData = (p.verificationData.serverVerificationData).trim();

          purchaseToken ??= _extractAndroidPurchaseToken(localData) ??
              _extractAndroidPurchaseToken(serverData) ??
              (serverData.length >= 6 ? serverData : null) ??
              (localData.length >= 6 ? localData : null);

          transactionId ??= (p.purchaseID ?? '').trim();

          // son fallback: stabil üret (random yok)
          if ((transactionId ?? '').isEmpty) {
            final dt = (p.transactionDate ?? DateTime.now().millisecondsSinceEpoch.toString()).trim();
            transactionId = "TXN-${p.productID}-$dt";
          }

          if ((purchaseToken ?? '').trim().length < 6) {
            throw Exception("Android purchaseToken alınamadı.");
          }
          if ((transactionId ?? '').trim().length < 3) {
            throw Exception("Android transactionId alınamadı.");
          }
        }

        // -------------------------
        // IOS (App Store)
        // -------------------------
        else {
          final serverData = (p.verificationData.serverVerificationData).trim();
          final localData = (p.verificationData.localVerificationData).trim();

          receiptData = (serverData.length >= 20) ? serverData : localData;

          transactionId = (p.purchaseID ?? '').trim();
          if (transactionId.isEmpty) {
            transactionId = "IOS-${DateTime.now().millisecondsSinceEpoch}";
          }

          if ((receiptData ?? '').trim().length < 20) {
            throw Exception("iOS receiptData alınamadı.");
          }
        }

        // ✅ Backend verify
        final res = await PurchaseApi.verify(
          deviceId: deviceId,
          paymentId: _activePaymentId!,
          sku: _activeSku!,
          platform: platform,
          transactionId: transactionId!,
          purchaseToken: purchaseToken,
          receiptData: receiptData,
        );

        if (!res.verified) {
          _fail("Backend verify başarısız: ${res.status}");
          return;
        }

        // ✅ completePurchase
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
