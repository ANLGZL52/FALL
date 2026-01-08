import 'package:flutter/material.dart';

import '../../services/payment_api.dart';
import '../../services/tarot_api.dart';
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

  double get _amount {
    switch (widget.spreadType) {
      case TarotSpreadType.three:
        return 49.9;
      case TarotSpreadType.six:
        return 79.9;
      case TarotSpreadType.twelve:
        return 119.9;
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

  Future<void> _payAndGenerate() async {
    setState(() => _loading = true);

    try {
      // ✅ ödeme başlat (artık backend 'tarot' kabul ediyor)
      final res = await PaymentApi.startPayment(
        readingId: widget.readingId,
        amount: _amount,
        product: "tarot",
      );

      if (!res.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme başarısız: ${res.provider}')),
        );
        return;
      }

      _lastPaymentId = res.paymentId;

      // ✅ backend’e ödeme onayı
      await TarotApi.markPaid(
        readingId: widget.readingId,
        paymentRef: res.paymentId,
      );

      // ✅ yorum üret
      final gen = await TarotApi.generate(readingId: widget.readingId);
      final resultText = (gen["result_text"] ?? "").toString();

      if (resultText.trim().isEmpty) {
        throw Exception("Yorum oluşturulamadı.");
      }

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
            // ✅ taşma olmasın diye içerik scroll
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
                          "Tutar: ${_amount.toStringAsFixed(1)} ₺",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
