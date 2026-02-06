# Quick Fix: NFC Capability Setup in Xcode

## Problem
The app crashes when tapping the NFC tab because the NFC capability isn't enabled in the Xcode project.

## Solution (5 minutes)

### Step 1: Open Project in Xcode
```bash
open ios/Runner.xcworkspace
```

**Important:** Open `.xcworkspace`, not `.xcodeproj`

### Step 2: Navigate to Signing & Capabilities
1. Click **"Runner"** in the left sidebar (blue icon)
2. Select **"Runner"** under TARGETS
3. Click the **"Signing & Capabilities"** tab at the top

### Step 3: Add NFC Capability
1. Click the **"+ Capability"** button (top left of capabilities area)
2. Type "NFC" in the search box
3. Double-click **"NFC Scan"** (in Xcode 26.2+, previously called "Near Field Communication Tag Reading")
4. The capability will appear with two checkboxes:
   - ✅ NDEF
   - ✅ TAG

Both should be automatically checked.

### Step 4: Verify Entitlements
You should see a new section appear:
```
NFC Scan
  Formats: NDEF, TAG
```

**Note:** In Xcode 26.2+, this capability is called "NFC Scan". In older versions it was "Near Field Communication Tag Reading".

### Step 5: Clean and Rebuild
1. In Xcode menu: **Product → Clean Build Folder** (or `Cmd + Shift + K`)
2. Click the **Play button** (▶️) to rebuild and run (or `Cmd + R`)

**OR** from Terminal:
```bash
flutter run -d 00008110-00120D0E02EB801E
```

### Step 6: Test NFC
1. Open the app on your iPhone
2. Tap the **NFC tab** - it should NOT crash anymore
3. Tap **"Start Reading"**
4. Hold your ISO 15693 tag near the **top** of your iPhone
5. See tag information displayed

## What This Does

The NFC capability:
- Adds required entitlements to your app
- Tells iOS your app needs NFC access
- Links to the `Runner.entitlements` file we created
- Enables the Core NFC framework

## Verification

After adding the capability, verify it's working:
1. NFC tab opens without crashing ✅
2. "Start Reading" button is enabled ✅
3. Holding an NFC tag shows data ✅
4. Tag ID and type are displayed ✅

## Why This Was Needed

The `Runner.entitlements` file exists with NFC configuration, but Xcode needs to:
1. Know to include it in the build
2. Add it to the app's provisioning profile
3. Enable the capability in the target settings

This can't be done automatically via code - it requires manual Xcode configuration.

## If You Still See Issues

### "Provisioning profile doesn't support NFC Tag Reading"
This can happen with free Apple Developer accounts. Two options:
1. **Recommended**: Get a paid developer account ($99/year)
2. **Workaround**: Remove NFC capability for now, test BLE only

### NFC still crashes
1. Make sure you cleaned build folder
2. Delete the app from your iPhone completely
3. Rebuild from Xcode
4. Check Console.app on Mac for detailed crash logs

### Can't find "+ Capability" button
- Make sure you're on the **"Signing & Capabilities"** tab
- Look in the top-left area of the capabilities section
- Try clicking on the target name first to refresh the view

## Once Working

Update your task tracking:
```bash
# In TODO.md, mark as complete:
- [✅] Fix NFC capability in Xcode to prevent crash
```

## References
- [Apple NFC Documentation](https://developer.apple.com/documentation/corenfc)
- [Flutter NFC Plugin](https://pub.dev/packages/nfc_manager)
