import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umz_self/src/storage/settings_store.dart';
import 'package:umz_self/src/theme/palettes.dart';
import 'package:umz_self/src/theme/theme_controller.dart';

class MemSettingsStore implements SettingsStore {
  String? mode;
  String? palette;
  int? interval;

  @override
  Future<String?> themeMode() async => mode;
  @override
  Future<void> setThemeMode(String m) async => mode = m;
  @override
  Future<String?> paletteId() async => palette;
  @override
  Future<void> setPaletteId(String id) async => palette = id;
  @override
  Future<int?> autoIntervalMinutes() async => interval;
  @override
  Future<void> setAutoIntervalMinutes(int m) async => interval = m;
}

void main() {
  group('palettes', () {
    test('ids are unique and there are at least five', () {
      expect(palettes.map((p) => p.id).toSet().length, palettes.length);
      expect(palettes.length, greaterThanOrEqualTo(5));
    });

    for (final p in palettes) {
      for (final b in Brightness.values) {
        test('${p.id} ${b.name} is readable', () {
          final v = p.variant(b);
          // Text on the page and on cards, and text on the accent fill.
          expect(contrastRatio(textColor(b), v.bg), greaterThanOrEqualTo(7));
          expect(
              contrastRatio(textColor(b), v.surface), greaterThanOrEqualTo(7));
          expect(contrastRatio(onColor(v.accent), v.accent),
              greaterThanOrEqualTo(4.5));
        });

        test('${p.id} ${b.name} builds a theme', () {
          final t = buildTheme(p, b);
          expect(t.brightness, b);
          expect(t.colorScheme.primary, p.variant(b).accent);
          expect(t.scaffoldBackgroundColor, p.variant(b).bg);
        });
      }
    }

    test('neon is black with neon green in dark mode', () {
      final neon = paletteById('neon');
      expect(neon.dark.bg.computeLuminance(), lessThan(0.02));
      expect(neon.dark.accent, const Color(0xFF39FF14));
    });

    test('unknown id falls back to the first palette', () {
      expect(paletteById('nope').id, palettes.first.id);
    });
  });

  group('ThemeController', () {
    test('defaults to system mode and the first palette', () {
      final c = ThemeController(MemSettingsStore());
      expect(c.mode, ThemeMode.system);
      expect(c.palette.id, palettes.first.id);
    });

    test('changes are saved and restored', () async {
      final store = MemSettingsStore();
      final a = ThemeController(store);
      await a.setMode(ThemeMode.dark);
      await a.setPalette('ocean');

      final b = ThemeController(store);
      await b.load();
      expect(b.mode, ThemeMode.dark);
      expect(b.palette.id, 'ocean');
    });

    test('ignores a stale saved palette id', () async {
      final store = MemSettingsStore()
        ..palette = 'deleted'
        ..mode = 'garbage';
      final c = ThemeController(store);
      await c.load();
      expect(c.palette.id, palettes.first.id);
      expect(c.mode, ThemeMode.system);
    });
  });
}
