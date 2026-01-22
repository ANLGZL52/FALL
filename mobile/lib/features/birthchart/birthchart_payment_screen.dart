import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/birthchart_reading.dart';
import '../../services/device_id_service.dart';
import '../../services/iap_service.dart';
import '../../services/payment_api.dart';
import '../../services/birthchart_api.dart';
import '../../services/product_catalog.dart';
import '../../widgets/mystic_scaffold.dart';

import 'birthchart_loading_screen.dart';

class BirthChartPaymentScreen extends StatefulWidget {
  final BirthChartReading reading;
  const BirthChartPaymentScreen({super.key, required this.reading});

  @override
  State<BirthChartPaymentScreen> createState() => _BirthChartPaymentScreenState();
}

class _BirthChartPaymentScreenState extends State<BirthChartPaymentScreen> {
  bool _loading = false;
  String? _lastPaymentId;

  static const double _amount = 299.0;

  // ✅ Play Console ile birebir
  static const bool debugUseStoreIap = false;

  String get _sku => ProductCatalog.birthchart299;

  Future<void> _goLoading() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BirthChartLoadingScreen(
          readingId: widget.reading.id,
          title: "Doğum haritan hazırlanıyor...",
        ),
      ),
    );
  }

  /// ✅ Debug/Local: legacy mock
  Future<void> _payLegacyMock(String deviceId) async {
    final res = await PaymentApi.startPayment(
      readingId: widget.reading.id,
      amount: _amount,
      product: "birthchart",
      deviceId: deviceId,
    );

    if (!res.ok) throw Exception("Ödeme başarısız: ${res.provider}");

    if (mounted) {
      setState(() => _lastPaymentId = res.paymentId);
    } else {
      _lastPaymentId = res.paymentId;
    }

    await BirthChartApi.markPaid(
      readingId: widget.reading.id,
      paymentRef: res.paymentId,
      deviceId: deviceId,
    );

    await _goLoading();
  }

  /// ✅ Release: Store/IAP + backend verify
  Future<void> _payStoreIap() async {
    final verify = await IapService.instance.buyAndVerify(
      readingId: widget.reading.id,
      sku: _sku,
    );

    if (!verify.verified) {
      throw Exception("Ödeme doğrulanamadı: ${verify.status}");
    }

    if (mounted) {
      setState(() => _lastPaymentId = verify.paymentId);
    } else {
      _lastPaymentId = verify.paymentId;
    }

    // verify sonrası backend paid yaptı -> loading ekranı generate/poll yapmalı
    await _goLoading();
  }

  Future<void> _payAndStart() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final deviceId = await DeviceIdService.getOrCreate();

      final shouldUseIap = kReleaseMode || debugUseStoreIap;

      if (shouldUseIap) {
        await _payStoreIap();
      } else {
        await _payLegacyMock(deviceId);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ödeme hatası: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reading;

    return MysticScaffold(
      scrimOpacity: 0.62,
      patternOpacity: 0.22,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    "Doğum Haritası – Özet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bilgiler",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("Ad: ${r.name}", style: const TextStyle(color: Colors.white)),
                    Text("Doğum: ${r.birthDate}", style: const TextStyle(color: Colors.white)),
                    Text("Saat: ${r.birthTime ?? "—"}", style: const TextStyle(color: Colors.white)),
                    Text("Yer: ${r.birthCity}, ${r.birthCountry}", style: const TextStyle(color: Colors.white)),
                    Text("Konu: ${r.topic}", style: const TextStyle(color: Colors.white)),
                    Text("Soru: ${r.question ?? "—"}", style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),

                    const Text(
                      "Tutar: 299 ₺",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "+ vergiler",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Vergiler Google Play tarafından ödeme sırasında eklenir.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text("SKU: $_sku", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (_lastPaymentId != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Son işlem: $_lastPaymentId",
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C361),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _loading ? null : _payAndStart,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Öde → Yorumu Üret", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
