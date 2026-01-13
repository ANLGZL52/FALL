import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/iap_service.dart';
import '../../services/payment_api.dart';
import '../../services/numerology_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mystic_scaffold.dart';

import 'numerology_loading_screen.dart';

class NumerologyPaymentScreen extends StatefulWidget {
  final String readingId;
  final String name;
  final String birthDate;
  final String question;

  const NumerologyPaymentScreen({
    super.key,
    required this.readingId,
    required this.name,
    required this.birthDate,
    required this.question,
  });

  @override
  State<NumerologyPaymentScreen> createState() => _NumerologyPaymentScreenState();
}

class _NumerologyPaymentScreenState extends State<NumerologyPaymentScreen> {
  bool _loading = false;
  String? _lastPaymentId;

  static const double _amount = 299.0;
  static const String _sku = "fall_numerology_299";

  Future<void> _goLoading() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NumerologyLoadingScreen(
          readingId: widget.readingId,
          title: "Numeroloji Analizi",
        ),
      ),
    );
  }

  /// ✅ Debug/Local: mevcut düzen bozulmasın diye legacy start + markPaid
  Future<void> _payLegacyMock(String deviceId) async {
    final res = await PaymentApi.startPayment(
      readingId: widget.readingId,
      amount: _amount,
      product: "numerology",
      deviceId: deviceId,
    );

    if (!res.ok) throw Exception("Ödeme başarısız: ${res.provider}");
    _lastPaymentId = res.paymentId;

    // Numerology endpoint (legacy unlock)
    await NumerologyApi.markPaid(
      readingId: widget.readingId,
      paymentRef: res.paymentId, // TEST-...
      deviceId: deviceId,
    );

    await _goLoading();
  }

  /// ✅ Release: Store satın alma + backend verify
  Future<void> _payStoreIap(String deviceId) async {
    final verify = await IapService.instance.buyAndVerify(
      readingId: widget.readingId,
      sku: _sku,
    );

    if (!verify.verified) {
      throw Exception("Ödeme doğrulanamadı: ${verify.status}");
    }

    _lastPaymentId = verify.paymentId;

    // verify sonrası backend server-side paid yaptı -> generate serbest
    await _goLoading();
  }

  Future<void> _payAndStart() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final deviceId = await DeviceIdService.getOrCreate();

      // ✅ KURAL:
      // - Release: Store/IAP çalışsın
      // - Debug: Legacy çalışsın (istersen store test edebilirsin)
      const bool debugUseStoreIap = false;

      if (kReleaseMode) {
        await _payStoreIap(deviceId);
      } else {
        if (debugUseStoreIap) {
          await _payStoreIap(deviceId);
        } else {
          await _payLegacyMock(deviceId);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ödeme hatası: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.82,
      patternOpacity: 0.18,
      appBar: AppBar(title: const Text("Ödeme")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Numeroloji Analizi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Ad: ${widget.name}\n"
                    "Doğum: ${widget.birthDate}\n"
                    "Soru: ${widget.question.isEmpty ? "—" : widget.question}",
                    style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.25),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tutar: 299 ₺",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SKU: $_sku",
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_lastPaymentId != null)
              Text(
                "Son işlem: $_lastPaymentId",
                style: TextStyle(color: Colors.white.withOpacity(0.75)),
              ),
            const SizedBox(height: 18),
            GradientButton(
              text: _loading ? "İşleniyor..." : "Ödemeyi Başlat ve Analizi Gör ✨",
              onPressed: _loading ? null : _payAndStart,
            ),
            const SizedBox(height: 10),
            Text(
              "Ödeme doğrulandıktan sonra analiz üretimine geçilir.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
