import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/birthchart_api.dart';
import '../../services/device_id_service.dart';
import '../../services/iap_service.dart';
import '../../services/product_catalog.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

import 'birthchart_loading_screen.dart';
import 'birthchart_result_screen.dart';

class BirthChartPaymentScreen extends StatefulWidget {
  final String readingId;

  const BirthChartPaymentScreen({
    super.key,
    required this.readingId,
  });

  @override
  State<BirthChartPaymentScreen> createState() => _BirthChartPaymentScreenState();
}

class _BirthChartPaymentScreenState extends State<BirthChartPaymentScreen> {
  bool _loading = false;
  String? _lastPaymentId;
  String _phase = 'idle';

  static const bool debugUseStoreIap = true;

  Future<void> _goToResult() async {
    if (!mounted) return;
    final deviceId = await DeviceIdService.getOrCreate();
    final reading = await BirthChartApi.detail(readingId: widget.readingId, deviceId: deviceId);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BirthChartResultScreen(reading: reading)),
      );
    }
  }

  Future<void> _goLoading() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BirthChartLoadingScreen(readingId: widget.readingId)),
    );
  }

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _phase = 'preparing';
    });
    try {
      // deviceId sadece IapService içinde de alınsa, burada çağırmak “header hazır” ve debug için iyi.
      final deviceId = await DeviceIdService.getOrCreate();

      await BirthChartApi.generate(readingId: widget.readingId, deviceId: deviceId);
      if (!mounted) return;
      setState(() => _phase = 'paying');

      final shouldUseIap = kReleaseMode || debugUseStoreIap;
      if (shouldUseIap) {
        final verify = await IapService.instance.buyAndVerify(
          readingId: widget.readingId,
          sku: ProductCatalog.birthchart299,
        );

        if (!verify.verified) {
          throw Exception("Ödeme doğrulanamadı: ${verify.status}");
        }

        if (mounted) setState(() => _lastPaymentId = verify.paymentId);
      }

      await _goToResult();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme/Yorum hatası: $e')),
      );
    } finally {
      if (mounted) setState(() {
        _loading = false;
        _phase = 'idle';
      });
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
                  const Text('Doğum Haritası', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  const Text('Yorumunu başlatmak için ödeme adımını tamamla.'),
                  const SizedBox(height: 12),
                  const Text('Tutar: 299 ₺', style: TextStyle(fontWeight: FontWeight.w900)),
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
                  const SizedBox(height: 10),
                  if (!kReleaseMode)
                    Text(
                      'SKU: ${ProductCatalog.birthchart299}',
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
            if (_phase == 'preparing')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Yorumunuz hazırlanıyor, lütfen bekleyin...',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 18),
            GradientButton(
              text: _loading
                  ? (_phase == 'preparing' ? 'Yorumunuz hazırlanıyor...' : 'Ödeme işleniyor...')
                  : 'Ödemeyi Tamamla ✨',
              onPressed: _loading ? null : _pay,
            ),
          ],
        ),
      ),
    );
  }
}
