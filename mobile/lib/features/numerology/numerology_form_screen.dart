import 'package:flutter/material.dart';

import 'package:lunaura/widgets/mystic_scaffold.dart';
import 'package:lunaura/services/numerology_api.dart';
import 'package:lunaura/features/numerology/numerology_loading_screen.dart';

class NumerologyFormScreen extends StatefulWidget {
  const NumerologyFormScreen({super.key});

  @override
  State<NumerologyFormScreen> createState() => _NumerologyFormScreenState();
}

class _NumerologyFormScreenState extends State<NumerologyFormScreen> {
  final _nameCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  DateTime? _birth;
  bool _loading = false;

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, "0");
    final m = d.month.toString().padLeft(2, "0");
    final day = d.day.toString().padLeft(2, "0");
    return "$y-$m-$day";
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _birth ?? DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
    );

    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _startAndGenerate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad Soyad gir")),
      );
      return;
    }
    if (_birth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doğum tarihi seç")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final reading = await NumerologyApi.start(
        name: name,
        birthDate: _fmt(_birth!),
        topic: "genel",
        question: _questionCtrl.text.trim().isEmpty ? null : _questionCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NumerologyLoadingScreen(
            readingId: reading.id,
            title: "Numeroloji Analizi",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.62,
      patternOpacity: 0.22,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Text(
                  "Numeroloji – Bilgiler",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Analiz için gerekli bilgiler",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _field(
                      child: TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Ad Soyad",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _field(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _birth == null ? "Doğum Tarihi: Seçilmedi" : "Doğum Tarihi: ${_fmt(_birth!)}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _field(
                      child: TextField(
                        controller: _questionCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "İstersen soru yaz (örn: 2026'da kariyerimde ne öne çıkıyor?)",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      "Not: Bu analiz bir rehberdir; kesin hüküm değil, farkındalık ve yön gösterme amaçlıdır.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C361),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _loading ? null : _startAndGenerate,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Analizi Başlat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}
