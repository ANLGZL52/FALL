// lib/features/coffee/coffee_payment_screen.dart
import 'package:flutter/material.dart';

import '../../services/payment_api.dart';
import '../../services/coffee_api.dart';
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
      // 1) ödeme başlat (mock)
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

      // 2) backend'e ödeme ref gönder
      await CoffeeApi.markPaid(
        readingId: widget.readingId,
        paymentRef: res.paymentId,
      );

      if (!mounted) return;

      // 3) yorum üretme ekranı
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CoffeeLoadingScreen(readingId: widget.readingId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentInfo = _lastPaymentId == null ? '' : 'Son işlem: $_lastPaymentId';

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kahve Falı Paketi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
                  Text('• Foto analiz (3-5 foto)\n• Falcı üslubuyla detaylı yorum\n• 7-14 gün yakın gelecek\n• Sembol sözlüğü'),
                  SizedBox(height: 10),
                  Text('Tutar: 50₺', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (paymentInfo.isNotEmpty)
              Text(paymentInfo, style: TextStyle(color: Colors.white.withOpacity(0.7))),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _pay,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Ödemeyi Başlat'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Şu an mock ödeme kullanıyoruz. (Gerçek Stripe/Iyzico entegre edince bu ekran Checkout açacak.)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
