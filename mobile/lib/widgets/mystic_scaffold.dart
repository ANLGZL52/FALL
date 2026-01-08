import 'package:flutter/material.dart';
import 'mystic_background.dart';

class MysticScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  /// Arka plan karartma
  final double scrimOpacity;

  /// Arka plan mistik doku yoğunluğu
  final double patternOpacity;

  const MysticScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.scrimOpacity = 0.60,
    this.patternOpacity = 0.10,
  });

  @override
  Widget build(BuildContext context) {
    final appBarH = appBar?.preferredSize.height ?? kToolbarHeight;

    return MysticBackground(
      scrimOpacity: scrimOpacity,
      patternOpacity: patternOpacity,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: appBar,

        // ✅ ÇAKIŞMA FIX:
        // extendBodyBehindAppBar olduğu için body AppBar'ın altına giriyor.
        // SafeArea status bar'ı çözer ama AppBar yüksekliğini çözmez.
        // O yüzden top padding veriyoruz.
        body: SafeArea(
          top: true,
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(top: appBar != null ? appBarH : 0),
            child: body,
          ),
        ),

        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
