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

  // ✅ Result’a taşımak için
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

  Future<void> _payAndGenerate() async {
    setState(() => _loading = true);
    try {
      // ✅ mock ödeme (kahve ile aynı)
      final res = await PaymentApi.startPayment(
        readingId: widget.readingId,
        amount: 50.0,
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

      // ✅ OpenAI üretim
      final gen = await TarotApi.generate(readingId: widget.readingId);
      final resultText = (gen["result_text"] ?? "").toString();

      if (resultText.isEmpty) {
        throw Exception("OpenAI boş döndü (result_text empty)");
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ödeme/Yorum hatası: $e')));
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
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Tarot Falı Paketi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(height: 10),
                  Text('• Kart seçimi\n• Açılıma göre derin yorum\n• Sonuç ekranı\n• Puanlama'),
                  SizedBox(height: 10),
                  Text('Tutar: 50₺', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_lastPaymentId != null)
              Text('Son işlem: $_lastPaymentId', style: TextStyle(color: Colors.white.withOpacity(0.75))),

            const Spacer(),

            GradientButton(
              text: _loading ? 'İşleniyor...' : 'Ödemeyi Başlat ve Yorumu Al',
              onPressed: _loading ? null : _payAndGenerate,
            ),

            const SizedBox(height: 10),
            Text(
              'Şu an mock ödeme kullanıyoruz. (Stripe/Iyzico entegre edince gerçek Checkout açılacak.)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
