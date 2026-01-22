import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lunaura/widgets/mystic_scaffold.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../services/device_id_service.dart';
import '../../services/personality_api.dart';

class PersonalityResultScreen extends StatefulWidget {
  final PersonalityReading reading;
  final String title;

  const PersonalityResultScreen({
    super.key,
    required this.reading,
    this.title = "Kişilik Analizi",
  });

  @override
  State<PersonalityResultScreen> createState() => _PersonalityResultScreenState();
}

class _PersonalityResultScreenState extends State<PersonalityResultScreen> {
  bool _downloading = false;
  bool _retrying = false;
  bool _ratingSending = false;

  int? _selectedRating;

  String get _resultText => (widget.reading.resultText ?? "").trim();

  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      final bytes = await PersonalityApi.downloadPdfBytes(
        readingId: widget.reading.id,
        deviceId: deviceId,
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/personality_${widget.reading.id}.pdf");
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF kaydedildi: ${file.path}"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF indirilemedi: $e"), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _retryGenerate() async {
    setState(() => _retrying = true);
    try {
      final deviceId = await DeviceIdService.getOrCreate();

      // backend idempotent: completed ise direkt döner
      final updated = await PersonalityApi.generate(
        readingId: widget.reading.id,
        deviceId: deviceId,
      );

      if (!mounted) return;

      // aynı ekranı yeni veriyle yenile
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonalityResultScreen(
            reading: updated,
            title: widget.title,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tekrar denenemedi: $e"), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _sendRating(int rating) async {
    setState(() {
      _ratingSending = true;
      _selectedRating = rating;
    });

    try {
      final deviceId = await DeviceIdService.getOrCreate();

      await PersonalityApi.rate(
        readingId: widget.reading.id,
        rating: rating,
        deviceId: deviceId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teşekkürler! Puanın kaydedildi."), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Puan gönderilemedi: $e"), behavior: SnackBarBehavior.floating),
      );
      // başarısızsa seçimi geri al
      if (mounted) setState(() => _selectedRating = null);
    } finally {
      if (mounted) setState(() => _ratingSending = false);
    }
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
  }

  Widget _ratingStars() {
    final current = _selectedRating ?? widget.reading.rating;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = (current ?? 0) >= idx;

        return IconButton(
          onPressed: (_ratingSending || _resultText.isEmpty) ? null : () => _sendRating(idx),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? const Color(0xFFF5C361) : Colors.white70,
          ),
          tooltip: "$idx/5",
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.reading.status).toString();

    final showRetry = _resultText.isEmpty || status == "paid" || status == "processing";

    return PopScope(
      canPop: false,
      child: MysticScaffold(
        scrimOpacity: 0.62,
        patternOpacity: 0.22,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 52),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _downloading ? null : _downloadPdf,
                    icon: _downloading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
                    tooltip: "PDF indir",
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ✅ mini durum satırı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Durum: $status",
                    style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _resultText.isEmpty
                            ? "Yorum henüz hazır değil.\n\n"
                                "Eğer ödeme aldıysan ama burada boş görüyorsan, aşağıdan Tekrar Dene’ye bas."
                            : _resultText,
                        style: const TextStyle(color: Colors.white, height: 1.35),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ✅ rating
              if (_resultText.isNotEmpty) ...[
                Text("Bu analizi puanla", style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                _ratingStars(),
              ],

              const SizedBox(height: 6),

              // ✅ Retry butonu (boş / paid / processing)
              if (showRetry)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.10),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      onPressed: (_retrying || _downloading) ? null : _retryGenerate,
                      child: _retrying
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Tekrar Dene (Yorumu Üret)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),

              // ✅ PDF indir
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.10),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    onPressed: _downloading ? null : _downloadPdf,
                    child: _downloading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("PDF İndir", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),

              // ✅ home
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C361),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadiusRadius.circular(16)),
                    ),
                    onPressed: _goHome,
                    child: const Text("Ana Sayfaya Dön", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
