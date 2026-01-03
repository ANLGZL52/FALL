// lib/features/synastry/synastry_payment_screen.dart
import 'package:flutter/material.dart';

import '../../services/synastry_api.dart';
import 'synastry_generating_screen.dart';

class SynastryPaymentScreen extends StatefulWidget {
  final String readingId;
  final String title;

  const SynastryPaymentScreen({
    super.key,
    required this.readingId,
    required this.title,
  });

  @override
  State<SynastryPaymentScreen> createState() => _SynastryPaymentScreenState();
}

class _SynastryPaymentScreenState extends State<SynastryPaymentScreen> {
  final _api = SynastryApi();
  final _paymentRef = TextEditingController(text: 'demo-payment');

  bool _loading = false;

  @override
  void dispose() {
    _paymentRef.dispose();
    super.dispose();
  }

  Future<void> _confirmPaidAndGenerate() async {
    setState(() => _loading = true);
    try {
      // 1) mark paid
      await _api.markPaid(widget.readingId, paymentRef: _paymentRef.text.trim());

      // 2) generate
      await _api.generate(widget.readingId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SynastryGeneratingScreen(readingId: widget.readingId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ödeme/Üretim hatası: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: AbsorbPointer(
        absorbing: _loading,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Demo ödeme ekranı.\nGerçekte burada Stripe/Iyzico entegre edeceğiz.',
                style: TextStyle(color: Colors.white70, height: 1.3),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _paymentRef,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'payment_ref (demo)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0B1120).withOpacity(0.75),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD6B15E)),
                  ),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6B15E),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _confirmPaidAndGenerate,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Ödedim → Analizi Başlat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
