import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/ble_manufacturer.dart';
import '../models/cached_device.dart';

/// Service that probes unknown BLE devices via GATT to identify them.
///
/// Connects briefly, discovers services, reads device name, and caches
/// the result in Hive for 24 hours.
class DeviceProbeService {
  DeviceProbeService._();
  static final instance = DeviceProbeService._();

  static const _boxName = HiveBoxNames.deviceCache;
  static const Duration _connectTimeout = BleConstants.probeConnectTimeout;

  final Set<String> _inFlight = {};

  /// Whether a probe is currently in progress for [remoteId].
  bool isProbing(String remoteId) => _inFlight.contains(remoteId);

  /// Get cached identification for [remoteId], or null if not cached / expired.
  CachedDeviceIdentification? getCached(String remoteId) {
    final box = Hive.box<CachedDeviceIdentification>(_boxName);
    final cached = box.get(remoteId);
    if (cached == null) return null;
    if (cached.isExpired) {
      cached.delete();
      return null;
    }
    return cached;
  }

  /// Probe a device: connect, discover GATT services, read device name,
  /// cache result, and disconnect. Returns a [BleDeviceInfo] on success,
  /// null on failure (never throws).
  Future<BleDeviceInfo?> probe(BluetoothDevice device) async {
    final remoteId = device.remoteId.str;
    if (_inFlight.contains(remoteId)) return null;
    _inFlight.add(remoteId);

    try {
      // Connect
      await device.connect(timeout: _connectTimeout, autoConnect: false);

      // Discover services
      final services = await device.discoverServices();
      final serviceUuids =
          services.map((s) => s.uuid.str.toLowerCase()).toList();

      // Try to read device name from GAP service (0x1800, char 0x2A00)
      String? deviceName;
      for (final svc in services) {
        if (svc.uuid.str.toLowerCase().startsWith('1800')) {
          for (final c in svc.characteristics) {
            if (c.uuid.str.toLowerCase().startsWith('2a00')) {
              try {
                final value = await c.read();
                if (value.isNotEmpty) {
                  deviceName = String.fromCharCodes(value).trim();
                }
              } catch (_) {
                // Some devices don't allow reading this characteristic
              }
              break;
            }
          }
          break;
        }
      }

      // Map GATT service UUIDs to a device type
      final deviceType = _deviceTypeFromGatt(serviceUuids);
      final manufacturer = _manufacturerFromName(deviceName);

      // Cache
      final cached = CachedDeviceIdentification(
        remoteId: remoteId,
        manufacturer: manufacturer,
        deviceType: deviceType,
        serviceUuids: serviceUuids,
        deviceName: deviceName,
        gattServiceCount: services.length,
        probedAt: DateTime.now(),
      );
      final box = Hive.box<CachedDeviceIdentification>(_boxName);
      await box.put(remoteId, cached);

      // Build result
      if (manufacturer != null || deviceType != null) {
        return BleDeviceInfo(
          manufacturer: manufacturer,
          deviceType: deviceType ?? 'BLE Device',
        );
      }
      if (deviceName != null && deviceName.isNotEmpty) {
        return BleDeviceInfo(deviceType: 'BLE Device');
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _inFlight.remove(remoteId);
      try {
        await device.disconnect();
      } catch (_) {
        // Best-effort disconnect
      }
    }
  }

  /// Map well-known GATT service UUIDs to device types.
  static String? _deviceTypeFromGatt(List<String> uuids) {
    final uuidSet = uuids.toSet();
    // Heart Rate
    if (uuidSet.any((u) => u.startsWith('180d'))) {
      return 'Heart Rate Monitor';
    }
    // HID (keyboard/mouse/gamepad)
    if (uuidSet.any((u) => u.startsWith('1812'))) return 'HID Peripheral';
    // Blood Pressure
    if (uuidSet.any((u) => u.startsWith('1810'))) {
      return 'Blood Pressure Monitor';
    }
    // Health Thermometer
    if (uuidSet.any((u) => u.startsWith('1809'))) return 'Thermometer';
    // Running Speed
    if (uuidSet.any((u) => u.startsWith('1814'))) return 'Running Sensor';
    // Cycling Speed
    if (uuidSet.any((u) => u.startsWith('1816'))) return 'Cycling Sensor';
    // Environmental Sensing
    if (uuidSet.any((u) => u.startsWith('181a'))) {
      return 'Environment Sensor';
    }
    // Battery Service only — generic but identified
    if (uuidSet.any((u) => u.startsWith('180f'))) return 'BLE Device';
    return null;
  }

  /// Try to guess manufacturer from device name.
  static String? _manufacturerFromName(String? name) {
    if (name == null || name.isEmpty) return null;
    final lower = name.toLowerCase();
    if (lower.contains('apple') || lower.contains('iphone') ||
        lower.contains('ipad') || lower.contains('macbook')) {
      return 'Apple';
    }
    if (lower.contains('samsung') || lower.startsWith('sm-') ||
        lower.contains('galaxy')) {
      return 'Samsung';
    }
    if (lower.contains('google') || lower.contains('nest') ||
        lower.contains('pixel')) {
      return 'Google';
    }
    if (lower.contains('bose')) return 'Bose';
    if (lower.contains('sony')) return 'Sony';
    if (lower.contains('jbl')) return 'JBL';
    if (lower.contains('fitbit')) return 'Fitbit';
    if (lower.contains('garmin')) return 'Garmin';
    return null;
  }
}
