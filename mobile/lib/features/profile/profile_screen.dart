import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/device_id_service.dart';
import '../../services/profile_api.dart';
import '../../models/profile_models.dart';
import '../../widgets/mystic_scaffold.dart';
import 'profile_legal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController(); // YYYY-MM-DD
  final _birthPlaceCtrl = TextEditingController();
  final _birthTimeCtrl = TextEditingController(); // HH:MM

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _boot();
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

  Future<void> _boot() async {
    try {
      await _loadLocal();        // hızlı açılış
      await _syncFromServer();   // Railway sync
    } catch (_) {
      // offline vs. sessiz geç
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLocal() async {
    final sp = await SharedPreferences.getInstance();
    _nameCtrl.text = sp.getString('profile_name') ?? '';
    _birthDateCtrl.text = sp.getString('profile_birth_date') ?? '';
    _birthPlaceCtrl.text = sp.getString('profile_birth_place') ?? '';
    _birthTimeCtrl.text = sp.getString('profile_birth_time') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _saveLocal({
    required String name,
    required String birthDate,
    required String birthPlace,
    required String birthTime,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('profile_name', name);
    await sp.setString('profile_birth_date', birthDate);
    await sp.setString('profile_birth_place', birthPlace);
    await sp.setString('profile_birth_time', birthTime);
  }

  Future<void> _syncFromServer() async {
    final deviceId = await DeviceIdService.getOrCreate();
    final me = await ProfileApi.getMe(deviceId: deviceId);

    if (me.displayName.trim().isNotEmpty && me.displayName != "Misafir") {
      _nameCtrl.text = me.displayName;
    }
    if ((me.birthDate ?? '').trim().isNotEmpty) _birthDateCtrl.text = me.birthDate!;
    if ((me.birthPlace ?? '').trim().isNotEmpty) _birthPlaceCtrl.text = me.birthPlace!;
    if ((me.birthTime ?? '').trim().isNotEmpty) _birthTimeCtrl.text = me.birthTime!;

    await _saveLocal(
      name: _nameCtrl.text.trim(),
      birthDate: _birthDateCtrl.text.trim(),
      birthPlace: _birthPlaceCtrl.text.trim(),
      birthTime: _birthTimeCtrl.text.trim(),
    );

    if (mounted) setState(() {});
  }

  Future<void> _saveAll() async {
    if (_saving) return;

    final name = _nameCtrl.text.trim();
    final birthDate = _birthDateCtrl.text.trim();
    final birthPlace = _birthPlaceCtrl.text.trim();
    final birthTime = _birthTimeCtrl.text.trim();

    if (name.isEmpty) {
      _toast("İsim boş olamaz (takma ad da olur).");
      return;
    }

    setState(() => _saving = true);
    try {
      await _saveLocal(
        name: name,
        birthDate: birthDate,
        birthPlace: birthPlace,
        birthTime: birthTime,
      );

      final deviceId = await DeviceIdService.getOrCreate();
      await ProfileApi.upsertMe(
        deviceId: deviceId,
        req: ProfileUpsertRequest(
          displayName: name,
          birthDate: birthDate.isEmpty ? null : birthDate,
          birthPlace: birthPlace.isEmpty ? null : birthPlace,
          birthTime: birthTime.isEmpty ? null : birthTime,
        ),
      );

      _toast("Kaydedildi ✅");
    } catch (e) {
      _toast("Kaydetme hatası: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthDateCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _birthTimeCtrl.dispose();
    super.dispose();
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        border: InputBorder.none,
      );

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.70,
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
                  "Profil",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      children: [
                        _card(
                          title: "Kişisel Bilgiler",
                          child: Column(
                            children: [
                              TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: _dec("Ad / Takma ad")),
                              const Divider(color: Colors.white12),
                              TextField(controller: _birthDateCtrl, style: const TextStyle(color: Colors.white), decoration: _dec("Doğum tarihi (YYYY-AA-GG)")),
                              const Divider(color: Colors.white12),
                              TextField(controller: _birthPlaceCtrl, style: const TextStyle(color: Colors.white), decoration: _dec("Doğum yeri (opsiyonel)")),
                              const Divider(color: Colors.white12),
                              TextField(controller: _birthTimeCtrl, style: const TextStyle(color: Colors.white), decoration: _dec("Doğum saati (HH:MM, opsiyonel)")),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF5C361),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: _saving ? null : _saveAll,
                                  child: _saving
                                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Not: Bilgiler cihazında cache’lenir ve Railway DB’ye de kaydedilir.",
                                style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        _card(
                          title: "Benim Okumalarım",
                          child: Text(
                            "Bir sonraki adım: Railway’den deviceId ile son 10 okuma çekip burada listeleyeceğiz.",
                            style: TextStyle(color: Colors.white.withOpacity(0.80), height: 1.3),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _card(
                          title: "Yasal",
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Gizlilik Politikası", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ProfileLegalScreen(type: LegalType.privacy)),
                                ),
                              ),
                              const Divider(color: Colors.white12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Kullanıcı Sözleşmesi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ProfileLegalScreen(type: LegalType.terms)),
                                ),
                              ),
                              const Divider(color: Colors.white12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Uyarı / Sorumluluk Reddi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ProfileLegalScreen(type: LegalType.disclaimer)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
