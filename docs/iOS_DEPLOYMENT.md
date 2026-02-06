# iOS Deployment Guide

This guide explains how to build and test the NOMAD48 app on your iOS device.

## Prerequisites

✅ **Completed:**
- Xcode 26.2 is installed
- CocoaPods installed (v1.16.2)
- Pod dependencies installed

**Required:**
- Apple Developer account (free or paid)
- iOS device with iOS 11.0 or later
- iPhone 7 or newer for NFC functionality
- USB cable to connect device to Mac

## Step-by-Step Deployment

### Option 1: Using Xcode (Recommended for First Time)

#### 1. Open Project in Xcode

```bash
open ios/Runner.xcworkspace
```

**Important:** Always open the `.xcworkspace` file, NOT the `.xcodeproj` file (CocoaPods requirement).

#### 2. Configure Signing

1. In Xcode, select the **Runner** project in the left sidebar
2. Select the **Runner** target under "Targets"
3. Go to the **"Signing & Capabilities"** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** from the dropdown
   - If you don't have a team, click "Add Account" to sign in with your Apple ID
   - Free accounts work fine for testing

#### 3. Configure Bundle Identifier (if needed)

If you get signing errors:
1. Change the **Bundle Identifier** to something unique
   - Current: `com.nomad48.nomad48`
   - Example: `com.yourname.nomad48`
2. This makes it unique to your Apple ID

#### 4. Connect Your Device

1. Connect your iOS device via USB
2. Unlock your device
3. Trust the computer if prompted
4. Select your device from the device dropdown at the top of Xcode (next to "Runner")

#### 5. Build and Run

1. Click the **Play** button (▶️) in Xcode, or press `Cmd + R`
2. Xcode will:
   - Build the app
   - Install it on your device
   - Launch it automatically

#### 6. Trust Developer on Device (First Time Only)

If you see "Untrusted Developer" on your device:
1. On your iOS device, go to **Settings → General → VPN & Device Management**
2. Find your Apple ID under "Developer App"
3. Tap it and select **"Trust [Your Apple ID]"**
4. Confirm by tapping **"Trust"**
5. Return to the app and launch it

### Option 2: Using Flutter CLI (Faster for Subsequent Builds)

Once you've configured signing in Xcode once, you can use Flutter CLI:

```bash
# List available devices
flutter devices

# Run on connected iOS device
flutter run

# Or specify the device
flutter run -d [device-id]

# Run in release mode for better performance
flutter run --release
```

## Testing Functionality

### BLE Testing

1. Open the **BLE tab** in the app
2. Tap **"Start Scan"**
3. Grant Bluetooth and Location permissions when prompted
4. Look for nearby BLE devices in the list
5. Tap **"Connect"** on a device to test connection

**Note:** You need actual BLE devices nearby to test. The app won't show simulated devices.

### NFC Testing

1. Open the **NFC tab** in the app
2. Tap **"Start Reading"**
3. Hold an NFC tag (especially ISO 15693) near the top of your iPhone
4. The app will display:
   - Tag ID
   - Tag Type
   - NDEF records (if any)
   - ISO 15693 specific details

**To test writing:**
1. Enter text or a URI
2. Tap **"Write Text"** or **"Write URI"**
3. Hold your NFC tag near the device
4. Wait for confirmation

## Common Issues

### Issue: "Signing for 'Runner' requires a development team"

**Solution:**
1. Open Xcode
2. Sign in with your Apple ID (Xcode → Settings → Accounts)
3. Select your team in Signing & Capabilities
4. If using a free account, change the Bundle Identifier to make it unique

### Issue: "Unable to install [app name]"

**Solution:**
1. Delete the app from your device if it's already installed
2. In Xcode, go to Product → Clean Build Folder (`Cmd + Shift + K`)
3. Try building again

### Issue: "Could not launch [app name]"

**Solution:**
1. Make sure you've trusted the developer certificate on the device
2. Settings → General → VPN & Device Management → Trust developer

### Issue: NFC not working

**Checklist:**
- ✅ iPhone 7 or newer?
- ✅ iOS 11.0 or later?
- ✅ NFC enabled in Settings (it's usually on by default)?
- ✅ Holding tag near the top of the iPhone?
- ✅ App in foreground when testing?

### Issue: BLE not finding devices

**Checklist:**
- ✅ Bluetooth enabled on iPhone?
- ✅ Location permission granted? (Required for BLE on iOS)
- ✅ Location Services enabled in Settings?
- ✅ BLE devices powered on and in range?
- ✅ Try closing and reopening the app

### Issue: "Provisioning profile doesn't support NFC Tag Reading"

**Solution:**
This can happen with free Apple Developer accounts. The app will still install, but NFC features may not work until you:
1. Get a paid Apple Developer account ($99/year), or
2. Remove NFC capabilities temporarily for testing other features

## Performance Tips

### Release Mode
For the best performance, build in release mode:
```bash
flutter run --release
```

Release mode:
- Runs much faster
- Uses less battery
- Doesn't include debugging tools

### Debug Mode
For development and debugging:
```bash
flutter run
# or just
flutter run --debug
```

Debug mode enables:
- Hot reload
- Debugging tools
- Performance overlay

## Next Steps

After successful deployment:

1. **Test all features** thoroughly on physical device
2. **Update TODO.md** - mark iOS testing tasks as complete
3. **Update CHANGELOG.md** - document any issues found or fixes made
4. **Document any device-specific issues** you encounter
5. Test with actual NOMAD48 BLE devices when available
6. Test with various NFC tag types

## Useful Commands

```bash
# Show detailed device info
flutter devices -v

# Run with verbose logging
flutter run -v

# Install without running
flutter install

# View app logs (after installation)
flutter logs

# Clean build artifacts
flutter clean
cd ios && pod install && cd ..
```

## Xcode Shortcuts

- `Cmd + R` - Build and Run
- `Cmd + .` - Stop Running
- `Cmd + Shift + K` - Clean Build Folder
- `Cmd + B` - Build Only

## Resources

- [Flutter iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Xcode Help](https://developer.apple.com/xcode/)
