import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';
import '../../services/birthchart_api.dart';
import '../../models/birthchart_reading.dart';
import 'birthchart_payment_screen.dart';

class BirthChartFormScreen extends StatefulWidget {
  const BirthChartFormScreen({super.key});

  @override
  State<BirthChartFormScreen> createState() => _BirthChartFormScreenState();
}

class _BirthChartFormScreenState extends State<BirthChartFormScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _topicCtrl = TextEditingController(text: "genel");
  final _questionCtrl = TextEditingController();

  DateTime? _birthDate;
  TimeOfDay? _birthTime; // opsiyonel
  bool _loading = false;

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, "0");
    final m = d.month.toString().padLeft(2, "0");
    final day = d.day.toString().padLeft(2, "0");
    return "$y-$m-$day";
  }

  String _fmtTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, "0");
    final mm = t.minute.toString().padLeft(2, "0");
    return "$hh:$mm";
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
    );

    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickBirthTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
    );

    if (picked != null) setState(() => _birthTime = picked);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 90), // butonu ezmesin
      ),
    );
  }

  Future<void> _continue() async {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final topic = _topicCtrl.text.trim().isEmpty ? "genel" : _topicCtrl.text.trim();

    if (name.isEmpty) return _toast("Ad Soyad gir");
    if (_birthDate == null) return _toast("Doğum tarihi seç");
    if (city.isEmpty) return _toast("Doğum yeri (şehir) gir");

    if (_loading) return;
    setState(() => _loading = true);

    try {
      final BirthChartReading reading = await BirthChartApi.start(
        name: name,
        birthDate: _fmtDate(_birthDate!),
        birthTime: _birthTime == null ? null : _fmtTime(_birthTime!),
        birthCity: city,
        birthCountry: "TR",
        topic: topic,
        question: _questionCtrl.text.trim().isEmpty ? null : _questionCtrl.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BirthChartPaymentScreen(readingId: reading.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast("Hata: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _topicCtrl.dispose();
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
                  "Doğum Haritası – Bilgiler",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ✅ Form alanı: scroll (overflow fix)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Gerekli Bilgiler",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
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
                              _birthDate == null
                                  ? "Doğum Tarihi: Seçilmedi"
                                  : "Doğum Tarihi: ${_fmtDate(_birthDate!)}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            onPressed: _pickBirthDate,
                            icon: const Icon(Icons.calendar_month, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _field(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _birthTime == null
                                  ? "Doğum Saati (opsiyonel): Seçilmedi"
                                  : "Doğum Saati: ${_fmtTime(_birthTime!)}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            onPressed: _pickBirthTime,
                            icon: const Icon(Icons.access_time, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _field(
                      child: TextField(
                        controller: _cityCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Doğum Yeri (Şehir)",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _field(
                      child: TextField(
                        controller: _topicCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Konu (genel/aşk/kariyer/para vb.)",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _field(
                      child: TextField(
                        controller: _questionCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Sorun (opsiyonel) — örn: 2026'da ilişki/iş tarafında ne öne çıkıyor?",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            // ✅ Buton sabit
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
                  onPressed: _loading ? null : _continue,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Devam → Ödeme", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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
