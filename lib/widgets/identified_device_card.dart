import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_manufacturer.dart';
import '../utils/brand_icons.dart';
import 'device_card_helpers.dart';

class IdentifiedDeviceCard extends StatefulWidget {
  final BluetoothDevice device;
  final AdvertisementData advertisementData;
  final int rssi;
  final BleDeviceInfo info;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onConnect;

  const IdentifiedDeviceCard({
    super.key,
    required this.device,
    required this.advertisementData,
    required this.rssi,
    required this.info,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onConnect,
  });

  @override
  State<IdentifiedDeviceCard> createState() => _IdentifiedDeviceCardState();
}

class _IdentifiedDeviceCardState extends State<IdentifiedDeviceCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String get _shortId =>
      widget.device.remoteId.str.substring(widget.device.remoteId.str.length - 8);

  @override
  void initState() {
    super.initState();
    debugPrint('[IDCard] initState $_shortId  isExpanded=${widget.isExpanded}');
  }

  @override
  void didUpdateWidget(IdentifiedDeviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      debugPrint('[IDCard] didUpdateWidget $_shortId  isExpanded: ${oldWidget.isExpanded} → ${widget.isExpanded}');
    }
  }

  @override
  void dispose() {
    debugPrint('[IDCard] dispose $_shortId');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adv = widget.advertisementData;
    final iconColor = widget.info.isIdentified
        ? BrandIcons.getBrandColor(widget.info.manufacturer, isDark: isDark)
        : theme.colorScheme.outline;

    final displayName = adv.advName.isNotEmpty
        ? adv.advName
        : widget.device.platformName.isNotEmpty
            ? widget.device.platformName
            : widget.info.isIdentified
                ? widget.info.displayLabel
                : unknownLabel(widget.device.remoteId.str);

    final isUnknown = !widget.info.isIdentified;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: BrandIcons.iconWithBadge(
          info: widget.info,
          connectable: adv.connectable,
          isDark: isDark,
          badgeBackground: theme.colorScheme.surface,
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnknown
                ? theme.colorScheme.onSurface.withAlpha(130)
                : null,
          ),
        ),
        subtitle: Row(
          children: [
            BrandIcons.signalBars(widget.rssi),
            const SizedBox(width: 6),
            Text('${widget.rssi} dBm',
                style: TextStyle(
                    fontSize: 12,
                    color: isUnknown
                        ? theme.colorScheme.onSurface.withAlpha(100)
                        : null)),
            if (widget.info.isIdentified) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(isDark ? 50 : 25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.info.displayLabel,
                    style: TextStyle(fontSize: 10, color: iconColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            if (adv.connectable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.link, size: 14, color: Colors.green),
            ],
          ],
        ),
        initiallyExpanded: widget.isExpanded,
        onExpansionChanged: widget.onExpansionChanged,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${widget.device.remoteId}',
                    style: detailStyle(context)),
                if (widget.info.appleContinuitySubType != null)
                  Text(
                      'Continuity: ${widget.info.appleContinuitySubType}',
                      style: detailStyle(context)),
                if (widget.info.appleContinuityModel != null)
                  Text('Model: ${widget.info.appleContinuityModel}',
                      style: detailStyle(context)),
                if (adv.txPowerLevel != null)
                  Text('TX Power: ${adv.txPowerLevel} dBm',
                      style: detailStyle(context)),
                if (adv.connectable)
                  Text('Connectable: Yes', style: detailStyle(context)),
                if (adv.serviceUuids.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Service UUIDs:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface)),
                  for (final uuid in adv.serviceUuids)
                    Text('  $uuid', style: _monoStyle(context)),
                ],
                if (adv.manufacturerData.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Manufacturer Data:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface)),
                  for (final entry in adv.manufacturerData.entries) ...[
                    Text(
                        '  Company ID: 0x${entry.key.toRadixString(16).padLeft(4, '0').toUpperCase()}',
                        style: _monoStyle(context)),
                    Text('  Hex: ${_bytesToHex(entry.value)}',
                        style: _monoStyle(context)),
                    if (_isLikelyUtf8(entry.value))
                      Text(
                          '  UTF-8: ${utf8.decode(entry.value, allowMalformed: true)}',
                          style: _monoStyle(context)),
                  ],
                ],
                if (adv.serviceData.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Service Data:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface)),
                  for (final entry in adv.serviceData.entries) ...[
                    Text('  UUID: ${entry.key}',
                        style: _monoStyle(context)),
                    Text('  Hex: ${_bytesToHex(entry.value)}',
                        style: _monoStyle(context)),
                    if (_isLikelyUtf8(entry.value))
                      Text(
                          '  UTF-8: ${utf8.decode(entry.value, allowMalformed: true)}',
                          style: _monoStyle(context)),
                  ],
                ],
                if (adv.connectable) ...[
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

  static TextStyle _monoStyle(BuildContext context) => TextStyle(
      fontSize: 12,
      fontFamily: 'Courier',
      color: Theme.of(context).colorScheme.onSurface.withAlpha(200));

  static String _bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  static bool _isLikelyUtf8(List<int> bytes) {
    if (bytes.isEmpty) return false;
    return bytes.any((b) => b >= 0x20 && b < 0x7F);
  }
}
