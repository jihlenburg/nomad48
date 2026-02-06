# NOMAD48 - Quick Start Guide

## Current Status

- BLE scanning with manufacturer identification, RSSI bars, brand icons
- Apple Continuity decoding (AirPods, iPhones, Macs, Apple TVs)
- GATT probing for unknown devices with 24-hour Hive cache
- ThermoBeacon temperature/humidity/battery display
- NFC read/write (text and URI) - requires paid Apple Developer account on iOS
- Expansion state persists across app restarts

## Test BLE

1. Open the app
2. Tap **BLE tab**
3. Allow location permission when prompted
4. Tap **"Start Scan"**
5. See nearby BLE devices with brand icons and signal bars

## NFC (iOS - Requires Paid Account)

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. **Runner** target -> **Signing & Capabilities**
2. Click **"+ Capability"**
3. Add **"NFC Scan"** (Xcode 26.2+) or **"Near Field Communication Tag Reading"**
4. Press `Cmd + R` to rebuild

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run tests
flutter test

# Check for issues
flutter analyze

# iOS pods
cd ios && pod install && cd ..
```

## Project Structure

See `README.md` for the full directory layout.

## Need Help?

- Deployment issues: See `docs/iOS_DEPLOYMENT.md`
- NFC crash: See `docs/XCODE_NFC_SETUP.md`
- Task status: See `TODO.md`
- Change history: See `CHANGELOG.md`
