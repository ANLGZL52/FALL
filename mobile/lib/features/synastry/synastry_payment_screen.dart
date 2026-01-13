import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/iap_service.dart';
import '../../services/payment_api.dart';
import '../../widgets/mystic_scaffold.dart';
import 'synastry_generating_screen.dart';

class SynastryPaymentScreen extends StatefulWidget {
  final String readingId;
  final String title;

  const SynastryPaymentScreen({
    super.key,
    required this.readingId,
    required this.title,
  });

  @override
  State<SynastryPaymentScreen> createState() => _SynastryPaymentScreenState();
}

class _SynastryPaymentScreenState extends State<SynastryPaymentScreen> {
  bool _loading = false;
  String? _lastPaymentId;

  static const String _sku = "fall_synastry_149";
  static const bool debugUseStoreIap = false;

  Future<PaymentVerifyResult> _debugStubVerify({
    required String deviceId,
    required String readingId,
    required String sku,
  }) async {
    final intent = await PurchaseApi.createIntent(
      deviceId: deviceId,
      readingId: readingId,
      sku: sku,
    );
    _lastPaymentId = intent.paymentId;

    final String platform =
        defaultTargetPlatform == TargetPlatform.iOS ? "app_store" : "google_play";
    final String transactionId = "TXN-DEV-${DateTime.now().millisecondsSinceEpoch}";

    String? purchaseToken;
    String? receiptData;

    if (platform == "google_play") {
      purchaseToken = "DEV_TOKEN_123456";
    } else {
      receiptData = "DEV_RECEIPT_DATA_ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    }

    return PurchaseApi.verify(
      deviceId: deviceId,
      paymentId: intent.paymentId,
      sku: sku,
      platform: platform,
      transactionId: transactionId,
      purchaseToken: purchaseToken,
      receiptData: receiptData,
    );
  }

  Future<void> _goGenerating() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SynastryGeneratingScreen(readingId: widget.readingId),
      ),
    );
  }

  Future<void> _payAndStart() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final deviceId = await DeviceIdService.getOrCreate();

      late final PaymentVerifyResult verify;

      if (kReleaseMode) {
        verify = await IapService.instance.buyAndVerify(
          readingId: widget.readingId,
          sku: _sku,
        );
      } else {
        if (debugUseStoreIap) {
          verify = await IapService.instance.buyAndVerify(
            readingId: widget.readingId,
            sku: _sku,
          );
        } else {
          verify = await _debugStubVerify(
            deviceId: deviceId,
            readingId: widget.readingId,
            sku: _sku,
          );
        }
      }

      _lastPaymentId = verify.paymentId;

      if (!verify.verified) {
        throw Exception("Ödeme doğrulanamadı: ${verify.status}");
      }

      // ✅ verify sonrası backend synastry reading'i paid yaptı
      await _goGenerating();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ödeme/Üretim hatası: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.62,
      patternOpacity: 0.22,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
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
                      "Sinastri (Uyum Analizi)",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Ödeme doğrulandıktan sonra analiz üretimine geçilir.",
                      style: TextStyle(color: Colors.white70, height: 1.25),
                    ),
                    const SizedBox(height: 12),
                    const Text("Tutar: 149 ₺", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text("SKU: $_sku", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (_lastPaymentId != null) ...[
                      const SizedBox(height: 6),
                      Text("Son işlem: $_lastPaymentId", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C361),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _loading ? null : _payAndStart,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Öde → Analizi Başlat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
