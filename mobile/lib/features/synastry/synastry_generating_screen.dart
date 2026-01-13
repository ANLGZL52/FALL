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
  bool _kickedOff = false; // ✅ generate bir kere çağrılsın

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _deviceId = await DeviceIdService.getOrCreate();

      // ✅ Kritik: payments/verify synastry generate tetiklemiyor → burada başlatıyoruz
      await _api.generate(widget.readingId, deviceId: _deviceId);
      _kickedOff = true;

      // ilk poll + periyodik poll
      await _poll();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'error';
        _error = e.toString();
      });
    }
  }

  Future<void> _poll() async {
    try {
      final s = await _api.getStatus(widget.readingId, deviceId: _deviceId);

      if (!mounted) return;
      setState(() {
        _status = s.status;
        _error = s.error;
      });

      if (s.status == 'done' && (s.resultText ?? '').trim().isNotEmpty) {
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
      }

      if (s.status == 'error') {
        _timer?.cancel();
      }
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
    });

    try {
      _deviceId ??= await DeviceIdService.getOrCreate();

      // retry’da da generate tekrar çağrılabilir (backend idempotent ise sorun yok)
      await _api.generate(widget.readingId, deviceId: _deviceId);
      _kickedOff = true;

      await _poll();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'error';
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = _status == 'error'
        ? ('Hata: ${_error ?? "Bilinmeyen hata"}')
        : (_kickedOff ? 'Analiz hazırlanıyor...' : 'Başlatılıyor...');

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
              if (_status != 'error')
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
              if (_status != 'error')
                const Text(
                  'Bittiği anda sonuç sayfasına geçiyoruz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.3),
                ),
              if (_status == 'error') ...[
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
