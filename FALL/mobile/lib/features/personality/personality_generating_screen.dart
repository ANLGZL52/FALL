import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/personality_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mystic_scaffold.dart';
import '../home/home_screen.dart';
import 'personality_result_screen.dart';

class PersonalityGeneratingScreen extends StatefulWidget {
  final String readingId;
  const PersonalityGeneratingScreen({super.key, required this.readingId});

  @override
  State<PersonalityGeneratingScreen> createState() => _PersonalityGeneratingScreenState();
}

class _PersonalityGeneratingScreenState extends State<PersonalityGeneratingScreen> {
  String _statusText = 'Kişilik analizin hazırlanıyor…';
  bool _loading = true;

  Timer? _timer;
  int _ticks = 0;

  static const Duration _pollEvery = Duration(seconds: 2);
  static const int _maxTicks = 90; // ~3dk (kötü ağlarda daha iyi)

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;

    // ✅ reset
    _ticks = 0;

    setState(() {
      _loading = true;
      _statusText = 'Kişilik analizin hazırlanıyor…';
    });

    // ✅ generate'i bir kez tetikle (backend artık hemen dönecek)
    try {
      final deviceId = await DeviceIdService.getOrCreate();
      await PersonalityApi.generate(readingId: widget.readingId, deviceId: deviceId);
    } catch (_) {
      // generate 402/403 vs olsa bile polling ile anlaşılır; sessiz geç
    }

    _timer?.cancel();
    _timer = Timer.periodic(_pollEvery, (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted) return;

    _ticks += 1;

    if (_ticks > _maxTicks) {
      _timer?.cancel();
      setState(() {
        _loading = false;
        _statusText = 'İşlem uzadı. İnternetini kontrol et ve tekrar dene.';
      });
      return;
    }

    try {
      final deviceId = await DeviceIdService.getOrCreate();
      final r = await PersonalityApi.detail(readingId: widget.readingId, deviceId: deviceId);

      final status = r.status.toLowerCase().trim();
      final result = (r.resultText ?? '').trim();

      // ✅ Sonuç geldiyse direkt geç (status bazen tutmayabilir)
      if (result.isNotEmpty) {
        _timer?.cancel();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => PersonalityResultScreen(readingId: widget.readingId)),
          (route) => false,
        );
        return;
      }

      // UI mesajı
      setState(() {
        _loading = true;

        if (status == 'processing') {
          _statusText = 'Analiz hazırlanıyor… ($_ticks/$_maxTicks)';
        } else if (status == 'paid' || status == 'started') {
          _statusText = 'Ödeme/analiz doğrulanıyor… ($_ticks/$_maxTicks)';
        } else {
          _statusText = 'İşlem sürüyor… ($_ticks/$_maxTicks)';
        }
      });
    } catch (_) {
      // ağ dalgalanması → devam
      if (!mounted) return;
      setState(() {
        _loading = true;
        _statusText = 'Bağlantı kontrol ediliyor… ($_ticks/$_maxTicks)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.86,
      patternOpacity: 0.12,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 520,
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusText, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    'Lütfen uygulamadan çıkma 🙏',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.70)),
                    textAlign: TextAlign.center,
                  ),
                  if (!_loading) ...[
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _goHome,
                      child: const Text('Ana sayfaya dön'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
