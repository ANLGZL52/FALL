import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

import 'tarot_models.dart';
import 'tarot_select_screen.dart';

class TarotSpreadSelectScreen extends StatefulWidget {
  final String question;
  const TarotSpreadSelectScreen({super.key, required this.question});

  @override
  State<TarotSpreadSelectScreen> createState() => _TarotSpreadSelectScreenState();
}

class _TarotSpreadSelectScreenState extends State<TarotSpreadSelectScreen> {
  TarotSpreadType _type = TarotSpreadType.three;

  void _goSelect() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TarotSelectScreen(
          question: widget.question,
          spreadType: _type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.72,
      patternOpacity: 0.22,
      appBar: AppBar(title: const Text('Açılım Seç')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GlassCard(
              child: Text(
                'Soru: ${widget.question}\n\n'
                'Açılım türünü seç. Kart sayısı buna göre kilitlenecek.',
                style: const TextStyle(height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Açılım', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _chip(TarotSpreadType.three),
                      _chip(TarotSpreadType.six),
                      _chip(TarotSpreadType.twelve),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Pozisyonlar:\n- ${_type.positionsTr.join("\n- ")}',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(text: 'Kartlara Geç', onPressed: _goSelect),
          ],
        ),
      ),
    );
  }

  Widget _chip(TarotSpreadType t) {
    final active = _type == t;
    return InkWell(
      onTap: () => setState(() => _type = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? Colors.amber.withOpacity(0.8) : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? Icons.check_circle : Icons.circle_outlined, size: 18, color: active ? Colors.amber : Colors.white54),
            const SizedBox(width: 8),
            Text(t.label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
