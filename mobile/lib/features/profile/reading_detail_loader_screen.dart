import 'package:flutter/material.dart';

import '../../services/birthchart_api.dart';
import '../../services/coffee_api.dart';
import '../../services/device_id_service.dart';
import '../../services/numerology_api.dart';
import '../../services/synastry_api.dart';
import '../../services/tarot_api.dart';

import '../../models/birthchart_reading.dart';
import '../birthchart/birthchart_result_screen.dart';
import '../coffee/coffee_result_screen.dart';
import '../numerology/numerology_result_screen.dart';
import '../synastry/synastry_result_screen.dart';
import '../tarot/tarot_deck.dart';
import '../tarot/tarot_models.dart';
import '../tarot/tarot_result_screen.dart';
import '../../widgets/mystic_scaffold.dart';

/// Profil "Benim Okumalarım"dan tıklanınca açılır. readingId + type ile
/// ilgili API'den detay çeker ve uygun sonuç ekranına yönlendirir.
class ReadingDetailLoaderScreen extends StatefulWidget {
  final String readingId;
  final String type;
  /// Profilde zaten varsa, API boş dönse bile bunu kullan
  final String? prefetchedResultText;

  const ReadingDetailLoaderScreen({
    super.key,
    required this.readingId,
    required this.type,
    this.prefetchedResultText,
  });

  @override
  State<ReadingDetailLoaderScreen> createState() => _ReadingDetailLoaderScreenState();
}

class _ReadingDetailLoaderScreenState extends State<ReadingDetailLoaderScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _deviceId() async {
    return DeviceIdService.getOrCreate();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
    Navigator.of(context).pop();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final deviceId = await _deviceId();

      switch (widget.type) {
        case 'coffee':
          await _openCoffee(deviceId);
          break;
        case 'tarot':
          await _openTarot(deviceId);
          break;
        case 'numerology':
          await _openNumerology(deviceId);
          break;
        case 'birthchart':
          await _openBirthChart(deviceId);
          break;
        case 'synastry':
          await _openSynastry(deviceId);
          break;
        default:
          _showError('Bu okuma türü desteklenmiyor: ${widget.type}');
          return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
        _showError('Okuma yüklenemedi: $e');
      }
    }
  }

  Future<void> _openCoffee(String deviceId) async {
    final d = await CoffeeApi.detailRaw(readingId: widget.readingId, deviceId: deviceId);
    var text = ((d['comment'] ?? d['result_text']) ?? '').toString().trim();
    if (text.isEmpty && (widget.prefetchedResultText ?? '').trim().isNotEmpty) {
      text = widget.prefetchedResultText!.trim();
    }
    if (text.isEmpty) {
      _showError('Bu okuma henüz hazır değil.');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CoffeeResultScreen(resultText: text)),
    );
  }

  Future<void> _openTarot(String deviceId) async {
    final d = await TarotApi.detail(readingId: widget.readingId, deviceId: deviceId);
    var resultText = (d['result_text'] ?? '').toString().trim();
    if (resultText.isEmpty && (widget.prefetchedResultText ?? '').trim().isNotEmpty) {
      resultText = widget.prefetchedResultText!.trim();
    }
    if (resultText.isEmpty) {
      _showError('Bu okuma henüz hazır değil.');
      return;
    }
    final question = (d['question'] ?? '').toString();
    final spreadStr = (d['spread_type'] ?? 'three').toString().toLowerCase();
    TarotSpreadType spreadType = TarotSpreadType.three;
    if (spreadStr == 'six') spreadType = TarotSpreadType.six;
    if (spreadStr == 'twelve') spreadType = TarotSpreadType.twelve;

    final rawCards = d['selected_cards'];
    List<TarotCard> selectedCards = [];
    if (rawCards is List) {
      selectedCards = TarotDeck.cardsFromApiList(rawCards);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TarotResultScreen(
          question: question,
          spreadType: spreadType,
          selectedCards: selectedCards,
          resultText: resultText,
        ),
      ),
    );
  }

  Future<void> _openNumerology(String deviceId) async {
    final r = await NumerologyApi.get(readingId: widget.readingId, deviceId: deviceId);
    var resultText = (r.resultText ?? '').trim();
    if (resultText.isEmpty && (widget.prefetchedResultText ?? '').trim().isNotEmpty) {
      resultText = widget.prefetchedResultText!.trim();
    }
    if (resultText.isEmpty) {
      _showError('Bu okuma henüz hazır değil.');
      return;
    }
    final title = (r.topic ?? 'Numeroloji').toString().trim();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NumerologyResultScreen(
          title: title.isEmpty ? 'Numeroloji' : title,
          resultText: resultText,
        ),
      ),
    );
  }

  Future<void> _openBirthChart(String deviceId) async {
    final reading = await BirthChartApi.detail(readingId: widget.readingId, deviceId: deviceId);
    final hasResult = (reading.resultText ?? '').trim().isNotEmpty;
    final hasPrefetched = (widget.prefetchedResultText ?? '').trim().isNotEmpty;
    if (!hasResult && hasPrefetched) {
      final fallback = BirthChartReading(
        id: reading.id,
        topic: reading.topic,
        question: reading.question,
        name: reading.name,
        birthDate: reading.birthDate,
        birthTime: reading.birthTime,
        birthCity: reading.birthCity,
        birthCountry: reading.birthCountry,
        status: reading.status,
        resultText: widget.prefetchedResultText!.trim(),
        isPaid: reading.isPaid,
        paymentRef: reading.paymentRef,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BirthChartResultScreen(reading: fallback)),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BirthChartResultScreen(reading: reading)),
    );
  }

  Future<void> _openSynastry(String deviceId) async {
    final api = SynastryApi();
    final status = await api.getStatus(widget.readingId, deviceId: deviceId);
    var resultText = (status.resultText ?? '').trim();
    if (resultText.isEmpty && (widget.prefetchedResultText ?? '').trim().isNotEmpty) {
      resultText = widget.prefetchedResultText!.trim();
    }
    if (resultText.isEmpty) {
      _showError('Bu okuma henüz hazır değil.');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SynastryResultScreen(
          readingId: widget.readingId,
          resultText: resultText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.70,
      patternOpacity: 0.22,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(height: 16),
                    Text('Okuma yükleniyor...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            if (_error != null && !_loading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: TextStyle(color: Colors.orange.shade200, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
