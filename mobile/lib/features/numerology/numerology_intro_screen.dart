import 'package:flutter/material.dart';

import 'package:lunaura/widgets/mystic_scaffold.dart';
import 'package:lunaura/features/numerology/numerology_form_screen.dart';

class NumerologyIntroScreen extends StatelessWidget {
  const NumerologyIntroScreen({super.key});

  void _goForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NumerologyFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.62,
      patternOpacity: 0.22,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Text(
                  "Numeroloji",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Numeroloji; doğum tarihin ve isminin sayı dilini kullanarak\n"
                      "karakter çekirdeğini, tekrar eden yaşam temalarını ve dönemsel\n"
                      "enerjilerini yorumlayan kadim bir analiz yöntemidir.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Kısa bir bilgi girişiyle; ilişki, kariyer, para ve karar süreçlerinde "
                      "sana en çok çalışan kalıpları görürsün. Çıktı; genel geçer cümleler değil, "
                      "uygulanabilir önerilerle dolu detaylı bir analizdir.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C361),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _goForm(context),
                  child: const Text(
                    "Başla",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
