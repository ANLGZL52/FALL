import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

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
LunAura Gizlilik Politikası (Özet)

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

Not: Tam metni aşağıdaki butondan PDF olarak açabilirsin.
""";

      case LegalType.disclaimer:
        return """
Uyarı / Sorumluluk Reddi

- LunAura, fal/astroloji/nümeroloji gibi içerikleri rehberlik ve eğlence amacıyla sunar.
- Sağlık, hukuk, finans gibi kritik konularda kesin karar kaynağı değildir.
- Kullanıcı, nihai sorumluluğun kendisine ait olduğunu kabul eder.
""";
    }
  }

  /// Asset'teki PDF'i kopyalayıp (temp klasöre) telefonun sistem PDF viewer'ında açar.
  /// Mevcut dependency'lerini kullanır: path_provider + open_filex
  Future<void> _openTermsPdf(BuildContext context) async {
    const assetPath = 'assets/legal/lunaura_kullanici_sozlesmesi.pdf';
    const outFileName = 'lunaura_kullanici_sozlesmesi.pdf';

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$outFileName');
      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        // Bazı cihazlarda PDF viewer yoksa bu mesaj çıkar.
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF açılamadı: ${result.message ?? 'Cihazda PDF görüntüleyici olmayabilir.'}',
            ),
          ),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF açılırken hata oluştu: $e')),
      );
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            /// ✅ Sadece "Kullanıcı Sözleşmesi" sayfasında PDF butonu göster
            if (type == LegalType.terms)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C361),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openTermsPdf(context),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text(
                      'Tam Metni PDF Olarak Aç',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
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
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
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
