import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/coffee_api.dart';
import '../../services/payment_api.dart';
import '../../services/device_id_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';
import 'coffee_loading_screen.dart';

class CoffeePaymentScreen extends StatefulWidget {
  final String readingId;

  const CoffeePaymentScreen({
    super.key,
    required this.readingId,
  });

  @override
  State<CoffeePaymentScreen> createState() => _CoffeePaymentScreenState();
}

class _CoffeePaymentScreenState extends State<CoffeePaymentScreen> {
  bool _loading = false;

  static const String _coffeeSku = "fall_coffee_49";
  static const double _coffeePrice = 49.0;

  Future<void> _goNext() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CoffeeLoadingScreen(readingId: widget.readingId),
      ),
    );
  }

  Future<void> _payLegacyMock() async {
    // ✅ Mevcut sistem (BOZULMASIN): payments/start -> coffee/mark-paid
    final res = await PaymentApi.startPayment(
      readingId: widget.readingId,
      amount: _coffeePrice, // ✅ fiyatı 49'a çektik (planınla uyumlu)
      product: "coffee",
    );

    if (!res.ok) {
      throw Exception('Ödeme başlatılamadı.');
    }

    await CoffeeApi.markPaid(
      readingId: widget.readingId,
      paymentRef: res.paymentId, // TEST-... geliyor
    );

    await _goNext();
  }

  Future<void> _payStoreFlow() async {
    // ✅ Yeni akış: intent -> (IAP) -> verify (server-side paid unlock)
    final deviceId = await DeviceIdService.getOrCreate();

    final intent = await PurchaseApi.createIntent(
      deviceId: deviceId,
      readingId: widget.readingId,
      sku: _coffeeSku,
    );

    // 🔥 Şu an gerçek store purchase yok.
    // Debug modda backend verify’ı test etmek için dummy token/transaction kullanıyoruz.
    // Release’te (store’a çıkarken) bunu IAP’den gelen gerçek token ile değiştireceğiz.
    final bool useMockPurchase = !kReleaseMode;

    String? purchaseToken;
    String? receiptData;
    final String platform = defaultTargetPlatform == TargetPlatform.iOS ? "app_store" : "google_play";

    final String transactionId = useMockPurchase
        ? "TXN-DEV-${DateTime.now().millisecondsSinceEpoch}"
        : "TXN-REAL"; // TODO: IAP’den al

    if (useMockPurchase) {
      if (platform == "google_play") {
        purchaseToken = "DEV_TOKEN_123456"; // ✅ backend stub: min 6 char
      } else {
        receiptData = "DEV_RECEIPT_DATA_ABCDEFGHIJKLMNOPQRSTUVWXYZ"; // ✅ backend stub: min 20 char
      }
    } else {
      // TODO (store): in_app_purchase ile gerçek satın alma yap
      // - Google: purchaseToken al
      // - iOS: receipt/base64 al
      throw Exception("Store satın alma entegrasyonu (IAP) henüz bağlanmadı. Debug modda test edebilirsin.");
    }

    final verify = await PurchaseApi.verify(
      deviceId: deviceId,
      paymentId: intent.paymentId,
      sku: _coffeeSku,
      platform: platform,
      transactionId: transactionId,
      purchaseToken: purchaseToken,
      receiptData: receiptData,
    );

    if (!verify.verified) {
      throw Exception("Ödeme doğrulanamadı: ${verify.status}");
    }

    // ✅ verify sonrası backend ilgili reading’i server-side paid yaptı.
    // coffee/mark-paid çağırmıyoruz.
    await _goNext();
  }

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      // ✅ Şu an sistemi bozmamak için:
      // - debug’da: legacy çalışsın (mevcut akış)
      // - istersen debug’da store flow test etmek için alttaki flag’i true yap.
      const bool debugTestStoreFlow = false;

      if (!kReleaseMode && debugTestStoreFlow) {
        await _payStoreFlow();
      } else {
        await _payLegacyMock();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.84,
      patternOpacity: 0.16,
      appBar: AppBar(
        title: const Text('Ödeme'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Kahve Falı',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Fincanında kalan izler, sana özel bir hikâye anlatıyor.\n'
                          'Şimdi bu hikâyeyi birlikte yorumlayalım.',
                          style: TextStyle(height: 1.4),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Tutar: 49₺',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientButton(
                text: _loading ? 'İşleniyor...' : 'Falımı Başlat ✨',
                onPressed: _loading ? null : _pay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
