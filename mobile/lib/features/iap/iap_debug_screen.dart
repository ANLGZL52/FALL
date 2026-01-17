// lib/features/iap/iap_debug_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../services/iap_service.dart';
import '../../services/product_catalog.dart';
import '../../widgets/mystic_scaffold.dart';

class IapDebugScreen extends StatefulWidget {
  const IapDebugScreen({super.key});

  @override
  State<IapDebugScreen> createState() => _IapDebugScreenState();
}

class _IapDebugScreenState extends State<IapDebugScreen> {
  final List<String> _skus = ProductCatalog.all;

  bool _checking = false;
  bool? _iapAvailable;

  Map<String, ProductDetails> _products = {};
  String? _lastError;
  String? _lastInfo;

  Future<void> _checkAndLoad() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _lastError = null;
      _lastInfo = null;
    });

    try {
      final available = await InAppPurchase.instance.isAvailable();
      setState(() => _iapAvailable = available);

      if (!available) {
        setState(() {
          _lastError =
              'IAP available değil. (Cihazda Play Store yok, test dağıtımı yok, test hesabı yok, veya internal build değil.)';
        });
        return;
      }

      final map = await IapService.instance.loadProducts(_skus.toSet());

      setState(() {
        _products = map;
        _lastInfo = 'queryProductDetails OK. Bulunan ürün sayısı: ${map.length}';
      });

      if (map.isEmpty) {
        setState(() {
          _lastError =
              'Ürün bulunamadı. Play Console ürünleri "Aktif" mi? Internal Testing ile kurulu mu? Product ID birebir aynı mı?';
        });
      }
    } catch (e) {
      setState(() => _lastError = 'Hata: $e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _buyTest(String sku) async {
    final controller = TextEditingController();

    final readingId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test satın alma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu SKU için satın alma başlatılacak.\n'
              'Intent oluşturmak için readingId gerekli.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'readingId',
                hintText: 'örn: 8f3a... (start endpointinden gelen)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Devam'),
          ),
        ],
      ),
    );

    if (readingId == null || readingId.trim().isEmpty) return;

    setState(() {
      _lastError = null;
      _lastInfo = 'Satın alma başlatılıyor: sku=$sku, readingId=$readingId';
    });

    try {
      final res = await IapService.instance.buyAndVerify(
        readingId: readingId,
        sku: sku,
      );

      setState(() {
        _lastInfo =
            '✅ Verify OK: verified=${res.verified}, status=${res.status}, paymentId=${res.paymentId}';
      });
    } catch (e) {
      setState(() => _lastError = 'Satın alma/verify hatası: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_checkAndLoad());
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.70,
      patternOpacity: 0.18,
      appBar: AppBar(
        title: const Text('IAP Debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),
          const SizedBox(height: 12),
          _statusCard(),
          const SizedBox(height: 12),
          _productsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ne işe yarar?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '1) isAvailable\n'
            '2) queryProductDetails (SKU görünür mü)\n'
            '3) buy + purchaseStream + backend verify\n\n'
            'En sağlıklısı: gerçek cihaz + Internal Testing ile test.',
            style: TextStyle(color: Colors.white.withOpacity(0.78), height: 1.25),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _checking ? null : _checkAndLoad,
                  child: Text(_checking ? 'Kontrol ediliyor...' : 'Tekrar Kontrol Et'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final availableText = (_iapAvailable == null)
        ? '—'
        : (_iapAvailable == true ? 'true ✅' : 'false ❌');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Durum',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'IAP isAvailable: $availableText',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          if (_lastInfo != null)
            Text(
              _lastInfo!,
              style: TextStyle(color: Colors.white.withOpacity(0.80)),
            ),
          if (_lastError != null) ...[
            const SizedBox(height: 8),
            Text(
              _lastError!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _productsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ürünler (queryProductDetails)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ..._skus.map((sku) {
            final p = _products[sku];
            final found = p != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: found ? Colors.white12 : Colors.redAccent.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sku,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    found
                        ? '${p.title}\n${p.description}\nPrice: ${p.price}'
                        : '❌ Bu SKU store’da görünmüyor.',
                    style: TextStyle(color: Colors.white.withOpacity(0.78), height: 1.25),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: found && (_iapAvailable == true) ? () => _buyTest(sku) : null,
                          child: const Text('BUY + VERIFY (Test)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
