import 'package:flutter/material.dart';
import 'package:lunaura/widgets/mystic_scaffold.dart';
import 'package:lunaura/services/personality_api.dart';
import 'personality_payment_screen.dart';

class PersonalityFormScreen extends StatefulWidget {
  const PersonalityFormScreen({super.key});

  @override
  State<PersonalityFormScreen> createState() => _PersonalityFormScreenState();
}

class _PersonalityFormScreenState extends State<PersonalityFormScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
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
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 90),
      ),
    );
  }

  Future<void> _continue() async {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final question = _questionCtrl.text.trim();

    if (name.isEmpty) return _toast("Ad Soyad gir");
    if (_birthDate == null) return _toast("Doğum tarihi seç");
    if (city.isEmpty) return _toast("Doğum yeri (şehir) gir");

    setState(() => _loading = true);

    try {
      // ✅ konu UI yok, backend'e sabit "genel" yolluyoruz
      final reading = await PersonalityApi.start(
        name: name,
        birthDate: _fmtDate(_birthDate!),
        birthTime: _birthTime == null ? null : _fmtTime(_birthTime!),
        birthCity: city,
        birthCountry: "TR",
        topic: "genel",
        question: question.isEmpty ? null : question,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonalityPaymentScreen(
            readingId: reading.id,
            name: name,
            birthDate: _fmtDate(_birthDate!),
            birthTime: _birthTime == null ? "" : _fmtTime(_birthTime!),
            birthCity: city,
            birthCountry: "TR",
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
    _cityCtrl.dispose();
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
                const Expanded(
                  child: Text(
                    "Kişilik Analizi – Bilgiler",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                        controller: _questionCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "İstersen ek not bırak (opsiyonel)",
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
                  onPressed: _loading ? null : _continue,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Devam", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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
