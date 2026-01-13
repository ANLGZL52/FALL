import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/payment_api.dart';
import '../../services/hand_api.dart';
import '../../services/device_id_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';
import 'hand_result_screen.dart';

class HandPaymentScreen extends StatefulWidget {
  final String readingId;
  const HandPaymentScreen({super.key, required this.readingId});

  @override
  State<HandPaymentScreen> createState() => _HandPaymentScreenState();
}

class _HandPaymentScreenState extends State<HandPaymentScreen> {
  bool _loading = false;

  static const String _handSku = "fall_hand_39";
  static const double _handPrice = 39.0;

  Future<void> _goResult(String readingId) async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HandResultScreen(readingId: readingId)),
    );
  }

  Future<void> _payLegacyMock() async {
    // 1) Payment start (mock) — bozulmasın
    final res = await PaymentApi.startPayment(
      readingId: widget.readingId,
      product: "hand",
      // amount backend set ediyor ama istersek gönderilebilir:
      // amount: _handPrice,
    );

    if (!res.ok) {
      throw Exception('Ödeme başarısız: ${res.provider}');
    }

    // 2) Mark paid (legacy)
    await HandApi.markPaid(
      readingId: widget.readingId,
      paymentRef: res.paymentId, // TEST-...
    );

    // 3) Generate
    final reading = await HandApi.generate(readingId: widget.readingId);
    await _goResult(reading.id);
  }

  Future<void> _payStoreFlow() async {
    final deviceId = await DeviceIdService.getOrCreate();

    // intent
    final intent = await PurchaseApi.createIntent(
      deviceId: deviceId,
      readingId: widget.readingId,
      sku: _handSku,
    );

    // Debug stub purchase (IAP henüz bağlanmadı)
    final bool useMockPurchase = !kReleaseMode;
    final String platform = defaultTargetPlatform == TargetPlatform.iOS ? "app_store" : "google_play";

    final String transactionId = useMockPurchase
        ? "TXN-DEV-${DateTime.now().millisecondsSinceEpoch}"
        : "TXN-REAL"; // TODO: IAP’den al

    String? purchaseToken;
    String? receiptData;

    if (useMockPurchase) {
      if (platform == "google_play") {
        purchaseToken = "DEV_TOKEN_123456";
      } else {
        receiptData = "DEV_RECEIPT_DATA_ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      }
    } else {
      throw Exception("Store satın alma entegrasyonu (IAP) henüz bağlanmadı. Debug modda test edebilirsin.");
    }

    // verify (server-side paid unlock)
    final verify = await PurchaseApi.verify(
      deviceId: deviceId,
      paymentId: intent.paymentId,
      sku: _handSku,
      platform: platform,
      transactionId: transactionId,
      purchaseToken: purchaseToken,
      receiptData: receiptData,
    );

    if (!verify.verified) {
      throw Exception("Ödeme doğrulanamadı: ${verify.status}");
    }

    // ✅ verify sonrası backend ilgili reading’i paid yaptı.
    // hand/mark-paid çağırmuyoruz.
    final reading = await HandApi.generate(readingId: widget.readingId, deviceId: deviceId);
    await _goResult(reading.id);
  }

  Future<void> _payAndGenerate() async {
    setState(() => _loading = true);
    try {
      // ✅ Şu an sistemi bozmamak için:
      // - debug’da: legacy çalışsın
      // - store flow test etmek için true yapabilirsin
      const bool debugTestStoreFlow = false;

      if (!kReleaseMode && debugTestStoreFlow) {
        await _payStoreFlow();
      } else {
        await _payLegacyMock();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.82,
      patternOpacity: 0.18,
      appBar: AppBar(title: const Text('Ödeme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'El Falı',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Avucundaki çizgiler, karakterin ve yolun hakkında küçük ipuçları taşır.\n'
                    'Şimdi bu ipuçlarını birlikte yorumlayalım.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tutar: 39₺',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              text: _loading ? 'İşleniyor...' : 'Falımı Başlat ✨',
              onPressed: _loading ? null : _payAndGenerate,
            ),
          ],
        ),
      ),
    );
  }
}
