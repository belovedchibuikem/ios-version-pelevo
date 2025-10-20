# Episode Progress System

## Overview

The Episode Progress System provides visual indicators for episode playback states, allowing users to quickly identify which episodes they've played, are currently playing, or haven't started yet.

## Visual States

### 1. Unplayed Episodes
- **Icon**: Play arrow (▶️)
- **Border**: Default outline color
- **Background**: Transparent
- **Text**: Full opacity, normal color

### 2. Partially Played Episodes
- **Icon**: Play arrow (▶️)
- **Border**: Primary theme color
- **Background**: Transparent
- **Progress**: Circular progress indicator showing completion percentage
- **Text**: Full opacity, normal color

### 3. Currently Playing Episodes
- **Icon**: Pause icon (⏸️)
- **Border**: Primary theme color
- **Background**: Primary theme color with low opacity
- **Progress**: Circular progress indicator
- **Text**: Full opacity, normal color

### 4. Completed Episodes
- **Icon**: Checkmark (✓)
- **Border**: Primary theme color
- **Background**: Primary theme color (solid)
- **Text**: Reduced opacity (grayed out)

## Data Structure

The system supports multiple ways to track episode progress:

### Method 1: Direct Progress Value
```dart
{
  'title': 'Episode Title',
  'duration': '45:30',
  'playProgress': 0.75, // 75% completed
  'isCurrentlyPlaying': false,
}
```

### Method 2: Played Duration
```dart
{
  'title': 'Episode Title',
  'duration': '60:00', // Total duration
  'playedDuration': '45:00', // How much has been played
  'isCurrentlyPlaying': false,
}
```

### Method 3: Boolean Flags
```dart
{
  'title': 'Episode Title',
  'duration': '45:30',
  'isCompleted': true, // Marked as fully played
  'isCurrentlyPlaying': false,
}
```

### Method 4: Playing State
```dart
{
  'title': 'Episode Title',
  'duration': '45:30',
  'playingState': 'playing', // 'playing', 'paused', 'stopped'
  'playProgress': 0.25,
}
```

## Implementation Details

### EpisodeListItem Widget
The `EpisodeListItem` widget automatically adapts its appearance based on the provided progress data:

- **Progress Range**: 0.0 (not started) to 1.0 (completed)
- **Visual Feedback**: Different colors, icons, and progress indicators
- **Accessibility**: Clear visual distinction between states

### Progress Calculation
The system automatically calculates progress when using duration-based data:

```dart
// Example: 45 minutes played out of 60 minutes total
final progress = (45 * 60) / (60 * 60) = 0.75
```

### Theme Integration
All visual elements use the app's theme colors:
- **Primary Color**: Used for progress indicators and completed states
- **Surface Colors**: Used for backgrounds and borders
- **Text Colors**: Automatically adjusted for different states

## Usage Examples

### Basic Implementation
```dart
EpisodeListItem(
  episode: episodeData,
  onPlay: () => playEpisode(episodeData),
  playProgress: 0.5, // 50% completed
  isCurrentlyPlaying: false,
)
```

### With Duration Data
```dart
EpisodeListItem(
  episode: {
    'title': 'My Episode',
    'duration': '60:00',
    'playedDuration': '30:00',
  },
  onPlay: () => playEpisode(episodeData),
)
```

### Currently Playing
```dart
EpisodeListItem(
  episode: episodeData,
  onPlay: () => pauseEpisode(episodeData),
  playProgress: 0.25,
  isCurrentlyPlaying: true, // Shows pause icon
)
```

## Benefits

1. **User Experience**: Clear visual feedback on episode status
2. **Progress Tracking**: Users can see how much of each episode they've completed
3. **Navigation**: Easy identification of played vs. unplayed content
4. **Consistency**: Unified design language across the app
5. **Accessibility**: Clear visual distinction between different states

## Future Enhancements

- **Seek Bar**: Add seek functionality to progress indicators
- **Time Display**: Show remaining time vs. total time
- **Bookmarks**: Allow users to set custom progress points
- **Sync**: Cloud synchronization of progress across devices
- **Analytics**: Track listening patterns and preferences
