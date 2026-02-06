import 'dart:typed_data';

/// Decoded ThermoBeacon advertisement data
class ThermoBeaconData {
  final double temperature; // °C
  final double humidity; // %
  final int batteryMv; // millivolts
  final int batteryPercent; // 0-100
  final Duration uptime;
  final bool buttonPressed;

  const ThermoBeaconData({
    required this.temperature,
    required this.humidity,
    required this.batteryMv,
    required this.batteryPercent,
    required this.uptime,
    required this.buttonPressed,
  });

  /// Company ID used by ThermoBeacon devices
  static const int companyId = 0x0010;

  /// Try to decode manufacturer data from a BLE scan result.
  /// Returns null if the data is not from a ThermoBeacon.
  static ThermoBeaconData? decode(Map<int, List<int>> manufacturerData) {
    final payload = manufacturerData[companyId];
    if (payload == null || payload.length < 16) return null;

    // Full data = company ID (2 bytes LE) + payload
    // Offsets below are relative to the combined 20-byte buffer
    // Since company ID is prepended, payload byte 0 = combined byte 2
    //
    // Combined layout:
    //   [0]    device ID (from company ID low byte)
    //   [1]    company ID high byte
    //   [2..9] device info / counters
    //   [3]    button state (bit 7)
    //   [10-11] battery voltage (uint16 LE, mV)
    //   [12-13] temperature (int16 LE, raw/16 = °C)
    //   [14-15] humidity (uint16 LE, raw/16 = %)
    //   [16-19] uptime (uint32 LE, seconds)
    //
    // Since we only have the payload (bytes 2+), adjust offsets by -2:
    //   button:  payload[1] bit 7
    //   voltage: payload[8..9]
    //   temp:    payload[10..11]
    //   humi:    payload[12..13]
    //   uptime:  payload[14..17]

    try {
      final bytes = Uint8List.fromList(payload);
      final data = ByteData.sublistView(bytes);

      final buttonPressed = (bytes[1] & 0x80) != 0;
      final batteryMv = data.getUint16(8, Endian.little);
      final tempRaw = data.getInt16(10, Endian.little);
      final humiRaw = data.getUint16(12, Endian.little);

      final temperature = tempRaw / 16.0;
      final humidity = humiRaw / 16.0;

      // Sanity check
      if (temperature > 100 || temperature < -40) return null;
      if (humidity > 100 || humidity < 0) return null;

      int uptimeSeconds = 0;
      if (payload.length >= 18) {
        uptimeSeconds = data.getUint32(14, Endian.little);
      }

      return ThermoBeaconData(
        temperature: temperature,
        humidity: humidity,
        batteryMv: batteryMv,
        batteryPercent: _voltageToPercent(batteryMv),
        uptime: Duration(seconds: uptimeSeconds),
        buttonPressed: buttonPressed,
      );
    } catch (_) {
      return null;
    }
  }

  static int _voltageToPercent(int mv) {
    if (mv >= 3000) return 100;
    if (mv >= 2600) return 60 + ((mv - 2600) * 40 ~/ 400);
    if (mv >= 2500) return 40 + ((mv - 2500) * 20 ~/ 100);
    if (mv >= 2450) return 20 + ((mv - 2450) * 20 ~/ 50);
    return 0;
  }

  String get uptimeString {
    final days = uptime.inDays;
    final hours = uptime.inHours % 24;
    final minutes = uptime.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
