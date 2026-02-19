import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Her dokunuşta sıradaki ipucunu gösteren, AI vurgulu animasyonlu rehber figürü.
class GuideOverlay extends StatefulWidget {
  final VoidCallback? onClose;

  const GuideOverlay({super.key, this.onClose});

  @override
  State<GuideOverlay> createState() => _GuideOverlayState();
}

class _GuideOverlayState extends State<GuideOverlay>
    with SingleTickerProviderStateMixin {
  static const List<GuideTip> _tips = [
    GuideTip(
      title: 'LunAura\'ya hoş geldin',
      body:
          'Burada 7\'den fazla analiz türü var. Hepsi AI ile kişiselleştirilmiş, sadece sana özel yorumlar üretir.',
      icon: Icons.auto_awesome,
    ),
    GuideTip(
      title: 'Kahve Falı',
      body:
          'Fincan fotoğrafını yükle. AI, fincandaki işaretleri analiz edip senin için detaylı ve kişisel bir yorum hazırlar.',
      icon: Icons.coffee_outlined,
    ),
    GuideTip(
      title: 'El Falı',
      body:
          'Avuç içi fotoğrafınla AI destekli kişilik haritan çıkar. Çizgiler ve şekiller kişiselleştirilmiş yorumla sunulur.',
      icon: Icons.pan_tool_outlined,
    ),
    GuideTip(
      title: 'Tarot',
      body:
          'Sorunu yaz, kartları seç. AI açılımı yorumlayıp senin durumuna özel bir metin üretir (3, 6 veya 12 kart).',
      icon: Icons.style_outlined,
    ),
    GuideTip(
      title: 'Numeroloji',
      body:
          'Doğum tarihi ve isminle AI yaşam sayısı, kader sayısı ve dönem enerjilerini kişiselleştirilmiş şekilde yorumlar.',
      icon: Icons.auto_awesome_outlined,
    ),
    GuideTip(
      title: 'Doğum Haritası',
      body:
          'Doğum bilgilerinle AI gökyüzü haritanı çıkarır ve karakter, ilişki tarzı ve dönem temalarını yorumlar.',
      icon: Icons.public_outlined,
    ),
    GuideTip(
      title: 'Kişilik Analizi',
      body:
          'Numeroloji + doğum haritası tek raporda. AI birleşik analiz ve PDF indirme ile tam kişisel rehber.',
      icon: Icons.psychology_alt_outlined,
    ),
    GuideTip(
      title: 'Sinastri (Aşk Uyumu)',
      body:
          'İki kişinin doğum bilgileriyle AI uyum analizi yapar. İndirilebilir PDF rapor ile paylaşabilirsin.',
      icon: Icons.favorite_outline,
    ),
    GuideTip(
      title: 'Hepsi AI ile',
      body:
          'Tüm yorumlar canlı AI ile üretilir; hazır metin değil. Soruna ve bilgilerine göre her seferinde yeniden kişiselleştirilir.',
      icon: Icons.auto_awesome,
    ),
  ];

  int _index = 0;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _tips.length - 1) {
      setState(() => _index++);
      _animController.reset();
      _animController.forward();
    } else {
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_index];
    final isLast = _index == _tips.length - 1;

    return Material(
      color: Colors.black54,
      child: InkWell(
        onTap: _next,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // Figür: AI rehber karakteri (ikon + gradient daire)
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: Opacity(
                        opacity: _fadeAnim.value,
                        child: _GuideFigure(icon: tip.icon),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Konuşma balonu
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _fadeAnim.value,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.aiAccent.withOpacity(0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.aiAccent.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: AppColors.aiAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tip.title,
                                  style: const TextStyle(
                                    color: AppColors.aiAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tip.body,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Sonraki / Kapat
                Text(
                  isLast ? 'Kapat (dokun)' : 'Sonraki (dokun)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_index + 1} / ${_tips.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuideTip {
  final String title;
  final String body;
  final IconData icon;

  const GuideTip({
    required this.title,
    required this.body,
    required this.icon,
  });
}

/// Ekranda görünen rehber figürü (basit, ikon tabanlı karakter).
class _GuideFigure extends StatelessWidget {
  final IconData icon;

  const _GuideFigure({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.aiAccent.withOpacity(0.9),
            AppColors.aiAccentSoft,
            AppColors.gold.withOpacity(0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiAccent.withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 44,
        color: Colors.white,
      ),
    );
  }
}
