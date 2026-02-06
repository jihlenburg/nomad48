/// Apple Continuity Protocol TLV decoder for BLE manufacturer data.
///
/// Apple devices (company ID 0x004C) broadcast manufacturer data using a
/// Type-Length-Value chain. This decoder walks the chain and identifies
/// device types like iPhones, AirPods, Macs, Apple TVs, etc.
class AppleContinuityInfo {
  final String deviceType;
  final String? subType;
  final String? modelName;

  const AppleContinuityInfo({
    required this.deviceType,
    this.subType,
    this.modelName,
  });

  /// Known Apple Continuity TLV type codes.
  static const int _typeIBeacon = 0x02;
  static const int _typeAirPrint = 0x03;
  static const int _typeAirDrop = 0x05;
  static const int _typeProximityPairing = 0x07;
  static const int _typeHeySiri = 0x08;
  static const int _typeAirPlay = 0x0A;
  static const int _typeHandoff = 0x0C;
  static const int _typeInstantHotspot = 0x0E;
  static const int _typeNearbyAction = 0x0F;
  static const int _typeNearbyInfo = 0x10;

  /// AirPods / Beats model codes (from proximity pairing TLV).
  /// The model code is a 2-byte big-endian value at offset 1-2 of the
  /// proximity pairing payload.
  static const _airpodsModels = <int, String>{
    0x2002: 'AirPods 1',
    0x0F20: 'AirPods 2',
    0x1320: 'AirPods 2',
    0x0E20: 'AirPods 3',
    0x1420: 'AirPods 3',
    0x0A20: 'AirPods Pro',
    0x1920: 'AirPods Pro',
    0x1220: 'AirPods Pro 2',
    0x1720: 'AirPods Pro 2',
    0x0320: 'Powerbeats Pro',
    0x0B20: 'Powerbeats',
    0x0620: 'AirPods Max',
    // Beats variants
    0x0520: 'Beats Solo3',
    0x0920: 'Beats Studio3',
    0x1020: 'Beats Flex',
    0x0D20: 'Beats Studio Buds',
    0x1120: 'Beats Studio Pro',
  };

  /// Decode Apple manufacturer data payload (bytes after company ID 0x004C).
  ///
  /// Walks the TLV chain and returns the best identification found, or null
  /// if no meaningful type is recognized. Strict bounds checking — returns
  /// best result so far on malformed data.
  static AppleContinuityInfo? decode(List<int> payload) {
    if (payload.isEmpty) return null;

    AppleContinuityInfo? best;
    int offset = 0;

    while (offset + 2 <= payload.length) {
      final type = payload[offset];
      final length = payload[offset + 1];
      final dataStart = offset + 2;

      // Bounds check: ensure we don't read past the payload
      if (dataStart + length > payload.length) break;

      final result = _decodeTlv(type, payload, dataStart, length);
      if (result != null) {
        // Prefer more specific results (proximity pairing > nearby info)
        if (best == null || _priority(result) > _priority(best)) {
          best = result;
        }
      }

      offset = dataStart + length;
    }

    return best;
  }

  static AppleContinuityInfo? _decodeTlv(
    int type,
    List<int> payload,
    int dataStart,
    int length,
  ) {
    switch (type) {
      case _typeIBeacon:
        return const AppleContinuityInfo(
          deviceType: 'Beacon',
          subType: 'iBeacon',
        );

      case _typeProximityPairing:
        return _decodeProximityPairing(payload, dataStart, length);

      case _typeAirPlay:
        return const AppleContinuityInfo(
          deviceType: 'Apple TV',
          subType: 'AirPlay Target',
        );

      case _typeHandoff:
        return const AppleContinuityInfo(
          deviceType: 'Apple Device',
          subType: 'Handoff',
        );

      case _typeInstantHotspot:
        return const AppleContinuityInfo(
          deviceType: 'iPhone',
          subType: 'Instant Hotspot',
        );

      case _typeNearbyAction:
        return const AppleContinuityInfo(
          deviceType: 'Apple Device',
          subType: 'Nearby Action',
        );

      case _typeNearbyInfo:
        return const AppleContinuityInfo(
          deviceType: 'Apple Device',
          subType: 'Nearby Info',
        );

      case _typeHeySiri:
        return const AppleContinuityInfo(
          deviceType: 'Apple Device',
          subType: 'Hey Siri',
        );

      case _typeAirDrop:
        return const AppleContinuityInfo(
          deviceType: 'Apple Device',
          subType: 'AirDrop',
        );

      case _typeAirPrint:
        return const AppleContinuityInfo(
          deviceType: 'Apple Device',
          subType: 'AirPrint',
        );

      default:
        return null;
    }
  }

  static AppleContinuityInfo? _decodeProximityPairing(
    List<int> payload,
    int dataStart,
    int length,
  ) {
    // Proximity pairing payload: at least 3 bytes needed for model code
    // Byte 0: status, Bytes 1-2: model code (big-endian)
    if (length < 3) {
      return const AppleContinuityInfo(
        deviceType: 'AirPods',
        subType: 'Proximity Pairing',
      );
    }

    final modelCode =
        (payload[dataStart + 1] << 8) | payload[dataStart + 2];
    final modelName = _airpodsModels[modelCode];

    if (modelName != null) {
      // Determine broader device type from model name
      final deviceType = modelName.contains('Beats') ? 'Beats' : 'AirPods';
      return AppleContinuityInfo(
        deviceType: deviceType,
        subType: 'Proximity Pairing',
        modelName: modelName,
      );
    }

    return const AppleContinuityInfo(
      deviceType: 'AirPods',
      subType: 'Proximity Pairing',
    );
  }

  /// Priority for selecting the best TLV result. Higher = more specific.
  static int _priority(AppleContinuityInfo info) {
    switch (info.deviceType) {
      case 'AirPods':
      case 'Beats':
        return 10; // Most specific — actual product identification
      case 'iPhone':
        return 8;
      case 'Apple TV':
        return 8;
      case 'Beacon':
        return 7;
      case 'Apple Device':
        return 3; // Generic Apple, still better than nothing
      default:
        return 1;
    }
  }
}
