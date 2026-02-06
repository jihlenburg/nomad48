import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

/// Persists ExpansionTile expanded/collapsed state in Hive.
///
/// Keys are device `remoteId.str` or `'unknown-group'`.
/// Default is collapsed (`false`).
class ExpansionStateService {
  ExpansionStateService._();
  static final instance = ExpansionStateService._();

  static const _boxName = HiveBoxNames.expansionState;

  bool getOrDefault(String key, {bool defaultValue = false}) {
    final box = Hive.box<bool>(_boxName);
    final value = box.get(key, defaultValue: defaultValue) ?? defaultValue;
    debugPrint('[Expansion] GET "$key" → $value (box has ${box.length} keys)');
    return value;
  }

  void set(String key, bool expanded) {
    debugPrint('[Expansion] SET "$key" → $expanded');
    Hive.box<bool>(_boxName).put(key, expanded);
  }
}
