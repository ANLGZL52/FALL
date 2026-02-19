import 'package:flutter/material.dart';
import '../../widgets/mystic_scaffold.dart';
import '../../core/app_colors.dart';
import 'birthchart_form_screen.dart';

class BirthChartInfoScreen extends StatelessWidget {
  const BirthChartInfoScreen({super.key});

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
            const SizedBox(height: 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Gerekli bilgiler:\n- Ad Soyad\n- Doğum tarihi\n- Doğum yeri\n- (Opsiyonel) Doğum saati\n- Konu (genel/aşk/kariyer vb.)",
                      style: TextStyle(color: Colors.white, fontSize: 15, height: 1.3, fontWeight: FontWeight.w700),
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
                  child: const Text("Devam", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
