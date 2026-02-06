import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

/// Service for managing Bluetooth Low Energy operations
class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Check Bluetooth adapter state, waiting for initialization
  Future<BluetoothAdapterState> getAdapterState() async {
    try {
      // Wait for a definitive state (skip unknown during init)
      final state = await FlutterBluePlus.adapterState
          .where((s) => s != BluetoothAdapterState.unknown)
          .first
          .timeout(BleConstants.adapterStateTimeout,
              onTimeout: () => BluetoothAdapterState.unknown);
      return state;
    } catch (e) {
      return BluetoothAdapterState.unknown;
    }
  }

  /// Request necessary permissions for BLE operations (Android only)
  /// On iOS, CoreBluetooth handles authorization automatically.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      // iOS: CoreBluetooth handles Bluetooth authorization natively.
      // The system dialog is triggered automatically when we access
      // the Bluetooth adapter. No permission_handler needed.
      return true;
    }

    // Android: Request location and Bluetooth permissions
    try {
      final results = await [
        Permission.locationWhenInUse,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      // Location is required on Android for BLE scanning
      final locationGranted =
          results[Permission.locationWhenInUse]?.isGranted ?? false;
      final scanGranted =
          results[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted =
          results[Permission.bluetoothConnect]?.isGranted ?? false;

      return locationGranted && (scanGranted || connectGranted);
    } catch (e) {
      return false;
    }
  }

  /// Start scanning for BLE devices
  Future<void> startScan({
    Duration timeout = BleConstants.scanTimeout,
  }) async {
    // On Android, check permissions first
    if (Platform.isAndroid) {
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw Exception('Bluetooth permissions not granted. '
            'Please grant Location and Bluetooth permissions in Settings.');
      }
    }

    // Check Bluetooth adapter state
    final adapterState = await getAdapterState();

    switch (adapterState) {
      case BluetoothAdapterState.on:
        // Good to go
        break;
      case BluetoothAdapterState.off:
        throw Exception('Bluetooth is turned off. '
            'Please enable Bluetooth in Settings.');
      case BluetoothAdapterState.unauthorized:
        throw Exception('Bluetooth permission denied. '
            'Please enable Bluetooth for Nomad48 in Settings → Privacy & Security → Bluetooth.');
      case BluetoothAdapterState.unavailable:
        throw Exception('Bluetooth is not available on this device.');
      default:
        throw Exception(
            'Bluetooth is in an unknown state. Please try again.');
    }

    // Start scanning
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  /// Stop scanning for BLE devices
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Get scan results stream
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// Get scanning state stream
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  /// Connect to a BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 30),
        autoConnect: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Disconnect from a BLE device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _scanSubscription?.cancel();
  }
}
