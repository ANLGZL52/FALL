import 'package:flutter/material.dart';

import '../../services/coffee_api.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mystic_scaffold.dart';
import 'coffee_result_screen.dart';
import '../home/home_screen.dart';

class CoffeeLoadingScreen extends StatefulWidget {
  final String readingId;
  const CoffeeLoadingScreen({super.key, required this.readingId});

  @override
  State<CoffeeLoadingScreen> createState() => _CoffeeLoadingScreenState();
}

class _CoffeeLoadingScreenState extends State<CoffeeLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final String text = await CoffeeApi.generateText(readingId: widget.readingId);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => CoffeeResultScreen(resultText: text)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorum üretilemedi: $e')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.86,
      patternOpacity: 0.12,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 520,
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Fincandaki işaretler çözülüyor...\nFalın hazırlanıyor.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
