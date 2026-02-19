import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../tarot_models.dart';

class TarotCardTile extends StatelessWidget {
  final double width;
  final double height;

  /// null => boş slot
  final TarotCard? card;

  /// true => ön yüz
  final bool faceUp;

  /// tıklanamasın
  final bool disabled;

  /// seçilmiş görünümü (border)
  final bool selected;

  /// sağ üst badge (1..)
  final String? badgeLabel;

  final VoidCallback? onTap;

  const TarotCardTile({
    super.key,
    required this.width,
    required this.height,
    required this.card,
    required this.faceUp,
    this.disabled = false,
    this.selected = false,
    this.badgeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = !disabled && onTap != null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFFD9B04C) : Colors.white.withOpacity(0.12),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 1,
                color: Colors.black.withOpacity(0.35),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _buildFace()),

              // Sadece kapalı kart (back) üzerinde marka; boş slot ve açık kartta gösterme
              if (card != null && !faceUp)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 10, color: Colors.white.withOpacity(0.9)),
                        const SizedBox(width: 4),
                        Text(
                          'LunAura',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (badgeLabel != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C547),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeLabel!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

              if (faceUp && (card?.isReversed ?? false))
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.40),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Text(
                      'ters',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFace() {
    // Boş slot: net kart yuvası görseli, kullanıcı dostu
    if (card == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 32,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              badgeLabel != null ? 'Kart $badgeLabel' : 'Boş',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    // kapalı = back (cover olabilir)
    if (!faceUp) {
      return _tryPngThenJpg(
        TarotCard.backBasePath,
        fit: BoxFit.cover,
        fallback: _backFallback(),
      );
    }

    // açık = front (✅ contain => kırpma yok)
    final front = Container(
      color: Colors.black, // contain boşluklarında zemin
      alignment: Alignment.center,
      child: _tryPngThenJpg(
        card!.assetBasePath,
        fit: BoxFit.contain,
        fallback: _frontFallback(card!),
      ),
    );

    if (card!.isReversed) {
      return Transform.rotate(angle: math.pi, child: front);
    }
    return front;
  }

  /// ✅ önce .png, yoksa .jpg
  Widget _tryPngThenJpg(
    String basePath, {
    required BoxFit fit,
    required Widget fallback,
  }) {
    return Image.asset(
      '$basePath.png',
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          '$basePath.jpg',
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => fallback,
        );
      },
    );
  }

  Widget _backFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A1F42),
            const Color(0xFF1A1535),
            const Color(0xFF0D0A12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.35), size: 36),
    );
  }

  Widget _frontFallback(TarotCard c) {
    return Container(
      color: Colors.black.withOpacity(0.35),
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          '${c.nameTr}\n${c.nameEn}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
