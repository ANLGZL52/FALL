import 'package:flutter/material.dart';

import '../../models/profile_models.dart';
import '../../services/profile_store.dart';
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

  /// Kullanıcı alanlara dokunduysa true.
  /// Store refresh geldi diye kullanıcı girdisini ezmeyelim.
  bool _dirty = false;

  /// İlk kez store’dan form doldurma (ya da dirty değilken)
  bool _appliedOnce = false;

  @override
  void initState() {
    super.initState();
    _boot();

    _nameCtrl.addListener(_markDirty);
    _birthDateCtrl.addListener(_markDirty);
    _birthPlaceCtrl.addListener(_markDirty);
    _birthTimeCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    // typing sırasında sürekli setState yapmayalım
    _dirty = true;
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
      // ✅ local hızlı yükle + server sync
      await ProfileStore.instance.init(alsoSyncServer: true);

      // store değişince UI kendini yenilesin
      ProfileStore.instance.addListener(_onStoreChanged);

      // ilk dolum
      _applyFromStore(force: true);
    } catch (_) {
      // offline vs. sessiz geç
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onStoreChanged() {
    if (!mounted) return;
    _applyFromStore(force: false);
  }

  void _applyFromStore({required bool force}) {
    final me = ProfileStore.instance.me;
    if (me == null) return;

    // Eğer kullanıcı yazmaya başladıysa ve force değilse ezme
    if (!force && _dirty) return;

    // İlk kez uygula veya force
    if (_appliedOnce && !force) return;

    final name = me.displayName.trim();
    final bd = (me.birthDate ?? '').trim();
    final bp = (me.birthPlace ?? '').trim();
    final bt = (me.birthTime ?? '').trim();

    _nameCtrl.text = (name.isNotEmpty && name != 'Misafir') ? name : '';
    _birthDateCtrl.text = bd;
    _birthPlaceCtrl.text = bp;
    _birthTimeCtrl.text = bt;

    _appliedOnce = true;

    // store’dan bastık → kullanıcı değişikliği sayma
    _dirty = false;

    setState(() {});
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
      await ProfileStore.instance.save(
        ProfileUpsertRequest(
          displayName: name,
          birthDate: birthDate.isEmpty ? null : birthDate,
          birthPlace: birthPlace.isEmpty ? null : birthPlace,
          birthTime: birthTime.isEmpty ? null : birthTime,
        ),
      );

      // Kaydedildi → artık dirty değil
      _dirty = false;

      _toast("Kaydedildi ✅");
    } catch (e) {
      _toast("Kaydetme hatası: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    ProfileStore.instance.removeListener(_onStoreChanged);

    _nameCtrl.removeListener(_markDirty);
    _birthDateCtrl.removeListener(_markDirty);
    _birthPlaceCtrl.removeListener(_markDirty);
    _birthTimeCtrl.removeListener(_markDirty);

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
                              TextField(
                                controller: _nameCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _dec("Ad / Takma ad"),
                              ),
                              const Divider(color: Colors.white12),
                              TextField(
                                controller: _birthDateCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _dec("Doğum tarihi (YYYY-AA-GG)"),
                              ),
                              const Divider(color: Colors.white12),
                              TextField(
                                controller: _birthPlaceCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _dec("Doğum yeri (opsiyonel)"),
                              ),
                              const Divider(color: Colors.white12),
                              TextField(
                                controller: _birthTimeCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _dec("Doğum saati (HH:MM, opsiyonel)"),
                              ),
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
                                "Not: Bilgiler cihazında cache’lenir ve Railway DB’ye de kaydedilir.\nBu ekran artık ProfileStore üzerinden tek kaynak mantığıyla çalışır.",
                                style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12, height: 1.25),
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
