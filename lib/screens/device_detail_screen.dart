import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Screen that connects to a BLE device and browses its GATT services
/// and characteristics. Supports reading and writing characteristic values.
class DeviceDetailScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscovering = false;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;

  // Track which characteristics have been read (id → bytes).
  final Map<String, List<int>> _readValues = {};
  final Set<String> _readingIds = {};
  final Set<String> _subscribedIds = {};

  @override
  void initState() {
    super.initState();
    _connectionSub = widget.device.connectionState.listen((state) {
      if (mounted) {
        setState(() => _connectionState = state);
        if (state == BluetoothConnectionState.connected && _services.isEmpty) {
          _discoverServices();
        }
      }
    });
    _connect();
  }

  Future<void> _connect() async {
    try {
      await widget.device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  Future<void> _discoverServices() async {
    if (_isDiscovering) return;
    setState(() => _isDiscovering = true);
    try {
      final services = await widget.device.discoverServices();
      if (mounted) setState(() => _services = services);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service discovery failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDiscovering = false);
    }
  }

  Future<void> _readCharacteristic(BluetoothCharacteristic c) async {
    final id = _charId(c);
    setState(() => _readingIds.add(id));
    try {
      final value = await c.read();
      if (mounted) {
        setState(() => _readValues[id] = value);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Read failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _readingIds.remove(id));
    }
  }

  Future<void> _writeCharacteristic(BluetoothCharacteristic c) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write Value'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'UTF-8 text or hex (e.g. 0A FF 01)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Write'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;

    try {
      final bytes = _parseWriteInput(result);
      final withResponse = c.properties.writeWithoutResponse
          ? false
          : c.properties.write;
      await c.write(bytes, withoutResponse: !withResponse);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Write successful')),
        );
        // Re-read to show updated value.
        if (c.properties.read) _readCharacteristic(c);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Write failed: $e')),
        );
      }
    }
  }

  Future<void> _toggleNotify(BluetoothCharacteristic c) async {
    final id = _charId(c);
    try {
      final subscribe = !_subscribedIds.contains(id);
      await c.setNotifyValue(subscribe);
      if (mounted) {
        setState(() {
          if (subscribe) {
            _subscribedIds.add(id);
          } else {
            _subscribedIds.remove(id);
          }
        });
      }
      if (subscribe) {
        c.onValueReceived.listen((value) {
          if (mounted) setState(() => _readValues[id] = value);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notify toggle failed: $e')),
        );
      }
    }
  }

  List<int> _parseWriteInput(String input) {
    // Try hex first: "0A FF 01" or "0AFF01"
    final hexPattern = RegExp(r'^[0-9a-fA-F\s]+$');
    final stripped = input.replaceAll(' ', '');
    if (hexPattern.hasMatch(stripped) && stripped.length.isEven) {
      try {
        return List.generate(
          stripped.length ~/ 2,
          (i) => int.parse(stripped.substring(i * 2, i * 2 + 2), radix: 16),
        );
      } catch (_) {
        // Fall through to UTF-8.
      }
    }
    return utf8.encode(input);
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    // Unsubscribe notifications.
    for (final service in _services) {
      for (final c in service.characteristics) {
        if (_subscribedIds.contains(_charId(c))) {
          c.setNotifyValue(false).catchError((_) => false);
        }
      }
    }
    widget.device.disconnect().catchError((_) => null);
    super.dispose();
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected =
        _connectionState == BluetoothConnectionState.connected;
    final name = widget.device.platformName.isNotEmpty
        ? widget.device.platformName
        : widget.device.remoteId.str.substring(
            widget.device.remoteId.str.length - 8);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 18)),
            Text(
              connected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color: connected ? Colors.greenAccent : Colors.white54,
              ),
            ),
          ],
        ),
        actions: [
          if (connected)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rediscover services',
              onPressed: _discoverServices,
            ),
          IconButton(
            icon: Icon(connected ? Icons.link_off : Icons.link),
            tooltip: connected ? 'Disconnect' : 'Connect',
            onPressed: () async {
              if (connected) {
                await widget.device.disconnect();
              } else {
                _connect();
              }
            },
          ),
        ],
      ),
      body: !connected
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Connecting to $name...', style: theme.textTheme.bodyLarge),
                ],
              ),
            )
          : _isDiscovering
              ? const Center(child: CircularProgressIndicator())
              : _services.isEmpty
                  ? Center(
                      child: Text('No services found',
                          style: theme.textTheme.bodyLarge))
                  : ListView.builder(
                      itemCount: _services.length,
                      itemBuilder: (context, index) =>
                          _buildServiceTile(_services[index]),
                    ),
    );
  }

  Widget _buildServiceTile(BluetoothService service) {
    final theme = Theme.of(context);
    final uuid = service.uuid.str;
    final label = _knownServiceName(uuid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: Icon(Icons.account_tree, color: theme.colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(uuid, style: const TextStyle(fontSize: 11)),
        children: [
          for (final c in service.characteristics) _buildCharacteristicTile(c),
        ],
      ),
    );
  }

  Widget _buildCharacteristicTile(BluetoothCharacteristic c) {
    final theme = Theme.of(context);
    final id = _charId(c);
    final uuid = c.uuid.str;
    final label = _knownCharacteristicName(uuid);
    final props = c.properties;
    final value = _readValues[id];
    final isReading = _readingIds.contains(id);
    final isSubscribed = _subscribedIds.contains(id);

    final propLabels = <String>[];
    if (props.read) propLabels.add('R');
    if (props.write) propLabels.add('W');
    if (props.writeWithoutResponse) propLabels.add('WnR');
    if (props.notify) propLabels.add('N');
    if (props.indicate) propLabels.add('I');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 16, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(uuid, style: const TextStyle(fontSize: 10)),
                    Text(propLabels.join(' | '),
                        style: TextStyle(
                            fontSize: 10, color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              if (props.read)
                isReading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.download, size: 18),
                        tooltip: 'Read',
                        onPressed: () => _readCharacteristic(c),
                        visualDensity: VisualDensity.compact,
                      ),
              if (props.write || props.writeWithoutResponse)
                IconButton(
                  icon: const Icon(Icons.upload, size: 18),
                  tooltip: 'Write',
                  onPressed: () => _writeCharacteristic(c),
                  visualDensity: VisualDensity.compact,
                ),
              if (props.notify || props.indicate)
                IconButton(
                  icon: Icon(
                    isSubscribed
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    size: 18,
                    color: isSubscribed ? Colors.green : null,
                  ),
                  tooltip: isSubscribed ? 'Unsubscribe' : 'Subscribe',
                  onPressed: () => _toggleNotify(c),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hex: ${_bytesToHex(value)}',
                        style: _monoStyle(context)),
                    if (_isLikelyUtf8(value))
                      Text(
                          'UTF-8: ${utf8.decode(value, allowMalformed: true)}',
                          style: _monoStyle(context)),
                    if (value.length == 2)
                      Text(
                          'UInt16: ${value[0] | (value[1] << 8)}',
                          style: _monoStyle(context)),
                    if (value.length == 4)
                      Text(
                          'UInt32: ${value[0] | (value[1] << 8) | (value[2] << 16) | (value[3] << 24)}',
                          style: _monoStyle(context)),
                  ],
                ),
              ),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  // -- Helpers --

  static String _charId(BluetoothCharacteristic c) =>
      '${c.serviceUuid}/${c.uuid}';

  static TextStyle _monoStyle(BuildContext context) => TextStyle(
      fontSize: 11,
      fontFamily: 'Courier',
      color: Theme.of(context).colorScheme.onSurface.withAlpha(200));

  static String _bytesToHex(List<int> bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  static bool _isLikelyUtf8(List<int> bytes) =>
      bytes.isNotEmpty && bytes.any((b) => b >= 0x20 && b < 0x7F);

  /// Well-known GATT service names.
  static String _knownServiceName(String uuid) {
    final short = uuid.length > 8 ? uuid.substring(4, 8).toLowerCase() : uuid;
    return _serviceNames[short] ?? 'Service';
  }

  /// Well-known GATT characteristic names.
  static String _knownCharacteristicName(String uuid) {
    final short = uuid.length > 8 ? uuid.substring(4, 8).toLowerCase() : uuid;
    return _characteristicNames[short] ?? 'Characteristic';
  }

  static const _serviceNames = <String, String>{
    '1800': 'Generic Access',
    '1801': 'Generic Attribute',
    '180a': 'Device Information',
    '180d': 'Heart Rate',
    '180f': 'Battery Service',
    '1809': 'Health Thermometer',
    '1810': 'Blood Pressure',
    '1812': 'HID (Keyboard/Mouse)',
    '1814': 'Running Speed',
    '1816': 'Cycling Speed',
    '181a': 'Environmental Sensing',
    '181c': 'User Data',
    'fe95': 'Xiaomi Mi',
    'fd6f': 'Exposure Notification',
  };

  static const _characteristicNames = <String, String>{
    '2a00': 'Device Name',
    '2a01': 'Appearance',
    '2a04': 'Connection Parameters',
    '2a05': 'Service Changed',
    '2a19': 'Battery Level',
    '2a23': 'System ID',
    '2a24': 'Model Number',
    '2a25': 'Serial Number',
    '2a26': 'Firmware Revision',
    '2a27': 'Hardware Revision',
    '2a28': 'Software Revision',
    '2a29': 'Manufacturer Name',
    '2a37': 'Heart Rate Measurement',
    '2a38': 'Body Sensor Location',
    '2a39': 'Heart Rate Control Point',
    '2a1c': 'Temperature Measurement',
    '2a1d': 'Temperature Type',
    '2a6e': 'Temperature',
    '2a6f': 'Humidity',
    '2a6d': 'Pressure',
  };
}
