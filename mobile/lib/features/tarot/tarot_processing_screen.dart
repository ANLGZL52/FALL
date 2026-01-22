import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/tarot_api.dart';
import '../../widgets/mystic_scaffold.dart';

import 'tarot_models.dart';
import 'tarot_result_screen.dart';

class TarotProcessingScreen extends StatefulWidget {
  final String readingId;
  final String question;
  final TarotSpreadType spreadType;
  final List<TarotCard> selectedCards;

  const TarotProcessingScreen({
    super.key,
    required this.readingId,
    required this.question,
    required this.spreadType,
    required this.selectedCards,
  });

  @override
  State<TarotProcessingScreen> createState() => _TarotProcessingScreenState();
}

class _TarotProcessingScreenState extends State<TarotProcessingScreen> {
  Timer? _timer;

  bool _done = false;
  bool _error = false;
  String? _errorMsg;

  int _elapsed = 0;
  static const int _pollSec = 2;

  bool _generateTriggered = false;

  // ✅ processing -> paid/selected geri düşerse (OpenAI hata/timeout) tekrar generate tetikle
  String _lastStatus = '';

  static const int _warnSec = 18;
  static const int _hardWarnSec = 40;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startPolling() async {
    _timer?.cancel();
    _elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: _pollSec), (_) => _pollOnce());
    await _pollOnce();
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = (v ?? '').toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }

  Future<void> _pollOnce() async {
    if (_done) return;

    _elapsed += _pollSec;

    try {
      final deviceId = await DeviceIdService.getOrCreate();
      final d = await TarotApi.detail(readingId: widget.readingId, deviceId: deviceId);

      final status = (d['status'] ?? '').toString().trim();
      final text = (d['result_text'] ?? '').toString().trim();
      final isPaid = _asBool(d['is_paid']);

      if (status == 'completed' && text.isNotEmpty) {
        _done = true;
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TarotResultScreen(
              question: widget.question,
              spreadType: widget.spreadType,
              selectedCards: widget.selectedCards,
              resultText: text,
            ),
          ),
        );
        return;
      }

      // ✅ status'a takılma:
      // is_paid == true ise generate tetiklenebilir (selected/paid fark etmez)
      final cameBackFromProcessing = (_lastStatus == 'processing' && (status == 'paid' || status == 'selected'));

      if (isPaid && (!_generateTriggered || cameBackFromProcessing)) {
        // processing'te değilse tetiklemeyi dene
        if (status != 'processing') {
          _generateTriggered = true;
          await TarotApi.generate(readingId: widget.readingId, deviceId: deviceId);
        }
      }

      _lastStatus = status;

      if (mounted) {
        setState(() {
          _error = false;
          _errorMsg = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _errorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _forceRetryGenerate() async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();
      _generateTriggered = true;
      await TarotApi.generate(readingId: widget.readingId, deviceId: deviceId);
      if (mounted) {
        setState(() {
          _error = false;
          _errorMsg = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _errorMsg = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final warn = _elapsed >= _warnSec;
    final hardWarn = _elapsed >= _hardWarnSec;

    return MysticScaffold(
      scrimOpacity: 0.84,
      patternOpacity: 0.16,
      appBar: AppBar(title: const Text('İşleniyor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 56, height: 56, child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              _error ? 'Bağlantı sorunu oluştu' : 'Tarot yorumun hazırlanıyor…',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error
                  ? (_errorMsg ?? 'Bilinmeyen hata')
                  : (hardWarn
                      ? 'Beklenenden uzun sürdü. İstersen yeniden tetikleyebilirsin.'
                      : (warn
                          ? 'Bu açılım biraz uzun sürebilir. Ekranda kalırsan otomatik açılacak.'
                          : 'Genelde birkaç saniye içinde hazır olur.')),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.75), height: 1.25),
            ),
            const SizedBox(height: 16),
            if (_error)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _error = false;
                      _errorMsg = null;
                    });
                    await _startPolling();
                  },
                  child: const Text('Tekrar Dene'),
                ),
              ),
            if (!_error && hardWarn)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _forceRetryGenerate,
                  child: const Text('Yeniden Tetikle'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
