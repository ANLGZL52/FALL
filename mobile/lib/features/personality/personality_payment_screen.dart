import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/device_id_service.dart';
import '../../services/iap_service.dart';
import '../../services/purchase_api.dart' as store; // ✅ FIX: doğru dosya
import '../../widgets/mystic_scaffold.dart';
import 'personality_generating_screen.dart';

class PersonalityPaymentScreen extends StatefulWidget {
  final String readingId;
  final String name;
  final String birthDate;
  final String birthTime;
  final String birthCity;
  final String birthCountry;
  final String question;

  const PersonalityPaymentScreen({
    super.key,
    required this.readingId,
    required this.name,
    required this.birthDate,
    required this.birthTime,
    required this.birthCity,
    required this.birthCountry,
    required this.question,
  });

  @override
  State<PersonalityPaymentScreen> createState() => _PersonalityPaymentScreenState();
}

class _PersonalityPaymentScreenState extends State<PersonalityPaymentScreen> {
  bool _loading = false;
  String? _lastPaymentId;

  static const String _sku = "fall_personality_399";
  static const bool debugUseStoreIap = false;

  Future<store.PaymentVerifyResult> _debugStubVerify({
    required String deviceId,
    required String readingId,
    required String sku,
  }) async {
    final intent = await store.PurchaseApi.createIntent(
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

    return store.PurchaseApi.verify(
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PersonalityGeneratingScreen(
          readingId: widget.readingId,
          name: widget.name,
        ),
      ),
    );
  }

  Future<void> _payAndContinue() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final deviceId = await DeviceIdService.getOrCreate();

      late final store.PaymentVerifyResult verify;

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

      // ✅ verify sonrası backend reading'i paid yaptı -> generate serbest
      await _goGenerating();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ödeme hatası: $e"), behavior: SnackBarBehavior.floating),
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
                    "Kişilik Analizi – Onay",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
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
                      "Bilgilerini kontrol et",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    _row("Ad", widget.name),
                    _row("Doğum", widget.birthDate),
                    _row("Saat", widget.birthTime.isEmpty ? "—" : widget.birthTime),
                    _row("Yer", "${widget.birthCity}, ${widget.birthCountry}"),
                    _row("Not", widget.question.isEmpty ? "—" : widget.question),
                    const SizedBox(height: 10),
                    const Text("Tutar: 399 ₺", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text("SKU: $_sku", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (_lastPaymentId != null) ...[
                      const SizedBox(height: 6),
                      Text("Son işlem: $_lastPaymentId", style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                  onPressed: _loading ? null : _payAndContinue,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Öde → Analizi Başlat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(k, style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(v, style: const TextStyle(color: Colors.white, height: 1.25))),
        ],
      ),
    );
  }
}
