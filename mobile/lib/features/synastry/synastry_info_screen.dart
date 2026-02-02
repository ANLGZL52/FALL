// lib/features/synastry/synastry_info_screen.dart
import 'package:flutter/material.dart';

import '../../models/synastry_models.dart';
import '../../services/device_id_service.dart'; // ✅ EKLE
import '../../services/synastry_api.dart';
import 'synastry_payment_screen.dart';

class SynastryInfoScreen extends StatefulWidget {
  const SynastryInfoScreen({super.key});

  @override
  State<SynastryInfoScreen> createState() => _SynastryInfoScreenState();
}

class _SynastryInfoScreenState extends State<SynastryInfoScreen> {
  final _api = SynastryApi();

  // Person A
  final _aName = TextEditingController();
  final _aDate = TextEditingController(); // YYYY-MM-DD
  final _aTime = TextEditingController(); // HH:MM
  final _aCity = TextEditingController();
  final _aCountry = TextEditingController(text: 'Türkiye');

  // Person B
  final _bName = TextEditingController();
  final _bDate = TextEditingController();
  final _bTime = TextEditingController();
  final _bCity = TextEditingController();
  final _bCountry = TextEditingController(text: 'Türkiye');

  final _question = TextEditingController();
  String _topic = 'Genel';

  bool _loading = false;

  @override
  void dispose() {
    _aName.dispose();
    _aDate.dispose();
    _aTime.dispose();
    _aCity.dispose();
    _aCountry.dispose();
    _bName.dispose();
    _bDate.dispose();
    _bTime.dispose();
    _bCity.dispose();
    _bCountry.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_aName.text.trim().isEmpty ||
        _aDate.text.trim().isEmpty ||
        _aCity.text.trim().isEmpty ||
        _bName.text.trim().isEmpty ||
        _bDate.text.trim().isEmpty ||
        _bCity.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İki kişi için isim + doğum tarihi + şehir zorunlu.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final req = SynastryStartRequest(
        nameA: _aName.text.trim(),
        birthDateA: _aDate.text.trim(),
        birthTimeA: _aTime.text.trim().isEmpty ? null : _aTime.text.trim(),
        birthCityA: _aCity.text.trim(),
        birthCountryA: _aCountry.text.trim().isEmpty ? 'Türkiye' : _aCountry.text.trim(),
        nameB: _bName.text.trim(),
        birthDateB: _bDate.text.trim(),
        birthTimeB: _bTime.text.trim().isEmpty ? null : _bTime.text.trim(),
        birthCityB: _bCity.text.trim(),
        birthCountryB: _bCountry.text.trim().isEmpty ? 'Türkiye' : _bCountry.text.trim(),
        topic: _topic,
        question: _question.text.trim().isEmpty ? null : _question.text.trim(),
      );

      // ✅ KRİTİK: deviceId üret ve header’a koy
      final deviceId = await DeviceIdService.getOrCreate();

      final startRes = await _api.start(req, deviceId: deviceId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SynastryPaymentScreen(
            readingId: startRes.readingId,
            title: 'Sinastri (Aşk Uyumu)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinastri - Bilgiler'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: AbsorbPointer(
        absorbing: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _sectionTitle('Kişi A'),
              _field(_aName, 'Ad Soyad'),
              _field(_aDate, 'Doğum Tarihi (YYYY-MM-DD)', hint: '1995-07-23'),
              _field(_aTime, 'Doğum Saati (HH:MM) (opsiyonel)', hint: '18:25'),
              _field(_aCity, 'Doğum Şehri', hint: 'İstanbul'),
              _field(_aCountry, 'Ülke', hint: 'Türkiye'),

              const SizedBox(height: 14),
              _sectionTitle('Kişi B'),
              _field(_bName, 'Ad Soyad'),
              _field(_bDate, 'Doğum Tarihi (YYYY-MM-DD)', hint: '1997-01-10'),
              _field(_bTime, 'Doğum Saati (HH:MM) (opsiyonel)', hint: '09:40'),
              _field(_bCity, 'Doğum Şehri', hint: 'İzmir'),
              _field(_bCountry, 'Ülke', hint: 'Türkiye'),

              const SizedBox(height: 14),
              _sectionTitle('Odak'),
              _dropdown(),
              _field(_question, 'Soru (opsiyonel)', hint: 'Bu ilişkide en kritik dinamik ne?'),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6B15E),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _start,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Devam → Ödeme'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF0B1120).withOpacity(0.75),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD6B15E)),
          ),
        ),
      ),
    );
  }

  Widget _dropdown() {
    final items = ['Genel', 'Aşk', 'İletişim', 'Güven', 'Evlilik', 'Ayrılık', 'Barışma', 'Uzun Vade'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120).withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _topic,
          isExpanded: true,
          dropdownColor: const Color(0xFF0B1120),
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _topic = v ?? 'Genel'),
        ),
      ),
    );
  }
}
