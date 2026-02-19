import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  /// AI ile kişiselleştirilmiş yorum vurgusu (Apple 4.3(b) + canlı arayüz)
  final bool showAiBadge;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.showAiBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        splashColor: AppColors.gold.withOpacity(0.28),
        highlightColor: AppColors.gold.withOpacity(0.12),
        child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),

          // ✅ Arka plan üstünde “belli” olması için güçlü glass
          color: Colors.black.withOpacity(0.42),

          // ✅ Mor-altın vibe
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.48),
              const Color(0xFF2A1642).withOpacity(0.60),
              Colors.black.withOpacity(0.48),
            ],
          ),

          border: Border.all(
            color: AppColors.gold.withOpacity(0.55),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.60),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.goldSoft],
                  ),
                ),
                child: Icon(icon, color: Colors.black, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (showAiBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.aiAccent.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.aiAccent.withOpacity(0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 10, color: AppColors.aiAccent),
                                const SizedBox(width: 3),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.aiAccent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.65)),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
