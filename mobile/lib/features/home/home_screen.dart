import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/feature_card.dart';
import '../coffee/coffee_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCoffee(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CoffeeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // custom appbar benzeri üst bölüm
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF12051F),
              Color(0xFF050816),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst başlık
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'MysticAura',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
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

              const SizedBox(height: 8),

              // Özellik kartları
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    children: [
                      FeatureCard(
                        title: 'Kahve Falı',
                        subtitle: 'Fotoğraf yükle, detaylı fal yorumunu al.',
                        icon: Icons.coffee_outlined,
                        onTap: () => _openCoffee(context),
                      ),
                      const SizedBox(height: 12),
                      const FeatureCard(
                        title: 'El Falı',
                        subtitle: 'Avuç içi analizi ve kişilik haritası.',
                        icon: Icons.pan_tool_outlined,
                      ),
                      const SizedBox(height: 12),
                      const FeatureCard(
                        title: 'Tarot',
                        subtitle: '3 - 6 - 12 kart açılımları.',
                        icon: Icons.style_outlined,
                      ),
                      const SizedBox(height: 12),
                      const FeatureCard(
                        title: 'Numeroloji',
                        subtitle: 'Yaşam sayısı, kader sayısı ve daha fazlası.',
                        icon: Icons.auto_awesome_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              // Alt navigasyon (şimdilik statik)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  border: const Border(
                    top: BorderSide(
                      color: Colors.white12,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _BottomItem(icon: Icons.person_outline, label: 'Profil'),
                    _BottomItem(icon: Icons.chat_bubble_outline, label: 'Yorumlar'),
                    _BottomItem(icon: Icons.shopping_bag_outlined, label: 'Mağaza'),
                  ],
                ),
              ),
            ],
          ),
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
        Icon(icon, size: 22, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
