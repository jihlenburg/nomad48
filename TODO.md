# TODO - NOMAD48 Project Tasks

Last Updated: 2026-02-06

## Active Tasks

### High Priority
- [ ] Grant location permission in iOS Settings for BLE
- [ ] Test BLE scanning with real devices
- [ ] Get paid Apple Developer account ($99/year) for NFC support
- [ ] Test NFC functionality after getting paid account
- [ ] Document NOMAD48 device protocol (UUIDs, characteristics, services)
- [ ] Test Android build with actual BLE hardware

### Medium Priority
- [ ] Add BLE device filtering by name or service UUID
- [ ] Implement persistent BLE connection management
- [ ] Add connection state indicator in UI
- [ ] Create device detail screen for connected BLE devices
- [ ] Add characteristic read/write functionality for BLE devices
- [ ] Implement NFC tag history/saved tags feature
- [ ] Add data validation for NFC writes
- [ ] Create custom NDEF record types for NOMAD48-specific data

### Low Priority
- [ ] Implement app settings screen
- [ ] Add BLE scan filters (RSSI threshold, service UUIDs)
- [ ] Create onboarding tutorial for first-time users
- [ ] Add export/import functionality for NFC tag data
- [ ] Implement logging system for debugging
- [ ] Add unit tests for BLE service
- [ ] Add unit tests for NFC service
- [ ] Add widget tests for main screens

### Unit Tests for Decoders & Sort Logic (2026-02-06)
- [x] ThermoBeacon decode tests (13 tests)
- [x] Apple Continuity TLV decoder tests (19 tests)
- [x] BLE manufacturer identification tests (30 tests)
- [x] RSSI sort hysteresis tests (9 tests)
- [x] 93 total tests, all passing
- [ ] Implement analytics (privacy-respecting)
- [ ] Add multi-language support (i18n)
- [ ] Create app icon

## In Progress
_No tasks currently in progress_

## Blocked
_No blocked tasks_

## Completed

### Initial Setup (2026-02-05)
- [x] Flutter project initialization
- [x] Git repository setup and connection to GitHub
- [x] BLE dependencies added (flutter_blue_plus)
- [x] NFC dependencies added (nfc_manager)
- [x] Permission handler setup
- [x] Platform-specific permissions configuration (iOS and Android)
- [x] BLE service implementation
- [x] NFC service implementation
- [x] Home screen with BLE scanning UI
- [x] NFC screen with read/write functionality
- [x] Tabbed main interface (BLE and NFC tabs)
- [x] Enhanced ISO 15693 (Type 5) tag support
- [x] Comprehensive README.md documentation
- [x] Project-specific CLAUDE.md instructions
- [x] NFC tag support documentation
- [x] Task management workflow established
- [x] CocoaPods installed and dependencies configured
- [x] First iOS deployment to physical device
- [x] Fixed BLE permission requests for iOS (locationWhenInUse)
- [x] Improved BLE error messages with clear instructions
- [x] Discovered free Apple accounts don't support NFC
- [x] Removed NFC entitlements to allow building with free account
- [x] Updated Xcode project configuration

### Manufacturer Icons & Device Display (2026-02-06)
- [x] Added `simple_icons` package for brand SVG icons
- [x] Created `lib/utils/brand_icons.dart` — centralized brand icon/color resolution
- [x] Fixed icon priority bug (device type first, brand fallback)
- [x] Fixed TV detection (QLED, OLED, screen sizes, soundbar patterns)
- [x] Removed `icon` field from BleManufacturer/BleDeviceInfo (clean separation)
- [x] Added RSSI signal strength bars to device cards
- [x] Added brand icon badge overlay (e.g. Apple logo on headphones icon)
- [x] Improved unknown device display (dimmed, collapsed by default)
- [x] Dark mode brand color adjustments (brightness-aware)
- [x] Increased dark theme badge alpha for readability

### Unknown Device Handling Improvements (2026-02-06)
- [x] Shortened unknown device labels — "Unknown (ACC1)" from last 4 hex digits of MAC
- [x] Sort scan results by priority: ThermoBeacons > identified > unknowns, RSSI within groups
- [x] Apple Continuity TLV decoder — identifies hidden iPhones, AirPods, Macs, Apple TVs
- [x] AirPods model code lookup (AirPods 1/2/3, Pro/Pro 2, Max, Beats variants)
- [x] Collapsed "Unknown Devices (N)" group card with compact list tiles
- [x] GATT probe service — "Identify" button connects, reads GATT, caches result in Hive
- [x] 24-hour Hive cache for probe results (survives app restart)
- [x] Probe UI: search icon -> spinner -> retry (auto-resets after 5s)
- [x] Probed devices move from unknown group to known list

### Native Splash Screen (2026-02-06)
- [x] Added `flutter_native_splash` dev dependency
- [x] Configured branded splash: primary blue `#1E384B` (light), dark blue `#0F1D28` (dark)
- [x] Generated platform-native splash assets for iOS and Android (including Android 12+)

### Persist ExpansionTile State (2026-02-06)
- [x] Created ExpansionStateService singleton wrapping Hive `Box<bool>`
- [x] Opened `expansion_state` box in main.dart
- [x] Wired all 3 ExpansionTiles to read/write state via service
- [x] Removed `shouldExpand` heuristic — all cards start collapsed, user choice persisted
- [x] Cleaned up unused `hasPayload` parameter

### Dark Mode, Device Detail Screen, App Icon (2026-02-06)
- [x] Dark mode toggle — system/light/dark cycle button in app bar, Hive-persisted
- [x] Device detail screen — GATT service/characteristic browser with read/write/notify
- [x] Custom branded app icon (N + orange accent on primary blue)
- [x] flutter_launcher_icons for iOS + Android adaptive icons

### Fix Jumpy List Sort: Stable Sort + RSSI Hysteresis (2026-02-06)
- [x] Fixed unstable sort — added `remoteId` tiebreaker for equal tier+RSSI
- [x] Added 5 dBm RSSI hysteresis — sort position only updates on genuine signal changes
- [x] Result: 7 swaps across 140 cycles (81 devices), down from hundreds
- [x] Added `[Sort]` diff logging for ongoing diagnostics

### ID-Cache Performance Fix (2026-02-06)
- [x] Fixed _sortAndCacheResults() clearing cache every scan cycle
- [x] Cache now persists across cycles, only prunes stale entries
- [x] Reduced debug log noise (only logs new or re-identified devices)

### Dependency Upgrade (2026-02-06)
- [x] flutter_blue_plus 1.36.8 → 2.1.0 (added `license: License.free` to all `connect()` calls)
- [x] nfc_manager 3.5.0 → 4.1.1 + nfc_manager_ndef 1.1.0 + ndef_record 1.4.1
- [x] permission_handler 11.4.0 → 12.0.1
- [x] simple_icons 10.1.3 → 14.6.1 (Microsoft icon removed, replaced with hardcoded color)
- [x] Removed hive_generator + build_runner dev deps (30+ transitive deps cleaned)
- [x] 93 tests passing, 0 analysis issues

### Full Codebase Refactor (2026-02-06)
- [x] Removed unused `provider` dependency
- [x] Removed dead service methods (discoverServices, formatNdef, isIso15693Tag)
- [x] Replaced placeholder counter-app test with NOMAD48 smoke test
- [x] Extracted constants to `lib/constants/app_constants.dart`
- [x] Extracted ThermoBeaconCard widget to `lib/widgets/thermobeacon_card.dart`
- [x] Extracted IdentifiedDeviceCard widget to `lib/widgets/identified_device_card.dart`
- [x] Extracted UnknownDeviceGroup widget to `lib/widgets/unknown_device_group.dart`
- [x] Extracted shared helpers to `lib/widgets/device_card_helpers.dart`
- [x] Extracted DeviceIdentificationCache to `lib/services/device_identification_cache.dart`
- [x] Fixed stream subscription memory leak in home_screen.dart
- [x] Deduplicated NFC write methods in nfc_screen.dart
- [x] Slimmed home_screen.dart from 802 lines to ~270 lines
- [x] Updated CLAUDE.md, README.md, QUICKSTART.md
- [x] Removed outdated SESSION_SUMMARY.md

## Future Considerations

### Architecture
- Consider implementing Repository pattern for data layer
- Evaluate state management alternatives (Riverpod, Bloc)
- Expand Hive usage for additional local storage needs

### Features
- Background BLE scanning (iOS background modes)
- NFC tag emulation (Android)
- QR code scanning for device pairing
- Bluetooth Classic support (if needed)
- Custom NOMAD48 protocol implementation

### Performance
- Optimize BLE scan performance
- Implement connection pooling for multiple devices
- Add memory leak detection in development

### Security
- Implement secure storage for sensitive data
- Add encryption for BLE communications
- Validate all NFC tag data before processing

## Notes

- iOS NFC requires physical device (iPhone 7+)
- Android BLE permissions differ between API 30 and 31+
- Test on multiple device manufacturers for compatibility
- Keep dependencies updated but test thoroughly after updates
