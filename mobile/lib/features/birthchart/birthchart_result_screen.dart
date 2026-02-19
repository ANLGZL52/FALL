// mobile/lib/features/birthchart/birthchart_result_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/mystic_scaffold.dart';
import '../../models/birthchart_reading.dart';
import '../home/home_screen.dart'; // yolunu projene göre düzelt

class BirthChartResultScreen extends StatelessWidget {
  final BirthChartReading reading;
  const BirthChartResultScreen({super.key, required this.reading});

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ✅ geri yok
      onPopInvoked: (_) => _goHome(context),
      child: MysticScaffold(
        scrimOpacity: 0.62,
        patternOpacity: 0.22,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _goHome(context), // ✅ geri yerine home
                    icon: const Icon(Icons.home, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      "Doğum Haritası – Yorum",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        (reading.resultText == null || reading.resultText!.trim().isEmpty)
                            ? "Yorum boş döndü."
                            : reading.resultText!,
                        style: const TextStyle(color: Colors.white, height: 1.35),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                    onPressed: () => _goHome(context),
                    child: const Text("Ana Ekrana Dön", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
