import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/app_constants.dart';
import '../models/ble_manufacturer.dart';
import '../models/thermobeacon.dart';
import 'device_probe_service.dart';

/// Per-session cache for BLE device identification results.
///
/// Avoids calling [BleManufacturer.identify] multiple times per scan cycle
/// for the same device. Handles platformName-triggered re-identification
/// when CoreBluetooth resolves names asynchronously.
class DeviceIdentificationCache {
  final Map<String, BleDeviceInfo> _cache = {};
  final Map<String, String> _cachePlatformName = {};
  final DeviceProbeService _probeService;

  // RSSI hysteresis — stabilized RSSI used for sorting.
  // Only updates when raw RSSI drifts beyond the hysteresis band.
  final Map<String, int> _stableRssi = {};

  // Sort debug state — tracks previous cycle for diff logging.
  List<String> _prevOrder = [];
  Map<String, int> _prevTiers = {};
  Map<String, int> _prevRssi = {};
  int _cycleCount = 0;
  int _orderChanges = 0;

  DeviceIdentificationCache({DeviceProbeService? probeService})
      : _probeService = probeService ?? DeviceProbeService.instance;

  BleDeviceInfo identify(ScanResult r) {
    final id = r.device.remoteId.str;
    final cached = _cache[id];
    final currentPlatformName = r.device.platformName;
    final cachedPlatformName = _cachePlatformName[id] ?? '';

    if (cached != null && cached.manufacturer != null) {
      if (currentPlatformName == cachedPlatformName ||
          currentPlatformName.isEmpty) {
        return cached;
      }
    }
    if (cached != null && currentPlatformName == cachedPlatformName) {
      return cached;
    }

    final adv = r.advertisementData;
    final info = BleManufacturer.identify(
      manufacturerData: adv.manufacturerData,
      advName: adv.advName,
      platformName: currentPlatformName,
      serviceUuids: adv.serviceUuids,
    );
    if (cached == null) {
      if (info.isIdentified) {
        debugPrint('[ID-cache] $id NEW \u2192 ${info.manufacturer}/${info.deviceType}');
      }
    } else if (cachedPlatformName != currentPlatformName) {
      debugPrint('[ID-cache] $id RE-ID (platformName changed: '
          '"$cachedPlatformName"\u2192"$currentPlatformName") \u2192 '
          '${info.manufacturer}/${info.deviceType}');
    }
    _cache[id] = info;
    _cachePlatformName[id] = currentPlatformName;
    return info;
  }

  /// Prune entries for devices no longer present in scan results.
  void prune(Set<String> currentIds) {
    _cache.removeWhere((id, _) => !currentIds.contains(id));
    _cachePlatformName.removeWhere((id, _) => !currentIds.contains(id));
  }

  /// Sort priority: ThermoBeacons (0), identified/probed (1), unknown (2).
  int sortPriority(ScanResult r) {
    final adv = r.advertisementData;
    if (ThermoBeaconData.decode(adv.manufacturerData) != null) return 0;
    final info = identify(r);
    if (info.isIdentified) return 1;
    final cached = _probeService.getCached(r.device.remoteId.str);
    if (cached != null &&
        (cached.manufacturer != null || cached.deviceType != null)) {
      return 1;
    }
    return 2;
  }

  /// Short ID for logging — last 4 characters of remote ID.
  static String _shortId(String remoteId) {
    return remoteId.length > 4
        ? remoteId.substring(remoteId.length - 4)
        : remoteId;
  }

  /// Return the stabilized RSSI for sorting. Only updates when the raw
  /// value drifts beyond [RssiThresholds.sortHysteresis] from the last
  /// stable value, preventing small fluctuations from reordering the list.
  int _sortRssi(String id, int rawRssi) {
    final prev = _stableRssi[id];
    if (prev == null || (rawRssi - prev).abs() > RssiThresholds.sortHysteresis) {
      _stableRssi[id] = rawRssi;
      return rawRssi;
    }
    return prev;
  }

  /// Sort results in-place by priority then RSSI, pruning stale cache entries.
  void sortAndPrune(List<ScanResult> results) {
    final currentIds = results.map((r) => r.device.remoteId.str).toSet();
    prune(currentIds);
    _stableRssi.removeWhere((id, _) => !currentIds.contains(id));

    results.sort((a, b) {
      final pa = sortPriority(a);
      final pb = sortPriority(b);
      if (pa != pb) return pa.compareTo(pb);
      final ra = _sortRssi(a.device.remoteId.str, a.rssi);
      final rb = _sortRssi(b.device.remoteId.str, b.rssi);
      final rssiCmp = rb.compareTo(ra);
      if (rssiCmp != 0) return rssiCmp;
      return a.device.remoteId.str.compareTo(b.device.remoteId.str);
    });

    _logSortDiff(results);
  }

  /// Compare current sort cycle against previous cycle and log meaningful
  /// changes. Avoids flooding the console — only logs when something moved.
  void _logSortDiff(List<ScanResult> results) {
    _cycleCount++;

    // Build current state maps.
    final curOrder = <String>[];
    final curTiers = <String, int>{};
    final curRssi = <String, int>{};
    for (final r in results) {
      final id = r.device.remoteId.str;
      curOrder.add(id);
      curTiers[id] = sortPriority(r);
      curRssi[id] = r.rssi;
    }

    // Detect new and removed devices.
    final prevSet = _prevOrder.toSet();
    final curSet = curOrder.toSet();
    final added = curSet.difference(prevSet);
    final removed = prevSet.difference(curSet);

    for (final id in added) {
      debugPrint('[Sort] +${_shortId(id)} '
          '(tier ${curTiers[id]}, rssi ${curRssi[id]})');
    }
    for (final id in removed) {
      debugPrint('[Sort] -${_shortId(id)}');
    }

    // Detect tier flips.
    for (final id in curOrder) {
      final prevTier = _prevTiers[id];
      final curTier = curTiers[id]!;
      if (prevTier != null && prevTier != curTier) {
        debugPrint('[Sort] TIER FLIP ${_shortId(id)}: '
            '$prevTier\u2192$curTier (rssi: ${curRssi[id]})');
      }
    }

    // Detect RSSI-driven swaps within the same tier.
    // Look for adjacent pairs that swapped order while staying in same tier.
    if (_prevOrder.length >= 2) {
      for (int i = 0; i < curOrder.length - 1; i++) {
        final a = curOrder[i];
        final b = curOrder[i + 1];
        final curTierA = curTiers[a]!;
        final curTierB = curTiers[b]!;
        if (curTierA != curTierB) continue;

        final prevIdxA = _prevOrder.indexOf(a);
        final prevIdxB = _prevOrder.indexOf(b);
        if (prevIdxA == -1 || prevIdxB == -1) continue;
        // They swapped if B was before A in previous cycle.
        if (prevIdxB < prevIdxA) {
          final prevRssiA = _prevRssi[a];
          final prevRssiB = _prevRssi[b];
          if (prevRssiA != null && prevRssiB != null) {
            debugPrint('[Sort] RSSI SWAP ${_shortId(a)}'
                '($prevRssiA\u2192${curRssi[a]}) '
                '\u2194 ${_shortId(b)}'
                '($prevRssiB\u2192${curRssi[b]})');
          }
        }
      }
    }

    // Detect order change.
    final orderChanged = !listEquals(_prevOrder, curOrder);
    if (orderChanged) {
      _orderChanges++;
      final shortIds = curOrder.map(_shortId).toList();
      debugPrint('[Sort] ORDER: $shortIds');
    }

    // Periodic summary every 10 cycles.
    if (_cycleCount % 10 == 0) {
      debugPrint('[Sort] cycle #$_cycleCount: ${results.length} devices, '
          '$_orderChanges order changes in last 10');
      _orderChanges = 0;
    }

    // Save state for next cycle.
    _prevOrder = curOrder;
    _prevTiers = curTiers;
    _prevRssi = curRssi;
  }

  /// Whether a device is "known" (ThermoBeacon, identified, or probed).
  bool isKnown(ScanResult r) {
    final adv = r.advertisementData;
    if (ThermoBeaconData.decode(adv.manufacturerData) != null) return true;
    final info = identify(r);
    if (info.isIdentified) return true;
    final cached = _probeService.getCached(r.device.remoteId.str);
    return cached != null &&
        (cached.manufacturer != null || cached.deviceType != null);
  }
}
