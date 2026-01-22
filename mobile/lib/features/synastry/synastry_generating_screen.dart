import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/synastry_api.dart';
import 'synastry_result_screen.dart';

class SynastryGeneratingScreen extends StatefulWidget {
  final String readingId;
  const SynastryGeneratingScreen({super.key, required this.readingId});

  @override
  State<SynastryGeneratingScreen> createState() => _SynastryGeneratingScreenState();
}

class _SynastryGeneratingScreenState extends State<SynastryGeneratingScreen> {
  final _api = SynastryApi();
  Timer? _timer;

  String _status = 'processing';
  String? _error;

  String? _deviceId;

  bool _generateTriggered = false;
  String _lastStatus = '';

  int _elapsed = 0;
  static const int _pollSec = 2;

  static const int _warnSec = 18;
  static const int _hardWarnSec = 40;

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

  String _norm(String? s) => (s ?? '').toLowerCase().trim();

  bool _isDoneStatus(String s) {
    final x = _norm(s);
    return x == 'done' || x == 'completed' || x == 'complete';
  }

  bool _isErrorStatus(String s) => _norm(s) == 'error';

  Future<void> _start() async {
    try {
      _deviceId = await DeviceIdService.getOrCreate();

      _timer?.cancel();
      _elapsed = 0;

      // periyodik poll
      _timer = Timer.periodic(const Duration(seconds: _pollSec), (_) => _pollOnce());

      // hemen ilk poll
      await _pollOnce();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'error';
        _error = e.toString();
      });
    }
  }

  Future<void> _pollOnce() async {
    _elapsed += _pollSec;

    try {
      final s = await _api.getStatus(widget.readingId, deviceId: _deviceId);

      if (!mounted) return;

      final st = _norm(s.status);
      final paid = (s.isPaid == true);
      final hasText = (s.resultText ?? '').trim().isNotEmpty;

      setState(() {
        _status = st.isEmpty ? 'processing' : st;
        _error = s.error; // model'de yoksa null kalır
      });

      // ✅ bittiyse result ekranı
      if (_isDoneStatus(st) && hasText) {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SynastryResultScreen(
              readingId: widget.readingId,
              resultText: s.resultText ?? '',
            ),
          ),
        );
        return;
      }

      // ✅ hata durumunda dur
      if (_isErrorStatus(st)) {
        _timer?.cancel();
        return;
      }

      // ✅ generate tetik kuralı:
      // sadece paid=true ve status paid / started iken
      final shouldTriggerGenerate = paid && (st == 'paid' || st == 'started');

      // processing -> paid geri düştüyse 1 kez daha tetikle
      final cameBackToPaid = (_lastStatus == 'processing' && st == 'paid');

      if (shouldTriggerGenerate && (!_generateTriggered || cameBackToPaid)) {
        _generateTriggered = true;
        await _api.generate(widget.readingId, deviceId: _deviceId);
      }

      _lastStatus = st;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'error';
        _error = e.toString();
      });
      _timer?.cancel();
    }
  }

  Future<void> _retry() async {
    setState(() {
      _status = 'processing';
      _error = null;
      _generateTriggered = false;
      _lastStatus = '';
      _elapsed = 0;
    });
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final warn = _elapsed >= _warnSec;
    final hardWarn = _elapsed >= _hardWarnSec;

    final isError = _status == 'error';

    final msg = isError ? ('Hata: ${_error ?? "Bilinmeyen hata"}') : 'Analiz hazırlanıyor...';

    final sub = isError
        ? 'Tekrar deneyebilirsin.'
        : (hardWarn
            ? 'Beklenenden uzun sürdü. Ekranda kalırsan otomatik açılacak. Gerekirse tekrar dene.'
            : (warn ? 'Bu analiz biraz uzun sürebilir. Birazdan hazır olacak.' : 'Genelde birkaç saniye içinde hazır olur.'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hazırlanıyor'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isError)
                const CircularProgressIndicator()
              else
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
              const SizedBox(height: 14),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.3),
              ),
              const SizedBox(height: 10),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, height: 1.3),
              ),
              if (isError) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6B15E),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _retry,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
