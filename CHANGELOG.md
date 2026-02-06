# CHANGELOG - NOMAD48 Project

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [v0.1.0] - 2026-02-06 — Initial Release

### Summary
First tagged release. BLE scanner with device identification, Apple Continuity decoding, GATT probing, ThermoBeacon support, persistent expansion state, stable sort with RSSI hysteresis.

---

## [2026-02-06] - Fix Jumpy List Sort: Stable Sort + RSSI Hysteresis

### Fixed
- **Unstable sort causing list jumping**: Devices with equal tier and RSSI swapped positions every scan cycle because Dart's `List.sort()` is not stable. Added `remoteId` as a deterministic tiebreaker.
- **RSSI jitter causing reorders**: Added 5 dBm hysteresis band — a device's sort RSSI only updates when the raw value drifts more than 5 dBm from its last stable value. Eliminates reorders from normal radio fluctuation.
  - Before: hundreds of spurious swaps per scan session
  - After: 7 total swaps across 140 cycles with 81 devices — all genuine >5 dBm jumps

### Added
- **`RssiThresholds.sortHysteresis`** constant (5 dBm) in `lib/constants/app_constants.dart`
- **`_stableRssi` map + `_sortRssi()` method** in `DeviceIdentificationCache` — stabilized RSSI used for sorting
- **Sort diff logging** in `lib/services/device_identification_cache.dart`:
  - `[Sort] TIER FLIP`, `[Sort] RSSI SWAP`, `[Sort] +/-`, `[Sort] ORDER`, `[Sort] cycle #N`
  - Only logs when something actually changed — no output when list is stable

### Notes
- All code passes `flutter analyze` with zero issues
- `flutter test` passes

---

## [2026-02-06] - Native Splash Screen

### Added
- **`flutter_native_splash`** (dev dependency): Generates platform-native splash screens from YAML config
- **Branded splash screen**: Replaces white launch screen with solid brand colors
  - Light mode: primary blue `#1E384B` (matches app bar)
  - Dark mode: dark blue `#0F1D28` (matches dark scaffold background)

### Changed
- **`pubspec.yaml`**: Added `flutter_native_splash: ^2.4.0` to dev_dependencies; added `flutter_native_splash:` config block
- **`android/app/src/main/res/drawable/launch_background.xml`**: Updated with branded background color
- **`android/app/src/main/res/drawable-night/launch_background.xml`**: Dark mode variant (auto-generated)
- **`android/app/src/main/res/drawable-v21/launch_background.xml`**: API 21+ variant (auto-generated)
- **`android/app/src/main/res/drawable-night-v21/launch_background.xml`**: Dark mode API 21+ (auto-generated)
- **`android/app/src/main/res/values/styles.xml`**: Splash style updated
- **`android/app/src/main/res/values-night/styles.xml`**: Dark splash style updated
- **`android/app/src/main/res/values-v31/styles.xml`**: Android 12+ splash (new file)
- **`android/app/src/main/res/values-night-v31/styles.xml`**: Android 12+ dark splash (new file)
- **`ios/Runner/Info.plist`**: Status bar configuration for splash

### Notes
- No logo image — solid branded background only (no logo asset exists yet)
- All code passes `flutter analyze` with zero issues
- `flutter test` passes

---

## [2026-02-06] - Full Codebase Refactor & Documentation Update

### Added
- **`lib/constants/app_constants.dart`**: Centralized constants (BLE timeouts, temperature/battery/RSSI thresholds, Hive box names, cache TTL)
- **`lib/widgets/thermobeacon_card.dart`**: Extracted ThermoBeacon card widget (~155 lines)
- **`lib/widgets/identified_device_card.dart`**: Extracted identified device card widget (~175 lines)
- **`lib/widgets/unknown_device_group.dart`**: Extracted unknown device group widget with probe button (~110 lines)
- **`lib/widgets/device_card_helpers.dart`**: Shared helpers (`unknownLabel`, `detailStyle`)
- **`lib/services/device_identification_cache.dart`**: Per-session BLE device identification cache with sort/prune/isKnown logic (~100 lines)

### Changed
- **`lib/screens/home_screen.dart`**: Refactored from 802 to ~270 lines — delegates to extracted widgets and DeviceIdentificationCache
- **`lib/screens/nfc_screen.dart`**: Deduplicated write methods into shared `_startWriting()` helper (~60 lines saved)
- **`lib/services/ble_service.dart`**: Uses `BleConstants` for timeouts; removed unused `discoverServices()` method
- **`lib/services/nfc_service.dart`**: Removed unused `formatNdef()` and `isIso15693Tag()` methods
- **`lib/services/device_probe_service.dart`**: Uses `BleConstants` and `HiveBoxNames` constants
- **`lib/services/expansion_state_service.dart`**: Uses `HiveBoxNames` constant
- **`lib/models/cached_device.dart`**: Uses `CacheConstants` for TTL
- **`lib/utils/brand_icons.dart`**: Uses `RssiThresholds` constants
- **`lib/main.dart`**: Uses `HiveBoxNames` constants
- **`test/widget_test.dart`**: Replaced counter-app smoke test with NOMAD48 title test (initializes Hive)

### Fixed
- **Stream subscription memory leak**: `home_screen.dart` now stores `StreamSubscription` references and cancels both in `dispose()`

### Removed
- **`provider` dependency**: Never imported anywhere; removed from `pubspec.yaml`
- **`SESSION_SUMMARY.md`**: Outdated single-session file; all info already in CHANGELOG.md

### Documentation
- **CLAUDE.md**: Updated technology stack (Hive replaces Provider), file organization, constants naming convention (lowerCamelCase), current dependencies, ripgrep preference
- **README.md**: Added Apple Continuity, GATT probing, Hive caching, ThermoBeacon to features; updated project structure and dependencies
- **QUICKSTART.md**: Modernized to be evergreen (removed session-specific language)
- **TODO.md**: Added Full Codebase Refactor section to completed tasks

### Notes
- All code passes `flutter analyze` with zero issues
- `flutter test` passes
- No file in `lib/` exceeds 400 lines
- No behavior changes — pure refactor

---

## [2026-02-06] - Persist ExpansionTile State in Hive

### Added
- **ExpansionStateService** (`lib/services/expansion_state_service.dart`): New singleton service that persists expand/collapse state for device cards in a Hive `Box<bool>`
  - `getOrDefault(key)` — reads state, defaults to collapsed (`false`)
  - `set(key, expanded)` — fire-and-forget write

### Changed
- **main.dart**: Opens `expansion_state` Hive box on startup
- **home_screen.dart**: All three `ExpansionTile` widgets now use `ExpansionStateService` for `initiallyExpanded` and persist changes via `onExpansionChanged`
  - ThermoBeacon card: keyed by `device.remoteId.str`, default collapsed
  - Identified device card: keyed by `device.remoteId.str`, default collapsed (replaces old `shouldExpand` heuristic)
  - Unknown group card: keyed by `'unknown-group'`, default collapsed
- **home_screen.dart**: Removed `shouldExpand` heuristic and unused `hasPayload` parameter from `_buildIdentifiedDeviceCard`

### Notes
- All devices now start collapsed by default
- Expansion state survives app restart and device rejoin
- All code passes `flutter analyze` with zero issues

---

## [2026-02-06] - Fix ID-Cache Cleared Every Scan Cycle

### Fixed
- **ID-cache performance bug**: `_sortAndCacheResults()` was clearing both `_identifyCache` and `_identifyCachePlatformName` maps on every scan update, causing every device to be re-identified every cycle (`hadCached=false` always)
  - Replaced full cache reset with pruning of stale entries (devices no longer in scan results)
  - Cache now persists across scan cycles; `_cachedIdentify()` logic for platformName-change re-identification now works as intended
  - Made both cache maps `final` (no longer reassigned)
- **Reduced debug log noise**: Replaced per-device-per-cycle `[ID-cache]` debug prints with targeted logging — only logs on first identification or platformName-triggered re-identification
  - File: `lib/screens/home_screen.dart`

---

## [2026-02-05] - Initial Project Setup

### Added
- **Flutter Project**: Created NOMAD48 Flutter application with organization ID `com.nomad48`
  - Files: `pubspec.yaml`, `lib/main.dart`, platform folders
- **Git Integration**: Connected to https://github.com/jihlenburg/nomad48.git
  - Existing LICENSE (GPL-3.0) and README.md preserved

#### BLE Functionality
- **Dependencies**: Added `flutter_blue_plus` (v1.36.8) for Bluetooth Low Energy support
- **BLE Service**: `lib/services/ble_service.dart`
  - Singleton pattern implementation
  - Device scanning with timeout
  - Connection/disconnection management
  - Permission checking and requesting
  - Service discovery
- **Home Screen**: `lib/screens/home_screen.dart`
  - BLE device scanner with real-time results
  - Device list showing RSSI signal strength
  - Connect button for each discovered device
  - Error handling and user feedback

#### NFC Functionality
- **Dependencies**: Added `nfc_manager` (v3.5.0) for NFC tag operations
- **NFC Service**: `lib/services/nfc_service.dart`
  - NFC availability checking
  - Tag reading (NDEF format)
  - Text writing to tags
  - URI writing to tags
  - Tag identification and type detection
  - Enhanced ISO/IEC 15693 (Type 5) support
- **NFC Screen**: `lib/screens/nfc_screen.dart`
  - Three sections: Read, Write Text, Write URI
  - Real-time tag information display
  - Progress indicators during operations
  - Tag details including ID, type, capacity, technologies

#### Platform Configuration
- **iOS** (`ios/Runner/Info.plist`):
  - Bluetooth usage permissions
  - Location permissions (required for BLE)
  - NFC reader permissions
  - NFC capability entitlements (`ios/Runner/Runner.entitlements`)
- **Android** (`android/app/src/main/AndroidManifest.xml`):
  - Bluetooth permissions (Android 11 and 12+ variants)
  - Location permissions for BLE scanning
  - NFC permissions and hardware feature
  - Intent filters for NFC tag discovery

#### User Interface
- **Main App**: `lib/main.dart`
  - Tabbed interface with BLE and NFC tabs
  - Material Design 3 theme
  - Easy navigation between features
- **Project Structure**:
  - `lib/screens/` - UI screens
  - `lib/services/` - Business logic services
  - `lib/models/` - Data models (empty, ready for use)
  - `lib/widgets/` - Reusable widgets (empty, ready for use)

#### Documentation
- **README.md**: Comprehensive project documentation
  - Features list
  - Installation instructions
  - Platform-specific requirements
  - Dependencies overview
  - Permissions documentation
  - Build commands
  - Troubleshooting guide
- **CLAUDE.md**: Project-specific instructions for Claude Code
  - Code style and conventions
  - BLE development guidelines
  - NFC development guidelines
  - Platform-specific considerations
  - Testing requirements
  - Task management workflow
- **NFC_TAG_SUPPORT.md**: `docs/NFC_TAG_SUPPORT.md`
  - Complete NFC tag type reference
  - ISO/IEC 15693 specifications
  - Supported operations
  - Troubleshooting for NFC issues
- **TODO.md**: Task tracking file
- **CHANGELOG.md**: This file

#### Dependencies Added
- `flutter_blue_plus: ^1.35.10` - BLE functionality
- `nfc_manager: ^3.5.0` - NFC functionality
- `permission_handler: ^11.3.1` - Runtime permissions
- `provider: ^6.1.2` - State management

### Changed
- README.md updated from minimal placeholder to comprehensive documentation

### Technical Details

#### ISO/IEC 15693 Support Enhancements
- Tag identifier extraction for NFC-V tags (8-byte UID in hex format)
- DSF ID and response flags display
- Proper tag type labeling: "NFC-V (ISO 15693 / Type 5)"
- Enhanced tag information display in UI

#### Code Quality
- All code passes `flutter analyze` with no issues
- Proper error handling throughout
- Resource cleanup in dispose methods
- Following Dart/Flutter best practices

### Notes
- Flutter installed via Homebrew during setup
- Project requires physical devices for BLE/NFC testing
- iOS NFC requires iPhone 7 or newer
- Android BLE permissions vary by API level
- GPL-3.0 license maintained from original repository

### Next Steps
1. Install CocoaPods for iOS: `cd ios && pod install`
2. Test on physical devices with BLE and NFC capabilities
3. Document NOMAD48 device protocol specifications
4. Implement device-specific communication protocols
5. Add persistent connection management
6. Create device detail screens

---

## [2026-02-05] - iOS Deployment and Permission Fixes

### Added
- **iOS Deployment Guide**: `docs/iOS_DEPLOYMENT.md`
  - Complete guide for building and deploying to iOS devices
  - Xcode configuration instructions
  - Troubleshooting common issues
  - Testing checklists

### Changed
- **BLE Service**: `lib/services/ble_service.dart`
  - Improved iOS permission handling
  - Now requests `locationWhenInUse` permission (required for BLE on iOS)
  - Better error handling for permission denials
  - Removed redundant permission checks that weren't working on iOS

- **Home Screen**: `lib/screens/home_screen.dart`
  - Added automatic permission request on screen initialization
  - Ensures permissions are requested before user attempts scanning

### Fixed
- **BLE Permissions on iOS**: Location permission now properly requested
  - iOS requires location permission for BLE scanning
  - Permission dialog now appears when opening BLE tab
  - Users can grant "Allow While Using App" permission

### Deployment
- **CocoaPods**: Installed via Homebrew (v1.16.2)
- **iOS Dependencies**: All pods installed successfully
  - flutter_blue_plus_darwin
  - nfc_manager
  - permission_handler_apple
- **First Deployment**: App successfully deployed to iPhone mini (iOS 26.2.1)

### Known Issues
- **NFC Crash**: App crashes when opening NFC tab
  - **Cause**: NFC capability not enabled in Xcode project
  - **Fix Required**: Add "Near Field Communication Tag Reading" capability in Xcode
  - **Status**: Documented in TODO.md, waiting for manual Xcode configuration
  - **Steps**:
    1. Open `ios/Runner.xcworkspace` in Xcode
    2. Runner target → Signing & Capabilities
    3. Click "+ Capability"
    4. Add "Near Field Communication Tag Reading"
    5. Clean and rebuild

### Testing Completed
- ✅ App builds successfully for iOS
- ✅ App deploys to physical device (wireless)
- ✅ Code signing configured
- ✅ BLE tab loads without issues
- ✅ Location permission dialog appears
- ⚠️ NFC tab crashes (capability not configured)

### Notes
- Wireless deployment works but is slower than USB
- Free Apple Developer account sufficient for testing
- Bundle identifier: `com.nomad48.nomad48` (using default)
- Xcode 26.2 used for building
- All code passes `flutter analyze` with no issues

---

## [2026-02-05 Evening] - NFC Investigation and BLE Improvements

### Changed
- **BLE Error Handling**: `lib/screens/home_screen.dart`
  - Added explicit permission check before scanning
  - Improved error messages with actionable instructions
  - Now guides users to Settings if permission denied

- **Xcode Project Configuration**: `ios/Runner.xcodeproj/project.pbxproj`
  - Added CODE_SIGN_ENTITLEMENTS to all build configurations
  - Later removed due to free account limitations

### Fixed
- **NFC Tab Crash**: No longer crashes when opened
  - Shows "NFC is not available" message instead
  - Graceful degradation when NFC capability not supported

### Discovered
- **Free Apple Developer Account Limitation**:
  - Personal development teams don't support NFC Tag Reading capability
  - Error: "Personal development teams do not support the NFC Tag Reading capability"
  - Requires paid Apple Developer Program ($99/year) for NFC features
  - BLE functionality works fine with free account

### Removed
- **NFC Entitlements** (temporarily)
  - Removed `CODE_SIGN_ENTITLEMENTS` from Xcode project
  - Allows app to build and run with free developer account
  - NFC code remains in place, ready to enable with paid account

### Testing
- ✅ App builds successfully without NFC entitlements
- ✅ App installs on physical device (iPhone mini, iOS 26.2.1)
- ✅ NFC tab loads without crashing
- ⚠️ BLE requires location permission (Settings → Nomad48 → Location)
- ⚠️ NFC shows "not available" (expected with free account)

### Documentation
- Updated TODO.md with current priorities
- Updated capability names for Xcode 26.2 ("NFC Scan")
- Documented free vs paid account differences

### Notes
- Xcode 26.2 renamed "Near Field Communication Tag Reading" to "NFC Scan"
- Wireless debugging is slower but functional
- Location permission is required for BLE on iOS
- All NFC implementation code is complete and ready for paid account

---

## [2026-02-06] - Refactoring Pass: Bug Fixes & Code Quality

### Fixed
- **Subtitle Row overflow**: Wrapped brand badge in `Flexible` with `TextOverflow.ellipsis` to prevent clipping on narrow screens
- **Hardcoded dark surface color**: `iconWithBadge` now takes a `badgeBackground` parameter from the theme instead of duplicating `Color(0xFF1A2F3E)`
- **`_isTvName` false positives**: Replaced `name.contains('tv')` with word-boundary regex `\btv\b` — no longer matches "activity", "creative", etc.
- **Watch misattributed to Apple**: Generic "watch" no longer routes to Apple; only "apple watch" does. Galaxy Watch, Garmin watch, etc. now correctly identified
- **Earphone→Phone misclassification**: Added `headphone`/`earphone` checks before `phone` in `_guessDeviceType` so "earphone" no longer matches the `phone` substring

### Changed
- **brand_icons.dart**: Replaced switch statements with `Map<String, T>` lookups for icons (`_brandIcons`), device types (`_deviceTypeIcons`), and colors (`_lightColors`/`_darkColors`) — data-driven, easier to extend
- **brand_icons.dart**: Removed unused `hasBrandIcon` method
- **brand_icons.dart**: Simplified null-manufacturer color from redundant `isDark ? Colors.grey : Colors.grey` to just `Colors.grey`
- **ble_manufacturer.dart**: Cleaned up `_guessDeviceType` signature — removed unused `manufacturer`, `manufacturerData`, `serviceUuids` params
- **ble_manufacturer.dart**: Promoted regex patterns to `static final` fields (`_tvWordPattern`, `_screenSizePattern`, `_screenSizeQuotePattern`) to avoid recompilation
- **ble_manufacturer.dart**: Removed unused `serviceUuids` param from `_identifyByName`
- **ble_manufacturer.dart**: Tightened Apple name matching — `macbook` only (not bare `mac`), `apple watch` only (not bare `watch`)

### Notes
- All code passes `flutter analyze` with zero issues

---

## [2026-02-06] - Manufacturer Icons & Device Display Improvements

### Added
- **simple_icons package** (`pubspec.yaml`): 1500+ brand SVG icons for manufacturer logos
  - Provides `SimpleIcons.apple`, `SimpleIcons.samsung`, `SimpleIcons.lg`, etc.
  - Includes `SimpleIconColors` for brand-accurate colors
- **Brand Icons Utility** (`lib/utils/brand_icons.dart`): Centralized brand icon/color resolution
  - `resolveIcon()` — device type first, brand icon fallback
  - `getBrandColor()` — brightness-aware brand colors for dark/light mode
  - `getBrandIcon()` — maps manufacturer names to SimpleIcons
  - `signalBars()` — 4-bar RSSI strength indicator (green/yellow/orange/red)
  - `iconWithBadge()` — main device icon with small brand logo overlay
- **Signal strength bars**: Visual RSSI indicator on all device cards
- **Brand icon badge overlay**: Small brand logo shown when device type drives the main icon
  (e.g., AirPods show headphones icon with small Apple logo)

### Changed
- **BLE Manufacturer Model** (`lib/models/ble_manufacturer.dart`):
  - Removed `icon` field from `BleManufacturer` and `BleDeviceInfo` (clean model/view separation)
  - Added TV detection patterns: QLED, OLED, screen size patterns (55", 65-inch), [TV], soundbar
  - Added `_isTvName()`, `_samsungDeviceType()`, `_detectTvOrDevice()` helper methods
  - Samsung devices now correctly detect TV, Soundbar, Watch, Earbuds subtypes
  - LG devices now detect TV vs generic
- **Home Screen** (`lib/screens/home_screen.dart`):
  - Replaced `_getDeviceIcon()` and `_getManufacturerColor()` with `BrandIcons` utility
  - Fixed icon priority bug: device type checked first (AirPods=headphones, TV=tv), brand icon only for generic 'Device' type
  - Unknown/unidentified devices now display dimmed and collapsed by default
  - Badge background alpha increased in dark mode (50 vs 25) for readability
- **App Theme** (`lib/theme/app_theme.dart`):
  - Increased dark mode `primaryContainer` and `secondaryContainer` alpha from 50 to 70 for better contrast

### Fixed
- **Icon priority bug**: Previously, icon hint ('apple') was checked first, so Apple AirPods always showed phone icon. Now device type drives the icon correctly.
- **TV detection**: Samsung QLED/OLED TVs, LG TVs, and generic TV patterns now correctly show TV icon

### Notes
- `simple_icons` v10.1.3 installed — legally safe open-source brand icons
- All code passes `flutter analyze` with zero issues
- Brand colors are dark-mode-aware (black brands like Apple/Sony/Bose lighten to grey in dark mode)

---

## [2026-02-06] - Unknown Device Handling & Apple Continuity

### Added
- **Apple Continuity Decoder** (`lib/models/apple_continuity.dart`): **NEW**
  - Walks TLV chain in Apple (0x004C) manufacturer data
  - Identifies: iBeacon, AirPods/Beats proximity pairing, AirPlay/Apple TV, Handoff, Instant Hotspot (iPhone), Nearby Info, AirDrop, Hey Siri
  - AirPods model code lookup: AirPods 1/2/3, Pro/Pro 2, Max, Beats Solo3/Studio3/Flex/Studio Buds/Studio Pro, Powerbeats
  - Strict bounds checking — returns best result on malformed data
- **GATT Probe Service** (`lib/services/device_probe_service.dart`): **NEW**
  - Singleton service that connects to unknown BLE devices, discovers GATT services, reads device name
  - Maps well-known GATT service UUIDs (heart rate, HID, blood pressure, etc.) to device types
  - Guesses manufacturer from device name patterns
  - 10-second connection timeout, always disconnects in `finally`
- **Hive Cache** (`lib/models/cached_device.dart`): **NEW**
  - `CachedDeviceIdentification` HiveObject with manual TypeAdapter (no code generation needed)
  - Fields: remoteId, manufacturer, deviceType, serviceUuids, deviceName, gattServiceCount, probedAt
  - 24-hour TTL with `isExpired` getter
- **Collapsed Unknown Group**: Unknown devices now grouped into single expandable "Unknown Devices (N)" card
  - Compact `ListTile`s with bluetooth icon, shortened label, signal bars, RSSI, connectable indicator
  - Collapsed by default — keeps scan list focused on identified devices
- **Probe UI**: "Identify" button on connectable unknowns
  - Search icon → spinner (probing) → retry on failure (auto-resets after 5s)
  - Successfully probed devices move from unknown group to known list immediately

### Changed
- **Home Screen** (`lib/screens/home_screen.dart`):
  - Unknown labels now show "Unknown (ACC1)" using last 4 hex digits of remote ID
  - Scan results sorted by priority: ThermoBeacons > identified > unknowns, RSSI descending within groups
  - Memoized `_identifyCache` rebuilt each scan update — avoids double-calling identify() in sort + render + partition
  - `_buildDeviceList()` replaces flat `ListView.builder` — partitions into known/unknown lists
  - Shows Apple Continuity sub-type and model name in expanded detail area
- **BLE Manufacturer Model** (`lib/models/ble_manufacturer.dart`):
  - `BleDeviceInfo` gains `appleContinuitySubType` and `appleContinuityModel` fields
  - `displayLabel` prefers `appleContinuityModel` when available (e.g. "AirPods Pro 2")
  - Apple (0x004C) manufacturer data now decoded via `AppleContinuityInfo.decode()` before falling back to `_guessDeviceType()`
- **Brand Icons** (`lib/utils/brand_icons.dart`):
  - Added device type icons: `Beats` (headphones), `Apple Device` (devices), `Apple TV` (tv), `Beacon` (cell_tower)
- **Main** (`lib/main.dart`):
  - Hive initialization with Flutter adapter
  - Registers `CachedDeviceIdentificationAdapter` and opens `device_cache` box

### Dependencies Added
- `hive: ^2.2.3` — lightweight local storage
- `hive_flutter: ^1.1.0` — Flutter integration for Hive
- `hive_generator: ^2.0.1` (dev) — Hive code generation (available but manual adapter used)
- `build_runner: ^2.4.8` (dev) — build tooling

### Notes
- All code passes `flutter analyze` with zero issues
- Manual Hive adapter used instead of code generation to avoid build_runner complexity
- Apple Continuity decoding converts many "unknown" Apple devices into identified ones, reducing unknown device count significantly
- Probe button only shown on connectable unknowns — non-connectable devices can't be probed

---

## [2026-02-06] - Fix Async platformName Identification

### Fixed
- **Devices misidentified as "BLE Device"**: CoreBluetooth resolves `device.platformName` asynchronously after scan results fire. Devices like iPhones that are identified only by `platformName` (no manufacturer data, no advName) were cached as unknown during the sort pass, then never re-checked at render time.
  - Added `_identifyCachePlatformName` map to track which `platformName` was used when each cache entry was created
  - Re-identification triggers when `platformName` resolves to a new non-empty value between frames
  - Strong cache entries (with manufacturer) are still trusted unless `platformName` changes
  - Weak cache entries skip re-identification if `platformName` hasn't changed (avoids wasted work)

### Changed
- **ble_manufacturer.dart**: Removed debug prints added during investigation
- **home_screen.dart**: Removed debug prints, added platformName-aware cache invalidation

### Notes
- All code passes `flutter analyze` with zero issues
- Root cause: `BluetoothDevice.platformName` is a live CoreBluetooth getter, not a snapshot from advertisement data

---

## Template for Future Entries

```markdown
## [YYYY-MM-DD] - Brief Description

### Added
- New features or files

### Changed
- Modifications to existing functionality

### Deprecated
- Features marked for removal

### Removed
- Deleted features or files

### Fixed
- Bug fixes

### Security
- Security-related changes

### Notes
- Important context or decisions
```
