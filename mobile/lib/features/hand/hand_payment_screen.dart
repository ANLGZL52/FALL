import 'package:flutter/material.dart';

import '../../services/payment_api.dart';
import '../../services/hand_api.dart';
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

  Future<void> _payAndGenerate() async {
    setState(() => _loading = true);
    try {
      // 1) Payment start (mock)
      final res = await PaymentApi.startPayment(
        readingId: widget.readingId,
        product: "hand",
        // amount: 149.0, // istersen gönder, göndermesen de backend default veriyor
      );

      if (!res.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme başarısız: ${res.provider}')),
        );
        return;
      }

      // 2) Mark paid
      await HandApi.markPaid(readingId: widget.readingId, paymentRef: res.paymentId);

      // 3) Generate
      final reading = await HandApi.generate(readingId: widget.readingId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HandResultScreen(readingId: reading.id)),
      );
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
                  Text('El Falı Paketi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 10),
                  Text(
                    'Ödeme tamamlandıktan sonra el fotoğrafların analiz edilerek falın hazırlanacak.\n\n'
                    'Not: El dışında görsel yüklenirse sistem zaten ödeme adımına geçirmez.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              text: _loading ? 'İşleniyor...' : 'Ödemeyi Tamamla & Yorumu Al',
              onPressed: _loading ? null : _payAndGenerate,
            ),
          ],
        ),
      ),
    );
  }
}
