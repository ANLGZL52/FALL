import 'package:flutter/material.dart';
import 'package:fall_app/widgets/mystic_scaffold.dart';
import 'package:fall_app/services/personality_api.dart';
import 'personality_generating_screen.dart';

class PersonalityPaymentScreen extends StatefulWidget {
  final String readingId;
  final String name;
  final String birthDate;
  final String birthTime;
  final String birthCity;
  final String birthCountry;
  final String question;

  const PersonalityPaymentScreen({
    super.key,
    required this.readingId,
    required this.name,
    required this.birthDate,
    required this.birthTime,
    required this.birthCity,
    required this.birthCountry,
    required this.question,
  });

  @override
  State<PersonalityPaymentScreen> createState() => _PersonalityPaymentScreenState();
}

class _PersonalityPaymentScreenState extends State<PersonalityPaymentScreen> {
  bool _loading = false;

  Future<void> _confirmAndContinue() async {
    setState(() => _loading = true);
    try {
      // UI’da MOCK yazmıyoruz ama backend akışı bozulmasın diye işaretliyoruz.
      await PersonalityApi.markPaid(
        readingId: widget.readingId,
        paymentRef: "ref_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonalityGeneratingScreen(
            readingId: widget.readingId,
            name: widget.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), behavior: SnackBarBehavior.floating),
      );
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
                    "Kişilik Analizi – Onay",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
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
                      "Bilgilerini kontrol et",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    _row("Ad", widget.name),
                    _row("Doğum", widget.birthDate),
                    _row("Saat", widget.birthTime.isEmpty ? "—" : widget.birthTime),
                    _row("Yer", "${widget.birthCity}, ${widget.birthCountry}"),
                    _row("Not", widget.question.isEmpty ? "—" : widget.question),
                    const SizedBox(height: 6),
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
                  onPressed: _loading ? null : _confirmAndContinue,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Devam", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(k, style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(color: Colors.white, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
