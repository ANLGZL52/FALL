import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fall_app/widgets/mystic_scaffold.dart';
import 'package:fall_app/services/personality_api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PersonalityResultScreen extends StatefulWidget {
  final String readingId;
  final String title;
  final String resultText;

  const PersonalityResultScreen({
    super.key,
    required this.readingId,
    required this.title,
    required this.resultText,
  });

  @override
  State<PersonalityResultScreen> createState() => _PersonalityResultScreenState();
}

class _PersonalityResultScreenState extends State<PersonalityResultScreen> {
  bool _downloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    try {
      final bytes = await PersonalityApi.downloadPdfBytes(readingId: widget.readingId);

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/personality_${widget.readingId}.pdf");
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

  void _goHome() {
    // Route adın farklıysa burada değiştir:
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ✅ sistem back kapalı
      child: MysticScaffold(
        scrimOpacity: 0.62,
        patternOpacity: 0.22,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 52), // back yok
                  Expanded(
                    child: Text(
                      widget.title, // "Kişilik Analizi"
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
                        widget.resultText.isEmpty ? "Yorum boş döndü." : widget.resultText,
                        style: const TextStyle(color: Colors.white, height: 1.35),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

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

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C361),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
