import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

/// Persists and notifies theme mode changes.
///
/// Stores the user's choice (system/light/dark) as an int in Hive.
/// Widgets listen via [addListener] / [ValueListenableBuilder].
class ThemeService extends ValueNotifier<ThemeMode> {
  ThemeService._() : super(_readFromBox());
  static final instance = ThemeService._();

  static ThemeMode _readFromBox() {
    final box = Hive.box<int>(HiveBoxNames.settings);
    final index = box.get(SettingsKeys.themeMode, defaultValue: 0) ?? 0;
    return ThemeMode.values.elementAtOrNull(index) ?? ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    Hive.box<int>(HiveBoxNames.settings).put(SettingsKeys.themeMode, mode.index);
    value = mode;
  }

  /// Cycle: system → light → dark → system.
  void cycle() {
    switch (value) {
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
    }
  }

  IconData get icon {
    switch (value) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  String get label {
    switch (value) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
