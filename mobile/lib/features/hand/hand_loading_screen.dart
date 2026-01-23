import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/hand_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mystic_scaffold.dart';
import '../home/home_screen.dart';
import 'hand_result_screen.dart';

class HandLoadingScreen extends StatefulWidget {
  final String readingId;
  const HandLoadingScreen({super.key, required this.readingId});

  @override
  State<HandLoadingScreen> createState() => _HandLoadingScreenState();
}

class _HandLoadingScreenState extends State<HandLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  bool _isHttp(Object e, int code) {
    final s = e.toString();
    return s.contains(' $code ') || s.contains('$code /') || s.contains(':$code');
  }

  String _pickText(dynamic reading) {
    try {
      // HandReading içinde olabilecek alanlar:
      // - resultText
      // - result_text
      // - comment
      final m = reading as dynamic;

      final a = (m.resultText ?? '').toString().trim();
      if (a.isNotEmpty) return a;

      final b = (m.result_text ?? '').toString().trim();
      if (b.isNotEmpty) return b;

      final c = (m.comment ?? '').toString().trim();
      if (c.isNotEmpty) return c;
    } catch (_) {}

    return '';
  }

  Future<void> _run() async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      const maxTry = 6;
      const baseDelayMs = 900;

      String text = '';

      for (var i = 1; i <= maxTry; i++) {
        try {
          final reading = await HandApi.generate(
            readingId: widget.readingId,
            deviceId: deviceId,
          );

          text = _pickText(reading);
          if (text.isEmpty) {
            throw Exception('generate: yorum boş döndü');
          }
          break;
        } catch (e) {
          final retryable = _isHttp(e, 402) || _isHttp(e, 409);
          if (retryable && i < maxTry) {
            await Future.delayed(Duration(milliseconds: baseDelayMs * i));
            continue;
          }
          rethrow;
        }
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HandResultScreen(resultText: text)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorum üretilemedi: $e')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
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
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Çizgiler okunuyor...\nEl falın hazırlanıyor.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
