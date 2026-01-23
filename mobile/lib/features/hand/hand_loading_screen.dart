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

  Future<void> _run() async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      // ✅ generate için retry/backoff
      const maxTry = 6;
      const baseDelayMs = 900;

      for (var i = 1; i <= maxTry; i++) {
        try {
          // ✅ Sende HandApi.generate var (generateText yok)
          await HandApi.generate(readingId: widget.readingId, deviceId: deviceId);
          break;
        } catch (e) {
          final retryable = _isHttp(e, 400) || _isHttp(e, 402) || _isHttp(e, 409);
          if (retryable && i < maxTry) {
            await Future.delayed(Duration(milliseconds: baseDelayMs * i));
            continue;
          }
          rethrow;
        }
      }

      if (!mounted) return;

      // ✅ Result screen readingId ile açılıyor
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HandResultScreen(readingId: widget.readingId)),
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
                    'El falın hazırlanıyor…',
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
