import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

import '../home/home_screen.dart';

class CoffeeResultScreen extends StatelessWidget {
  final String resultText;

  const CoffeeResultScreen({
    super.key,
    required this.resultText,
  });

  void _goHome(BuildContext context) {
    // ✅ Stack'i temizle: kullanıcı hiçbir şekilde önceki adımlara dönemez
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // ✅ Android back / iOS back swipe dahil: geri dönüşü kapatır
      canPop: false,
      onPopInvoked: (didPop) {
        _goHome(context);
      },
      child: MysticScaffold(
        scrimOpacity: 0.84,
        patternOpacity: 0.16,
        appBar: AppBar(
          title: const Text('Fal Sonucu'),
          backgroundColor: Colors.transparent,
          elevation: 0,

          // ✅ Sol üst geri butonunu kaldırıyoruz (çünkü geri dönmek istemiyoruz)
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Ana Sayfa',
              onPressed: () => _goHome(context),
              icon: const Icon(Icons.home_rounded),
            ),
          ],
        ),

        // ✅ Çakışmayı bitiren ana çözüm: SafeArea + doğru padding + scroll
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // ✅ Sonuç metni scroll’lu alan
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      child: Text(
                        resultText,
                        style: const TextStyle(height: 1.45, fontSize: 14.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ Alt aksiyon alanı sabit kalsın, metnin üstüne binmesin
                GlassCard(
                  child: Column(
                    children: [
                      const Text(
                        'Bu faldan memnun kaldın mı?',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: GradientButton(
                              text: 'Evet',
                              onPressed: () {
                                // TODO: Feedback endpoint varsa gönder
                                _goHome(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: Feedback endpoint varsa gönder
                                _goHome(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.white.withOpacity(0.35)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Hayır'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
