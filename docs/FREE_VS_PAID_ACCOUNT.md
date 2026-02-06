# Free vs Paid Apple Developer Account

This document explains the differences between free and paid Apple Developer accounts for the NOMAD48 app.

## Current Status

The app is configured to work with a **free Apple Developer account** with the following limitations:

## Free Account (Current)

### ✅ What Works
- **BLE Functionality**: Full Bluetooth Low Energy support
  - Device scanning
  - Connection management
  - Characteristic read/write
  - All NOMAD48 BLE features

- **Testing on Physical Devices**: Deploy and test on your own devices
- **Development**: Full development and debugging capabilities
- **App Structure**: All UI, navigation, and code functionality

### ❌ What Doesn't Work
- **NFC**: Near Field Communication is NOT supported
  - NFC tab shows "NFC is not available"
  - Cannot read or write NFC tags
  - ISO 15693 tag support unavailable
  - Requires paid Apple Developer Program

- **App Store Distribution**: Cannot publish to App Store
- **TestFlight**: Cannot use for beta testing
- **Push Notifications**: Limited or no support
- **Associated Domains**: Not available
- **App Groups**: Not available

## Paid Account ($99/year)

### ✅ Everything from Free, Plus:

- **NFC Tag Reading**: Full support
  - Read ISO 15693 (Type 5) tags
  - Read NDEF formatted tags
  - Write text and URIs to tags
  - All tag types supported by nfc_manager

- **App Store**: Publish to the App Store
- **TestFlight**: Beta testing with external testers
- **Push Notifications**: Full APNS support
- **CloudKit**: Apple's cloud database
- **Associated Domains**: Universal links, handoff
- **App Groups**: Share data between apps
- **Wallet**: PassKit for digital passes
- **SiriKit**: Siri integration
- **More**: Many other enterprise features

## Enabling NFC (After Getting Paid Account)

Once you have a paid Apple Developer account:

### 1. Update Xcode Project

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Runner target → **Build Settings**
2. Search for "entitlements"
3. Set **Code Signing Entitlements** to: `Runner/Runner.entitlements`

### 2. Add NFC Capability

1. Go to **Signing & Capabilities**
2. Click **"+ Capability"**
3. Add **"NFC Scan"** (Xcode 26.2+)
4. Ensure formats include: **NDEF, TAG**

### 3. Rebuild

```bash
flutter clean
cd ios && pod install && cd ..
flutter run
```

### 4. Test NFC

1. Open NFC tab - should show "NFC is available" ✅
2. Tap "Start Reading"
3. Hold ISO 15693 tag near iPhone
4. See all tag details!

## Cost-Benefit Analysis

### For Development/Testing Only
- **Use Free Account**: If you only need BLE functionality
- No additional cost
- Full BLE feature testing

### For Production/Full Features
- **Get Paid Account** if you need:
  - NFC functionality
  - App Store distribution
  - TestFlight beta testing
  - Professional development

## Current Configuration

The NOMAD48 app is currently configured for:
- ✅ Free account compatibility (NFC disabled)
- ✅ All NFC code implemented and ready
- ✅ BLE fully functional
- ✅ Easy upgrade path to paid account

## Migration Path

To migrate to paid account:

1. **Sign up**: https://developer.apple.com/programs/
2. **Update Xcode**: Add your paid account
3. **Re-enable NFC**: Follow steps above
4. **Test**: All features should work
5. **Deploy**: Can now use TestFlight and App Store

## Files Affected

When re-enabling NFC:
- `ios/Runner.xcodeproj/project.pbxproj` - Add CODE_SIGN_ENTITLEMENTS
- Xcode capabilities - Add "NFC Scan"
- No code changes needed - everything is ready!

## Support Resources

- [Apple Developer Program](https://developer.apple.com/programs/)
- [Enrolling Guide](https://developer.apple.com/programs/enroll/)
- [Program Benefits](https://developer.apple.com/support/compare-memberships/)
