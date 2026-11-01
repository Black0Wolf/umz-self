import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret app preferences.
abstract class SettingsStore {
  Future<String?> themeMode();
  Future<void> setThemeMode(String mode);
  Future<String?> paletteId();
  Future<void> setPaletteId(String id);
  Future<int?> autoIntervalMinutes();
  Future<void> setAutoIntervalMinutes(int minutes);
}

class PrefsSettingsStore implements SettingsStore {
  static const _kMode = 'theme_mode';
  static const _kPalette = 'palette_id';
  static const _kInterval = 'auto_interval_min';

  @override
  Future<String?> themeMode() async =>
      (await SharedPreferences.getInstance()).getString(_kMode);

  @override
  Future<void> setThemeMode(String mode) async =>
      (await SharedPreferences.getInstance()).setString(_kMode, mode);

  @override
  Future<String?> paletteId() async =>
      (await SharedPreferences.getInstance()).getString(_kPalette);

  @override
  Future<void> setPaletteId(String id) async =>
      (await SharedPreferences.getInstance()).setString(_kPalette, id);

  @override
  Future<int?> autoIntervalMinutes() async =>
      (await SharedPreferences.getInstance()).getInt(_kInterval);

  @override
  Future<void> setAutoIntervalMinutes(int minutes) async =>
      (await SharedPreferences.getInstance()).setInt(_kInterval, minutes);
}
