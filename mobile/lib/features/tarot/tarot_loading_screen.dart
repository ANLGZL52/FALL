import 'package:flutter/material.dart';

import '../../widgets/mystic_scaffold.dart';
import 'tarot_models.dart';
import 'tarot_select_screen.dart';

class TarotLoadingScreen extends StatefulWidget {
  final String question;
  final TarotSpreadType spreadType;

  const TarotLoadingScreen({
    super.key,
    required this.question,
    required this.spreadType,
  });

  @override
  State<TarotLoadingScreen> createState() => _TarotLoadingScreenState();
}

class _TarotLoadingScreenState extends State<TarotLoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TarotSelectScreen(
            question: widget.question,
            spreadType: widget.spreadType,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MysticScaffold(
      scrimOpacity: 0.78,
      patternOpacity: 0.16,
      appBar: AppBar(title: Text(widget.spreadType.title)),
      body: const Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
