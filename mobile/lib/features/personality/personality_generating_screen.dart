import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/personality_api.dart';
import '../../widgets/mystic_scaffold.dart';
import 'personality_result_screen.dart';

class PersonalityGeneratingScreen extends StatefulWidget {
  final String readingId;

  const PersonalityGeneratingScreen({
    super.key,
    required this.readingId,
  });

  @override
  State<PersonalityGeneratingScreen> createState() => _PersonalityGeneratingScreenState();
}

class _PersonalityGeneratingScreenState extends State<PersonalityGeneratingScreen> {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  bool _isHttp(Object e, int code) {
    final s = e.toString();
    return s.contains(' $code ') || s.contains('$code /') || s.contains(':$code');
  }

  String _prettyError(Object e) {
    final s = e.toString();

    if (_isHttp(e, 402)) {
      return "Ödeme doğrulaması henüz sisteme yansımadı.\n\n"
          "Birazdan otomatik tekrar deneyeceğim…";
    }

    if (_isHttp(e, 409)) {
      return "İşlem çakıştı / sonuç hazır değil.\n\n"
          "Tekrar deniyorum…";
    }

    if (s.toLowerCase().contains('timeout') || s.contains('zaman a')) {
      return "İşlem çok uzadı ve zaman aşımına uğradı.\n\n"
          "İnternetini kontrol et ve tekrar dene.";
    }

    return "Bir hata oluştu:\n$s";
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;

    final deviceId = await DeviceIdService.getOrCreate();

    // ✅ 402/409 gibi timing durumları için kontrollü retry
    const maxTry = 6;           // toplam deneme
    const baseDelayMs = 900;    // ilk bekleme

    for (var i = 1; i <= maxTry; i++) {
      try {
        final reading = await PersonalityApi.generate(
          readingId: widget.readingId,
          deviceId: deviceId,
        );

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => PersonalityResultScreen(reading: reading)),
          (route) => false,
        );
        return;
      } catch (e) {
        if (!mounted) return;

        final isRetryable = _isHttp(e, 402) || _isHttp(e, 409);

        if (isRetryable && i < maxTry) {
          // kullanıcıya hafif bilgi ver (spam yok)
          if (i == 1 || i == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_prettyError(e)), behavior: SnackBarBehavior.floating),
            );
          }

          // artan backoff
          final wait = Duration(milliseconds: baseDelayMs * i);
          await Future.delayed(wait);
          continue;
        }

        // retry bitince veya retryable değilse
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_prettyError(e)), behavior: SnackBarBehavior.floating),
        );
        Navigator.of(context).pop();
        return;
      }
    }

    _running = false;
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
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kişilik analizin hazırlanıyor...",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Semboller ve temalar birleştiriliyor…\n"
                      "Kişilik çekirdeği netleştiriliyor…\n"
                      "Birazdan hazır.",
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
