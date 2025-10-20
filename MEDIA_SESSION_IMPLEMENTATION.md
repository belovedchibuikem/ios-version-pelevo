# Media Session Implementation Guide

This guide explains how to use the unified media session implementation that works with both `just_audio` and `audioplayers` packages.

## Overview

The media session implementation provides:
- Lock screen controls (play, pause, skip, seek)
- Notification controls
- Background playback support
- Integration with both audio packages
- Unified API for all audio services

## Files Created/Modified

### New Files:
1. `lib/core/services/unified_media_session.dart` - Core media session service
2. `lib/core/services/media_session_manager.dart` - Manager for coordinating media sessions
3. `lib/core/services/media_session_example.dart` - Example implementation

### Modified Files:
1. `lib/services/enhanced_audio_player_service.dart` - Added media session integration
2. `lib/services/audio_player_service.dart` - Updated to use unified media session

## Dependencies

The following dependencies are required in `pubspec.yaml`:

```yaml
dependencies:
  audio_service: ^0.18.15  # For media session support
  just_audio: ^0.9.36      # Primary audio player
  audioplayers: any        # Alternative audio player
  audio_session: ^0.1.18   # Audio session management
```

## Basic Usage

### 1. Initialize Media Session

In your main app initialization:

```dart
import 'package:pelevo_podcast/core/services/media_session_manager.dart';

// In your main app or provider initialization
final mediaSessionManager = MediaSessionManager();
await mediaSessionManager.initialize(playerProvider: yourPlayerProvider);
```

### 2. Update Episode Information

When playing a new episode:

```dart
// Set the current episode
mediaSessionManager.setEpisode(episode);

// Update playback state
mediaSessionManager.updatePlaybackState(
  isPlaying: true,
  position: Duration.zero,
  duration: Duration(seconds: episodeDuration),
);
```

### 3. Update Playback State

When playback state changes:

```dart
// Update when playing/pausing
mediaSessionManager.updatePlaybackState(
  isPlaying: isPlaying,
  position: currentPosition,
  duration: totalDuration,
);

// Update position during playback
mediaSessionManager.updatePosition(currentPosition);

// Update duration when loaded
mediaSessionManager.updateDuration(totalDuration);
```

## Integration with Existing Services

### Enhanced Audio Player Service

The `EnhancedAudioPlayerService` now automatically integrates with the media session:

```dart
final audioService = EnhancedAudioPlayerService();
await audioService.initialize();

// Play episode - media session is automatically updated
await audioService.loadAndPlayEpisode(episode);
```

### Audio Player Service (just_audio)

The `AudioPlayerService` already has media session integration:

```dart
final audioService = AudioPlayerService();
await audioService.initialize(playerProvider: playerProvider);

// Play episode - media session is automatically updated
await audioService.playEpisode(episode);
```

## Media Session Controls

The media session provides the following controls:

### Lock Screen Controls:
- Play/Pause button
- Skip to next episode
- Skip to previous episode
- Stop button
- Seek bar (on supported devices)

### Notification Controls:
- Play/Pause
- Skip forward/backward
- Stop
- Episode information display

## Platform-Specific Configuration

### Android

The media session automatically configures:
- Notification channel for podcast playback
- Background playback permissions
- Audio focus management
- Lock screen controls

### iOS

The media session automatically configures:
- AVAudioSession for background playback
- Now Playing info
- Control center integration
- Lock screen controls

## Troubleshooting

### Common Issues:

1. **Media session not showing on lock screen**
   - Ensure `audio_service` is properly initialized
   - Check that the app has notification permissions
   - Verify the audio session is configured for playback

2. **Controls not responding**
   - Make sure the `PodcastPlayerProvider` is properly connected
   - Check that the media session handlers are implemented
   - Verify the audio service is not disposed

3. **Background playback not working**
   - Ensure proper audio session configuration
   - Check background app refresh permissions
   - Verify wake lock is enabled

### Debug Information:

Enable debug logging to see media session events:

```dart
// The services automatically log media session events
// Look for logs starting with "🎵" in your debug console
```

## Example Implementation

See `lib/core/services/media_session_example.dart` for a complete example of how to integrate the media session with your existing audio services.

## Testing

To test the media session:

1. Play an episode in your app
2. Lock your device
3. Check that controls appear on the lock screen
4. Test play/pause/skip functionality
5. Verify episode information is displayed correctly

## Migration from Old Implementation

If you were using the old `SimpleMediaSession`:

1. Replace imports:
   ```dart
   // Old
   import '../core/services/simple_media_session.dart';
   
   // New
   import '../core/services/unified_media_session.dart';
   ```

2. Update initialization:
   ```dart
   // Old
   final mediaSession = SimpleMediaSession();
   
   // New
   final mediaSession = UnifiedMediaSession();
   ```

3. The API remains largely the same, but now works with both audio packages.

## Support

The media session implementation is designed to work seamlessly with both `just_audio` and `audioplayers` packages. If you encounter issues:

1. Check the debug logs for media session events
2. Verify all dependencies are properly installed
3. Ensure proper initialization order
4. Test on both Android and iOS devices

The implementation provides comprehensive media session support for podcast playback with lock screen controls, notification controls, and background playback capabilities.
