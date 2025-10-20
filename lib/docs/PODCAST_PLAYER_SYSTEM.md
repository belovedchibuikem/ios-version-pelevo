# 🎧 Podcast Player System

## Overview

The Podcast Player System is a comprehensive audio player solution that provides a seamless podcast listening experience across the Pelevo app. It features a single player component that adapts between minimized and maximized states, with intelligent tab management based on playback state.

## 🏗️ Architecture

### Core Components

1. **PodcastPlayerProvider** - State management for player UI and playback
2. **AudioPlayerService** - Background audio playback and session management
3. **PodcastPlayer** - Main UI component with adaptive states
4. **EpisodeDetailModal** - Episode information and quick actions

### State Management

The system uses Provider pattern for state management, ensuring:
- Persistent player state across app restarts
- Synchronized UI updates
- Background playback support
- Cross-screen state consistency

## 🎯 Key Features

### 1. **Adaptive Player States**
- **Minimized**: Floating player at bottom navigation
- **Maximized**: Full-screen player with tabs
- **Episode Detail Modal**: Episode information with player controls

### 2. **Intelligent Tab Management**
- **Now Playing**: Only visible when actively playing
- **Details**: Episode information and metadata
- **Bookmarks**: User-created markers and notes

### 3. **Background Playback**
- Continues playing when phone locks
- Audio session management
- Wake lock for continuous playback
- State persistence across app restarts

### 4. **Advanced Controls**
- Playback speed control (0.5x - 3.0x)
- Sleep timer functionality
- Shuffle and repeat modes
- Skip forward/backward (10s/30s)
- Queue management

## 🚀 Getting Started

### 1. **Add Dependencies**

```yaml
dependencies:
  just_audio: ^0.9.36
  audio_session: ^0.1.18
  wakelock_plus: ^1.1.4
  provider: any
  shared_preferences: ^2.2.2
```

### 2. **Setup Provider**

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PodcastPlayerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 3. **Add Player to App**

```dart
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your main content
          YourMainContent(),
          
          // Podcast Player (floating at bottom)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PodcastPlayer(),
          ),
        ],
      ),
    );
  }
}
```

## 📱 Usage Examples

### Play an Episode

```dart
final playerProvider = Provider.of<PodcastPlayerProvider>(context, listen: false);

// Set episode and start playing
playerProvider.setCurrentEpisode(episode);
playerProvider.play();

// Show full player
playerProvider.setMinimized(false);
```

### Show Episode Detail Modal

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (context, scrollController) => EpisodeDetailModal(
      episode: episode,
      episodes: episodeList,
      episodeIndex: index,
    ),
  ),
);
```

### Control Playback

```dart
final audioService = AudioPlayerService();

// Play/Pause
if (playerProvider.isPlaying) {
  audioService.pause();
} else {
  audioService.play();
}

// Seek to position
audioService.seekTo(Duration(minutes: 5, seconds: 30));

// Set playback speed
audioService.setPlaybackSpeed(1.5);
```

## 🎨 Theme Integration

The player system uses the app's main theme colors:

- **Primary**: Main buttons and active elements
- **Surface**: Background colors
- **OnSurface**: Text colors
- **Outline**: Borders and dividers
- **Error**: Delete actions

## 🔧 Configuration

### Audio Session Settings

```dart
await _audioSession!.configure(const AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.playback,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
      AVAudioSessionCategoryOptions.allowBluetoothA2DP |
      AVAudioSessionCategoryOptions.allowAirPlay |
      AVAudioSessionCategoryOptions.defaultToSpeaker,
  androidAudioAttributes: AndroidAudioAttributes(
    contentType: AndroidAudioContentType.music,
    usage: AndroidAudioUsage.media,
  ),
  androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  androidWillPauseWhenDucked: true,
));
```

### Player Settings

```dart
// Auto-play next episode
playerProvider.toggleAutoPlayNext();

// Keep screen on during playback
playerProvider.toggleKeepScreenOn();

// Set sleep timer
playerProvider.setSleepTimer(Duration(minutes: 30));
```

## 📊 State Persistence

The player automatically saves and restores:
- Current episode and queue
- Playback position and duration
- Player settings (shuffle, repeat, speed)
- UI state (minimized/maximized)
- Sleep timer settings

## 🔄 Integration Points

### Episode List Integration

```dart
// In your episode list item
EpisodeListItem(
  episode: episode,
  isCurrentlyPlaying: playerProvider.currentEpisode?.id == episode.id,
  playProgress: playerProvider.progressPercentage,
  onTap: () {
    // Show episode detail modal
    _showEpisodeDetailModal(context, episode);
  },
  onLongPress: () {
    // Enter selection mode
    _enterSelectionMode();
  },
)
```

### Navigation Integration

```dart
// The player automatically appears on all screens
// No need to manually add it to each screen

// Just ensure the PodcastPlayer widget is in your main app structure
```

## 🧪 Testing

### Demo Mode

Use the included demo to test the player:

```dart
// Run the demo app
flutter run -t lib/main_with_player.dart

// Test player functionality
1. Tap "Test Player" to activate demo player
2. Tap "Episode Details" to see episode modal
3. Use player controls to test functionality
```

### Testing Checklist

- [ ] Player appears when episode is loaded
- [ ] Minimized player shows at bottom
- [ ] Maximized player shows full controls
- [ ] Tabs change based on playing state
- [ ] Background playback works
- [ ] State persists across app restarts
- [ ] Audio controls respond correctly
- [ ] Episode queue management works

## 🐛 Troubleshooting

### Common Issues

1. **Player not appearing**
   - Check if PodcastPlayerProvider is in MultiProvider
   - Ensure PodcastPlayer widget is in app structure
   - Verify episode data is properly formatted

2. **Audio not playing**
   - Check audio permissions
   - Verify audio URL is accessible
   - Check device volume settings

3. **State not persisting**
   - Ensure SharedPreferences is working
   - Check for storage permissions
   - Verify provider disposal

### Debug Information

```dart
// Enable debug logging
if (kDebugMode) {
  _dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));
}

// Check player state
print('Player State: ${playerProvider.isPlaying}');
print('Current Episode: ${playerProvider.currentEpisode?.title}');
print('Position: ${playerProvider.formattedPosition}');
```

## 🔮 Future Enhancements

### Planned Features

1. **Advanced Queue Management**
   - Drag and drop reordering
   - Smart queue suggestions
   - Queue history

2. **Enhanced Audio Features**
   - Equalizer and audio effects
   - Voice boost and noise reduction
   - Crossfade between episodes

3. **Social Features**
   - Share timestamps
   - Collaborative playlists
   - Episode recommendations

4. **Analytics Integration**
   - Listening statistics
   - Episode completion rates
   - User behavior insights

## 📚 Additional Resources

- [just_audio Package](https://pub.dev/packages/just_audio)
- [audio_session Package](https://pub.dev/packages/audio_session)
- [Provider Package](https://pub.dev/packages/provider)
- [Flutter Audio Documentation](https://docs.flutter.dev/development/platform-integration/audio)

## 🤝 Contributing

When contributing to the player system:

1. Follow the existing code structure
2. Use the app's theme colors
3. Test on both Android and iOS
4. Ensure background playback works
5. Update this documentation

## 📄 License

This player system is part of the Pelevo Podcast app and follows the same licensing terms.
