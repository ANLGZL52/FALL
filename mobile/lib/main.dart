import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const FallApp());
}

class FallApp extends StatelessWidget {
  const FallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MysticAura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const HomeScreen(),
    );
  }
}
