import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

import 'tarot_spread_select_screen.dart';

class TarotIntroScreen extends StatefulWidget {
  const TarotIntroScreen({super.key});

  @override
  State<TarotIntroScreen> createState() => _TarotIntroScreenState();
}

class _TarotIntroScreenState extends State<TarotIntroScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TarotSpreadSelectScreen(question: q),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.70,
      patternOpacity: 0.22,
      appBar: AppBar(title: const Text('Tarot')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const GlassCard(
              child: Text(
                'Tarot Açılımı\n\n'
                '• Niyetini / sorunu net bir cümleyle yaz.\n'
                '• Açılım türünü seç (3 / 6 / 12 kart).\n'
                '• Kartlar kapalı gelir; dokunarak kartları açarsın.\n'
                '• Açılan kartlar arasından, açılımın istediği sayıda kartı seçersin.\n\n'
                'Not: Ne kadar net bir soru, o kadar isabetli bir yorum.',
                style: TextStyle(height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sorun',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Örn: İlişkim nereye gidiyor? / Kariyerde karar aşaması / Maddi plan…',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.25),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              text: 'Devam Et',
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}
