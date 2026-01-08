import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../services/tarot_api.dart';
import 'tarot_payment_screen.dart';
import 'tarot_models.dart';

class TarotDeckScreen extends StatefulWidget {
  final String readingId;
  final String spreadType;
  final int cardsWanted;

  const TarotDeckScreen({
    super.key,
    required this.readingId,
    required this.spreadType,
    required this.cardsWanted,
  });

  @override
  State<TarotDeckScreen> createState() => _TarotDeckScreenState();
}

class _TarotDeckScreenState extends State<TarotDeckScreen> {
  bool _loading = false;

  final List<String> _deck = const [
    "the_fool", "the_magician", "the_high_priestess", "the_empress", "the_emperor",
    "the_hierophant", "the_lovers", "the_chariot", "strength", "the_hermit",
    "wheel_of_fortune", "justice", "the_hanged_man", "death", "temperance",
    "the_devil", "the_tower", "the_star", "the_moon", "the_sun",
    "judgement", "the_world",
  ];

  final Set<int> _selectedIndexes = {};

  Future<void> _saveAndContinue() async {
    setState(() => _loading = true);
    try {
      final cards = _selectedIndexes.map((i) => _deck[i]).toList();
      await TarotApi.selectCards(readingId: widget.readingId, cards: cards);

      if (!mounted) return;

      // ⚠️ Legacy ekran: question/spreadType/selectedCards yoktu.
      // Kırılmasın diye minimal dolduruyoruz.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TarotPaymentScreen(
            readingId: widget.readingId,
            question: "Tarot",
            spreadType: TarotSpreadType.three,
            selectedCards: const [],
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

  void _toggle(int idx) {
    if (_selectedIndexes.contains(idx)) {
      setState(() => _selectedIndexes.remove(idx));
      return;
    }
    if (_selectedIndexes.length >= widget.cardsWanted) return;
    setState(() => _selectedIndexes.add(idx));
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedIndexes.length == widget.cardsWanted;

    return MysticScaffold(
      scrimOpacity: 0.86,
      patternOpacity: 0.14,
      appBar: AppBar(title: const Text('Tarot – Kart Seç')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              child: Text(
                '${widget.cardsWanted} kart seç.',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                itemCount: _deck.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, i) {
                  final selected = _selectedIndexes.contains(i);
                  return GestureDetector(
                    onTap: () => _toggle(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.white.withOpacity(0.25),
                          width: selected ? 2.0 : 1.0,
                        ),
                        color: Colors.white.withOpacity(selected ? 0.10 : 0.06),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.style,
                              size: 46,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          if (selected)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              text: _loading ? 'Kaydediliyor...' : 'Devam',
              onPressed: (!canContinue || _loading) ? null : _saveAndContinue,
            ),
          ],
        ),
      ),
    );
  }
}
