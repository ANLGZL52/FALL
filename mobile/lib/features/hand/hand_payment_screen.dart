// mobile/lib/features/hand/hand_payment_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/iap_service.dart';
import '../../services/product_catalog.dart';

import 'hand_loading_screen.dart';

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
  String? _lastPaymentId;

  // ✅ Debug modda store akışını test etmek istersen true
  static const bool debugUseStoreIap = false;

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      // ✅ cihaz id hazır olsun
      await DeviceIdService.getOrCreate();

      final shouldUseIap = kReleaseMode || debugUseStoreIap;

      if (shouldUseIap) {
        final verify = await IapService.instance.buyAndVerify(
          readingId: widget.readingId,
          sku: ProductCatalog.hand39,
        );

        if (!verify.verified) {
          throw Exception("Ödeme doğrulanamadı: ${verify.status}");
        }

        if (mounted) setState(() => _lastPaymentId = verify.paymentId);
      }

      if (!mounted) return;

      // ✅ ödeme sonrası generate burada yok -> Loading ekranı yapacak
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HandLoadingScreen(readingId: widget.readingId),
        ),
      );
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
                  const Text(
                    'Avucundaki çizgiler, karakterin ve yolun hakkında küçük ipuçları taşır.\nŞimdi yorumlayalım.',
                  ),
                  const SizedBox(height: 12),
                  const Text('Tutar: 39 ₺', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '+ vergiler',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vergiler Google Play tarafından ödeme sırasında eklenir.',
                    style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 11, height: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SKU: ${ProductCatalog.hand39}',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                  ),
                  if (_lastPaymentId != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Son işlem: $_lastPaymentId',
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                    ),
                  ],
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
