# NOMAD48 Mobile Application

A Flutter-based mobile application for interacting with NOMAD48 Bluetooth Low Energy (BLE) enabled devices and NFC tags.

## Features

- **Bluetooth Low Energy (BLE)**
  - Device scanning and discovery
  - Connection management for NOMAD48 devices
  - Real-time data communication with BLE peripherals
  - **Manufacturer identification** with brand icons (Apple, Samsung, Google, Sony, Bose, etc.)
  - **Apple Continuity TLV decoder** — identifies hidden iPhones, AirPods, Macs, Apple TVs
  - **AirPods model code lookup** (AirPods 1/2/3, Pro/Pro 2, Max, Beats variants)
  - **GATT probing** for unknown devices — connects, reads device name, maps services to device types
  - **ThermoBeacon** support — temperature, humidity, battery, uptime display
  - **Hive-based caching** — 24-hour probe result cache, persisted expansion state
  - RSSI signal strength bars with brand icon badge overlays
- **Near Field Communication (NFC)**
  - Read NFC tags (NDEF format)
  - Write text to NFC tags
  - Write URIs to NFC tags
  - Tag information display (type, ID, capacity)
  - **Full support for ISO/IEC 15693 (Type 5) tags**
- Cross-platform support (iOS and Android)

## Prerequisites

- Flutter SDK 3.10.8 or higher
- Dart SDK (comes with Flutter)
- iOS development:
  - Xcode 14 or higher
  - CocoaPods
  - iOS 11.0 or higher
  - iPhone 7 or newer (for NFC functionality)
- Android development:
  - Android Studio
  - Android SDK (API level 21 or higher)
  - Java Development Kit (JDK)
  - NFC-enabled device (for NFC functionality)

## Getting Started

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jihlenburg/nomad48.git
   cd nomad48
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. For iOS, install CocoaPods dependencies:
   ```bash
   cd ios && pod install && cd ..
   ```

### Running the App

#### iOS
```bash
flutter run -d ios
```

#### Android
```bash
flutter run -d android
```

#### Development Mode
```bash
flutter run --debug
```

## Project Structure

```
nomad48/
├── android/              # Android-specific code and configuration
├── ios/                  # iOS-specific code and configuration
├── lib/                  # Flutter application code
│   ├── main.dart         # Application entry point (Hive init, tabs)
│   ├── constants/        # App-wide constants
│   │   └── app_constants.dart
│   ├── models/           # Data models
│   │   ├── apple_continuity.dart
│   │   ├── ble_manufacturer.dart
│   │   ├── cached_device.dart
│   │   └── thermobeacon.dart
│   ├── screens/          # Screen-level widgets
│   │   ├── home_screen.dart
│   │   └── nfc_screen.dart
│   ├── services/         # Business logic
│   │   ├── ble_service.dart
│   │   ├── device_identification_cache.dart
│   │   ├── device_probe_service.dart
│   │   ├── expansion_state_service.dart
│   │   └── nfc_service.dart
│   ├── theme/            # App theme
│   │   └── app_theme.dart
│   ├── utils/            # Utilities
│   │   └── brand_icons.dart
│   └── widgets/          # Extracted reusable widgets
│       ├── device_card_helpers.dart
│       ├── identified_device_card.dart
│       ├── thermobeacon_card.dart
│       └── unknown_device_group.dart
├── docs/                 # Documentation
│   └── NFC_TAG_SUPPORT.md
├── test/                 # Unit and widget tests
├── CHANGELOG.md          # Project changelog and logbook
├── TODO.md               # Active tasks and project roadmap
├── CLAUDE.md             # Claude Code project instructions
├── pubspec.yaml          # Project dependencies and metadata
└── README.md             # This file
```

## Dependencies

- **flutter_blue_plus**: BLE functionality for device scanning and communication
- **nfc_manager**: NFC functionality for reading and writing NFC tags
- **permission_handler**: Runtime permission management
- **hive** / **hive_flutter**: Lightweight local storage (device probe cache, expansion state)
- **simple_icons**: Brand SVG icons for manufacturer logo display

## Permissions

### iOS
The app requires the following permissions (configured in `ios/Runner/Info.plist`):
- Bluetooth usage (NSBluetoothAlwaysUsageDescription)
- Location when in use (NSLocationWhenInUseUsageDescription)
- NFC reader session (NFCReaderUsageDescription)

NFC capabilities are configured in `ios/Runner/Runner.entitlements` with support for NDEF and TAG formats.

### Android
The app requires the following permissions (configured in `android/app/src/main/AndroidManifest.xml`):
- BLUETOOTH and BLUETOOTH_ADMIN (Android 11 and below)
- BLUETOOTH_SCAN and BLUETOOTH_CONNECT (Android 12+)
- ACCESS_FINE_LOCATION and ACCESS_COARSE_LOCATION (for BLE scanning)
- NFC (for reading and writing NFC tags)

Intent filters are configured to handle NFC tag discovery (NDEF, TECH, and TAG discovered actions).

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Testing

Run all tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## Troubleshooting

### Bluetooth Issues
- Ensure Bluetooth is enabled on your device
- Check that location services are enabled (required for BLE scanning)
- Verify that all permissions are granted in device settings

### NFC Issues
- Ensure NFC is enabled in device settings
- On iOS, NFC only works on iPhone 7 and newer
- Hold the device's NFC antenna (usually near the top) close to the tag
- Some NFC tags may be read-only or locked
- Android devices may need to be unlocked to read/write NFC tags

### Build Issues
- Run `flutter clean` and then `flutter pub get`
- For iOS, try deleting `ios/Podfile.lock` and running `pod install` again
- Ensure your Flutter SDK is up to date: `flutter upgrade`

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Documentation

- [TODO.md](TODO.md) - Active tasks and project roadmap
- [CHANGELOG.md](CHANGELOG.md) - Project changelog and development history
- [CLAUDE.md](CLAUDE.md) - Development guidelines and Claude Code instructions
- [NFC Tag Support Guide](docs/NFC_TAG_SUPPORT.md) - Comprehensive guide to supported NFC tag types, including ISO/IEC 15693

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Blue Plus Documentation](https://pub.dev/packages/flutter_blue_plus)
- [NFC Manager Documentation](https://pub.dev/packages/nfc_manager)
- [BLE Fundamentals](https://www.bluetooth.com/bluetooth-resources/intro-to-bluetooth-low-energy/)
- [NFC Forum](https://nfc-forum.org/)

## Support

For issues and questions, please use the [GitHub Issues](https://github.com/jihlenburg/nomad48/issues) page.
