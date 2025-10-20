# iOS Simulator Setup in Codemagic

## What's Added

### 1. ✅ Simulator Build Support
- **`flutter build ios --simulator --debug`** - Builds for iOS Simulator
- **iPhone 15 Pro simulator** - Modern device for testing
- **Automatic app installation** - Installs app on simulator
- **App launch** - Automatically launches your app

### 2. ✅ Simulator Screenshots
- **Automatic screenshots** - Takes screenshots of running app
- **Artifact collection** - Screenshots saved as build artifacts
- **Visual verification** - See how your app looks on iOS

### 3. ✅ Multiple Build Configurations
- **`codemagic_simulator.yaml`** - Dedicated simulator build
- **`codemagic_working.yaml`** - Both device + simulator builds
- **`codemagic_simple.yaml`** - Both device + simulator builds

## How to Use

### Option 1: Use Simulator-Only Build
```yaml
# Use codemagic_simulator.yaml
# Builds only for simulator, faster build time
```

### Option 2: Use Combined Build (Recommended)
```yaml
# Use codemagic_working.yaml or codemagic_simple.yaml
# Builds for both device and simulator
```

## What You'll Get

### Build Artifacts:
- ✅ **Device build** - `build/ios/Release-iphoneos/Runner.app`
- ✅ **Simulator build** - `build/ios/iphonesimulator/Runner.app`
- ✅ **Screenshots** - `simulator_screenshot.png`

### Simulator Actions:
- ✅ **Boots iPhone 15 Pro simulator**
- ✅ **Installs your app**
- ✅ **Launches your app**
- ✅ **Takes screenshots**

## Simulator Device Options

You can change the simulator device by modifying:
```bash
xcrun simctl boot "iPhone 15 Pro"
```

Available devices:
- `iPhone 15 Pro` (recommended)
- `iPhone 15`
- `iPhone 14 Pro`
- `iPhone 14`
- `iPad Pro (12.9-inch)`

## Bundle ID Configuration

Make sure your bundle ID matches:
```bash
xcrun simctl launch "iPhone 15 Pro" com.podemeraldsltd.pelevo
```

Current bundle ID: `com.podemeraldsltd.pelevo`

## Expected Results

After build completion:
1. ✅ **App builds successfully for simulator**
2. ✅ **Simulator boots automatically**
3. ✅ **App installs on simulator**
4. ✅ **App launches automatically**
5. ✅ **Screenshots are captured**
6. ✅ **All artifacts are available for download**

## Ready for Simulator Testing! 📱
