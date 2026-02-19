// mobile/lib/features/hand/hand_loading_screen.dart
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
  String _statusText = 'El falın hazırlanıyor…';
  int _tryNo = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  bool _isHttp(Object e, int code) {
    final s = e.toString();
    return s.contains(' $code ') || s.contains('$code /') || s.contains(':$code');
  }

  String _extractUserMessage(Object e) {
    var msg = e.toString();
    msg = msg.replaceFirst('Exception: ', '').trim();

    // bazı throw formatlarında detail çok uzuyor -> kısa tut
    if (msg.toLowerCase().contains('payment required') || msg.contains('402')) {
      return 'Ödeme doğrulanıyor… (lütfen bekle)';
    }
    if (msg.toLowerCase().contains('upload hand photos') || msg.toLowerCase().contains('photos')) {
      return 'Fotoğraflar bulunamadı. Lütfen yeniden yükleyin.';
    }
    if (msg.toLowerCase().contains('avuç') || msg.toLowerCase().contains('palm')) {
      return 'Lütfen yalnızca avuç içi (palm) fotoğrafı yükleyin.';
    }
    return msg.isEmpty ? 'Bir hata oluştu.' : msg;
  }

  Future<void> _run() async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      // ✅ güçlü retry/backoff
      const int maxTry = 8;
      const int baseDelayMs = 900;

      for (var i = 1; i <= maxTry; i++) {
        _tryNo = i;
        if (mounted) {
          setState(() {
            _statusText = 'Yorum hazırlanıyor… (deneme $i/$maxTry)';
          });
        }

        try {
          // 1) önce mevcut durumu çek
          var r = await HandApi.detail(deviceId: deviceId, readingId: widget.readingId);
          final status = (r.status ?? '').toLowerCase().trim();
          final result = (r.resultText ?? r.comment ?? '').trim();

          // ✅ zaten hazırsa direkt çık
          if (result.isNotEmpty && status == 'completed') {
            break;
          }

          // 2) değilse generate tetikle
          await HandApi.generate(deviceId: deviceId, readingId: widget.readingId);

          // 3) generate sonrası tekrar detail çek (DB güncellenmiş mi?)
          r = await HandApi.detail(deviceId: deviceId, readingId: widget.readingId);
          final status2 = (r.status ?? '').toLowerCase().trim();
          final result2 = (r.resultText ?? r.comment ?? '').trim();

          if (result2.isNotEmpty && status2 == 'completed') {
            break;
          }

          // ✅ bazı durumlarda status processing kalır; bekleyip retry
          if (i < maxTry) {
            await Future.delayed(Duration(milliseconds: baseDelayMs * i));
            continue;
          }
        } catch (e) {
          // ✅ 400: yanlış foto / validasyon -> retry YOK
          if (_isHttp(e, 400)) {
            throw Exception(_extractUserMessage(e));
          }

          // ✅ 402: verify gecikmesi olabilir -> retry var
          // ✅ 409: lock/idempotent -> retry var
          // ✅ 429/500: geçici -> retry var
          final retryable = _isHttp(e, 402) || _isHttp(e, 409) || _isHttp(e, 429) || _isHttp(e, 500);

          if (retryable && i < maxTry) {
            if (mounted) {
              setState(() {
                _statusText = _extractUserMessage(e);
              });
            }
            await Future.delayed(Duration(milliseconds: baseDelayMs * i));
            continue;
          }

          throw Exception(_extractUserMessage(e));
        }
      }

      if (!mounted) return;

      // ✅ sonuç ekranına geç
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HandResultScreen(readingId: widget.readingId)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      final msg = _extractUserMessage(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lütfen uygulamadan çıkma 🙏',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
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
