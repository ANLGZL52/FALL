import 'package:flutter/material.dart';
import 'numerology_form_screen.dart';

class NumerologyInfoScreen extends StatelessWidget {
  const NumerologyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Bu ekran artık kullanılmıyor. Direkt form'a yönlendir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NumerologyFormScreen()),
      );
    });

    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
