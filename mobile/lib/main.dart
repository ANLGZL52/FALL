import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'features/home/home_screen.dart';

// ✅ Synastry
import 'features/synastry/synastry_intro_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FallApp());
}

class FallApp extends StatelessWidget {
  const FallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),

      // ✅ Varsayılan dil: Türkçe
      locale: const Locale('tr', 'TR'),

      // ✅ Desteklenen diller
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],

      // ✅ Flutter localization delegeleri
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ✅ Named routes (home’u bozmadan ekledik)
      routes: {
        '/synastry': (_) => const SynastryIntroScreen(),
      },
    );
  }
}
