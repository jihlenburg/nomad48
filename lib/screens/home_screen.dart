import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/app_constants.dart';
import '../models/ble_manufacturer.dart';
import '../models/thermobeacon.dart';
import '../services/ble_service.dart';
import '../services/device_identification_cache.dart';
import '../services/device_probe_service.dart';
import '../services/expansion_state_service.dart';
import '../widgets/identified_device_card.dart';
import '../widgets/thermobeacon_card.dart';
import '../widgets/unknown_device_group.dart';
import 'device_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final _probeService = DeviceProbeService.instance;
  final _expansionService = ExpansionStateService.instance;
  final _idCache = DeviceIdentificationCache();

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  String? _errorMessage;
  StreamSubscription<List<ScanResult>>? _scanResultsSub;
  StreamSubscription<bool>? _isScanningStateSub;
  final Map<String, ProbeState> _probeStates = {};

  // -- Lifecycle --

  @override
  void initState() {
    super.initState();
    _listenToScanResults();
    _checkBluetoothOnStart();
  }

  Future<void> _checkBluetoothOnStart() async {
    if (!await _bleService.requestPermissions()) {
      setState(() {
        _errorMessage =
            'Bluetooth permissions are required.\n'
            'Please grant permissions in Settings.';
      });
    }
  }

  void _listenToScanResults() {
    _scanResultsSub = _bleService.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _idCache.sortAndPrune(results);
          _scanResults = results;
        });
      }
    });

    _isScanningStateSub = _bleService.isScanning.listen((isScanning) {
      if (mounted) {
        setState(() => _isScanning = isScanning);
      }
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _errorMessage = null;
      _scanResults.clear();
    });
    try {
      await _bleService.startScan();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _stopScan() async {
    await _bleService.stopScan();
  }

  void _openDeviceDetail(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(device: device),
      ),
    );
  }

  // -- Probe --

  Future<void> _probeDevice(BluetoothDevice device) async {
    final id = device.remoteId.str;
    setState(() => _probeStates[id] = ProbeState.probing);

    final result = await _probeService.probe(device);

    if (!mounted) return;
    setState(() {
      if (result != null) {
        _probeStates.remove(id);
      } else {
        _probeStates[id] = ProbeState.failed;
        Future.delayed(BleConstants.probeFailureResetDelay, () {
          if (mounted) {
            setState(() {
              if (_probeStates[id] == ProbeState.failed) {
                _probeStates[id] = ProbeState.idle;
              }
            });
          }
        });
      }
    });
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.error.withAlpha(30),
            child: Row(
              children: [
                Icon(Icons.error, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? _stopScan : _startScan,
                  icon: Icon(_isScanning ? Icons.stop : Icons.search),
                  label: Text(_isScanning ? 'Stop Scan' : 'Start Scan'),
                ),
              ),
            ],
          ),
        ),
        if (_isScanning)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LinearProgressIndicator(color: theme.colorScheme.primary),
          ),
        Expanded(
          child: _scanResults.isEmpty
              ? Center(
                  child: Text(
                    _isScanning
                        ? 'Scanning for devices...'
                        : 'No devices found. Tap "Start Scan" to begin.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                )
              : _buildDeviceList(),
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    final known = <ScanResult>[];
    final unknown = <ScanResult>[];
    for (final r in _scanResults) {
      (_idCache.isKnown(r) ? known : unknown).add(r);
    }

    return ListView(
      key: const ValueKey('device-list'),
      children: [
        for (final r in known) _buildDeviceCard(r),
        if (unknown.isNotEmpty)
          UnknownDeviceGroup(
            unknowns: unknown,
            isExpanded: _expansionService.getOrDefault('unknown-group'),
            onExpansionChanged: (expanded) =>
                _expansionService.set('unknown-group', expanded),
            probeStates: _probeStates,
            onProbe: _probeDevice,
          ),
      ],
    );
  }

  Widget _buildDeviceCard(ScanResult result) {
    final device = result.device;
    final adv = result.advertisementData;
    final rssi = result.rssi;

    final thermoData = ThermoBeaconData.decode(adv.manufacturerData);
    if (thermoData != null) {
      return ThermoBeaconCard(
        key: ValueKey(device.remoteId.str),
        device: device,
        advertisementData: adv,
        rssi: rssi,
        thermoData: thermoData,
        isExpanded: _expansionService.getOrDefault(device.remoteId.str),
        onExpansionChanged: (expanded) =>
            _expansionService.set(device.remoteId.str, expanded),
        onConnect: () => _openDeviceDetail(device),
      );
    }

    var info = _idCache.identify(result);
    if (!info.isIdentified) {
      final cached = _probeService.getCached(device.remoteId.str);
      if (cached != null &&
          (cached.manufacturer != null || cached.deviceType != null)) {
        info = BleDeviceInfo(
          manufacturer: cached.manufacturer,
          deviceType: cached.deviceType ?? 'BLE Device',
        );
      }
    }

    return IdentifiedDeviceCard(
      key: ValueKey(device.remoteId.str),
      device: device,
      advertisementData: adv,
      rssi: rssi,
      info: info,
      isExpanded: _expansionService.getOrDefault(device.remoteId.str),
      onExpansionChanged: (expanded) =>
          _expansionService.set(device.remoteId.str, expanded),
      onConnect: () => _openDeviceDetail(device),
    );
  }

  @override
  void dispose() {
    _scanResultsSub?.cancel();
    _isScanningStateSub?.cancel();
    _bleService.stopScan();
    super.dispose();
  }
}
