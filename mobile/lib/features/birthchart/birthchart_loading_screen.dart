import 'package:flutter/material.dart';

import '../../services/birthchart_api.dart';
import '../../services/device_id_service.dart';
import '../../widgets/mystic_scaffold.dart';
import 'birthchart_result_screen.dart';

class BirthChartLoadingScreen extends StatefulWidget {
  final String readingId;
  final String title;

  const BirthChartLoadingScreen({
    super.key,
    required this.readingId,
    this.title = "Doğum haritan hazırlanıyor...",
  });

  @override
  State<BirthChartLoadingScreen> createState() => _BirthChartLoadingScreenState();
}

class _BirthChartLoadingScreenState extends State<BirthChartLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      final reading = await BirthChartApi.generate(
        readingId: widget.readingId,
        deviceId: deviceId,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => BirthChartResultScreen(reading: reading)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.72,
      patternOpacity: 0.18,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),
            Row(
              children: const [
                SizedBox(width: 16),
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Analiz Oluşturuluyor",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
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
                  color: Colors.black.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Semboller ve temalar birleştiriliyor…\n"
                      "Kişilik çekirdeği, ilişki dili ve dönem enerjileri netleştiriliyor…\n"
                      "Birazdan sana özel, uygulanabilir öneriler hazır.",
                      style: TextStyle(color: Colors.white.withOpacity(0.80), height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}
