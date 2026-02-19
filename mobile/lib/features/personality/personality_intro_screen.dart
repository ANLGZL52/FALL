import 'package:flutter/material.dart';
import 'package:lunaura/widgets/mystic_scaffold.dart';
import 'personality_form_screen.dart';

class PersonalityIntroScreen extends StatelessWidget {
  const PersonalityIntroScreen({super.key});

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
                const Expanded(
                  child: Text(
                    "Kişilik Analizi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bu analiz nasıl hazırlanır?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Doğum tarihi ve yer bilgilerini; karakter, ilişki dili, kariyer/para yaklaşımı ve "
                        "yakın dönem aksiyon önerileriyle birleştirerek bütüncül bir profil çıkarır. "
                        "Bu bir farkındalık çalışmasıdır; kesin kehanet değildir.",
                        style: TextStyle(color: Colors.white.withOpacity(0.86), height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Adımlar",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StepRow(text: "Bilgileri gir"),
                      _StepRow(text: "Onayla"),
                      _StepRow(text: "Analiz hazırlanıyor"),
                      _StepRow(text: "Sonucu oku ve PDF indir"),
                      const SizedBox(height: 10),
                      Text(
                        "Not: Doğum saati opsiyoneldir. Saat girmezsen analiz daha genel yorumlanır.",
                        style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12, height: 1.25),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C361),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PersonalityFormScreen()),
                    );
                  },
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

class _StepRow extends StatelessWidget {
  final String text;
  const _StepRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFF5C361), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}
