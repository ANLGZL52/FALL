import 'package:flutter/material.dart';

import '../../services/profile_store.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

import 'tarot_spread_select_screen.dart';

class TarotIntroScreen extends StatefulWidget {
  const TarotIntroScreen({super.key});

  @override
  State<TarotIntroScreen> createState() => _TarotIntroScreenState();
}

class _TarotIntroScreenState extends State<TarotIntroScreen> {
  final _questionCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _loadingProfile = true;

  // kullanıcı adı alanına dokunduysa profil sync gelse de ezmeyelim
  bool _nameDirty = false;
  bool _appliedNameOnce = false;

  @override
  void initState() {
    super.initState();
    _boot();

    _nameCtrl.addListener(() {
      _nameDirty = true;
    });
  }

  Future<void> _boot() async {
    try {
      await ProfileStore.instance.init(alsoSyncServer: true);
      ProfileStore.instance.addListener(_onProfileChanged);
      _applyNameFromProfile(force: true);
    } catch (_) {
      // sessiz geç
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  void _onProfileChanged() {
    if (!mounted) return;
    _applyNameFromProfile(force: false);
  }

  void _applyNameFromProfile({required bool force}) {
    final me = ProfileStore.instance.me;
    if (me == null) return;

    if (!force && _nameDirty) return;
    if (_appliedNameOnce && !force) return;

    final name = me.displayName.trim();
    if (name.isNotEmpty && name != 'Misafir') {
      // kullanıcı zaten bir şey yazdıysa ezme
      if (_nameCtrl.text.trim().isEmpty || force) {
        _nameCtrl.text = name;
      }
    } else {
      if (force && _nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = 'Misafir';
      }
    }

    _appliedNameOnce = true;
    _nameDirty = false;

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ProfileStore.instance.removeListener(_onProfileChanged);
    _questionCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    final q = _questionCtrl.text.trim();
    if (q.isEmpty) return;

    final name = _nameCtrl.text.trim().isEmpty ? 'Misafir' : _nameCtrl.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TarotSpreadSelectScreen(
          question: q,
          name: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.70,
      patternOpacity: 0.22,
      appBar: AppBar(title: const Text('Tarot')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const GlassCard(
              child: Text(
                'Tarot Açılımı\n\n'
                '• Niyetini / sorunu net bir cümleyle yaz.\n'
                '• Açılım türünü seç (3 / 6 / 12 kart).\n'
                '• Kartlar kapalı gelir; dokunarak kartları açarsın.\n'
                '• Açılan kartlar arasından, açılımın istediği sayıda kartı seçersin.\n\n'
                'Not: Ne kadar net bir soru, o kadar isabetli bir yorum.',
                style: TextStyle(height: 1.35),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Profil adı buraya yansır
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İsmin (profilinden gelir)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameCtrl,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _loadingProfile ? 'Profil yükleniyor…' : 'Örn: Anıl',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.25),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'İstersen buradan değiştirebilirsin.',
                    style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sorun',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _questionCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Örn: İlişkim nereye gidiyor? / Kariyerde karar aşaması / Maddi plan…',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.25),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              text: 'Devam Et',
              onPressed: _continue,
              trailingIcon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}
