/// Centralized constants for the NOMAD48 application.
library;

class BleConstants {
  BleConstants._();

  static const Duration scanTimeout = Duration(seconds: 15);
  static const Duration probeConnectTimeout = Duration(seconds: 10);
  static const Duration probeFailureResetDelay = Duration(seconds: 5);
  static const Duration adapterStateTimeout = Duration(seconds: 5);
}

class TemperatureThresholds {
  TemperatureThresholds._();

  static const double cold = 10;
  static const double comfortable = 25;
  static const double warm = 35;
}

class BatteryThresholds {
  BatteryThresholds._();

  static const int high = 80;
  static const int medium = 50;
  static const int low = 20;
}

class RssiThresholds {
  RssiThresholds._();

  static const int excellent = -60;
  static const int good = -70;
  static const int fair = -80;

  /// RSSI must change by more than this (dBm) to update sort position.
  static const int sortHysteresis = 5;
}

class HiveBoxNames {
  HiveBoxNames._();

  static const String deviceCache = 'device_cache';
  static const String expansionState = 'expansion_state';
  static const String settings = 'settings';
}

class SettingsKeys {
  SettingsKeys._();

  static const String themeMode = 'theme_mode';
}

class CacheConstants {
  CacheConstants._();

  static const Duration deviceCacheTtl = Duration(hours: 24);
}
