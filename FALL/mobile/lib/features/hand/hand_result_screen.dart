import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/hand_reading.dart';
import '../../services/device_id_service.dart';
import '../../services/hand_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';
import '../home/home_screen.dart';

class HandResultScreen extends StatefulWidget {
  final String readingId;
  const HandResultScreen({super.key, required this.readingId});

  @override
  State<HandResultScreen> createState() => _HandResultScreenState();
}

class _HandResultScreenState extends State<HandResultScreen> {
  bool _loading = true;
  HandReading? _reading;
  int? _selectedRating;

  String? _deviceId;
  String? _lastError;

  Timer? _pollTimer;
  int _pollTicks = 0;

  // Poll ayarları
  static const int _maxPollTicks = 35; // ~35 * 2sn = ~70 sn
  static const Duration _pollEvery = Duration(seconds: 2);

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

  Future<String> _ensureDeviceId() async {
    if (_deviceId != null && _deviceId!.trim().isNotEmpty) return _deviceId!;
    final id = await DeviceIdService.getOrCreate();
    _deviceId = id;
    return id;
  }

  bool _shouldPoll(HandReading r) {
    final status = (r.status ?? '').toLowerCase().trim();
    final result = (r.resultText ?? r.comment ?? '').trim();

    // ✅ completed ise poll yok
    if (status == 'completed') return false;

    // ✅ processing / paid gibi durumlarda yorum boşsa poll yap
    if (result.isEmpty && (status == 'processing' || status == 'paid' || status == 'photos_uploaded')) {
      return true;
    }

    // bazı backend’lerde status set edilmeyebiliyor ama sonuç boş kalıyor
    if (result.isEmpty && status.isNotEmpty && status != 'completed') {
      return true;
    }

    return false;
  }

  Future<void> _load() async {
    _stopPolling();
    setState(() {
      _loading = true;
      _lastError = null;
    });

    try {
      final deviceId = await _ensureDeviceId();

      // 1) detail
      var r = await HandApi.detail(deviceId: deviceId, readingId: widget.readingId);

      // 2) Eğer yorum yok ve "tamamlanmış" değilse generate tetikle
      final status = (r.status ?? '').toLowerCase().trim();
      final resultText = (r.resultText ?? r.comment ?? '').trim();

      // processing'e girmemişse generate çağırmak mantıklı
      if (resultText.isEmpty && status != 'completed' && status != 'processing') {
        r = await HandApi.generate(deviceId: deviceId, readingId: widget.readingId);
      }

      // 3) tekrar detail (güncel state)
      r = await HandApi.detail(deviceId: deviceId, readingId: widget.readingId);

      if (!mounted) return;
      setState(() {
        _reading = r;
        _selectedRating = r.rating;
      });

      // 4) hala boşsa poll başlat
      if (_shouldPoll(r)) {
        _startPolling();
      }
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
      if (_pollTicks >= _maxPollTicks) {
        _stopPolling();
        setState(() {
          _lastError = _lastError ??
              'Yorum biraz uzun sürdü. Lütfen Yenile ile tekrar dene.';
        });
        return;
      }

      _pollTicks += 1;

      try {
        final deviceId = await _ensureDeviceId();
        final r = await HandApi.detail(deviceId: deviceId, readingId: widget.readingId);

        if (!mounted) return;

        setState(() {
          _reading = r;
          _selectedRating = r.rating;
        });

        if (!_shouldPoll(r)) {
          _stopPolling();
        }
      } catch (e) {
        // poll sırasında 1-2 kez ağ hatası olabilir; hemen düşürmeyelim.
        // ama deviceId hatası gelirse direkt durdur (bu gerçek bug)
        final msg = '$e';
        if (msg.contains('X-Device-Id') || msg.contains('deviceId')) {
          _stopPolling();
          setState(() => _lastError = msg);
        }
      }
    });
  }

  Future<void> _rate(int rating) async {
    try {
      final deviceId = await _ensureDeviceId();
      final r = await HandApi.rate(deviceId: deviceId, readingId: widget.readingId, rating: rating);

      setState(() {
        _reading = r;
        _selectedRating = rating;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puanın alındı ✨')));

      await Future.delayed(const Duration(milliseconds: 650));
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

  @override
  Widget build(BuildContext context) {
    final r = _reading;
    final result = (r?.resultText ?? r?.comment ?? '').trim();
    final status = (r?.status ?? '').toLowerCase().trim();

    final bool waiting = (r != null) && result.isEmpty && (status == 'processing' || status == 'paid');

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _goHome(),
      child: MysticScaffold(
        scrimOpacity: 0.82,
        patternOpacity: 0.18,
        appBar: AppBar(
          title: const Text('El Falın'),
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
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Konu: ${r.topic}'),
                                      const SizedBox(height: 8),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      if (waiting) ...[
                                        const Text('El falın hazırlanıyor...'),
                                        const SizedBox(height: 10),
                                        const Center(child: CircularProgressIndicator()),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Lütfen bekle. (Otomatik kontrol ediyorum: $_pollTicks/$_maxPollTicks)',
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
                                if (!waiting) // ✅ yorum gelmeden puan vermesin
                                  GlassCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Değerlendir',
                                          style: TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 8),
                                        _ratingRow(),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GradientButton(
                            text: 'Ana Sayfaya Dön',
                            onPressed: _goHome,
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
