// lib/features/synastry/synastry_result_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../services/device_id_service.dart';
import '../../services/synastry_api.dart';

class SynastryResultScreen extends StatelessWidget {
  final String readingId;
  final String resultText;

  const SynastryResultScreen({
    super.key,
    required this.readingId,
    required this.resultText,
  });

  Future<void> _downloadAndOpenPdf(BuildContext context) async {
    try {
      final api = SynastryApi();

      final deviceId = await DeviceIdService.getOrCreate();
      final bytes = await api.downloadPdf(readingId, deviceId: deviceId);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/synastry_$readingId.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF hatası: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonuç'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6B15E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _downloadAndOpenPdf(context),
                    child: const Text('PDF İndir & Aç'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1120).withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    resultText,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
