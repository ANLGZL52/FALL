import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/tarot_api.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mystic_scaffold.dart';

import 'tarot_payment_screen.dart';
import 'widgets/tarot_card_tile.dart';
import 'tarot_deck.dart';
import 'tarot_models.dart';

class TarotSelectScreen extends StatefulWidget {
  final String readingId;
  final String question;
  final TarotSpreadType spreadType;

  const TarotSelectScreen({
    super.key,
    required this.readingId,
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
  bool _loading = false;

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

  Future<void> _saveAndGoPayment() async {
    if (_picked.length != _need || !_revealed) return;

    setState(() => _loading = true);
    try {
      // backend’e: "<id>|R" veya "<id>|U"
      final cards = _picked.map((c) {
        final revFlag = c.isReversed ? "R" : "U";
        return "${c.id}|$revFlag";
      }).toList();

      await TarotApi.selectCards(readingId: widget.readingId, cards: cards);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TarotPaymentScreen(
            readingId: widget.readingId,
            question: widget.question,
            spreadType: widget.spreadType,
            selectedCards: _picked,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

    return MysticScaffold(
      scrimOpacity: 0.78,
      patternOpacity: 0.18,
      appBar: AppBar(
        title: Text(widget.spreadType.label),
        actions: [
          IconButton(onPressed: _loading ? null : _reset, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              child: Text(
                "Soru: ${widget.question}\n"
                "Seçim: ${widget.spreadType.label}\n"
                "Kart seç: ${_picked.length} / $_need\n"
                "readingId: ${widget.readingId}",
                style: const TextStyle(height: 1.25),
              ),
            ),

            // kırmızı alan yukarı gelsin
            const SizedBox(height: 8),

            /// ✅ SLOT ALANI:
            /// - 3 kart: yine yan yana sığar
            /// - 6/12 kart: yatay scroll + daha kısa yükseklik
            /// - overflow: Expanded + buffer
            LayoutBuilder(
              builder: (context, c) {
                const gap = 10.0;
                const cardAspect = 0.70;

                // Kartları küçük tutuyoruz (6/12’de daha da küçülür)
                final double maxSlotW = (_need <= 3)
                    ? 150.0
                    : (_need <= 6)
                        ? 96.0
                        : 82.0;

                // ✅ slotW: ekrana göre akıllı
                final double idealW =
                    (c.maxWidth - gap * (_need - 1)) / _need; // hepsi sığarsa bu
                final double slotW = math.max(
                  64.0,
                  math.min(maxSlotW, idealW.isFinite ? idealW : maxSlotW),
                );

                final double cardH = slotW / cardAspect;

                // ✅ OVERFLOW FIX: başlık + boşluk + kart + buffer
                const headerH = 24.0;
                const vGap = 8.0;
                const extraBuffer = 56.0; // 40px taşmayı da rahat yutar

                final slotAreaH = headerH + vGap + cardH + extraBuffer;

                return SizedBox(
                  height: slotAreaH,
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: headerH,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Seçilen Kartlar",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(height: vGap),

                          // ✅ Column taşmasın diye Expanded
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _need,
                                separatorBuilder: (_, __) => const SizedBox(width: gap),
                                itemBuilder: (context, i) {
                                  final hasCard = i < _picked.length;
                                  final card = hasCard ? _picked[i] : null;

                                  return SizedBox(
                                    width: slotW,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: TarotCardTile(
                                            width: slotW,
                                            height: cardH,
                                            card: card,
                                            faceUp: _revealed && hasCard,
                                            disabled: true,
                                            selected: hasCard,
                                            badgeLabel: "${i + 1}",
                                          ),
                                        ),

                                        // Pozisyon etiketi
                                        Positioned(
                                          left: 8,
                                          right: 8,
                                          bottom: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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

            // deste yukarı
            const SizedBox(height: 8),

            /// ✅ DESTE ALANI: daha geniş ve yüksek alan (kırmızı)
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

                            final canPick = !_revealed && _picked.length < _need && !_loading;

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
                    onPressed: (_picked.length == _need && !_revealed && !_loading) ? _reveal : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(
                    text: _loading ? "Kaydediliyor..." : "Devam",
                    onPressed: (_picked.length == _need && _revealed && !_loading) ? _saveAndGoPayment : null,
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
