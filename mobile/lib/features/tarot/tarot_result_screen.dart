import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
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

  void _goHome(BuildContext context) {
    // ✅ kesin home (stack temiz)
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final positions = spreadType.positionsTr;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _goHome(context);
      },
      child: MysticScaffold(
        scrimOpacity: 0.72,
        patternOpacity: 0.18,
        appBar: AppBar(
          title: Text(spreadType.title),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    GlassCard(
                      child: Text(
                        'Sorun: $question\n\n'
                        'Açılım: ${spreadType.label}',
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// ✅ Kartlar: okunabilir olsun diye açılır-kapanır
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seçilen Kartlar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          ...selectedCards.asMap().entries.map((e) {
                            final i = e.key;
                            final c = e.value;

                            // ✅ crash-proof
                            final pos = (i < positions.length)
                                ? positions[i]
                                : 'Pozisyon ${i + 1}';

                            final rev = c.isReversed ? ' (ters)' : '';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  collapsedIconColor: Colors.white70,
                                  iconColor: Colors.white70,
                                  title: Text(
                                    '${i + 1}) $pos → ${c.nameTr}$rev',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${c.nameEn}',
                                    style: TextStyle(color: Colors.white.withOpacity(0.70)),
                                  ),
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          '• ${c.shortMeaningTr}\n'
                                          '• Anahtarlar: ${c.keywordsTr.take(3).join(", ")}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.88),
                                            height: 1.28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                          const Text(
                            'Yorum',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
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
              const SizedBox(height: 12),
              GradientButton(
                text: 'Ana Sayfaya Dön',
                onPressed: () => _goHome(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
