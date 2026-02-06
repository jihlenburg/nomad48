import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/app_constants.dart';
import '../models/thermobeacon.dart';
import 'device_card_helpers.dart';

class ThermoBeaconCard extends StatefulWidget {
  final BluetoothDevice device;
  final AdvertisementData advertisementData;
  final int rssi;
  final ThermoBeaconData thermoData;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onConnect;

  const ThermoBeaconCard({
    super.key,
    required this.device,
    required this.advertisementData,
    required this.rssi,
    required this.thermoData,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onConnect,
  });

  @override
  State<ThermoBeaconCard> createState() => _ThermoBeaconCardState();
}

class _ThermoBeaconCardState extends State<ThermoBeaconCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String get _shortId =>
      widget.device.remoteId.str.substring(widget.device.remoteId.str.length - 8);

  @override
  void initState() {
    super.initState();
    debugPrint('[TBCard] initState $_shortId  isExpanded=${widget.isExpanded}');
  }

  @override
  void didUpdateWidget(ThermoBeaconCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      debugPrint('[TBCard] didUpdateWidget $_shortId  isExpanded: ${oldWidget.isExpanded} → ${widget.isExpanded}');
    }
  }

  @override
  void dispose() {
    debugPrint('[TBCard] dispose $_shortId');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(Icons.thermostat,
            color: _tempColor(widget.thermoData.temperature)),
        title: Text(
          widget.advertisementData.advName.isNotEmpty
              ? widget.advertisementData.advName
              : 'ThermoBeacon',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
                '${widget.thermoData.temperature.toStringAsFixed(1)}\u00B0C'),
            const SizedBox(width: 8),
            Text('${widget.thermoData.humidity.toStringAsFixed(1)}%'),
            const SizedBox(width: 8),
            _batteryIcon(widget.thermoData.batteryPercent),
          ],
        ),
        initiallyExpanded: widget.isExpanded,
        onExpansionChanged: widget.onExpansionChanged,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _sensorTile(
                        icon: Icons.thermostat,
                        color: _tempColor(widget.thermoData.temperature),
                        label: 'Temperature',
                        value:
                            '${widget.thermoData.temperature.toStringAsFixed(2)} \u00B0C',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _sensorTile(
                        icon: Icons.water_drop,
                        color: theme.colorScheme.tertiary,
                        label: 'Humidity',
                        value:
                            '${widget.thermoData.humidity.toStringAsFixed(2)} %',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _sensorTile(
                        icon: Icons.battery_std,
                        color: _batteryColor(widget.thermoData.batteryPercent),
                        label: 'Battery',
                        value:
                            '${widget.thermoData.batteryPercent}% (${widget.thermoData.batteryMv} mV)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _sensorTile(
                        icon: Icons.timer,
                        color: theme.colorScheme.outline,
                        label: 'Uptime',
                        value: widget.thermoData.uptimeString,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('RSSI: ${widget.rssi} dBm',
                        style: detailStyle(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('ID: ${widget.device.remoteId}',
                          style: detailStyle(context),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (widget.advertisementData.connectable) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onConnect,
                      child: const Text('Connect'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _batteryIcon(int percent) {
    final IconData icon;
    if (percent > BatteryThresholds.high) {
      icon = Icons.battery_full;
    } else if (percent > BatteryThresholds.medium) {
      icon = Icons.battery_5_bar;
    } else if (percent > BatteryThresholds.low) {
      icon = Icons.battery_3_bar;
    } else {
      icon = Icons.battery_1_bar;
    }
    return Icon(icon, size: 16, color: _batteryColor(percent));
  }

  static Color _tempColor(double temp) {
    if (temp < TemperatureThresholds.cold) return Colors.blue;
    if (temp < TemperatureThresholds.comfortable) return Colors.green;
    if (temp < TemperatureThresholds.warm) return Colors.orange;
    return Colors.red;
  }

  static Color _batteryColor(int percent) {
    if (percent > BatteryThresholds.medium) return Colors.green;
    if (percent > BatteryThresholds.low) return Colors.orange;
    return Colors.red;
  }
}
