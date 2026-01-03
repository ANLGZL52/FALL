import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';
import '../../services/birthchart_api.dart';
import '../../models/birthchart_reading.dart';
import 'birthchart_result_screen.dart';

class BirthChartPaymentScreen extends StatefulWidget {
  final BirthChartReading reading;
  const BirthChartPaymentScreen({super.key, required this.reading});

  @override
  State<BirthChartPaymentScreen> createState() => _BirthChartPaymentScreenState();
}

class _BirthChartPaymentScreenState extends State<BirthChartPaymentScreen> {
  bool _loading = false;

  Future<void> _payAndGenerate() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // 1) mock ödeme: paid işaretle
      await BirthChartApi.markPaid(
        readingId: widget.reading.id,
        paymentRef: "mock_${DateTime.now().millisecondsSinceEpoch}",
      );

      // 2) AI üret
      final generated = await BirthChartApi.generate(readingId: widget.reading.id);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BirthChartResultScreen(reading: generated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reading;

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
                  "Doğum Haritası – Ödeme",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Özet", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Text("Ad: ${r.name}", style: const TextStyle(color: Colors.white)),
                    Text("Doğum: ${r.birthDate}", style: const TextStyle(color: Colors.white)),
                    Text("Saat: ${r.birthTime ?? "—"}", style: const TextStyle(color: Colors.white)),
                    Text("Yer: ${r.birthCity}, ${r.birthCountry}", style: const TextStyle(color: Colors.white)),
                    Text("Konu: ${r.topic}", style: const TextStyle(color: Colors.white)),
                    Text("Soru: ${r.question ?? "—"}", style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                    Text(
                      "Şimdilik ödeme entegrasyonu yok.\nButona basınca ödeme yapılmış sayıp AI yorumu üretiyoruz.",
                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
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
                  onPressed: _loading ? null : _payAndGenerate,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Öde → Yorumu AI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
