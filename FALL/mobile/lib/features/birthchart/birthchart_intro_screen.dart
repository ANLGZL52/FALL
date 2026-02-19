// mobile/lib/features/birthchart/birthchart_intro_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/mystic_scaffold.dart';
import 'birthchart_form_screen.dart';

class BirthChartIntroScreen extends StatelessWidget {
  const BirthChartIntroScreen({super.key});

  void _goForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BirthChartFormScreen()),
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
                  "Doğum Haritası",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Spacer(),
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Doğum haritası, doğduğun anın gökyüzü koordinatlarıyla oluşturulan kişisel bir pusuladır.\n\n"
                      "Karakter çekirdeğini, ilişki tarzını, stres-tetikleyicilerini ve önümüzdeki dönem temalarını "
                      "daha net görmene yardımcı olur. Saat bilgisi varsa yorum daha keskinleşir; yoksa genel tema üzerinden ilerler.",
                      style: TextStyle(color: Colors.white, fontSize: 15.5, height: 1.3, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Analiz; verdiğin bilgilere göre kişiselleştirilir ve pratik önerilerle desteklenir. "
                      "Amacımız: ‘ne oluyor?’u anlatmak değil, ‘ne yapmalısın?’ı netleştirmek.",
                      style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w600),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _goForm(context),
                  child: const Text("Başla", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
