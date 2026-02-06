import 'package:flutter_test/flutter_test.dart';
import 'package:nomad48/models/ble_manufacturer.dart';

void main() {
  /// Shorthand for identify() with sensible defaults.
  BleDeviceInfo id({
    Map<int, List<int>> mfr = const {},
    String advName = '',
    String platformName = '',
    List<dynamic> serviceUuids = const [],
  }) {
    return BleManufacturer.identify(
      manufacturerData: mfr,
      advName: advName,
      platformName: platformName,
      serviceUuids: serviceUuids,
    );
  }

  group('Company ID identification', () {
    test('Apple company ID', () {
      // Nearby Info TLV so decode returns something
      final result = id(mfr: {
        0x004C: [0x10, 0x01, 0x00],
      });
      expect(result.manufacturer, 'Apple');
      expect(result.isIdentified, isTrue);
    });

    test('Samsung company ID', () {
      final result = id(mfr: {0x0075: [0x01, 0x02]});
      expect(result.manufacturer, 'Samsung');
    });

    test('Google company ID', () {
      final result = id(mfr: {0x00E0: [0x01]});
      expect(result.manufacturer, 'Google');
    });

    test('unknown company ID returns null manufacturer', () {
      final result = id(mfr: {0x9999: [0x01]});
      // Has mfr data but unknown company → "BLE Device"
      expect(result.manufacturer, isNull);
      expect(result.deviceType, 'BLE Device');
    });
  });

  group('Name-based identification', () {
    test('AirPods by advName', () {
      final result = id(advName: 'AirPods Pro');
      expect(result.manufacturer, 'Apple');
      expect(result.deviceType, 'AirPods');
    });

    test('iPhone by platformName', () {
      final result = id(platformName: "Joern's iPhone");
      expect(result.manufacturer, 'Apple');
      expect(result.deviceType, 'iPhone');
    });

    test('iPad', () {
      final result = id(advName: "Joern's iPad");
      expect(result.manufacturer, 'Apple');
      expect(result.deviceType, 'iPad');
    });

    test('MacBook', () {
      final result = id(platformName: 'MacBook Pro');
      expect(result.manufacturer, 'Apple');
      expect(result.deviceType, 'Mac');
    });

    test('Apple Watch requires both words', () {
      final result = id(platformName: 'Apple Watch');
      expect(result.manufacturer, 'Apple');
      expect(result.deviceType, 'Watch');
    });

    test('generic watch is not Apple', () {
      final result = id(advName: 'Garmin Watch');
      // Should match Garmin, not Apple
      expect(result.manufacturer, 'Garmin');
    });

    test('Samsung Galaxy', () {
      final result = id(advName: 'Galaxy S24');
      expect(result.manufacturer, 'Samsung');
    });

    test('Samsung SM- prefix', () {
      final result = id(advName: 'SM-G998B');
      expect(result.manufacturer, 'Samsung');
      expect(result.deviceType, 'Phone');
    });

    test('Samsung Galaxy Buds', () {
      final result = id(advName: 'Galaxy Buds Pro');
      expect(result.manufacturer, 'Samsung');
      expect(result.deviceType, 'Earbuds');
    });

    test('Sony WH- headphones', () {
      final result = id(advName: 'WH-1000XM5');
      expect(result.manufacturer, 'Sony');
      expect(result.deviceType, 'Audio');
    });

    test('Sony WF- earbuds', () {
      final result = id(advName: 'WF-1000XM5');
      expect(result.manufacturer, 'Sony');
      expect(result.deviceType, 'Audio');
    });

    test('Bose', () {
      final result = id(advName: 'Bose QC45');
      expect(result.manufacturer, 'Bose');
      expect(result.deviceType, 'Audio');
    });

    test('Sonos', () {
      final result = id(advName: 'Sonos One');
      expect(result.manufacturer, 'Sonos');
      expect(result.deviceType, 'Speaker');
    });

    test('Tile tracker', () {
      final result = id(advName: 'Tile Pro');
      expect(result.manufacturer, 'Tile');
      expect(result.deviceType, 'Tracker');
    });

    test('Govee', () {
      final result = id(advName: 'Govee H6159');
      expect(result.manufacturer, 'Govee');
      expect(result.deviceType, 'LED/Sensor');
    });

    test('Nest/Google Smart Home', () {
      final result = id(advName: 'Nest Hub');
      expect(result.manufacturer, 'Google');
      expect(result.deviceType, 'Smart Home');
    });

    test('Logitech mouse', () {
      final result = id(advName: 'Logitech MX Master');
      expect(result.manufacturer, 'Logitech');
    });

    test('SwitchBot', () {
      final result = id(advName: 'SwitchBot Hub');
      expect(result.manufacturer, 'SwitchBot');
      expect(result.deviceType, 'Smart Home');
    });
  });

  group('TV detection edge cases', () {
    test('[TV] prefix detected', () {
      final result = id(advName: '[TV] Samsung 55"');
      expect(result.manufacturer, 'Samsung');
      expect(result.deviceType, 'TV');
    });

    test('QLED detected as TV', () {
      final result = id(advName: 'Samsung QLED QN85');
      expect(result.manufacturer, 'Samsung');
      expect(result.deviceType, 'TV');
    });

    test('OLED detected as TV', () {
      final result = id(advName: 'LG OLED55C3');
      expect(result.manufacturer, 'LG');
      expect(result.deviceType, 'TV');
    });

    test('"tv" as word boundary matches', () {
      final result = id(advName: 'Samsung TV');
      expect(result.manufacturer, 'Samsung');
      expect(result.deviceType, 'TV');
    });

    test('"activity" does not match tv', () {
      // "activity" contains "tv" but not as a word
      final result = id(advName: 'activity tracker');
      // Should not be identified as TV
      expect(result.deviceType, isNot('TV'));
    });
  });

  group('Earphone vs phone disambiguation', () {
    test('earphone detected as Audio', () {
      final result = id(advName: 'earphone BT');
      expect(result.deviceType, 'Audio');
    });

    test('headphone detected as Audio', () {
      final result = id(advName: 'headphone X');
      expect(result.deviceType, 'Audio');
    });
  });

  group('Service UUID identification', () {
    test('heart rate service', () {
      final result = id(serviceUuids: ['180d']);
      expect(result.deviceType, 'Heart Rate Monitor');
    });

    test('HID service', () {
      final result = id(serviceUuids: ['1812']);
      expect(result.deviceType, 'HID Peripheral');
    });

    test('health thermometer', () {
      final result = id(serviceUuids: ['1809']);
      expect(result.deviceType, 'Thermometer');
    });
  });

  group('Fallback behavior', () {
    test('unknown mfr data returns BLE Device', () {
      final result = id(mfr: {0x9999: [0x01]});
      expect(result.manufacturer, isNull);
      expect(result.deviceType, 'BLE Device');
      expect(result.isIdentified, isTrue);
    });

    test('completely empty returns unidentified', () {
      final result = id();
      expect(result.manufacturer, isNull);
      expect(result.deviceType, isNull);
      expect(result.isIdentified, isFalse);
    });
  });

  group('BleDeviceInfo', () {
    test('displayLabel with continuity model', () {
      const info = BleDeviceInfo(
        manufacturer: 'Apple',
        deviceType: 'AirPods',
        appleContinuityModel: 'AirPods Pro 2',
      );
      expect(info.displayLabel, 'AirPods Pro 2');
    });

    test('displayLabel with manufacturer and type', () {
      const info = BleDeviceInfo(
        manufacturer: 'Samsung',
        deviceType: 'Phone',
      );
      expect(info.displayLabel, 'Samsung Phone');
    });

    test('displayLabel manufacturer only', () {
      const info = BleDeviceInfo(manufacturer: 'Sony');
      expect(info.displayLabel, 'Sony');
    });

    test('displayLabel type only', () {
      const info = BleDeviceInfo(deviceType: 'Speaker');
      expect(info.displayLabel, 'Speaker');
    });

    test('displayLabel unknown', () {
      const info = BleDeviceInfo();
      expect(info.displayLabel, 'Unknown Device');
    });

    test('isIdentified true with manufacturer', () {
      const info = BleDeviceInfo(manufacturer: 'Apple');
      expect(info.isIdentified, isTrue);
    });

    test('isIdentified true with deviceType', () {
      const info = BleDeviceInfo(deviceType: 'Speaker');
      expect(info.isIdentified, isTrue);
    });

    test('isIdentified false when empty', () {
      const info = BleDeviceInfo();
      expect(info.isIdentified, isFalse);
    });
  });
}
