# App Icon Implementation Guide

This document explains how the app icon has been implemented in the Pelevo Podcast app.

## Implementation Details

1. **Splash Screen**: Updated to display the new app icon from `assets/images/icon-1749483338270.png`

2. **App Icons**: To properly implement the app icon across all platforms, you should use a tool like `flutter_launcher_icons` package:

```yaml
# Add to dev_dependencies in pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

# Add configuration
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/icon-1749483338270.png"
  adaptive_icon_background: "#FFFFFF" # For Android adaptive icons
  adaptive_icon_foreground: "assets/images/icon-1749483338270.png"
  web:
    generate: true
    image_path: "assets/images/icon-1749483338270.png"
    background_color: "#FFFFFF"
    theme_color: "#FFFFFF"
```

Then run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all necessary icon files for Android, iOS and Web platforms.

## Manual Icon Replacement

If you prefer to replace icons manually, you'll need to:

1. Generate different icon sizes for Android (mipmap directories)
2. Generate different icon sizes for iOS (AppIcon.appiconset)
3. Replace web icons in the web/icons directory

## Current Implementation

Currently, we've updated the splash screen to use the new icon. For a complete implementation across all platforms, follow the instructions above to use flutter_launcher_icons.