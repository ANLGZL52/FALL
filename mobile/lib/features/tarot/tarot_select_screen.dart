import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../widgets/gradient_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mystic_scaffold.dart';

import 'widgets/tarot_card_tile.dart';

import 'tarot_deck.dart';
import 'tarot_models.dart';
import 'tarot_result_screen.dart';

class TarotSelectScreen extends StatefulWidget {
  final String question;
  final TarotSpreadType spreadType;

  const TarotSelectScreen({
    super.key,
    required this.question,
    required this.spreadType,
  });

  @override
  State<TarotSelectScreen> createState() => _TarotSelectScreenState();
}

class _TarotSelectScreenState extends State<TarotSelectScreen> {
  late List<TarotCard> _pool;
  final List<TarotCard> _picked = [];
  bool _revealed = false;

  int get _need => widget.spreadType.count;

  @override
  void initState() {
    super.initState();
    _pool = TarotDeck.shuffled();
  }

  void _pickFromPool(TarotCard c) {
    if (_revealed) return;
    if (_picked.length >= _need) return;

    setState(() {
      _picked.add(c);
      _pool.removeWhere((x) => x.id == c.id);
    });
  }

  void _reset() {
    setState(() {
      _pool = TarotDeck.shuffled();
      _picked.clear();
      _revealed = false;
    });
  }

  void _reveal() {
    if (_picked.length != _need) return;
    setState(() => _revealed = true);
  }

  void _goResult() {
    final text = _picked.map((c) => "- ${c.nameTr}: ${c.shortMeaningTr}").join("\n");

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TarotResultScreen(
          question: widget.question,
          spreadType: widget.spreadType,
          selectedCards: _picked,
          resultText:
              "Seçtiğin kartların kısa mesajı:\n\n$text\n\n(Detaylı yorum OpenAI adımında gelecek.)",
        ),
      ),
    );
  }

  ({int cols, int rows}) _slotGridForNeed(int need) {
    if (need <= 3) return (cols: 3, rows: 1);
    if (need <= 6) return (cols: 3, rows: 2);
    return (cols: 4, rows: 3); // 12
  }

  int _deckColsFor(double w) {
    if (w >= 1400) return 12;
    if (w >= 1200) return 10;
    if (w >= 950) return 8;
    if (w >= 700) return 6;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final positions = widget.spreadType.positionsTr;
    final grid = _slotGridForNeed(_need);

    return MysticScaffold(
      scrimOpacity: 0.78,
      patternOpacity: 0.18,
      appBar: AppBar(
        title: Text(widget.spreadType.label),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            tooltip: 'Sıfırla',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // üst bilgi küçük
            GlassCard(
              child: Text(
                "Soru: ${widget.question}\n"
                "Seçim: ${widget.spreadType.label}\n"
                "Kart seç: ${_picked.length} / $_need",
                style: const TextStyle(height: 1.25),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ SLOT ALANI: küçültülmüş, “deste aşağı kaçmasın”
            LayoutBuilder(
              builder: (context, c) {
                const gap = 12.0;

                // Kart oranı (Rider-Waite görselleri dikey kart)
                const cardAspect = 0.70; // width/height

                // Slot kart genişliği: çok büyümesin
                final rawW = (c.maxWidth - gap * (grid.cols - 1)) / grid.cols;
                final slotW = math.min(150.00, rawW);

                // Slot kart yüksekliği (oranla)
                final slotH = slotW / cardAspect;

                // ✅ Slot alan yüksekliği: “başlık + kart + ufak boşluk” kadar sabit.
                // 3 kart için tek satır → çok kompakt kalsın.
                final headerH = 34.0;       // "Seçilen Kartlar" yazısı + spacing
                final bottomPad = 10.0;
                final slotAreaH = headerH + slotH + bottomPad;

                return SizedBox(
                  height: slotAreaH,
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Seçilen Kartlar",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),

                          // Slotlar tek satır (need=3) / grid (need>3)
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                width: math.min(c.maxWidth, (slotW * grid.cols) + gap * (grid.cols - 1)),
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: _need,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: grid.cols,
                                    crossAxisSpacing: gap,
                                    mainAxisSpacing: gap,
                                    childAspectRatio: cardAspect,
                                  ),
                                  itemBuilder: (context, i) {
                                    final hasCard = i < _picked.length;
                                    final card = hasCard ? _picked[i] : null;

                                    return Stack(
                                      children: [
                                        Positioned.fill(
                                          child: TarotCardTile(
                                            width: slotW,
                                            height: slotH,
                                            card: card,
                                            faceUp: _revealed && hasCard,
                                            disabled: true,
                                            selected: hasCard,
                                            badgeLabel: "${i + 1}",
                                          ),
                                        ),
                                        // pozisyon etiketi (kartın üstüne bindir, yer kaplamasın)
                                        Positioned(
                                          left: 10,
                                          right: 10,
                                          bottom: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.45),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white.withOpacity(0.10)),
                                            ),
                                            child: Text(
                                              positions[i],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.85),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // ✅ DESTE: kalan alanı komple alsın (slot küçüldü → deste yukarı oturur)
            Expanded(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Deste (Kapalı Kartlar)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),

                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, dc) {
                            const gap = 12.0;
                            const cardAspect = 0.70;

                            final cols = _deckColsFor(dc.maxWidth);
                            final tileW = (dc.maxWidth - gap * (cols - 1)) / cols;
                            final tileH = tileW / cardAspect;

                            final canPick = !_revealed && _picked.length < _need;

                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: gap,
                                mainAxisSpacing: gap,
                                childAspectRatio: cardAspect,
                              ),
                              itemCount: _pool.length,
                              itemBuilder: (context, index) {
                                final card = _pool[index];
                                return TarotCardTile(
                                  width: tileW,
                                  height: tileH,
                                  card: card,
                                  faceUp: false,
                                  disabled: !canPick,
                                  onTap: canPick ? () => _pickFromPool(card) : null,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: "Kartları Çevir",
                    onPressed: (_picked.length == _need && !_revealed) ? _reveal : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(
                    text: "Devam",
                    onPressed: (_picked.length == _need && _revealed) ? _goResult : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
