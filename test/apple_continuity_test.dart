import 'package:flutter_test/flutter_test.dart';
import 'package:nomad48/models/apple_continuity.dart';

void main() {
  group('AppleContinuityInfo.decode', () {
    test('returns null for empty payload', () {
      expect(AppleContinuityInfo.decode([]), isNull);
    });

    test('returns null for single byte (incomplete TLV)', () {
      expect(AppleContinuityInfo.decode([0x10]), isNull);
    });

    test('decodes iBeacon', () {
      // Type 0x02, length 0x15 (21 bytes of iBeacon data)
      final payload = [0x02, 0x15, ...List.filled(21, 0x00)];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Beacon');
      expect(result.subType, 'iBeacon');
    });

    test('decodes AirPlay target', () {
      final payload = [0x0A, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Apple TV');
      expect(result.subType, 'AirPlay Target');
    });

    test('decodes Instant Hotspot as iPhone', () {
      final payload = [0x0E, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'iPhone');
      expect(result.subType, 'Instant Hotspot');
    });

    test('decodes Handoff', () {
      final payload = [0x0C, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Apple Device');
      expect(result.subType, 'Handoff');
    });

    test('decodes Nearby Info', () {
      final payload = [0x10, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Apple Device');
      expect(result.subType, 'Nearby Info');
    });

    test('decodes AirDrop', () {
      final payload = [0x05, 0x02, 0x00, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Apple Device');
      expect(result.subType, 'AirDrop');
    });

    test('decodes Hey Siri', () {
      final payload = [0x08, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Apple Device');
      expect(result.subType, 'Hey Siri');
    });

    test('decodes AirPrint', () {
      final payload = [0x03, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Apple Device');
      expect(result.subType, 'AirPrint');
    });

    test('decodes Nearby Action', () {
      final payload = [0x0F, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Apple Device');
      expect(result.subType, 'Nearby Action');
    });

    test('skips unknown TLV types', () {
      // Unknown type 0xFF, then a valid Nearby Info
      final payload = [0xFF, 0x01, 0x00, 0x10, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'Apple Device');
      expect(result.subType, 'Nearby Info');
    });

    test('stops on truncated TLV (length exceeds payload)', () {
      // Type 0x10, length claims 20 bytes but only 2 available
      final payload = [0x10, 0x14, 0x00, 0x00];
      final result = AppleContinuityInfo.decode(payload);
      expect(result, isNull);
    });
  });

  group('Proximity pairing (AirPods/Beats)', () {
    /// Build a proximity pairing TLV: type=0x07, length, status, modelHi, modelLo
    List<int> buildProximityPairing(int modelCode, {int extraBytes = 0}) {
      return [
        0x07, // type: proximity pairing
        3 + extraBytes, // length
        0x00, // status byte
        (modelCode >> 8) & 0xFF, // model high
        modelCode & 0xFF, // model low
        ...List.filled(extraBytes, 0x00),
      ];
    }

    test('decodes AirPods Pro 2', () {
      final result =
          AppleContinuityInfo.decode(buildProximityPairing(0x1220));

      expect(result, isNotNull);
      expect(result!.deviceType, 'AirPods');
      expect(result.modelName, 'AirPods Pro 2');
    });

    test('decodes AirPods 1', () {
      final result =
          AppleContinuityInfo.decode(buildProximityPairing(0x2002));

      expect(result, isNotNull);
      expect(result!.modelName, 'AirPods 1');
    });

    test('decodes AirPods Max', () {
      final result =
          AppleContinuityInfo.decode(buildProximityPairing(0x0620));

      expect(result, isNotNull);
      expect(result!.modelName, 'AirPods Max');
    });

    test('decodes Beats Solo3 as Beats deviceType', () {
      final result =
          AppleContinuityInfo.decode(buildProximityPairing(0x0520));

      expect(result, isNotNull);
      expect(result!.deviceType, 'Beats');
      expect(result.modelName, 'Beats Solo3');
    });

    test('decodes Beats Studio Buds', () {
      final result =
          AppleContinuityInfo.decode(buildProximityPairing(0x0D20));

      expect(result, isNotNull);
      expect(result!.deviceType, 'Beats');
      expect(result.modelName, 'Beats Studio Buds');
    });

    test('unknown model code falls back to generic AirPods', () {
      final result =
          AppleContinuityInfo.decode(buildProximityPairing(0xFFFF));

      expect(result, isNotNull);
      expect(result!.deviceType, 'AirPods');
      expect(result.modelName, isNull);
      expect(result.subType, 'Proximity Pairing');
    });

    test('short proximity pairing (< 3 bytes) falls back gracefully', () {
      // Type 0x07, length 1, one data byte
      final payload = [0x07, 0x01, 0x00];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'AirPods');
      expect(result.subType, 'Proximity Pairing');
      expect(result.modelName, isNull);
    });
  });

  group('TLV priority (most specific wins)', () {
    test('proximity pairing wins over nearby info', () {
      // Nearby Info first, then AirPods Pro 2
      final payload = [
        0x10, 0x01, 0x00, // Nearby Info
        0x07, 0x03, 0x00, 0x12, 0x20, // AirPods Pro 2
      ];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'AirPods');
      expect(result.modelName, 'AirPods Pro 2');
    });

    test('iPhone wins over generic Apple Device', () {
      // Handoff (Apple Device) first, then Instant Hotspot (iPhone)
      final payload = [
        0x0C, 0x01, 0x00, // Handoff → Apple Device
        0x0E, 0x01, 0x00, // Instant Hotspot → iPhone
      ];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'iPhone');
    });

    test('AirPods wins over iPhone', () {
      // Instant Hotspot (iPhone) first, then AirPods
      final payload = [
        0x0E, 0x01, 0x00, // iPhone
        0x07, 0x03, 0x00, 0x0F, 0x20, // AirPods 2
      ];
      final result = AppleContinuityInfo.decode(payload);

      expect(result, isNotNull);
      expect(result!.deviceType, 'AirPods');
      expect(result.modelName, 'AirPods 2');
    });
  });
}
