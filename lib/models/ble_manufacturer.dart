import 'package:flutter/foundation.dart';
import 'apple_continuity.dart';

/// BLE manufacturer identification from Bluetooth SIG Company IDs
/// and advertisement data heuristics
class BleManufacturer {
  final String name;

  const BleManufacturer(this.name);

  /// Matches "tv" as a whole word, not as a substring of "activity" etc.
  static final _tvWordPattern = RegExp(r'\btv\b');

  /// Matches screen size patterns like 55", 65-inch, 75 inch
  static final _screenSizePattern = RegExp(r'\b\d{2}["\u2033-]?\s*inch');
  static final _screenSizeQuotePattern = RegExp(r'\b\d{2}"');

  /// Known Bluetooth SIG Company IDs
  /// Source: https://www.bluetooth.com/specifications/assigned-numbers/
  static const Map<int, BleManufacturer> _companyIds = {
    // Major consumer electronics
    0x004C: BleManufacturer('Apple'),
    0x0075: BleManufacturer('Samsung'),
    0x00E0: BleManufacturer('Google'),
    0x0006: BleManufacturer('Microsoft'),
    0x001D: BleManufacturer('Qualcomm'),
    0x000F: BleManufacturer('Broadcom'),
    0x0059: BleManufacturer('Nordic Semiconductor'),
    0x000A: BleManufacturer('CSR (Qualcomm)'),
    0x0046: BleManufacturer('MediaTek'),
    0x0002: BleManufacturer('Intel'),
    0x000D: BleManufacturer('Texas Instruments'),
    0x0131: BleManufacturer('Cypress Semiconductor'),

    // Audio & wearables
    0x00AA: BleManufacturer('Harman'),
    0x00E3: BleManufacturer('ProximityMarketing.com'),
    0x0087: BleManufacturer('Garmin'),
    0x0078: BleManufacturer('Nike'),
    0x028A: BleManufacturer('Tile'),
    0x0157: BleManufacturer('Huawei'),
    0x038F: BleManufacturer('Xiaomi'),
    0x0310: BleManufacturer('Xiaomi Communications'),
    0x01DA: BleManufacturer('BOSE'),
    0x000E: BleManufacturer('Ericsson'),
    0x0001: BleManufacturer('Nokia'),
    0x0003: BleManufacturer('Motorola'),

    // Smart home & IoT
    0x004F: BleManufacturer('Philips'),
    0x0010: BleManufacturer('ThermoBeacon'),
    0x0171: BleManufacturer('Amazon'),
    0x0822: BleManufacturer('Govee'),
    0x0499: BleManufacturer('Ruuvi'),

    // LG
    0x00C7: BleManufacturer('LG Electronics'),

    // Sony
    0x012D: BleManufacturer('Sony'),

    // Fitbit
    0x0224: BleManufacturer('Fitbit'),

    // Sonos
    0x05A7: BleManufacturer('Sonos'),
  };

  /// Identify manufacturer from BLE advertisement data
  static BleDeviceInfo identify({
    required Map<int, List<int>> manufacturerData,
    required String advName,
    required String platformName,
    required List<dynamic> serviceUuids,
  }) {
    // 1. Check manufacturer data company IDs
    for (final entry in manufacturerData.entries) {
      final companyId = entry.key;
      final mfr = _companyIds[companyId];
      if (mfr != null) {
        // Apple: try continuity TLV decode for more specific identification
        if (companyId == 0x004C) {
          final continuity = AppleContinuityInfo.decode(entry.value);
          if (continuity != null) {
            return BleDeviceInfo(
              manufacturer: 'Apple',
              deviceType: continuity.deviceType,
              appleContinuitySubType: continuity.subType,
              appleContinuityModel: continuity.modelName,
            );
          }
        }
        return BleDeviceInfo(
          manufacturer: mfr.name,
          deviceType: _guessDeviceType(advName, platformName),
        );
      }
    }

    // 2. Try to identify by name patterns.
    // Check both advName and platformName — Apple Watch may advertise
    // shortened advName "Watch" while full name is in platformName.
    // Try the longer/more-specific name first.
    final primary = (advName.isNotEmpty ? advName : platformName).toLowerCase();
    final secondary = (advName.isNotEmpty && platformName.isNotEmpty)
        ? platformName.toLowerCase()
        : null;
    debugPrint('  [identify] step2: advName="$advName" platformName="$platformName" '
        'primary="$primary" secondary="$secondary"');
    // If secondary is more specific, try it first
    if (secondary != null && secondary.length > primary.length) {
      final match = _identifyByName(secondary);
      if (match != null) {
        debugPrint('  [identify] step2: secondary matched → ${match.manufacturer}/${match.deviceType}');
        return match;
      }
    }
    final nameMatch = _identifyByName(primary);
    if (nameMatch != null) {
      debugPrint('  [identify] step2: primary matched → ${nameMatch.manufacturer}/${nameMatch.deviceType}');
      return nameMatch;
    }
    // Try secondary if not already tried
    if (secondary != null && secondary.length <= primary.length) {
      final match = _identifyByName(secondary);
      if (match != null) {
        debugPrint('  [identify] step2: secondary(short) matched → ${match.manufacturer}/${match.deviceType}');
        return match;
      }
    }

    // 3. Try to identify by service UUIDs
    final uuidMatch = _identifyByServiceUuids(serviceUuids);
    if (uuidMatch != null) return uuidMatch;

    // 4. Unknown but has data
    if (manufacturerData.isNotEmpty || serviceUuids.isNotEmpty) {
      return BleDeviceInfo(
        manufacturer: null,
        deviceType: 'BLE Device',
      );
    }

    return BleDeviceInfo(manufacturer: null, deviceType: null);
  }

  static BleDeviceInfo? _identifyByName(String name) {
    // Apple devices — specific products only, not generic "watch"
    if (name.contains('airpods') || name.contains('air pods')) {
      return BleDeviceInfo(manufacturer: 'Apple', deviceType: 'AirPods');
    }
    // Check 'apple' and 'watch' separately to handle non-breaking spaces
    // or other Unicode whitespace in iOS platformName strings
    if (name.contains('apple') && name.contains('watch')) {
      return BleDeviceInfo(manufacturer: 'Apple', deviceType: 'Watch');
    }
    if (name.contains('iphone')) {
      return BleDeviceInfo(manufacturer: 'Apple', deviceType: 'iPhone');
    }
    if (name.contains('ipad')) {
      return BleDeviceInfo(manufacturer: 'Apple', deviceType: 'iPad');
    }
    if (name.contains('macbook')) {
      return BleDeviceInfo(manufacturer: 'Apple', deviceType: 'Mac');
    }
    if (name.contains('homepod')) {
      return BleDeviceInfo(manufacturer: 'Apple', deviceType: 'HomePod');
    }

    // Samsung — detect TV/soundbar before generic
    if (name.contains('samsung') || name.startsWith('sm-') ||
        name.startsWith('[tv]') || name.contains('galaxy')) {
      return BleDeviceInfo(
          manufacturer: 'Samsung', deviceType: _samsungDeviceType(name));
    }

    // Google
    if (name.contains('nest') || name.contains('chromecast') ||
        name.contains('google')) {
      return BleDeviceInfo(manufacturer: 'Google', deviceType: 'Smart Home');
    }

    // LG — detect TV before generic
    if (name.contains('[lg]') || name.startsWith('lg')) {
      return BleDeviceInfo(
          manufacturer: 'LG', deviceType: _detectTvOrDevice(name));
    }

    // Sony
    if (name.contains('sony') || name.startsWith('wh-') ||
        name.startsWith('wf-')) {
      return BleDeviceInfo(manufacturer: 'Sony', deviceType: 'Audio');
    }

    // Audio brands
    if (name.contains('bose')) {
      return BleDeviceInfo(manufacturer: 'Bose', deviceType: 'Audio');
    }
    if (name.contains('jbl')) {
      return BleDeviceInfo(manufacturer: 'JBL', deviceType: 'Audio');
    }
    if (name.contains('sonos')) {
      return BleDeviceInfo(manufacturer: 'Sonos', deviceType: 'Speaker');
    }

    // Wearables
    if (name.contains('fitbit')) {
      return BleDeviceInfo(manufacturer: 'Fitbit', deviceType: 'Wearable');
    }
    if (name.contains('garmin')) {
      return BleDeviceInfo(manufacturer: 'Garmin', deviceType: 'Wearable');
    }
    if (name.contains('tile')) {
      return BleDeviceInfo(manufacturer: 'Tile', deviceType: 'Tracker');
    }
    if (name.contains('xiaomi') || name.contains('mi band')) {
      return BleDeviceInfo(manufacturer: 'Xiaomi', deviceType: 'Device');
    }

    // IoT sensors
    if (name.contains('thermobeacon') || name.contains('thermometer')) {
      return BleDeviceInfo(
          manufacturer: 'ThermoBeacon', deviceType: 'Sensor');
    }
    if (name.contains('govee')) {
      return BleDeviceInfo(manufacturer: 'Govee', deviceType: 'LED/Sensor');
    }
    if (name.contains('ruuvi')) {
      return BleDeviceInfo(manufacturer: 'Ruuvi', deviceType: 'Sensor');
    }
    if (name.contains('switchbot')) {
      return BleDeviceInfo(
          manufacturer: 'SwitchBot', deviceType: 'Smart Home');
    }

    // Generic patterns — order matters: specific before general
    if (name.contains('keyboard') || name.contains('keychron')) {
      return BleDeviceInfo(deviceType: 'Keyboard');
    }
    if (name.contains('mouse') || name.contains('logitech')) {
      return BleDeviceInfo(
          manufacturer: 'Logitech', deviceType: 'Peripheral');
    }
    if (name.contains('soundbar')) {
      return BleDeviceInfo(deviceType: 'Soundbar');
    }
    if (name.contains('speaker')) {
      return BleDeviceInfo(deviceType: 'Speaker');
    }
    if (name.contains('headphone') || name.contains('earphone') ||
        name.contains('earbuds')) {
      return BleDeviceInfo(deviceType: 'Audio');
    }
    // Generic "watch" (not Apple — that's caught above)
    if (name.contains('watch')) {
      return BleDeviceInfo(deviceType: 'Watch');
    }
    if (_isTvName(name)) {
      return BleDeviceInfo(deviceType: 'TV');
    }
    if (name.contains('printer')) {
      return BleDeviceInfo(deviceType: 'Printer');
    }
    if (name.contains('lamp') || name.contains('light') ||
        name.contains('bulb')) {
      return BleDeviceInfo(deviceType: 'Smart Light');
    }

    return null;
  }

  static BleDeviceInfo? _identifyByServiceUuids(List<dynamic> serviceUuids) {
    final uuids = serviceUuids.map((u) => u.toString().toLowerCase()).toSet();

    // Heart Rate Service
    if (uuids.contains('180d') || uuids.contains('0000180d-0000-1000-8000-00805f9b34fb')) {
      return BleDeviceInfo(deviceType: 'Heart Rate Monitor');
    }
    // Blood Pressure
    if (uuids.contains('1810')) {
      return BleDeviceInfo(deviceType: 'Blood Pressure Monitor');
    }
    // Health Thermometer
    if (uuids.contains('1809')) {
      return BleDeviceInfo(deviceType: 'Thermometer');
    }
    // Battery Service (very common, low confidence)
    if (uuids.contains('180f')) {
      return BleDeviceInfo(deviceType: 'BLE Device');
    }
    // HID (keyboard/mouse)
    if (uuids.contains('1812')) {
      return BleDeviceInfo(deviceType: 'HID Peripheral');
    }
    // Running Speed
    if (uuids.contains('1814')) {
      return BleDeviceInfo(deviceType: 'Running Sensor');
    }
    // Cycling
    if (uuids.contains('1816')) {
      return BleDeviceInfo(deviceType: 'Cycling Sensor');
    }
    // Environmental Sensing
    if (uuids.contains('181a')) {
      return BleDeviceInfo(deviceType: 'Environment Sensor');
    }

    return null;
  }

  /// Detect TV-like names using word boundaries to avoid false positives.
  ///
  /// Matches: "[TV]", "Samsung TV", "QLED", "OLED", "55-inch", '65"'
  /// Does NOT match: "activity", "creative", "motivate"
  static bool _isTvName(String name) {
    if (_tvWordPattern.hasMatch(name)) return true;
    if (name.contains('television')) return true;
    if (name.contains('qled') || name.contains('oled')) return true;
    if (_screenSizePattern.hasMatch(name)) return true;
    if (_screenSizeQuotePattern.hasMatch(name)) return true;
    return false;
  }

  /// Determine Samsung device type from name
  static String _samsungDeviceType(String name) {
    if (name.contains('buds')) return 'Earbuds';
    if (name.contains('watch')) return 'Watch';
    if (name.contains('soundbar')) return 'Soundbar';
    if (_isTvName(name)) return 'TV';
    if (name.startsWith('sm-')) return 'Phone';
    return 'Device';
  }

  /// Detect TV vs generic device for a name
  static String _detectTvOrDevice(String name) {
    if (name.contains('soundbar')) return 'Soundbar';
    if (_isTvName(name)) return 'TV';
    return 'Device';
  }

  /// Guess device type from advertisement name when manufacturer is already
  /// known via company ID. Only uses advName/platformName.
  static String _guessDeviceType(String advName, String platformName) {
    final name = (advName.isNotEmpty ? advName : platformName).toLowerCase();

    if (name.contains('airpods')) return 'AirPods';
    if (name.contains('watch')) return 'Watch';
    if (name.contains('soundbar')) return 'Soundbar';
    if (_isTvName(name)) return 'TV';
    if (name.contains('speaker')) return 'Speaker';
    if (name.contains('keyboard')) return 'Keyboard';
    if (name.contains('mouse')) return 'Mouse';
    if (name.contains('buds') || name.contains('earbuds')) return 'Earbuds';
    // Check headphone/earphone BEFORE phone to avoid "earphone"→"Phone"
    if (name.contains('headphone') || name.contains('earphone')) {
      return 'Headphones';
    }
    if (name.contains('phone') || name.startsWith('sm-')) return 'Phone';
    if (name.contains('pad') || name.contains('tablet')) return 'Tablet';

    return 'Device';
  }
}

/// Identified BLE device info
class BleDeviceInfo {
  final String? manufacturer;
  final String? deviceType;

  /// Apple Continuity protocol sub-type (e.g. "Nearby Info", "Instant Hotspot")
  final String? appleContinuitySubType;

  /// Apple Continuity model name (e.g. "AirPods Pro 2", "Beats Studio Buds")
  final String? appleContinuityModel;

  const BleDeviceInfo({
    this.manufacturer,
    this.deviceType,
    this.appleContinuitySubType,
    this.appleContinuityModel,
  });

  bool get isIdentified => manufacturer != null || deviceType != null;

  String get displayLabel {
    if (appleContinuityModel != null) {
      return appleContinuityModel!;
    }
    if (manufacturer != null && deviceType != null) {
      return '$manufacturer $deviceType';
    }
    return manufacturer ?? deviceType ?? 'Unknown Device';
  }
}
