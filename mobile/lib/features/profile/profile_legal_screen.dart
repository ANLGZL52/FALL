import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';

enum LegalType { privacy, terms, disclaimer }

class ProfileLegalScreen extends StatelessWidget {
  final LegalType type;
  const ProfileLegalScreen({super.key, required this.type});

  String get title {
    switch (type) {
      case LegalType.privacy:
        return "Gizlilik Politikası";
      case LegalType.terms:
        return "Kullanıcı Sözleşmesi";
      case LegalType.disclaimer:
        return "Uyarı / Sorumluluk Reddi";
    }
  }

  String get body {
    switch (type) {
      case LegalType.privacy:
        return """
LunaAura Gizlilik Politikası (Özet)

- Uygulama, analiz üretmek için kullanıcının girdiği bilgileri (örn. ad/takma ad, doğum tarihi, opsiyonel sorular) işler.
- Ödeme işlemleri Google Play üzerinden gerçekleşir. Kart bilgileri uygulama tarafından görülmez ve saklanmaz.
- Uygulama içi analizler rehberlik/eğlence amaçlıdır.
- Kullanıcı profil bilgileri (V1) yalnızca cihazda saklanır. (Üyelik yok.)
""";
      case LegalType.terms:
        return """
Kullanıcı Sözleşmesi (Özet)

- Uygulama içerikleri ve analizler “rehberlik/eğlence” amaçlıdır; kesin hüküm değildir.
- Kullanıcı, uygulamayı yasalara uygun şekilde kullanmayı kabul eder.
- Dijital içerik/servis sunulduğu için satın alımlar Google Play kuralları kapsamındadır.
- Uygulama, hizmet kalitesini artırmak için akışları güncelleyebilir.
""";
      case LegalType.disclaimer:
        return """
Uyarı / Sorumluluk Reddi

- LunaAura, fal/astroloji/nümeroloji gibi içerikleri rehberlik ve eğlence amacıyla sunar.
- Sağlık, hukuk, finans gibi kritik konularda kesin karar kaynağı değildir.
- Kullanıcı, nihai sorumluluğun kendisine ait olduğunu kabul eder.
""";
    }
  }

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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    body.trim(),
                    style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.35, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
