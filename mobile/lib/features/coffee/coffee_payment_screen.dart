import 'package:flutter/material.dart';

import '../../services/coffee_api.dart';
import '../../services/payment_api.dart';
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

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final res = await PaymentApi.startPayment(
        readingId: widget.readingId,
        amount: 50.0,
      );

      if (!res.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme başlatılamadı. Lütfen tekrar dene.')),
        );
        return;
      }

      await CoffeeApi.markPaid(
        readingId: widget.readingId,
        paymentRef: res.paymentId,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CoffeeLoadingScreen(readingId: widget.readingId)),
      );
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
                          'Tutar: 50₺',
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
