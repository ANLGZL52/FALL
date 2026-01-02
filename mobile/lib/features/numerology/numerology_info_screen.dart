import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';
import '../../core/app_colors.dart';

import 'numerology_form_screen.dart';

class NumerologyInfoScreen extends StatelessWidget {
  const NumerologyInfoScreen({super.key});

  void _goForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NumerologyFormScreen()),
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

            const SizedBox(height: 16),

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
                    const Text(
                      "3 adım:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "1) Bilgileri gir\n2) Ödeme\n3) AI yorumu",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Not: Şimdilik ödeme 'mock' çalışıyor, butona basınca ödeme yapılmış sayıp AI üretimi başlatıyoruz.",
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.95),
                        fontSize: 12,
                        height: 1.35,
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
