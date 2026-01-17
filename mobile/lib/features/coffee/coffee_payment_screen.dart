import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/coffee_api.dart';
import '../../services/payment_api.dart';
import '../../services/purchase_api.dart';
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
    final res = await PaymentApi.startPayment(
      readingId: widget.readingId,
      amount: _coffeePrice,
      product: "coffee",
    );

    if (!res.ok) {
      throw Exception('Ödeme başlatılamadı.');
    }

    await CoffeeApi.markPaid(
      readingId: widget.readingId,
      paymentRef: res.paymentId,
    );

    await _goNext();
  }

  Future<void> _payStoreFlow() async {
    final deviceId = await DeviceIdService.getOrCreate();

    final intent = await PurchaseApi.createIntent(
      deviceId: deviceId,
      readingId: widget.readingId,
      sku: _coffeeSku,
    );

    final bool useMockPurchase = !kReleaseMode;

    String? purchaseToken;
    String? receiptData;
    final String platform = defaultTargetPlatform == TargetPlatform.iOS ? "app_store" : "google_play";

    final String transactionId = useMockPurchase
        ? "TXN-DEV-${DateTime.now().millisecondsSinceEpoch}"
        : "TXN-REAL";

    if (useMockPurchase) {
      if (platform == "google_play") {
        purchaseToken = "DEV_TOKEN_123456";
      } else {
        receiptData = "DEV_RECEIPT_DATA_ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      }
    } else {
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

    await _goNext();
  }

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
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
      appBar: AppBar(title: const Text('Ödeme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Kahve Falı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 10),
                  Text('Falını başlatmak için ödeme adımını tamamla.'),
                  SizedBox(height: 12),
                  Text('Tutar: 49₺', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              text: _loading ? 'İşleniyor...' : 'Ödemeyi Tamamla ✨',
              onPressed: _loading ? null : _pay,
            ),
          ],
        ),
      ),
    );
  }
}
