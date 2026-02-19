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
  final List<String> _skus = ProductCatalog.allSkus.toList();

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
        _lastInfo = '✅ Verify OK: verified=${res.verified}, status=${res.status}, paymentId=${res.paymentId}';
      });
    } catch (e) {
      setState(() => _lastError = 'Satın alma/verify hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      appBar: AppBar(title: const Text('IAP Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: _checking ? null : _checkAndLoad,
              child: Text(_checking ? 'Kontrol ediliyor...' : 'IAP Kontrol + Ürünleri Çek'),
            ),
            const SizedBox(height: 12),
            Text('IAP Available: ${_iapAvailable ?? '-'}'),
            if (_lastInfo != null) Text(_lastInfo!, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (_lastError != null) Text(_lastError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            for (final e in _products.entries)
              ListTile(
                title: Text('${e.key} — ${e.value.title}'),
                subtitle: Text('${e.value.price} / ${e.value.description}'),
                trailing: TextButton(
                  onPressed: () => _buyTest(e.key),
                  child: const Text('BUY'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
