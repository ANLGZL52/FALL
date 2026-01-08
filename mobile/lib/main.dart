import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';

import 'core/app_theme.dart';
import 'features/home/home_screen.dart';

// ✅ Synastry
import 'features/synastry/synastry_intro_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // debug modda açık
      builder: (context) => const FallApp(),
    ),
  );
}

class FallApp extends StatelessWidget {
  const FallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ DevicePreview için gerekli
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: AppTheme.dark(),

      // ✅ İlk ekran
      home: const HomeScreen(),

      // ✅ TR/EN
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ✅ Named routes (Ana sayfaya dön gibi yerler için)
      routes: {
        '/home': (_) => const HomeScreen(),
        '/synastry': (_) => const SynastryIntroScreen(),
      },
    );
  }
}
