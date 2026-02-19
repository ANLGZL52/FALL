import 'package:flutter/material.dart';

import '../../services/tarot_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

import 'tarot_models.dart';
import 'tarot_select_screen.dart';

class TarotSpreadSelectScreen extends StatefulWidget {
  final String question;
  final String name;

  const TarotSpreadSelectScreen({
    super.key,
    required this.question,
    required this.name,
  });

  @override
  State<TarotSpreadSelectScreen> createState() => _TarotSpreadSelectScreenState();
}

class _TarotSpreadSelectScreenState extends State<TarotSpreadSelectScreen> {
  TarotSpreadType _type = TarotSpreadType.three;
  bool _loading = false;

  static const Map<TarotSpreadType, double> _prices = {
    TarotSpreadType.three: 149.0,
    TarotSpreadType.six: 199.0,
    TarotSpreadType.twelve: 250.0,
  };

  String _spreadToApi(TarotSpreadType t) {
    switch (t) {
      case TarotSpreadType.three:
        return "three";
      case TarotSpreadType.six:
        return "six";
      case TarotSpreadType.twelve:
        return "twelve";
    }
  }

  Future<void> _goSelect() async {
    setState(() => _loading = true);
    try {
      final startRes = await TarotApi.start(
        topic: "Tarot",
        question: widget.question,
        name: widget.name.trim().isEmpty ? "Misafir" : widget.name.trim(), // ✅ PROFİL ADI
        age: null,
        spreadType: _spreadToApi(_type),
      );

      final readingId = (startRes["id"] ?? "").toString();
      if (readingId.isEmpty) {
        throw Exception("readingId boş döndü");
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TarotSelectScreen(
            readingId: readingId,
            question: widget.question,
            spreadType: _type,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = _prices[_type] ?? 0.0;

    return MysticScaffold(
      scrimOpacity: 0.72,
      patternOpacity: 0.22,
      appBar: AppBar(title: const Text('Açılım Seç')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GlassCard(
              child: Text(
                'Kullanıcı: ${widget.name}\n\n'
                'Sorun:\n${widget.question}\n\n'
                'Açılım türünü seç. Seçtiğin açılıma göre kart sayısı ve yorum derinliği belirlenir.',
                style: const TextStyle(height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Açılım Türü',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _chip(TarotSpreadType.three),
                      _chip(TarotSpreadType.six),
                      _chip(TarotSpreadType.twelve),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Pozisyonlar:\n- ${_type.positionsTr.join("\n- ")}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paket ücreti: ${price.toStringAsFixed(0)} ₺',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "+ vergiler",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Vergiler Google Play tarafından ödeme sırasında eklenir.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              text: _loading ? 'Hazırlanıyor...' : 'Kartlara Geç',
              onPressed: _loading ? null : _goSelect,
              trailingIcon: _loading ? null : Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(TarotSpreadType t) {
    final active = _type == t;

    final price = _prices[t] ?? 0.0;
    final priceText = price.toStringAsFixed(0);

    return InkWell(
      onTap: () => setState(() => _type = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Colors.amber.withOpacity(0.8) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: active ? Colors.amber : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              '${t.label}  •  $priceText ₺',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
