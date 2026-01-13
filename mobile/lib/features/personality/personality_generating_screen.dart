import 'package:flutter/material.dart';

import 'package:lunaura/widgets/mystic_scaffold.dart';
import 'package:lunaura/services/personality_api.dart';
import 'package:lunaura/services/device_id_service.dart';
import 'personality_result_screen.dart';

class PersonalityGeneratingScreen extends StatefulWidget {
  final String readingId;
  final String name;

  const PersonalityGeneratingScreen({
    super.key,
    required this.readingId,
    required this.name,
  });

  @override
  State<PersonalityGeneratingScreen> createState() => _PersonalityGeneratingScreenState();
}

class _PersonalityGeneratingScreenState extends State<PersonalityGeneratingScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _run();
    }
  }

  Future<void> _run() async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      final generated = await PersonalityApi.generate(
        readingId: widget.readingId,
        deviceId: deviceId,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonalityResultScreen(
            readingId: generated.id,
            title: "Kişilik Analizi",
            resultText: generated.resultText ?? "",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
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
              children: const [
                SizedBox(width: 52),
                Expanded(
                  child: Text(
                    "Kişilik Analizi",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 52),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                        const Icon(Icons.auto_awesome, color: Color(0xFFF5C361), size: 28),
                        const SizedBox(height: 12),
                        Text(
                          "${widget.name} için analiz hazırlanıyor…",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bu işlem birkaç saniye sürebilir. Lütfen ekranı kapatma.",
                          style: TextStyle(color: Colors.white70, height: 1.25),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        const SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 14),
                        _hint("Karakter çekirdeği, ilişki dili ve kariyer temaları harmanlanıyor"),
                        _hint("Yakın dönem öneriler ve mini plan hazırlanıyor"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _hint(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
