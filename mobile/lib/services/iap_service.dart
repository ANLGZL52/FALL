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

  // Purchased geldi ama verify/network anlık sapıttıysa retry etmek için
  PurchaseDetails? _lastPurchasedForActiveFlow;

  static const Duration _defaultTimeout = Duration(minutes: 2);

  bool get _hasActiveFlow => _verifyCompleter != null;

  Future<void> _ensureListener(String deviceId) async {
    _sub ??= _iap.purchaseStream.listen(
      (purchases) async {
        for (final p in purchases) {
          try {
            await _handlePurchaseUpdate(deviceId, p);
          } catch (_) {
            // stream içinde patlamasın
          }
        }
      },
      onError: (e) {
        if (_hasActiveFlow) _fail("purchaseStream error: $e");
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

    // 0) Listener (önce bağla ki missed event olmasın)
    _verifyCompleter = Completer<PaymentVerifyResult>();
    await _ensureListener(deviceId);

    // 0.1) ANDROID: eski purchase kuyruğu varsa temizlemek satın alma akışını stabil yapar
    if (Platform.isAndroid) {
      await _drainAndroidPendingPurchases();
    }

    // 1) Intent
    final intent = await PurchaseApi.createIntent(
      deviceId: deviceId,
      readingId: readingId,
      sku: sku,
    );

    _activePaymentId = intent.paymentId;
    _activeSku = sku;
    _lastPurchasedForActiveFlow = null;

    // 2) Buy (consumable) -> autoConsume FALSE (kontrol bizde)
    final products = await loadProducts({sku});
    final pd = products[sku];
    if (pd == null) {
      _fail("SKU store’da bulunamadı: $sku");
      throw Exception("SKU store’da bulunamadı: $sku");
    }

    final ok = await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: pd),
      autoConsume: false,
    );

    if (!ok) {
      _fail("Satın alma başlatılamadı (buyConsumable false).");
      throw Exception("Satın alma başlatılamadı.");
    }

    // 3) Wait with timeout
    return await _verifyCompleter!.future.timeout(
      timeout,
      onTimeout: () {
        _fail("Ödeme zaman aşımına uğradı. (pending/verify çok uzun sürdü)");
        throw Exception("Ödeme zaman aşımı.");
      },
    );
  }

  /// ✅ Stream’den gelen her purchase’ı yönet:
  /// - Aktif flow SKU’su değilse bile: pendingCompletePurchase ise complete et (queue temizliği)
  /// - Android consumable ise token varsa consume et (özellikle debug/testte şart)
  Future<void> _handlePurchaseUpdate(String deviceId, PurchaseDetails p) async {
    final isActive = _activeSku != null && _activePaymentId != null && _verifyCompleter != null;
    final isForActiveSku = isActive && (p.productID == _activeSku);

    // PENDING: aktif akış SKU’su ise bekle, değilse dokunma
    if (p.status == PurchaseStatus.pending) return;

    // Active değilse: sadece kuyruğu temizle (complete + consume)
    if (!isActive || !isForActiveSku) {
      await _finalizeIfNeeded(p);
      return;
    }

    // CANCELLED/ERROR: flow biter
    if (p.status == PurchaseStatus.canceled) {
      _fail("Satın alma iptal edildi.");
      return;
    }
    if (p.status == PurchaseStatus.error) {
      _fail("Satın alma hatası: ${p.error}");
      return;
    }

    // PURCHASED/RESTORED
    if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
      _lastPurchasedForActiveFlow = p;

      try {
        final res = await _verifyWithRetries(deviceId, p);

        if (!res.verified) {
          _fail("Backend verify başarısız: ${res.status}");
          return;
        }

        // ✅ verify OK -> önce acknowledge/complete
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }

        // ✅ Android: sonra consume
        if (Platform.isAndroid) {
          await _consumeAndroidIfNeeded(p);
        }

        _success(res);
      } catch (e) {
        // verify exception -> cleanup + kullanıcı tekrar denesin
        _fail("Verify exception: $e");
      }
    }
  }

  Future<PaymentVerifyResult> _verifyWithRetries(String deviceId, PurchaseDetails p) async {
    const maxTry = 4;
    const baseDelayMs = 650;

    Object? lastErr;

    for (var i = 1; i <= maxTry; i++) {
      try {
        final platform = Platform.isIOS ? "app_store" : "google_play";

        String? transactionId;
        String? purchaseToken;
        String? receiptData;

        if (platform == "google_play") {
          if (p is GooglePlayPurchaseDetails) {
            final orderId = (p.billingClientPurchase.orderId ?? '').trim();
            final token = (p.billingClientPurchase.purchaseToken ?? '').trim();
            final purchaseTime = p.billingClientPurchase.purchaseTime ?? 0;

            if (token.isNotEmpty) purchaseToken = token;

            if (orderId.isNotEmpty) {
              transactionId = orderId;
            } else if (token.isNotEmpty) {
              final head = token.substring(0, token.length >= 16 ? 16 : token.length);
              transactionId = "GP-$head-$purchaseTime";
            }
          }

          final localData = (p.verificationData.localVerificationData).trim();
          final serverData = (p.verificationData.serverVerificationData).trim();

          purchaseToken ??= _extractAndroidPurchaseToken(localData) ??
              _extractAndroidPurchaseToken(serverData) ??
              (serverData.length >= 6 ? serverData : null) ??
              (localData.length >= 6 ? localData : null);

          transactionId ??= (p.purchaseID ?? '').trim();

          if ((transactionId ?? '').isEmpty) {
            final dt = (p.transactionDate ?? DateTime.now().millisecondsSinceEpoch.toString()).trim();
            transactionId = "TXN-${p.productID}-$dt";
          }

          if ((purchaseToken ?? '').trim().length < 6) throw Exception("Android purchaseToken alınamadı.");
          if ((transactionId ?? '').trim().length < 3) throw Exception("Android transactionId alınamadı.");
        } else {
          final serverData = (p.verificationData.serverVerificationData).trim();
          final localData = (p.verificationData.localVerificationData).trim();

          receiptData = (serverData.length >= 20) ? serverData : localData;

          transactionId = (p.purchaseID ?? '').trim();
          if (transactionId.isEmpty) transactionId = "IOS-${DateTime.now().millisecondsSinceEpoch}";

          if ((receiptData ?? '').trim().length < 20) throw Exception("iOS receiptData alınamadı.");
        }

        return await PurchaseApi.verify(
          deviceId: deviceId,
          paymentId: _activePaymentId!,
          sku: _activeSku!,
          platform: platform,
          transactionId: transactionId!,
          purchaseToken: purchaseToken,
          receiptData: receiptData,
        );
      } catch (e) {
        lastErr = e;
        if (i < maxTry) {
          await Future.delayed(Duration(milliseconds: baseDelayMs * i));
          continue;
        }
      }
    }

    throw Exception(lastErr ?? "Verify failed");
  }

  Future<void> _finalizeIfNeeded(PurchaseDetails p) async {
    // Active flow değilken gelen purchase’ları temizle
    try {
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    } catch (_) {}

    if (Platform.isAndroid) {
      await _consumeAndroidIfNeeded(p);
    }
  }

  Future<void> _consumeAndroidIfNeeded(PurchaseDetails p) async {
    try {
      if (p is GooglePlayPurchaseDetails) {
        final token = (p.billingClientPurchase.purchaseToken ?? '').trim();
        if (token.isEmpty) return;

        final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await addition.consumePurchase(p);
      }
    } catch (_) {
      // consume başarısız olsa bile genelde akış yürür.
      // tekrar deliver ederse backend duplicate korur.
    }
  }

  /// ✅ Android’de satın alma öncesi “kuyruk temizliği”
  /// Çok sık karşılaşılan: testte/önceki denemede kalan purchase yüzünden aynı sku tekrar tekrar deliver olur.
  Future<void> _drainAndroidPendingPurchases() async {
    try {
      // in_app_purchase paketinde doğrudan “query purchases” yok.
      // Bu yüzden pratik çözüm: stream üzerinden gelenleri finalize ediyoruz (yukarıdaki finalize).
      // Burada ekstra bir şey yapmıyoruz; sadece future-proof bir hook.
      return;
    } catch (_) {}
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
    _lastPurchasedForActiveFlow = null;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
