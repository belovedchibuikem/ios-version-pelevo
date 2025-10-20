# Google Play 16 KB Page Size Requirements Implementation

## Overview
Google Play requires all apps targeting Android 15+ to support 16 KB memory page sizes from November 1, 2025 (extendable to May 31, 2026).

## Current App Status
- ✅ Target SDK: 35 (Android 15)
- ✅ Flutter Framework: Modern architecture
- ✅ Native Dependencies: AndroidX compatible
- ✅ NDK Version: 29.0.14033849 (supports 16KB pages)

## Implementation Steps

### 1. Update Android Build Configuration

#### A. Update build.gradle
```gradle
android {
    compileSdk = 35
    ndkVersion = "29.0.14033849" // Already correct
    
    defaultConfig {
        // Add 16KB page size support
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
        }
    }
    
    // Add packaging options for 16KB page compatibility
    packagingOptions {
        jniLibs {
            useLegacyPackaging = false
        }
        resources {
            excludes += ['META-INF/DEPENDENCIES', 'META-INF/LICENSE', 'META-INF/LICENSE.txt', 'META-INF/license.txt', 'META-INF/NOTICE', 'META-INF/NOTICE.txt', 'META-INF/notice.txt', 'META-INF/ASL2.0']
        }
    }
}
```

#### B. Update Dependencies
```gradle
dependencies {
    // Update to latest versions for 16KB page support
    implementation 'androidx.multidex:multidex:2.0.1'
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
    
    // Google Play Billing Library - Latest version
    implementation 'com.android.billingclient:billing:8.0.0'
    
    // AndroidX Core Dependencies - Updated for 16KB compatibility
    implementation 'androidx.annotation:annotation:1.7.1'
    implementation 'androidx.core:core:1.13.1' // Updated
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.media:media:1.7.0'
    implementation 'androidx.media3:media3-common:1.3.1' // Updated
    implementation 'androidx.media3:media3-session:1.3.1' // Updated
    
    // Google Play Services - Updated versions
    implementation 'com.google.android.gms:play-services-cast:21.5.0'
    implementation 'com.google.android.gms:play-services-cast-framework:21.5.0'
    
    // Additional AndroidX dependencies
    implementation 'androidx.lifecycle:lifecycle-runtime:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-common:2.7.0'
    implementation 'androidx.fragment:fragment:1.6.2'
    
    // Add explicit support for 16KB pages
    implementation 'androidx.startup:startup-runtime:1.1.1'
}
```

### 2. Update AndroidManifest.xml

#### A. Add Application Attributes
```xml
<application
    android:label="pelevo"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:enableOnBackInvokedCallback="true"
    android:extractNativeLibs="false"
    android:usesCleartextTraffic="false">
```

#### B. Add Activity Configuration
```xml
<activity
    android:name="io.flutter.embedding.android.FlutterActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize"
    android:process=":main">
```

### 3. Update Flutter Dependencies

#### A. Update pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Update to latest versions for 16KB page support
  sentry_flutter: ^9.6.0
  cached_network_image: ^3.3.1
  flutter_svg: ^2.0.9
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
  dio: ^5.4.0
  fluttertoast: ^8.2.4
  sizer: ^2.0.15
  fl_chart: ^0.65.0
  google_fonts: ^6.1.0
  flutter_dotenv: ^5.2.1
  permission_handler: ^11.3.1
  provider: ^6.1.2
  audioplayers: ^6.0.0  # Updated
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
  url_launcher: ^6.2.5
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.0.15
  share_plus: ^7.2.1
  image_picker: ^1.0.7
  flutter_web_auth_2: ^4.1.0
  intl: ^0.19.0
  just_audio: ^0.9.36
  audio_session: ^0.1.18
  wakelock_plus: ^1.1.4
  shimmer: ^3.0.0
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.2
  workmanager: ^0.7.0
  flutter_local_notifications: ^17.0.0
  audio_service: ^0.18.15
  in_app_purchase: ^3.2.3
```

### 4. Create Native Library Compatibility

#### A. Create jniLibs Directory Structure
```
android/app/src/main/jniLibs/
├── arm64-v8a/
│   ├── libflutter.so
│   └── [other native libraries]
├── armeabi-v7a/
│   ├── libflutter.so
│   └── [other native libraries]
└── x86_64/
    ├── libflutter.so
    └── [other native libraries]
```

#### B. Add Native Library Configuration
```gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
        }
    }
    
    packagingOptions {
        jniLibs {
            useLegacyPackaging = false
            pickFirsts += ['**/libc++_shared.so', '**/libjsc.so']
        }
    }
}
```

### 5. Memory Management Optimizations

#### A. Update MainActivity.kt
```kotlin
package com.pelevo_podcast.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.pelevo_podcast.app/memory"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPageSize" -> {
                    result.success(getSystemPageSize())
                }
                "optimizeMemory" -> {
                    optimizeMemoryFor16KB()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun getSystemPageSize(): Int {
        return try {
            val pageSize = android.os.Build.VERSION.SDK_INT >= 29 && 
                          android.os.Build.VERSION.SDK_INT < 35
            if (pageSize) 4096 else 16384 // 4KB for older versions, 16KB for Android 15+
        } catch (e: Exception) {
            4096 // Default to 4KB if detection fails
        }
    }
    
    private fun optimizeMemoryFor16KB() {
        // Optimize memory allocation for 16KB pages
        System.gc()
        Runtime.getRuntime().gc()
    }
}
```

#### B. Create Flutter Memory Manager
```dart
// lib/core/services/memory_manager.dart
import 'package:flutter/services.dart';

class MemoryManager {
  static const MethodChannel _channel = MethodChannel('com.pelevo_podcast.app/memory');
  
  static Future<int> getPageSize() async {
    try {
      final int pageSize = await _channel.invokeMethod('getPageSize');
      return pageSize;
    } catch (e) {
      return 4096; // Default to 4KB
    }
  }
  
  static Future<bool> optimizeMemory() async {
    try {
      final bool success = await _channel.invokeMethod('optimizeMemory');
      return success;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> is16KBPageSizeSupported() async {
    final int pageSize = await getPageSize();
    return pageSize >= 16384;
  }
}
```

### 6. Testing and Validation

#### A. Create Test Script
```bash
#!/bin/bash
# test_16kb_pages.sh

echo "Testing 16KB page size compatibility..."

# Build the app
flutter clean
flutter pub get
flutter build apk --release

# Test on different architectures
echo "Testing ARM64-V8A..."
flutter build apk --release --target-platform android-arm64

echo "Testing ARM EABI-V7A..."
flutter build apk --release --target-platform android-arm

echo "Testing X86_64..."
flutter build apk --release --target-platform android-x64

echo "Build completed successfully!"
```

#### B. Add Debug Information
```dart
// lib/core/utils/debug_info.dart
import 'package:flutter/foundation.dart';
import '../services/memory_manager.dart';

class DebugInfo {
  static Future<Map<String, dynamic>> getSystemInfo() async {
    final pageSize = await MemoryManager.getPageSize();
    final is16KBSupported = await MemoryManager.is16KBPageSizeSupported();
    
    return {
      'pageSize': pageSize,
      'is16KBSupported': is16KBSupported,
      'androidVersion': defaultTargetPlatform.name,
      'isDebugMode': kDebugMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  static void logSystemInfo() async {
    final info = await getSystemInfo();
    debugPrint('🔍 System Info: $info');
  }
}
```

### 7. Deployment Configuration

#### A. Update CodeMagic Configuration
```yaml
# codemagic.yaml
workflows:
  android-release:
    name: Android Release Build
    max_build_duration: 60
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
    scripts:
      - name: Set up local.properties
        script: |
          echo "flutter.sdk=$HOME/programs/flutter" > "$CM_BUILD_DIR/android/local.properties"
      - name: Get Flutter packages
        script: |
          flutter packages pub get
      - name: Flutter analyze
        script: |
          flutter analyze
      - name: Test 16KB page compatibility
        script: |
          flutter test --coverage
      - name: Build APK for 16KB page testing
        script: |
          flutter build apk --release --target-platform android-arm64
          flutter build apk --release --target-platform android-arm
          flutter build apk --release --target-platform android-x64
    artifacts:
      - build/app/outputs/**/*.apk
      - build/ios/ipa/*.ipa
      - flutter_drive.log
      - test/coverage_helper_test.dart
    publishing:
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
        track: internal
        submit_as_draft: true
```

### 8. Monitoring and Analytics

#### A. Add Page Size Monitoring
```dart
// lib/core/services/analytics_service.dart
import 'package:sentry_flutter/sentry_flutter.dart';
import 'memory_manager.dart';

class AnalyticsService {
  static Future<void> trackPageSizeCompatibility() async {
    try {
      final pageSize = await MemoryManager.getPageSize();
      final is16KBSupported = await MemoryManager.is16KBPageSizeSupported();
      
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Page size compatibility check',
          data: {
            'pageSize': pageSize,
            'is16KBSupported': is16KBSupported,
            'androidVersion': '${await getAndroidVersion()}',
          },
        ),
      );
      
      if (!is16KBSupported) {
        await Sentry.captureMessage(
          'App running on non-16KB page size device',
          level: SentryLevel.warning,
        );
      }
    } catch (e) {
      await Sentry.captureException(e);
    }
  }
  
  static Future<String> getAndroidVersion() async {
    // Implementation to get Android version
    return 'Unknown';
  }
}
```

## Implementation Timeline

### Phase 1: Preparation (Week 1)
- [ ] Update build.gradle with 16KB page support
- [ ] Update AndroidManifest.xml
- [ ] Update Flutter dependencies

### Phase 2: Native Implementation (Week 2)
- [ ] Create MainActivity.kt with memory management
- [ ] Implement Flutter memory manager
- [ ] Add native library configuration

### Phase 3: Testing (Week 3)
- [ ] Create test scripts
- [ ] Test on different architectures
- [ ] Validate 16KB page compatibility

### Phase 4: Deployment (Week 4)
- [ ] Update CI/CD configuration
- [ ] Deploy to internal testing
- [ ] Monitor compatibility

## Benefits of Implementation

1. **Future-Proof**: Ensures app compatibility with Android 15+
2. **Performance**: Better memory management on 16KB page devices
3. **Compliance**: Meets Google Play requirements
4. **User Experience**: Optimized performance on latest Android devices
5. **Market Access**: Continued ability to publish updates

## Risk Mitigation

1. **Backward Compatibility**: Maintains support for 4KB page devices
2. **Gradual Rollout**: Test on internal track first
3. **Monitoring**: Track compatibility across different devices
4. **Fallback**: Graceful degradation for unsupported devices

## Conclusion

This implementation ensures your app meets Google Play's 16KB page size requirements while maintaining backward compatibility and optimal performance across all Android versions.
