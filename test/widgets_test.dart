import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:umz_self/src/state/app_state.dart';
import 'package:umz_self/src/theme/palettes.dart';
import 'package:umz_self/src/theme/theme_controller.dart';
import 'package:umz_self/src/ui/settings_page.dart';
import 'package:umz_self/src/ui/widgets/glint_button.dart';
import 'package:umz_self/src/ui/widgets/widgets.dart';

import 'app_state_test.dart' show MemCredentialStore, MemLedgerStore;
import 'theme_test.dart' show MemSettingsStore;

Widget _host(Widget child) => MaterialApp(
      theme: buildTheme(palettes.first, Brightness.dark),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('GlintButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
          GlintButton(label: 'Go', onPressed: () => taps++)));
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('does nothing when disabled', (tester) async {
      await tester
          .pumpWidget(_host(const GlintButton(label: 'Go', onPressed: null)));
      await tester.tap(find.text('Go'), warnIfMissed: false);
      await tester.pumpAndSettle();
      // No exception and still rendered.
      expect(find.text('Go'), findsOneWidget);
    });

    testWidgets('ignores taps while busy and shows a spinner', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
          GlintButton(label: 'Go', busy: true, onPressed: () => taps++)));
      await tester.tap(find.text('Go'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('all three styles render', (tester) async {
      await tester.pumpWidget(_host(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in GlintStyle.values)
            GlintButton(label: s.name, style: s, onPressed: () {}),
        ],
      )));
      for (final s in GlintStyle.values) {
        expect(find.text(s.name), findsOneWidget);
      }
    });
  });

  testWidgets('CountUp ends on the target value', (tester) async {
    await tester.pumpWidget(_host(CountUp(
      value: 1000,
      builder: (context, v) => Text('${v.round()}'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('settings page switches palette and mode', (tester) async {
    final theme = ThemeController(MemSettingsStore());
    final app = AppState(
      store: MemCredentialStore(),
      ledgerStore: MemLedgerStore(),
      settings: MemSettingsStore(),
    )..lang = 'en';

    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: app),
        ChangeNotifierProvider<ThemeController>.value(value: theme),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          theme: buildTheme(theme.palette, Brightness.light),
          darkTheme: buildTheme(theme.palette, Brightness.dark),
          themeMode: context.watch<ThemeController>().mode,
          home: const SettingsPage(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    for (final p in palettes) {
      expect(find.text(p.nameEn), findsOneWidget);
    }

    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    expect(theme.palette.id, 'ocean');

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.dark);

    // Account/auto-reserve sections are hidden while signed out.
    expect(find.text('Sign out'), findsNothing);
  });
}
