import 'package:flutter/material.dart';

import 'numerology_loading_screen.dart';

class NumerologyPaymentScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Ödeme ekranı kaldırıldı. Direkt üretime geç.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NumerologyLoadingScreen(
            readingId: readingId,
            title: "Numeroloji Analizi",
          ),
        ),
      );
    });

    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
