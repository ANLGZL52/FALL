import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MysticBackground extends StatelessWidget {
  final Widget child;

  /// Arka planı ne kadar karartacağımız (0.0 - 1.0)
  final double scrimOpacity;

  /// Hafif mistik doku/pattern (0.0 - 1.0)
  /// Asset istemez, painter ile üretir.
  final double patternOpacity;

  const MysticBackground({
    super.key,
    required this.child,
    this.scrimOpacity = 0.60,
    this.patternOpacity = 0.10,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 🔮 Background image
        Image.asset(
          'assets/backgrounds/ChatGPT Image 3 Oca 2026 18_20_30.png',
          fit: BoxFit.cover,
        ),

        // 🖤 Readability scrim
        Container(color: Colors.black.withOpacity(scrimOpacity)),

        // ✨ Pattern overlay (asset yok, painter var)
        if (patternOpacity > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: patternOpacity.clamp(0.0, 1.0),
                child: CustomPaint(
                  painter: _MysticPatternPainter(),
                ),
              ),
            ),
          ),

        // 🌒 Vignette (kenarları karartır)
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.15,
              colors: [Colors.transparent, Colors.black54],
              stops: [0.55, 1.0],
            ),
          ),
        ),

        child,
      ],
    );
  }
}

class _MysticPatternPainter extends CustomPainter {
  final ui.Paint _paint = ui.Paint()
    ..isAntiAlias = true
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Çok hafif, mistik “sigil” çizgileri + yıldız noktaları.
    // Sabit pseudo-random: ekran her çizimde aynı görünür.
    final seed = 42;
    final rnd = math.Random(seed);

    // İnce çizgi rengi (beyaza yakın)
    _paint.color = Colors.white.withOpacity(0.10);

    // 1) Büyük dairesel halkalar
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final baseR = math.min(size.width, size.height) * 0.35;
    for (int i = 0; i < 4; i++) {
      final r = baseR + i * (baseR * 0.12);
      canvas.drawCircle(center, r, _paint);
    }

    // 2) Sigil çizgileri (kısa, yönlü)
    for (int i = 0; i < 80; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;

      final len = 18 + rnd.nextDouble() * 22;
      final ang = rnd.nextDouble() * math.pi * 2;

      final p1 = Offset(x, y);
      final p2 = Offset(x + math.cos(ang) * len, y + math.sin(ang) * len);

      canvas.drawLine(p1, p2, _paint);
    }

    // 3) “Star dust” noktaları
    final dotPaint = ui.Paint()
      ..isAntiAlias = true
      ..style = ui.PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.10);

    for (int i = 0; i < 140; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 0.6 + rnd.nextDouble() * 1.6;
      canvas.drawCircle(Offset(x, y), r, dotPaint);
    }

    // 4) Çok hafif grid hissi (mistik defter gibi)
    final gridPaint = ui.Paint()
      ..isAntiAlias = true
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withOpacity(0.06);

    const step = 120.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
