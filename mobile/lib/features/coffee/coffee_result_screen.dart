// lib/features/coffee/coffee_result_screen.dart
import 'package:flutter/material.dart';

import '../../models/coffee_reading.dart';
import '../../services/coffee_api.dart';

class CoffeeResultScreen extends StatefulWidget {
  final CoffeeReading reading;
  const CoffeeResultScreen({super.key, required this.reading});

  @override
  State<CoffeeResultScreen> createState() => _CoffeeResultScreenState();
}

class _CoffeeResultScreenState extends State<CoffeeResultScreen> {
  bool _sending = false;

  Future<void> _send(bool liked) async {
    setState(() => _sending = true);
    try {
      final rating = liked ? 5 : 2;
      await CoffeeApi.rate(readingId: widget.reading.id, rating: rating);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            liked ? 'Memnun olmana sevindim ✨' : 'Not ettim. Bir dahaki daha iyi olacak.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geri bildirim hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.reading.status;
    final isRejected = status == 'rejected';

    final title = isRejected ? 'Foto Uygun Değil' : 'Fal Sonucu';
    final comment = widget.reading.comment ?? 'Yorum bulunamadı.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isRejected ? _buildRejected(context, comment) : _buildReady(context, comment),
      ),
    );
  }

  Widget _buildRejected(BuildContext context, String comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(comment),
        const SizedBox(height: 12),
        Text(
          'Lütfen sadece kahve falına ait fotoğraflar yükle:\n'
          '• fincan içi (telve görünsün)\n'
          '• tabak (akmış telve)\n'
          '• üstten yakın plan\n'
          '3–5 foto olmalı.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.75)),
        ),
        const Spacer(),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Yeni Foto ile Tekrar Dene'),
          ),
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context, String comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(comment),
        const Spacer(),
        const Text(
          'Bu faldan memnun kaldın mı?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (_sending)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _send(true),
                  child: const Text('Evet'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _send(false),
                  child: const Text('Hayır'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _card(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
    );
  }
}
