import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/root_gate.dart';
import 'screens/splash_screen.dart';
import 'services/secure_window.dart';
import 'services/settings_service.dart';
import 'theme.dart';

class LessonsApp extends StatefulWidget {
  const LessonsApp({super.key});

  @override
  State<LessonsApp> createState() => LessonsAppState();

  static LessonsAppState of(BuildContext context) =>
      context.findAncestorStateOfType<LessonsAppState>()!;
}

class LessonsAppState extends State<LessonsApp> {
  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
    // Keep the Android secure-window flag in sync with the toggle.
    SecureWindow.applyFromSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Apply the persisted screenshot-block setting once the engine is up.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => SecureWindow.applyFromSettings(),
    );
  }

  /// Legacy convenience used by the home-page icon: cycles Light -> Dark -> Light.
  Future<void> toggleTheme() async {
    final current = SettingsService.instance.themeMode;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await SettingsService.instance.setThemeMode(next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studies',
      debugShowCheckedModeBanner: false,
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: SettingsService.instance.themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AnimatedSplash(child: RootGate()),
    );
  }
}
