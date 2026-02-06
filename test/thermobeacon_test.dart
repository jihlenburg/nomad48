import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomad48/models/thermobeacon.dart';

void main() {
  group('ThermoBeaconData.decode', () {
    /// Build a minimal 18-byte ThermoBeacon payload.
    /// Offsets (relative to payload, company ID already stripped):
    ///   [1] bit7 = button
    ///   [8..9]  battery mV   (uint16 LE)
    ///   [10..11] temperature  (int16 LE, raw/16 = °C)
    ///   [12..13] humidity     (uint16 LE, raw/16 = %)
    ///   [14..17] uptime       (uint32 LE, seconds)
    List<int> buildPayload({
      bool button = false,
      int batteryMv = 3000,
      double tempC = 22.5,
      double humidity = 55.0,
      int uptimeSec = 3600,
    }) {
      final bytes = Uint8List(18);
      final data = ByteData.sublistView(bytes);
      if (button) bytes[1] = 0x80;
      data.setUint16(8, batteryMv, Endian.little);
      data.setInt16(10, (tempC * 16).round(), Endian.little);
      data.setUint16(12, (humidity * 16).round(), Endian.little);
      data.setUint32(14, uptimeSec, Endian.little);
      return bytes.toList();
    }

    test('decodes valid payload', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: buildPayload(
          tempC: 22.5,
          humidity: 55.0,
          batteryMv: 2800,
          uptimeSec: 7200,
        ),
      });

      expect(result, isNotNull);
      expect(result!.temperature, 22.5);
      expect(result.humidity, 55.0);
      expect(result.batteryMv, 2800);
      expect(result.uptime, const Duration(seconds: 7200));
    });

    test('detects button pressed', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: buildPayload(button: true),
      });

      expect(result, isNotNull);
      expect(result!.buttonPressed, isTrue);
    });

    test('detects button not pressed', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: buildPayload(button: false),
      });

      expect(result, isNotNull);
      expect(result!.buttonPressed, isFalse);
    });

    test('returns null for wrong company ID', () {
      final result = ThermoBeaconData.decode({
        0x004C: buildPayload(),
      });
      expect(result, isNull);
    });

    test('returns null for empty manufacturer data', () {
      expect(ThermoBeaconData.decode({}), isNull);
    });

    test('returns null for payload too short', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: List.filled(10, 0),
      });
      expect(result, isNull);
    });

    test('returns null for temperature out of range (>100)', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: buildPayload(tempC: 110.0),
      });
      expect(result, isNull);
    });

    test('returns null for temperature out of range (<-40)', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: buildPayload(tempC: -50.0),
      });
      expect(result, isNull);
    });

    test('returns null for humidity out of range', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: buildPayload(humidity: 110.0),
      });
      expect(result, isNull);
    });

    test('decodes negative temperature', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: buildPayload(tempC: -5.0),
      });

      expect(result, isNotNull);
      expect(result!.temperature, -5.0);
    });

    test('handles 16-byte payload (no uptime)', () {
      final payload = buildPayload(uptimeSec: 0).sublist(0, 16);
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: payload,
      });

      expect(result, isNotNull);
      expect(result!.uptime, Duration.zero);
    });
  });

  group('Battery voltage to percent', () {
    test('full battery (3000+ mV)', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: _buildPayloadWithBattery(3100),
      });
      expect(result!.batteryPercent, 100);
    });

    test('high battery (2800 mV)', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: _buildPayloadWithBattery(2800),
      });
      expect(result!.batteryPercent, greaterThan(60));
      expect(result.batteryPercent, lessThanOrEqualTo(100));
    });

    test('low battery (2450 mV)', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: _buildPayloadWithBattery(2450),
      });
      expect(result!.batteryPercent, 20);
    });

    test('dead battery (<2450 mV)', () {
      final result = ThermoBeaconData.decode({
        ThermoBeaconData.companyId: _buildPayloadWithBattery(2400),
      });
      expect(result!.batteryPercent, 0);
    });
  });

  group('uptimeString', () {
    test('formats days', () {
      final d = ThermoBeaconData(
        temperature: 0,
        humidity: 0,
        batteryMv: 0,
        batteryPercent: 0,
        uptime: const Duration(days: 2, hours: 3, minutes: 15),
        buttonPressed: false,
      );
      expect(d.uptimeString, '2d 3h 15m');
    });

    test('formats hours only', () {
      final d = ThermoBeaconData(
        temperature: 0,
        humidity: 0,
        batteryMv: 0,
        batteryPercent: 0,
        uptime: const Duration(hours: 5, minutes: 30),
        buttonPressed: false,
      );
      expect(d.uptimeString, '5h 30m');
    });

    test('formats minutes only', () {
      final d = ThermoBeaconData(
        temperature: 0,
        humidity: 0,
        batteryMv: 0,
        batteryPercent: 0,
        uptime: const Duration(minutes: 42),
        buttonPressed: false,
      );
      expect(d.uptimeString, '42m');
    });
  });
}

/// Helper to build a payload with a specific battery voltage.
List<int> _buildPayloadWithBattery(int batteryMv) {
  final bytes = Uint8List(18);
  final data = ByteData.sublistView(bytes);
  data.setUint16(8, batteryMv, Endian.little);
  // Valid temp/humidity so decode doesn't reject
  data.setInt16(10, (22.0 * 16).round(), Endian.little);
  data.setUint16(12, (50.0 * 16).round(), Endian.little);
  return bytes.toList();
}
