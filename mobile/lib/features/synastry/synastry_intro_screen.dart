import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';
import 'synastry_info_screen.dart';

class SynastryIntroScreen extends StatelessWidget {
  const SynastryIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.62,
      patternOpacity: 0.22,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AppBar benzeri üst satır
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Sinastri (Aşk Uyumu)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Text(
                'İki kişinin doğum bilgilerini girip\nilişki dinamiğini derin analiz ediyoruz.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.3),
              ),
              const SizedBox(height: 16),

              _card(
                'Neleri kapsar?',
                '• Çekim ve uyum dinamikleri\n'
                '• Tetikleyiciler ve iletişim dili\n'
                '• Güven, bağlılık, alan ihtiyacı\n'
                '• Uzun vade uyumu ve öneriler\n'
                '• 14 günlük mini plan + 90 günlük yol haritası',
              ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6B15E),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SynastryInfoScreen()),
                  );
                },
                child: const Text(
                  'Başla',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _card(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}
