import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/state/app_state.dart';
import 'src/storage/settings_store.dart';
import 'src/theme/palettes.dart';
import 'src/theme/theme_controller.dart';
import 'src/ui/home_page.dart';
import 'src/ui/login_page.dart';
import 'src/ui/widgets/widgets.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..start()),
        ChangeNotifierProvider(
            create: (_) => ThemeController(PrefsSettingsStore())..load()),
      ],
      child: const UmzSelfApp(),
    ),
  );
}

class UmzSelfApp extends StatelessWidget {
  const UmzSelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final theme = context.watch<ThemeController>();
    final palette = theme.palette;

    final Widget home = switch (s.status) {
      AuthStatus.starting => const _Splash(key: ValueKey('splash')),
      AuthStatus.loggedIn => const HomePage(key: ValueKey('home')),
      _ => const LoginPage(key: ValueKey('login')),
    };

    return MaterialApp(
      title: s.t('appTitle'),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette, Brightness.light),
      darkTheme: buildTheme(palette, Brightness.dark),
      themeMode: theme.mode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeOutCubic,
      builder: (context, child) => Directionality(
        textDirection: s.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        child: home,
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: FadeSlideIn(child: AppMark(size: 72))),
      );
}
