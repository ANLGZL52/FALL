import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/numerology_api.dart';
import '../../models/numerology_reading.dart';
import '../../widgets/mystic_scaffold.dart';

import 'numerology_payment_screen.dart';

class NumerologyFormScreen extends StatefulWidget {
  const NumerologyFormScreen({super.key});

  @override
  State<NumerologyFormScreen> createState() => _NumerologyFormScreenState();
}

class _NumerologyFormScreenState extends State<NumerologyFormScreen> {
  final _nameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController(); // YYYY-MM-DD
  final _topicCtrl = TextEditingController(text: "genel");
  final _questionCtrl = TextEditingController();

  bool _loading = false;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 90),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    DateTime? initial;
    try {
      final parts = _birthDateCtrl.text.trim().split("-");
      if (parts.length == 3) {
        initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}

    initial ??= DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
    );

    if (picked != null) {
      final y = picked.year.toString().padLeft(4, "0");
      final m = picked.month.toString().padLeft(2, "0");
      final d = picked.day.toString().padLeft(2, "0");
      _birthDateCtrl.text = "$y-$m-$d";
      setState(() {});
    }
  }

  Future<void> _continueToPayment() async {
    final name = _nameCtrl.text.trim();
    final birthDate = _birthDateCtrl.text.trim();
    final topic = _topicCtrl.text.trim().isEmpty ? "genel" : _topicCtrl.text.trim();
    final question = _questionCtrl.text.trim();

    if (name.isEmpty) return _toast("Ad Soyad gir");
    if (birthDate.isEmpty) return _toast("Doğum tarihi seç/gir (YYYY-AA-GG)");
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final deviceId = await DeviceIdService.getOrCreate();

      final NumerologyReading reading = await NumerologyApi.start(
        name: name,
        birthDate: birthDate,
        topic: topic,
        question: question.isEmpty ? null : question,
        deviceId: deviceId,
      );

      if (!mounted) return;

      // ✅ ÖNCE ÖDEME
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NumerologyPaymentScreen(
            readingId: reading.id,
            name: name,
            birthDate: birthDate,
            question: question,
          ),
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
    _birthDateCtrl.dispose();
    _topicCtrl.dispose();
    _questionCtrl.dispose();
    super.dispose();
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
                  "Nümeroloji – Bilgiler",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),

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
                              _birthDateCtrl.text.trim().isEmpty
                                  ? "Doğum Tarihi: Seçilmedi"
                                  : "Doğum Tarihi: ${_birthDateCtrl.text.trim()}",
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
                          hintText: "Sorun (opsiyonel)",
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
                  onPressed: _loading ? null : _continueToPayment,
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
}
