import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/hand_api.dart';
import '../../services/iap_service.dart';
import '../../services/product_catalog.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

class HandPaymentScreen extends StatefulWidget {
  final String readingId;
  const HandPaymentScreen({super.key, required this.readingId});

  @override
  State<HandPaymentScreen> createState() => _HandPaymentScreenState();
}

class _HandPaymentScreenState extends State<HandPaymentScreen> {
  bool _loading = false;

  // ✅ Debug modda da store akışını test etmek istersen true
  static const bool debugUseStoreIap = false;

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      final shouldUseIap = kReleaseMode || debugUseStoreIap;
      if (shouldUseIap) {
        final verify = await IapService.instance.buyAndVerify(
          readingId: widget.readingId,
          sku: ProductCatalog.hand39,
        );
        if (!verify.verified) {
          throw Exception("Ödeme doğrulanamadı: ${verify.status}");
        }
      }

      await HandApi.generate(readingId: widget.readingId, deviceId: deviceId);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme/Yorum hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('El Falı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text('Avucundaki çizgiler, karakterin ve yolun hakkında küçük ipuçları taşır.\nŞimdi yorumlayalım.'),
                  const SizedBox(height: 12),

                  const Text('Tutar: 39 ₺', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '+ vergiler',
                    style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vergiler Google Play tarafından ödeme sırasında eklenir.',
                    style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 11, height: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              text: _loading ? 'İşleniyor...' : 'Ödemeyi Tamamla ✨',
              onPressed: _loading ? null : _pay,
            ),
          ],
        ),
      ),
    );
  }
}
