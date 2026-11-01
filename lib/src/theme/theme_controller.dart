import 'package:flutter/material.dart';

import '../storage/settings_store.dart';
import 'palettes.dart';

/// Holds the chosen palette and light/dark mode, and remembers them.
class ThemeController extends ChangeNotifier {
  ThemeController(this._store);

  final SettingsStore _store;

  ThemeMode mode = ThemeMode.system;
  String paletteId = palettes.first.id;

  AppPalette get palette => paletteById(paletteId);

  Future<void> load() async {
    final m = await _store.themeMode();
    mode = ThemeMode.values.firstWhere((e) => e.name == m,
        orElse: () => ThemeMode.system);
    final p = await _store.paletteId();
    if (p != null) paletteId = paletteById(p).id;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    mode = m;
    notifyListeners();
    await _store.setThemeMode(m.name);
  }

  Future<void> setPalette(String id) async {
    paletteId = paletteById(id).id;
    notifyListeners();
    await _store.setPaletteId(paletteId);
  }
}
