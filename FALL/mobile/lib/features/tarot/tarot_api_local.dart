import 'dart:async';

import 'tarot_models.dart';

class TarotApiLocal {
  static Future<String> generateMockReading({
    required String question,
    required TarotSpreadType spreadType,
    required List<TarotCard> selected,
  }) async {
    await Future.delayed(const Duration(milliseconds: 650));

    final positions = spreadType.positionsTr;

    final lines = <String>[];
    lines.add('Soru: $question');
    lines.add('');
    lines.add('Açılım: ${spreadType.label}');
    lines.add('');
    lines.add('Seçilen Kartlar');
    lines.add('');

    for (int i = 0; i < selected.length; i++) {
      final c = selected[i];
      final pos = positions[i];
      lines.add('${i + 1}) $pos → ${c.nameTr} (${c.nameEn})'
          '${c.isReversed ? " (Ters)" : ""}');
      lines.add('   • ${c.shortMeaningTr}');
      lines.add('   • Anahtarlar: ${c.keywordsTr.take(3).join(", ")}');
      lines.add('');
    }

    return lines.join('\n');
  }
}
