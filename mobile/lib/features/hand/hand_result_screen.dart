import 'package:flutter/material.dart';

import '../../models/hand_reading.dart';
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await HandApi.detail(readingId: widget.readingId);
      setState(() {
        _reading = r;
        _selectedRating = r.rating;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rate(int rating) async {
    try {
      final r = await HandApi.rate(readingId: widget.readingId, rating: rating);
      setState(() {
        _reading = r;
        _selectedRating = rating;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puanın alındı ✨')),
      );

      // ✅ kullanıcı sonuçtan sonra geri dönmesin -> ana sayfaya yönlendir
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

    final String result = (r?.resultText ?? r?.comment ?? '').trim();

    return PopScope(
      canPop: false, // ✅ geri dönüş kapalı
      onPopInvoked: (_) => _goHome(),
      child: MysticScaffold(
        scrimOpacity: 0.82,
        patternOpacity: 0.18,
        appBar: AppBar(
          title: const Text('El Falın'),
          automaticallyImplyLeading: false, // ✅ back icon yok
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
                          const Text('Veri bulunamadı.'),
                          const SizedBox(height: 12),
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
                                      Text(
                                        result.isEmpty ? 'Yorum bulunamadı.' : result,
                                        style: const TextStyle(height: 1.42),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
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
