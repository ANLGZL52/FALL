// lib/features/synastry/synastry_generating_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final s = await _api.getStatus(widget.readingId);

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

  @override
  Widget build(BuildContext context) {
    final msg = _status == 'error'
        ? ('Hata: ${_error ?? "Bilinmeyen hata"}')
        : 'Analiz hazırlanıyor...';

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
                  onPressed: _poll,
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
