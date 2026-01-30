import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/mystic_scaffold.dart';

import '../coffee/coffee_screen.dart';
import '../hand/hand_screen.dart';
import '../tarot/tarot_intro_screen.dart';
import '../numerology/numerology_intro_screen.dart';
import '../birthchart/birthchart_intro_screen.dart';
import '../personality/personality_intro_screen.dart';
import '../synastry/synastry_intro_screen.dart';

import '../iap/iap_debug_screen.dart';

// ✅ NEW
import '../profile/profile_screen.dart';

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

  void _openIapDebug(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IapDebugScreen()));
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
                children: [
                  const Text(
                    'LunaAura',
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

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView(
                  children: [
                    if (!kReleaseMode) ...[
                      FeatureCard(
                        title: 'IAP Debug',
                        subtitle: 'Ürünleri gör, satın alma/verify test et (debug only).',
                        icon: Icons.bug_report_outlined,
                        onTap: () => _openIapDebug(context),
                      ),
                      const SizedBox(height: 12),
                    ],

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

            // ✅ Yeni bottom bar (Home + Profil)
            _BottomBar(
              onTapHome: () {}, // zaten home'dasın
              onTapProfile: () => _openProfile(context),
              active: _BottomTab.home,
            ),
          ],
        ),
      ),
    );
  }
}

enum _BottomTab { home, profile }

class _BottomBar extends StatelessWidget {
  final VoidCallback onTapHome;
  final VoidCallback onTapProfile;
  final _BottomTab active;

  const _BottomBar({
    required this.onTapHome,
    required this.onTapProfile,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        border: const Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomItem(
            icon: Icons.home_outlined,
            label: 'Ana Sayfa',
            active: active == _BottomTab.home,
            onTap: onTapHome,
          ),
          _BottomItem(
            icon: Icons.person_outline,
            label: 'Profil',
            active: active == _BottomTab.profile,
            onTap: onTapProfile,
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFF5C361) : Colors.white70;
    final textColor = active ? const Color(0xFFF5C361) : Colors.white.withOpacity(0.70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
