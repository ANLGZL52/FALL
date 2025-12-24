import 'package:flutter/material.dart';

import '../../models/coffee_reading.dart';
import '../../services/coffee_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

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
        SnackBar(content: Text(liked ? 'Memnun olmana sevindim ✨' : 'Not ettim. Bir dahaki daha iyi olacak.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Geri bildirim hatası: $e')));
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

    return MysticScaffold(
      scrimOpacity: 0.86,
      patternOpacity: 0.12,
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isRejected ? _buildRejected(comment) : _buildReady(comment),
      ),
    );
  }

  Widget _buildRejected(String comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(child: Text(comment, style: const TextStyle(height: 1.5))),
        const SizedBox(height: 12),
        Text(
          'Lütfen sadece kahve falına ait fotoğraflar yükle:\n'
          '• fincan içi (telve görünsün)\n'
          '• tabak (akmış telve)\n'
          '• üstten yakın plan\n'
          '3–5 foto olmalı.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.80)),
        ),
        const Spacer(),
        GradientButton(
          text: 'Yeni Foto ile Tekrar Dene',
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    );
  }

  Widget _buildReady(String comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GlassCard(
            child: SingleChildScrollView(
              child: Text(comment, style: const TextStyle(height: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Bu faldan memnun kaldın mı?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (_sending)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(child: GradientButton(text: 'Evet', onPressed: () => _send(true))),
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
}
