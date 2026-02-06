import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import '../constants/app_constants.dart';
import '../models/ble_manufacturer.dart';

/// Centralized brand icon and color resolution for BLE devices.
///
/// Priority: device type drives the main icon; brand logo is a fallback
/// or shown as a small badge overlay.
class BrandIcons {
  BrandIcons._();

  // -- Brand icon mapping (SimpleIcons) --

  static const _brandIcons = <String, IconData>{
    'Apple': SimpleIcons.apple,
    'Samsung': SimpleIcons.samsung,
    'Google': SimpleIcons.google,
    'LG': SimpleIcons.lg,
    'LG Electronics': SimpleIcons.lg,
    'Sony': SimpleIcons.sony,
    'Bose': SimpleIcons.bose,
    'Xiaomi': SimpleIcons.xiaomi,
    'Xiaomi Communications': SimpleIcons.xiaomi,
    'Nokia': SimpleIcons.nokia,
    'Huawei': SimpleIcons.huawei,
    'Fitbit': SimpleIcons.fitbit,
    'Garmin': SimpleIcons.garmin,
    'Amazon': SimpleIcons.amazon,
    'Sonos': SimpleIcons.sonos,
    'Philips': SimpleIcons.philipshue,
    'Logitech': SimpleIcons.logitech,
    'JBL': SimpleIcons.jbl,
  };

  // -- Device type → icon mapping --

  static const _deviceTypeIcons = <String, IconData>{
    'AirPods': Icons.headphones,
    'Earbuds': Icons.headphones,
    'Audio': Icons.headphones,
    'Headphones': Icons.headphones,
    'Beats': Icons.headphones,
    'Watch': Icons.watch,
    'Wearable': Icons.watch,
    'iPhone': Icons.phone_iphone,
    'Phone': Icons.phone_iphone,
    'iPad': Icons.tablet,
    'Tablet': Icons.tablet,
    'Mac': Icons.laptop,
    'Apple Device': Icons.devices,
    'Apple TV': Icons.tv,
    'TV': Icons.tv,
    'Speaker': Icons.speaker,
    'HomePod': Icons.speaker,
    'Soundbar': Icons.surround_sound,
    'Beacon': Icons.cell_tower,
    'Keyboard': Icons.keyboard,
    'Mouse': Icons.mouse,
    'Peripheral': Icons.mouse,
    'HID Peripheral': Icons.mouse,
    'Tracker': Icons.location_on,
    'Smart Home': Icons.lightbulb,
    'Smart Light': Icons.lightbulb,
    'LED/Sensor': Icons.lightbulb,
    'Sensor': Icons.thermostat,
    'Environment Sensor': Icons.thermostat,
    'Thermometer': Icons.thermostat,
    'Heart Rate Monitor': Icons.favorite,
    'Running Sensor': Icons.favorite,
    'Cycling Sensor': Icons.favorite,
    'Printer': Icons.print,
  };

  // -- Brand color mapping (light / dark pairs) --
  // Colors that are fine in both modes use a single value.

  static const _lightColors = <String, Color>{
    'Apple': Color(0xFF555555),
    'Samsung': SimpleIconColors.samsung,
    'Google': SimpleIconColors.google,
    'LG': SimpleIconColors.lg,
    'LG Electronics': SimpleIconColors.lg,
    'Sony': Color(0xFF333333),
    'Bose': Color(0xFF1A1A1A),
    'Xiaomi': SimpleIconColors.xiaomi,
    'Nokia': SimpleIconColors.nokia,
    'Huawei': SimpleIconColors.huawei,
    'Fitbit': SimpleIconColors.fitbit,
    'Garmin': Color(0xFF333333),
    'Amazon': Color(0xFFFF9900),
    'Sonos': Color(0xFF333333),
    'Philips': SimpleIconColors.philipshue,
    'Microsoft': Color(0xFF737373),
    'Logitech': SimpleIconColors.logitech,
    'JBL': SimpleIconColors.jbl,
    'ThermoBeacon': Color(0xFFFF5722), // deepOrange
  };

  static const _darkColors = <String, Color>{
    'Apple': Color(0xFFB0B0B0),
    'Samsung': Color(0xFF5B8DEE),
    'Google': SimpleIconColors.google,
    'LG': Color(0xFFFF4D6A),
    'LG Electronics': Color(0xFFFF4D6A),
    'Sony': Color(0xFFB0B0B0),
    'Bose': Color(0xFFB0B0B0),
    'Xiaomi': SimpleIconColors.xiaomi,
    'Nokia': Color(0xFF6699FF),
    'Huawei': Color(0xFFFF5555),
    'Fitbit': SimpleIconColors.fitbit,
    'Garmin': Color(0xFFB0B0B0),
    'Amazon': Color(0xFFFFAA44),
    'Sonos': Color(0xFFB0B0B0),
    'Philips': Color(0xFF66AAFF),
    'Microsoft': Color(0xFFA0A0A0),
    'Logitech': SimpleIconColors.logitech,
    'JBL': SimpleIconColors.jbl,
    'ThermoBeacon': Color(0xFFFF5722),
  };

  /// Resolve the primary display icon for a device.
  ///
  /// Device type takes priority (AirPods → headphones, TV → tv, Watch → watch).
  /// Brand icon is only used when deviceType is generic ('Device' or null).
  static IconData resolveIcon(BleDeviceInfo info, {bool connectable = false}) {
    // Device-type-specific icons first
    final typeIcon = _deviceTypeIcons[info.deviceType];
    if (typeIcon != null) return typeIcon;

    // For generic 'Device' or 'BLE Device', try brand icon
    final brandIcon = getBrandIcon(info.manufacturer);
    if (brandIcon != null) return brandIcon;

    // Fallback
    return connectable ? Icons.bluetooth : Icons.bluetooth_disabled;
  }

  /// Get the SimpleIcons brand logo for a manufacturer, or null.
  static IconData? getBrandIcon(String? manufacturer) {
    if (manufacturer == null) return null;
    return _brandIcons[manufacturer];
  }

  /// Get brightness-aware brand color for a manufacturer.
  ///
  /// Many brand colors (Apple black, Sony black, Bose black) are invisible
  /// in dark mode, so we lighten them.
  static Color getBrandColor(String? manufacturer, {required bool isDark}) {
    if (manufacturer == null) return Colors.grey;
    final colors = isDark ? _darkColors : _lightColors;
    return colors[manufacturer] ?? Colors.grey;
  }

  /// Build RSSI signal strength bars widget.
  ///
  /// 4 bars: >= -60 dBm = 4 bars (green), >= -70 = 3 (yellow),
  /// >= -80 = 2 (orange), < -80 = 1 (red).
  static Widget signalBars(int rssi, {double height = 14.0}) {
    final int bars;
    final Color color;
    if (rssi >= RssiThresholds.excellent) {
      bars = 4;
      color = Colors.green;
    } else if (rssi >= RssiThresholds.good) {
      bars = 3;
      color = Colors.yellow.shade700;
    } else if (rssi >= RssiThresholds.fair) {
      bars = 2;
      color = Colors.orange;
    } else {
      bars = 1;
      color = Colors.red;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final barHeight = height * (0.25 + 0.25 * i);
        final active = i < bars;
        return Padding(
          padding: const EdgeInsets.only(right: 1.5),
          child: Container(
            width: 3,
            height: barHeight,
            decoration: BoxDecoration(
              color: active ? color : color.withAlpha(50),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }

  /// Build a leading widget with the main device icon, and optionally
  /// a small brand badge in the bottom-right corner.
  ///
  /// [badgeBackground] should match the card/surface color so the badge
  /// circle blends with the background.
  static Widget iconWithBadge({
    required BleDeviceInfo info,
    required bool connectable,
    required bool isDark,
    required Color badgeBackground,
    double iconSize = 28,
  }) {
    final mainIcon = resolveIcon(info, connectable: connectable);
    final brandColor = getBrandColor(info.manufacturer, isDark: isDark);
    final brandIcon = getBrandIcon(info.manufacturer);

    // Only show badge when the main icon is device-type-driven and
    // a brand icon is available (so the brand is not already shown).
    final showBadge = brandIcon != null && mainIcon != brandIcon;

    if (!showBadge) {
      return Icon(mainIcon, color: brandColor, size: iconSize);
    }

    return SizedBox(
      width: iconSize + 8,
      height: iconSize + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(mainIcon, color: brandColor, size: iconSize),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                brandIcon,
                color: brandColor,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
