import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/state/app_state.dart';
import 'src/ui/home_page.dart';
import 'src/ui/login_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..start(),
      child: const UmzSelfApp(),
    ),
  );
}

class UmzSelfApp extends StatelessWidget {
  const UmzSelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      title: s.t('appTitle'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      builder: (context, child) => Directionality(
        textDirection: s.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: switch (s.status) {
        AuthStatus.starting => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        AuthStatus.loggedIn => const HomePage(),
        _ => const LoginPage(),
      },
    );
  }
}
