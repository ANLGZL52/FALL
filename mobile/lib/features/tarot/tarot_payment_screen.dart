import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/payment_api.dart';
import '../../services/tarot_api.dart';
import '../../services/device_id_service.dart';
import '../../services/iap_service.dart';
import '../../services/product_catalog.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

import 'tarot_models.dart';
import 'tarot_result_screen.dart';

class TarotPaymentScreen extends StatefulWidget {
  final String readingId;
  final String question;
  final TarotSpreadType spreadType;
  final List<TarotCard> selectedCards;

  const TarotPaymentScreen({
    super.key,
    required this.readingId,
    required this.question,
    required this.spreadType,
    required this.selectedCards,
  });

  @override
  State<TarotPaymentScreen> createState() => _TarotPaymentScreenState();
}

class _TarotPaymentScreenState extends State<TarotPaymentScreen> {
  bool _loading = false;
  String? _lastPaymentId;

  // Debug’ta store test etmek istersen true yap
  static const bool debugUseStoreIap = false;

  double get _amount {
    switch (widget.spreadType) {
      case TarotSpreadType.three:
        return 149.0;
      case TarotSpreadType.six:
        return 199.0;
      case TarotSpreadType.twelve:
        return 250.0;
    }
  }

  String get _sku {
    switch (widget.spreadType) {
      case TarotSpreadType.three:
        return ProductCatalog.tarot3_149;
      case TarotSpreadType.six:
        return ProductCatalog.tarot6_199;
      case TarotSpreadType.twelve:
        return ProductCatalog.tarot12_250;
    }
  }

  String get _packageTitle {
    switch (widget.spreadType) {
      case TarotSpreadType.three:
        return "Hızlı Açılım (3 Kart)";
      case TarotSpreadType.six:
        return "Derin Açılım (6 Kart)";
      case TarotSpreadType.twelve:
        return "Premium Açılım (12 Kart)";
    }
  }

  String get _packageSubtitle {
    switch (widget.spreadType) {
      case TarotSpreadType.three:
        return "Geçmiş–Şimdi–Yakın Gelecek ekseninde net bir okuma.";
      case TarotSpreadType.six:
        return "İlişki/iş/para odağında daha katmanlı yorum ve öneriler.";
      case TarotSpreadType.twelve:
        return "Kapsamlı tema analizi, ek mesajlar ve güçlü kapanış.";
    }
  }

  Future<void> _goResult(String resultText) async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TarotResultScreen(
          question: widget.question,
          spreadType: widget.spreadType,
          selectedCards: widget.selectedCards,
          resultText: resultText,
        ),
      ),
    );
  }

  Future<void> _payLegacyMock({required String deviceId}) async {
    final res = await PaymentApi.startPayment(
      readingId: widget.readingId,
      amount: _amount,
      product: "tarot",
      deviceId: deviceId,
    );

    if (!res.ok) throw Exception('Ödeme başarısız: ${res.provider}');
    _lastPaymentId = res.paymentId;

    await TarotApi.markPaid(
      readingId: widget.readingId,
      paymentRef: res.paymentId,
      deviceId: deviceId,
    );

    final gen = await TarotApi.generate(
      readingId: widget.readingId,
      deviceId: deviceId,
    );

    final resultText = (gen["result_text"] ?? "").toString().trim();
    if (resultText.isEmpty) throw Exception("Yorum oluşturulamadı.");

    await _goResult(resultText);
  }

  Future<void> _payStoreIap({required String deviceId}) async {
    final verify = await IapService.instance.buyAndVerify(
      readingId: widget.readingId,
      sku: _sku,
    );

    if (!verify.verified) throw Exception("Ödeme doğrulanamadı: ${verify.status}");
    _lastPaymentId = verify.paymentId;

    final gen = await TarotApi.generate(
      readingId: widget.readingId,
      deviceId: deviceId,
    );

    final resultText = (gen["result_text"] ?? "").toString().trim();
    if (resultText.isEmpty) throw Exception("Yorum oluşturulamadı.");

    await _goResult(resultText);
  }

  Future<void> _payAndGenerate() async {
    setState(() => _loading = true);
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      if (kReleaseMode) {
        await _payStoreIap(deviceId: deviceId);
      } else {
        if (debugUseStoreIap) {
          await _payStoreIap(deviceId: deviceId);
        } else {
          await _payLegacyMock(deviceId: deviceId);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme/Yorum hatası: $e')),
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _packageTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _packageSubtitle,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Bu paket şunları içerir:",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "• Kart seçimi ve pozisyonlara göre yorum\n"
                          "• Soruna özel kapsamlı analiz\n"
                          "• Sonuç ekranı + kısa değerlendirme",
                          style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Tutar: ${_amount.toStringAsFixed(0)} ₺",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        if (!kReleaseMode)
                          Text(
                            "SKU: $_sku",
                            style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_lastPaymentId != null)
                    Text(
                      'Son işlem: $_lastPaymentId',
                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              text: _loading ? 'İşleniyor...' : 'Ödemeyi Başlat ve Yorumu Gör',
              onPressed: _loading ? null : _payAndGenerate,
            ),
            const SizedBox(height: 10),
            Text(
              'Ödeme sonrası yorum oluşturulur ve sonuç ekranına yönlendirilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
