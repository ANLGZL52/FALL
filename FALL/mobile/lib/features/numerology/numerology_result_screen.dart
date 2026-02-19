import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';
import '../home/home_screen.dart'; // ✅ Home import (path sende farklıysa düzelt)

class NumerologyResultScreen extends StatelessWidget {
  final String title;
  final String resultText;

  const NumerologyResultScreen({
    super.key,
    required this.title,
    required this.resultText,
  });

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ Android fiziksel back + swipe back yakalanır
      onWillPop: () async {
        _goHome(context);
        return false; // geri dönmeyi engelle
      },
      child: MysticScaffold(
        scrimOpacity: 0.62,
        patternOpacity: 0.22,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    // ✅ Üst ok da Home’a atsın
                    onPressed: () => _goHome(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                        resultText.isEmpty ? "Yorum boş döndü." : resultText,
                        style: const TextStyle(color: Colors.white, height: 1.35),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
