import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/coffee_api.dart';
import '../../services/device_id_service.dart';
import '../../services/iap_service.dart';
import '../../services/product_catalog.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

class CoffeePaymentScreen extends StatefulWidget {
  final String readingId;
  const CoffeePaymentScreen({super.key, required this.readingId});

  @override
  State<CoffeePaymentScreen> createState() => _CoffeePaymentScreenState();
}

class _CoffeePaymentScreenState extends State<CoffeePaymentScreen> {
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
          sku: ProductCatalog.coffee49,
        );
        if (!verify.verified) {
          throw Exception("Ödeme doğrulanamadı: ${verify.status}");
        }
      }

      await CoffeeApi.generate(readingId: widget.readingId, deviceId: deviceId);

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
                  const Text('Kahve Falı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text('Falını başlatmak için ödeme adımını tamamla.'),
                  const SizedBox(height: 12),

                  const Text('Tutar: 49 ₺', style: TextStyle(fontWeight: FontWeight.w800)),
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
