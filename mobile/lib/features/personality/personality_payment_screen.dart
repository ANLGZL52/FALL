import 'package:flutter/material.dart';
import 'package:fall_app/widgets/mystic_scaffold.dart';
import 'package:fall_app/services/personality_api.dart';
import 'personality_result_screen.dart';

class PersonalityPaymentScreen extends StatefulWidget {
  final String readingId;
  final String name;
  final String birthDate;
  final String birthTime;
  final String birthCity;
  final String birthCountry;
  final String topic;
  final String question;

  const PersonalityPaymentScreen({
    super.key,
    required this.readingId,
    required this.name,
    required this.birthDate,
    required this.birthTime,
    required this.birthCity,
    required this.birthCountry,
    required this.topic,
    required this.question,
  });

  @override
  State<PersonalityPaymentScreen> createState() => _PersonalityPaymentScreenState();
}

class _PersonalityPaymentScreenState extends State<PersonalityPaymentScreen> {
  bool _loading = false;

  Future<void> _payAndGenerate() async {
    setState(() => _loading = true);
    try {
      await PersonalityApi.markPaid(
        readingId: widget.readingId,
        paymentRef: "mock_${DateTime.now().millisecondsSinceEpoch}",
      );

      final generated = await PersonalityApi.generate(readingId: widget.readingId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonalityResultScreen(
            readingId: generated.id,
            title: "Kişilik Analizi – AI",
            resultText: generated.resultText ?? "",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                const Expanded(
                  child: Text(
                    "Kişilik Analizi – Ödeme",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    const Text(
                      "Ödeme",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text("Ad: ${widget.name}", style: const TextStyle(color: Colors.white)),
                    Text("Doğum: ${widget.birthDate}", style: const TextStyle(color: Colors.white)),
                    Text("Saat: ${widget.birthTime.isEmpty ? "—" : widget.birthTime}",
                        style: const TextStyle(color: Colors.white)),
                    Text("Yer: ${widget.birthCity}, ${widget.birthCountry}", style: const TextStyle(color: Colors.white)),
                    Text("Konu: ${widget.topic}", style: const TextStyle(color: Colors.white)),
                    Text(
                      "Soru: ${widget.question.isEmpty ? "—" : widget.question}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Şimdilik ödeme entegrasyonu yok.\nButona basınca ödeme yapılmış sayıp AI analizi üretilecek.",
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
                      : const Text("Öde → AI Analizi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
