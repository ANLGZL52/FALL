import 'package:flutter/material.dart';
import 'personality_form_screen.dart';

class PersonalityInfoScreen extends StatefulWidget {
  const PersonalityInfoScreen({super.key});

  @override
  State<PersonalityInfoScreen> createState() => _PersonalityInfoScreenState();
}

class _PersonalityInfoScreenState extends State<PersonalityInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PersonalityFormScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
