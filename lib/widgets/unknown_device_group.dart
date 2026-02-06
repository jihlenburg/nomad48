import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/brand_icons.dart';
import 'device_card_helpers.dart';

enum ProbeState { idle, probing, failed }

class UnknownDeviceGroup extends StatefulWidget {
  final List<ScanResult> unknowns;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Map<String, ProbeState> probeStates;
  final void Function(BluetoothDevice device) onProbe;

  const UnknownDeviceGroup({
    super.key,
    required this.unknowns,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.probeStates,
    required this.onProbe,
  });

  @override
  State<UnknownDeviceGroup> createState() => _UnknownDeviceGroupState();
}

class _UnknownDeviceGroupState extends State<UnknownDeviceGroup>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('[UnkGrp] initState  isExpanded=${widget.isExpanded}');
  }

  @override
  void didUpdateWidget(UnknownDeviceGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      debugPrint('[UnkGrp] didUpdateWidget  isExpanded: ${oldWidget.isExpanded} → ${widget.isExpanded}');
    }
  }

  @override
  void dispose() {
    debugPrint('[UnkGrp] dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey('unknown-group'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(Icons.bluetooth_disabled,
            color: theme.colorScheme.outline, size: 24),
        title: Text(
          'Unknown Devices (${widget.unknowns.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
        initiallyExpanded: widget.isExpanded,
        onExpansionChanged: widget.onExpansionChanged,
        children: [
          for (final r in widget.unknowns)
            _buildUnknownListTile(r, context, theme),
        ],
      ),
    );
  }

  Widget _buildUnknownListTile(
      ScanResult result, BuildContext context, ThemeData theme) {
    final device = result.device;
    final adv = result.advertisementData;
    final rssi = result.rssi;
    final label = unknownLabel(device.remoteId.str);

    return ListTile(
      dense: true,
      leading: Icon(Icons.bluetooth,
          size: 20, color: theme.colorScheme.outline.withAlpha(150)),
      title: Text(
        adv.advName.isNotEmpty ? adv.advName : label,
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withAlpha(130),
        ),
      ),
      subtitle: Row(
        children: [
          BrandIcons.signalBars(rssi, height: 12),
          const SizedBox(width: 4),
          Text('$rssi dBm',
              style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withAlpha(100))),
          if (adv.connectable) ...[
            const SizedBox(width: 4),
            const Icon(Icons.link, size: 12, color: Colors.green),
          ],
        ],
      ),
      trailing:
          adv.connectable ? _buildProbeButton(result, theme) : null,
    );
  }

  Widget _buildProbeButton(ScanResult result, ThemeData theme) {
    final id = result.device.remoteId.str;
    final state = widget.probeStates[id] ?? ProbeState.idle;

    switch (state) {
      case ProbeState.idle:
        return IconButton(
          icon: Icon(Icons.search, size: 20, color: theme.colorScheme.primary),
          tooltip: 'Identify',
          onPressed: () => widget.onProbe(result.device),
        );
      case ProbeState.probing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ProbeState.failed:
        return IconButton(
          icon: const Icon(Icons.refresh, size: 20, color: Colors.orange),
          tooltip: 'Retry',
          onPressed: () => widget.onProbe(result.device),
        );
    }
  }
}
