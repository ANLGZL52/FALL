import 'package:flutter/material.dart';

import 'package:fall_app/widgets/mystic_scaffold.dart';
import 'package:fall_app/features/numerology/numerology_info_screen.dart';

class NumerologyIntroScreen extends StatelessWidget {
  const NumerologyIntroScreen({super.key});

  void _goInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NumerologyInfoScreen()),
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
                      "Numeroloji ile yaşam sayın, kader temaların\nve dönem enerjilerin analiz edilir.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "3 adım:\n1) Bilgileri gir\n2) Ödeme\n3) AI yorumu",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
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
                  onPressed: () => _goInfo(context),
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
