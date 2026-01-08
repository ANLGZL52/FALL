import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/mystic_scaffold.dart';

import '../coffee/coffee_screen.dart';
import '../hand/hand_screen.dart';
import '../tarot/tarot_intro_screen.dart';
import '../numerology/numerology_intro_screen.dart';

// ✅ Doğum Haritası
import '../birthchart/birthchart_intro_screen.dart';

// ✅ Kişilik Analizi
import '../personality/personality_intro_screen.dart';

// ✅ Sinastri
import '../synastry/synastry_intro_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCoffee(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoffeeScreen()));
  }

  void _openHand(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HandScreen()));
  }

  void _openTarot(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TarotIntroScreen()));
  }

  void _openNumerology(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NumerologyIntroScreen()));
  }

  void _openBirthChart(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BirthChartIntroScreen()));
  }

  void _openPersonality(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonalityIntroScreen()));
  }

  void _openSynastry(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SynastryIntroScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.62,
      patternOpacity: 0.22,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                // ❗ const LIST KULLANMIYORUZ (Windows "Not a constant expression" fix)
                children: [
                  const Text(
                    'MysticAura',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kaderin, senin için hazır.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Kartlar listesi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView(
                  children: [
                    FeatureCard(
                      title: 'Kahve Falı',
                      subtitle: 'Fotoğraf yükle, detaylı fal yorumunu al.',
                      icon: Icons.coffee_outlined,
                      onTap: () => _openCoffee(context),
                    ),
                    const SizedBox(height: 12),

                    FeatureCard(
                      title: 'El Falı',
                      subtitle: 'Avuç içi analizi ve kişilik haritası.',
                      icon: Icons.pan_tool_outlined,
                      onTap: () => _openHand(context),
                    ),
                    const SizedBox(height: 12),

                    FeatureCard(
                      title: 'Tarot',
                      subtitle: '3 - 6 - 12 kart açılımları.',
                      icon: Icons.style_outlined,
                      onTap: () => _openTarot(context),
                    ),
                    const SizedBox(height: 12),

                    FeatureCard(
                      title: 'Numeroloji',
                      subtitle: 'Yaşam sayısı, kader sayısı ve daha fazlası.',
                      icon: Icons.auto_awesome_outlined,
                      onTap: () => _openNumerology(context),
                    ),
                    const SizedBox(height: 12),

                    FeatureCard(
                      title: 'Doğum Haritası',
                      subtitle: 'Doğum tarihi, yer ve (opsiyonel) saat ile analiz.',
                      icon: Icons.public_outlined,
                      onTap: () => _openBirthChart(context),
                    ),
                    const SizedBox(height: 12),

                    FeatureCard(
                      title: 'Kişilik Analizi',
                      subtitle: 'Numeroloji + Doğum Haritası birleşik rapor + PDF indir.',
                      icon: Icons.psychology_alt_outlined,
                      onTap: () => _openPersonality(context),
                    ),
                    const SizedBox(height: 12),

                    FeatureCard(
                      title: 'Sinastri (Aşk Uyumu)',
                      subtitle: 'İki kişinin doğum bilgileriyle uyum analizi + PDF rapor.',
                      icon: Icons.favorite_outline,
                      onTap: () => _openSynastry(context),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.42),
                border: const Border(
                  top: BorderSide(color: Colors.white12, width: 0.5),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BottomItem(icon: Icons.person_outline, label: 'Profil'),
                  _BottomItem(icon: Icons.chat_bubble_outline, label: 'Yorumlar'),
                  _BottomItem(icon: Icons.shopping_bag_outlined, label: 'Mağaza'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.70),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
