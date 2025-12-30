import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/mystic_scaffold.dart';
import 'tarot_models.dart';

class TarotResultScreen extends StatelessWidget {
  final String question;
  final TarotSpreadType spreadType;
  final List<TarotCard> selectedCards;
  final String resultText;

  const TarotResultScreen({
    super.key,
    required this.question,
    required this.spreadType,
    required this.selectedCards,
    required this.resultText,
  });

  @override
  Widget build(BuildContext context) {
    final positions = spreadType.positionsTr;

    return MysticScaffold(
      scrimOpacity: 0.72,
      patternOpacity: 0.18,
      appBar: AppBar(title: Text(spreadType.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GlassCard(
              child: Text(
                'Soru: $question\n\n'
                'Açılım: ${spreadType.label}',
                style: const TextStyle(height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seçilen Kartlar (Pozisyonlara Göre)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  ...selectedCards.asMap().entries.map((e) {
                    final i = e.key;
                    final c = e.value;
                    final pos = positions[i];
                    final rev = c.isReversed ? ' (ters)' : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${i + 1}) $pos → ${c.nameTr} (${c.nameEn})$rev\n'
                        '• ${c.shortMeaningTr}\n'
                        '• Anahtarlar: ${c.keywordsTr.take(3).join(", ")}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          height: 1.28,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yorum',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(
                    resultText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
