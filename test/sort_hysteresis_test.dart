import 'package:flutter_test/flutter_test.dart';
import 'package:nomad48/constants/app_constants.dart';

/// Tests for the RSSI hysteresis logic used in sort stabilization.
///
/// The actual _sortRssi() method is private to DeviceIdentificationCache,
/// so we test the algorithm in isolation here to verify the threshold math.
void main() {
  group('RSSI hysteresis algorithm', () {
    // Replicate the _sortRssi logic for testing.
    final stableRssi = <String, int>{};

    int sortRssi(String id, int rawRssi) {
      final prev = stableRssi[id];
      if (prev == null ||
          (rawRssi - prev).abs() > RssiThresholds.sortHysteresis) {
        stableRssi[id] = rawRssi;
        return rawRssi;
      }
      return prev;
    }

    setUp(() {
      stableRssi.clear();
    });

    test('first reading is accepted as-is', () {
      expect(sortRssi('A', -70), -70);
    });

    test('small fluctuation within band is suppressed', () {
      sortRssi('A', -70);
      // Within 5 dBm
      expect(sortRssi('A', -72), -70);
      expect(sortRssi('A', -68), -70);
      expect(sortRssi('A', -65), -70); // exactly 5, not > 5
    });

    test('fluctuation exceeding band updates stable value', () {
      sortRssi('A', -70);
      // More than 5 dBm away
      expect(sortRssi('A', -76), -76);
    });

    test('upward jump exceeding band updates', () {
      sortRssi('A', -80);
      expect(sortRssi('A', -74), -74); // 6 dBm improvement
    });

    test('stable value tracks after update', () {
      sortRssi('A', -70);
      sortRssi('A', -76); // updates to -76
      // Now small fluctuation around -76 is suppressed
      expect(sortRssi('A', -78), -76);
      expect(sortRssi('A', -74), -76);
    });

    test('multiple devices are independent', () {
      sortRssi('A', -70);
      sortRssi('B', -90);

      expect(sortRssi('A', -72), -70); // A suppressed
      expect(sortRssi('B', -92), -90); // B suppressed
      expect(sortRssi('A', -80), -80); // A updates (10 dBm)
      expect(sortRssi('B', -92), -90); // B still suppressed
    });

    test('hysteresis threshold matches constant', () {
      expect(RssiThresholds.sortHysteresis, 5);
    });

    test('boundary: exactly at threshold is suppressed', () {
      sortRssi('A', -70);
      // Exactly sortHysteresis (5) away — not strictly greater, so suppressed
      expect(sortRssi('A', -75), -70);
      expect(sortRssi('A', -65), -70);
    });

    test('boundary: one past threshold updates', () {
      sortRssi('A', -70);
      expect(sortRssi('A', -76), -76); // 6 > 5
      stableRssi.clear();
      sortRssi('A', -70);
      expect(sortRssi('A', -64), -64); // 6 > 5
    });
  });
}
