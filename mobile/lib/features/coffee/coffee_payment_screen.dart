import 'package:flutter/material.dart';

import '../../services/coffee_api.dart';
import '../../services/payment_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';
import 'coffee_loading_screen.dart';

class CoffeePaymentScreen extends StatefulWidget {
  final String readingId;
  const CoffeePaymentScreen({super.key, required this.readingId});

  @override
  State<CoffeePaymentScreen> createState() => _CoffeePaymentScreenState();
}

class _CoffeePaymentScreenState extends State<CoffeePaymentScreen> {
  bool _loading = false;
  String? _lastPaymentId;

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final res = await PaymentApi.startPayment(readingId: widget.readingId, amount: 50.0);

      if (!res.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme başarısız: ${res.provider}')),
        );
        return;
      }

      _lastPaymentId = res.paymentId;

      await CoffeeApi.markPaid(readingId: widget.readingId, paymentRef: res.paymentId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CoffeeLoadingScreen(readingId: widget.readingId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ödeme hatası: $e')));
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
                  Text('Kahve Falı Paketi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(height: 10),
                  Text('• Foto analiz (3-5 foto)\n• Falcı üslubuyla detaylı yorum\n• 7-14 gün yakın gelecek\n• Sembol sözlüğü'),
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
              text: _loading ? 'İşleniyor...' : 'Ödemeyi Başlat',
              onPressed: _loading ? null : _pay,
            ),

            const SizedBox(height: 10),
            Text(
              'Şu an mock ödeme kullanıyoruz. (Stripe/Iyzico entegre edince Checkout açılacak.)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
