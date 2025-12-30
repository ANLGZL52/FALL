import 'dart:async';
import 'package:uuid/uuid.dart';

import '../features/tarot/tarot_deck.dart';
import '../features/tarot/tarot_models.dart';

class TarotApi {
  static const _uuid = Uuid();

  /// Şimdilik: “OpenAI yok” => local anlam + pozisyonlara göre mock yorum üretir.
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
    lines.add('Seçilen kartlar ve pozisyon anlamları:');
    lines.add('');

    for (int i = 0; i < selected.length; i++) {
      final c = selected[i];
      final pos = positions[i];
      lines.add('${i + 1}) $pos → ${c.nameTr} (${c.nameEn})');
      lines.add('   • ${c.shortMeaningTr}');
      lines.add('   • Anahtarlar: ${c.keywordsTr.take(3).join(", ")}');
      lines.add('');
    }

    lines.add('Not: Şu an yorum “local/mock”. Sonraki adımda backend + OpenAI ile gerçek yoruma geçeceğiz.');

    return lines.join('\n');
  }

  /// Örnek: kart id -> TarotCard (result ekranında yeniden inşa için)
  static TarotCard? findById(String id) {
    for (final c in TarotDeck.all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static String newId() => _uuid.v4();
}
