// mobile/lib/features/personality/personality_result_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/device_id_service.dart';
import '../../services/personality_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';
import '../home/home_screen.dart';

class PersonalityResultScreen extends StatefulWidget {
  final String readingId;

  const PersonalityResultScreen({
    super.key,
    required this.readingId,
  });

  @override
  State<PersonalityResultScreen> createState() => _PersonalityResultScreenState();
}

class _PersonalityResultScreenState extends State<PersonalityResultScreen> {
  bool _loading = true;
  PersonalityReading? _reading;
  String? _lastError;

  int? _selectedRating;

  Timer? _pollTimer;
  int _pollTicks = 0;

  static const Duration _pollEvery = Duration(seconds: 2);
  static const int _maxPollTicks = 60; // ~120 sn

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollTicks = 0;
  }

  bool _shouldPoll(PersonalityReading r) {
    final status = r.status.toLowerCase().trim();
    final result = (r.resultText ?? '').trim();

    if (result.isNotEmpty && (status == 'done' || status == 'completed')) return false;

    // processing / paid iken boşsa poll
    if (result.isEmpty && (status == 'processing' || status == 'paid' || status == 'created' || status == 'started')) {
      return true;
    }

    // status gelmese bile sonuç boşsa poll edelim
    if (result.isEmpty) return true;

    return false;
  }

  Future<void> _load() async {
    _stopPolling();
    setState(() {
      _loading = true;
      _lastError = null;
    });

    try {
      final deviceId = await DeviceIdService.getOrCreate();

      // 1) detail al
      var r = await PersonalityApi.detail(readingId: widget.readingId, deviceId: deviceId);

      // 2) Eğer sonuç yoksa generate tetiklemeyi deneyebiliriz (idempotent)
      final result = (r.resultText ?? '').trim();
      if (result.isEmpty) {
        try {
          await PersonalityApi.generate(readingId: widget.readingId, deviceId: deviceId);
        } catch (_) {
          // 402 vs olabilir; yine de polling ile görebiliriz
        }
      }

      // 3) tekrar detail
      r = await PersonalityApi.detail(readingId: widget.readingId, deviceId: deviceId);

      if (!mounted) return;
      setState(() {
        _reading = r;
        _selectedRating = r.rating;
      });

      if (_shouldPoll(r)) _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reading = null;
        _lastError = '$e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(_pollEvery, (_) async {
      if (!mounted) return;

      _pollTicks += 1;
      if (_pollTicks >= _maxPollTicks) {
        _stopPolling();
        setState(() {
          _lastError = _lastError ?? 'Analiz biraz uzun sürdü. Yenile ile tekrar dene.';
        });
        return;
      }

      try {
        final deviceId = await DeviceIdService.getOrCreate();
        final r = await PersonalityApi.detail(readingId: widget.readingId, deviceId: deviceId);

        if (!mounted) return;

        setState(() {
          _reading = r;
          _selectedRating = r.rating;
        });

        if (!_shouldPoll(r)) {
          _stopPolling();
        }
      } catch (e) {
        // ağ dalgalanması → poll devam
      }
    });
  }

  Future<void> _rate(int rating) async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();
      await PersonalityApi.rate(readingId: widget.readingId, rating: rating, deviceId: deviceId);

      setState(() => _selectedRating = rating);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puanın alındı ✨')));

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _goHome();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Widget _ratingRow() {
    return Row(
      children: List.generate(5, (i) {
        final v = i + 1;
        final selected = (_selectedRating ?? 0) >= v;
        return IconButton(
          onPressed: () => _rate(v),
          icon: Icon(selected ? Icons.star : Icons.star_border),
        );
      }),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();
      final bytes = await PersonalityApi.downloadPdfBytes(readingId: widget.readingId, deviceId: deviceId);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/personality_${widget.readingId}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF indirildi: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Hatası: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _reading;
    final result = (r?.resultText ?? '').trim();
    final status = (r?.status ?? '').toLowerCase().trim();

    final waiting = r != null && result.isEmpty && (status == 'processing' || status == 'paid' || status == 'created' || status == 'started');

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _goHome(),
      child: MysticScaffold(
        scrimOpacity: 0.82,
        patternOpacity: 0.18,
        appBar: AppBar(
          title: const Text('Kişilik Analizi'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Yenile',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Ana Sayfa',
              onPressed: _goHome,
              icon: const Icon(Icons.home_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (r == null)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_lastError == null ? 'Veri bulunamadı.' : 'Veri alınamadı.'),
                          if (_lastError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _lastError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 12),
                          GradientButton(text: 'Tekrar Dene', onPressed: _load),
                          const SizedBox(height: 10),
                          GradientButton(text: 'Ana Sayfaya Dön', onPressed: _goHome),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView(
                              children: [
                                GlassCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r.name} ✨',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Doğum: ${r.birthDate} ${r.birthTime ?? ""}'.trim()),
                                      const SizedBox(height: 6),
                                      Text('Yer: ${r.birthCity}, ${r.birthCountry}'),
                                      const SizedBox(height: 10),
                                      const Divider(),
                                      const SizedBox(height: 10),
                                      if (waiting) ...[
                                        const Text('Analiz hazırlanıyor...'),
                                        const SizedBox(height: 10),
                                        const Center(child: CircularProgressIndicator()),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Otomatik kontrol: $_pollTicks/$_maxPollTicks',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ] else
                                        Text(
                                          result.isEmpty ? 'Yorum bulunamadı.' : result,
                                          style: const TextStyle(height: 1.42),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (!waiting && result.isNotEmpty) ...[
                                  GlassCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('PDF', style: TextStyle(fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 10),
                                        GradientButton(text: 'PDF İndir', onPressed: _downloadPdf),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  GlassCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Değerlendir', style: TextStyle(fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 8),
                                        _ratingRow(),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GradientButton(text: 'Ana Sayfaya Dön', onPressed: _goHome),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
