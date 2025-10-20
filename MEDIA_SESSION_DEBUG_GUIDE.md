# Media Session Debug Guide

## 🚨 CRITICAL FIXES APPLIED

### 1. **EnhancedAudioPlayerService Fix**
- **Issue**: Was calling `_mediaSession.initialize()` without `playerProvider`
- **Fix**: Updated to `_mediaSession.initialize(playerProvider: playerProvider)`
- **Impact**: Media session now has access to provider for system controls

### 2. **HybridAudioPlayerService Fix**
- **Issue**: Not passing `playerProvider` to enhanced service
- **Fix**: Updated to pass `playerProvider` to both services
- **Impact**: Both audio implementations now properly initialize media session

### 3. **Enhanced Debug Logging**
- **Added**: Comprehensive logging to track media session initialization
- **Added**: Logging for episode updates and playback state changes
- **Impact**: Can now track exactly what's happening with media session

## 🔍 DEBUGGING STEPS

### Step 1: Check Debug Logs
Run the app and look for these log messages:

```
🎵 MediaSessionService: Starting initialization...
🎵 MediaSessionService: Player provider set: true
🎵 MediaSessionService: Initializing AudioService...
✅ MediaSessionService: Initialized successfully with AudioHandler: true
```

### Step 2: Test Episode Loading
When you play an episode, look for:

```
🎵 MediaSessionService: setEpisode called with: [Episode Title]
🎵 MediaSessionService: AudioHandler available, creating MediaItem...
✅ MediaSessionService: Media session updated with episode: [Episode Title]
```

### Step 3: Test Playback Controls
When you play/pause, look for:

```
🎵 MediaSessionService: updatePlaybackState called - isPlaying: true/false
✅ MediaSessionService: Playback state updated: Playing/Paused
```

## 🚨 COMMON ISSUES & SOLUTIONS

### Issue 1: "AudioHandler is null"
**Cause**: Media session not properly initialized
**Solution**: Check if `MediaSessionService.initialize()` is being called

### Issue 2: No lock screen controls
**Cause**: Android notification permissions or audio service not running
**Solution**: 
1. Check notification permissions in Android settings
2. Verify audio service is running in background
3. Check if app has "Display over other apps" permission

### Issue 3: Controls don't respond
**Cause**: PlayerProvider not properly connected
**Solution**: Verify `PodcastAudioHandler` has valid `_playerProvider`

## 📱 TESTING CHECKLIST

### Android Testing:
- [ ] App has notification permissions
- [ ] Audio service is running in background
- [ ] Lock screen shows media controls
- [ ] Notification shows media controls
- [ ] Hardware buttons (headphones) work
- [ ] Bluetooth controls work

### iOS Testing:
- [ ] Control Center shows media controls
- [ ] Lock screen shows media controls
- [ ] AirPods controls work
- [ ] CarPlay integration works

## 🔧 MANUAL TESTING STEPS

1. **Start the app**
2. **Play an episode**
3. **Lock the device**
4. **Check lock screen for media controls**
5. **Try play/pause from lock screen**
6. **Check notification panel for media controls**

## 📋 DEBUG COMMANDS

### Check if media session is initialized:
```dart
final mediaSession = MediaSessionService();
print('Media session initialized: ${mediaSession.isInitialized}');
```

### Check current episode:
```dart
final mediaSession = MediaSessionService();
print('Current episode: ${mediaSession.currentEpisode?.title}');
```

### Check playback state:
```dart
final mediaSession = MediaSessionService();
print('Is playing: ${mediaSession.isPlaying}');
```

## 🚨 IF STILL NOT WORKING

### Check Android Logs:
```bash
adb logcat | grep -E "(MediaSession|AudioService|Pelevo)"
```

### Check for Errors:
Look for these error patterns:
- `AudioService.init` failures
- `MediaSessionService` initialization errors
- `PodcastAudioHandler` null pointer exceptions

### Verify Permissions:
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- `POST_NOTIFICATIONS`
- `WAKE_LOCK`

## 📞 NEXT STEPS

If the media session is still not working after these fixes:

1. **Check the debug logs** for the specific error messages
2. **Verify Android permissions** are granted
3. **Test on different devices** (some devices have different behaviors)
4. **Check if audio_service package** is properly installed
5. **Verify the app is not being killed** by the system

The fixes applied should resolve the most common issues. The enhanced debug logging will help identify any remaining problems.
