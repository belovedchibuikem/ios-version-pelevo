# Podcast App API Reference

## Table of Contents
1. [Services](#services)
2. [Models](#models)
3. [Providers](#providers)
4. [Widgets](#widgets)
5. [Utilities](#utilities)

## Services

### EpisodeProgressService

The central service for managing episode progress and bookmarks.

#### Constructor
```dart
EpisodeProgressService()
```

#### Methods

##### Progress Management
```dart
// Save or update episode progress
Future<void> saveProgress({
  required String episodeId,
  required int currentPosition,
  required int totalDuration,
  bool isCompleted = false,
  String? podcastId,
  DateTime? lastPlayedAt,
})

// Get progress for a specific episode
Future<EpisodeProgress?> getProgress(String episodeId)

// Update existing progress
Future<void> updateProgress({
  required String episodeId,
  required int currentPosition,
  required int totalDuration,
  bool isCompleted = false,
})

// Mark episode as completed
Future<void> markCompleted(String episodeId)

// Get all progress records
Future<List<EpisodeProgress>> getAllProgress({
  String? podcastId,
  bool? isCompleted,
  DateTime? since,
})

// Delete progress for an episode
Future<void> deleteProgress(String episodeId)

// Clear all progress
Future<void> clearAllProgress()
```

##### Bookmark Management
```dart
// Add a new bookmark
Future<void> addBookmark({
  required String episodeId,
  required String podcastId,
  required int position,
  required String title,
  String? notes,
  String color = '#2196F3',
  bool isPublic = false,
  String? category,
  List<String>? tags,
  Map<String, dynamic>? metadata,
})

// Update an existing bookmark
Future<void> updateBookmark({
  required String episodeId,
  required int position,
  String? title,
  String? notes,
  String? color,
  bool? isPublic,
  String? category,
  List<String>? tags,
  Map<String, dynamic>? metadata,
})

// Remove a bookmark
Future<void> removeBookmark(String episodeId, int position)

// Get bookmarks for an episode
Future<List<EpisodeBookmark>> getBookmarks(String episodeId)

// Get bookmarks by category
Future<List<EpisodeBookmark>> getBookmarksByCategory(String category)

// Get bookmarks by tags
Future<List<EpisodeBookmark>> getBookmarksByTags(List<String> tags)

// Search bookmarks
Future<List<EpisodeBookmark>> searchBookmarks(String query)

// Get bookmark statistics
Future<Map<String, dynamic>> getBookmarkStatistics()
```

##### Synchronization
```dart
// Sync progress to cloud
Future<void> syncProgress()

// Sync all progress to cloud
Future<void> syncAllProgress()

// Get sync statistics
Future<Map<String, dynamic>> getSyncStatistics()

// Check network and sync
Future<void> checkNetworkAndSync()

// Clear sync queue
Future<void> clearSyncQueue()
```

#### Properties
```dart
bool get isInitialized
bool get isOnline
bool get hasPendingSync
```

### AudioPlayerService

Manages audio playback and player state.

#### Constructor
```dart
AudioPlayerService()
```

#### Methods
```dart
// Playback control
Future<void> play()
Future<void> pause()
Future<void> stop()
Future<void> seek(Duration position)
Future<void> setVolume(double volume)
Future<void> setPlaybackRate(double rate)

// Queue management
void setQueue(List<Episode> episodes, int startIndex)
void playNext()
void playPrevious()
void skipToEpisode(int index)

// State management
void dispose()
```

#### Streams
```dart
Stream<PlayerState> get playerStateStream
Stream<Duration> get positionStream
Stream<Duration> get durationStream
Stream<bool> get isPlayingStream
Stream<Episode?> get currentEpisodeStream
```

### PerformanceMonitorService

Monitors app performance and provides optimization insights.

#### Constructor
```dart
PerformanceMonitorService()
```

#### Methods
```dart
// Start monitoring
void startMonitoring()

// Stop monitoring
void stopMonitoring()

// Monitor operation performance
Future<T> monitorOperation<T>(String operationName, Future<T> Function() operation)

// Monitor widget build performance
void monitorWidgetBuild(String widgetName, VoidCallback buildCallback)

// Get performance statistics
Map<String, dynamic> getPerformanceStats()

// Get performance warnings
List<String> getPerformanceWarnings()
```

### MemoryManagementService

Manages memory usage and caching.

#### Constructor
```dart
MemoryManagementService()
```

#### Methods
```dart
// Cache management
void cacheData(String key, dynamic data, {Duration? expiration})
T? getCachedData<T>(String key)
void removeFromCache(String key)
void clearCache()

// Memory management
Map<String, dynamic> getCacheStats()
Map<String, dynamic> getMemoryUsage()
void optimizeCache()
```

### EnhancedErrorHandler

Provides comprehensive error handling and user feedback.

#### Constructor
```dart
EnhancedErrorHandler()
```

#### Methods
```dart
// Initialize error handler
void initialize()

// Handle errors
void handleError(dynamic error, StackTrace? stackTrace)

// Add error listener
void addErrorListener(Function(String, String) listener)

// Remove error listener
void removeErrorListener(Function(String, String) listener)
```

### AnimationService

Centralized service for creating animations.

#### Constructor
```dart
AnimationService()
```

#### Methods
```dart
// Basic animations
Animation<double> createFadeInAnimation(AnimationController controller)
Animation<Offset> createSlideInFromBottomAnimation(AnimationController controller)
Animation<Offset> createSlideInFromTopAnimation(AnimationController controller)
Animation<Offset> createSlideInFromLeftAnimation(AnimationController controller)
Animation<Offset> createSlideInFromRightAnimation(AnimationController controller)

// Advanced animations
Animation<double> createScaleAnimation(AnimationController controller)
Animation<double> createBounceAnimation(AnimationController controller)
Animation<double> createRotationAnimation(AnimationController controller)
Animation<double> createPulseAnimation(AnimationController controller)
Animation<double> createShakeAnimation(AnimationController controller)

// Staggered animations
List<Animation<double>> createStaggeredAnimations(
  AnimationController controller,
  int itemCount, {
  Duration staggerDelay = const Duration(milliseconds: 100),
})

// Custom animations
Animation<double> createCustomCurveAnimation(
  AnimationController controller,
  Curve curve, {
  double begin = 0.0,
  double end = 1.0,
})

// Combined animations
CombinedAnimation createCombinedAnimation(AnimationController controller)
```

## Models

### Episode

Represents a podcast episode.

#### Constructor
```dart
Episode({
  required this.id,
  required this.title,
  required this.description,
  required this.audioUrl,
  required this.duration,
  required this.publishedAt,
  required this.podcastId,
  required this.podcastTitle,
  this.coverImage,
  this.hasTranscript = false,
  this.lastPlayedPosition,
  this.totalDuration,
  this.lastPlayedAt,
  this.isCompleted = false,
})
```

#### Properties
```dart
final String id
final String title
final String description
final String audioUrl
final Duration duration
final DateTime publishedAt
final String podcastId
final String podcastTitle
final String? coverImage
final bool hasTranscript
final int? lastPlayedPosition
final int? totalDuration
final DateTime? lastPlayedAt
final bool isCompleted
```

#### Methods
```dart
// JSON serialization
Map<String, dynamic> toJson()
factory Episode.fromJson(Map<String, dynamic> json)

// Progress calculations
double get progressPercentage
Duration get remainingTime
String get formattedRemainingTime
bool get isPartiallyPlayed
bool get isInProgress

// Copy with modifications
Episode copyWith({...})
```

### EpisodeProgress

Represents episode playback progress.

#### Constructor
```dart
EpisodeProgress({
  required this.episodeId,
  required this.podcastId,
  required this.currentPosition,
  required this.totalDuration,
  required this.lastPlayedAt,
  this.isCompleted = false,
  this.createdAt,
  this.updatedAt,
})
```

#### Properties
```dart
final String episodeId
final String podcastId
final int currentPosition
final int totalDuration
final DateTime lastPlayedAt
final bool isCompleted
final DateTime createdAt
final DateTime updatedAt
```

#### Methods
```dart
// JSON serialization
Map<String, dynamic> toJson()
factory EpisodeProgress.fromJson(Map<String, dynamic> json)

// Progress calculations
double get progressPercentage
Duration get remainingTime
String get formattedRemainingTime
```

### EpisodeBookmark

Represents an episode bookmark.

#### Constructor
```dart
EpisodeBookmark({
  required this.episodeId,
  required this.podcastId,
  required this.position,
  required this.title,
  this.notes,
  this.color = '#2196F3',
  this.isPublic = false,
  this.category,
  this.tags,
  this.metadata,
  this.createdAt,
  this.updatedAt,
  this.deviceId,
})
```

#### Properties
```dart
final String episodeId
final String podcastId
final int position
final String title
final String? notes
final String color
final bool isPublic
final String? category
final List<String>? tags
final Map<String, dynamic>? metadata
final DateTime createdAt
final DateTime? updatedAt
final String? deviceId
```

#### Methods
```dart
// JSON serialization
Map<String, dynamic> toJson()
factory EpisodeBookmark.fromJson(Map<String, dynamic> json)

// Position formatting
String get formattedPosition
String get formattedPositionShort

// Copy with modifications
EpisodeBookmark copyWith({...})
```

## Providers

### PodcastPlayerProvider

Manages podcast player state and functionality.

#### Constructor
```dart
PodcastPlayerProvider()
```

#### Properties
```dart
// Player state
Episode? get currentEpisode
bool get isPlaying
Duration get position
Duration get duration
bool get isBuffering
String? get currentAudioUrl

// Queue management
List<Episode> get episodeQueue
int get currentEpisodeIndex
bool get hasNextEpisode
bool get hasPreviousEpisode

// Mini-player
bool get isMiniPlayerVisible
ResumeInfo? get lastResumeInfo

// Settings
bool get autoPlayNextEpisode
bool get repeatPlaylist
```

#### Methods
```dart
// Episode management
void setEpisodeQueue(List<Episode> episodes, {int startIndex = 0})
void loadAndPlayEpisode(Episode episode, {bool clearQueue = true})
void playNext()
void playPrevious()
void skipToEpisode(int index)

// Playback control
void play()
void pause()
void stop()
void seek(Duration position)
void setVolume(double volume)

// Mini-player control
void showFloatingMiniPlayer(BuildContext context, Map<String, dynamic> episode, List<Map<String, dynamic>> episodes, int episodeIndex)
void hideFloatingMiniPlayer()
void setMiniPlayerPositioning(String position)

// Settings
void setAutoPlayNextEpisode(bool value)
void setRepeatPlaylist(bool value)
```

#### Streams
```dart
Stream<Episode?> get currentEpisodeStream
Stream<bool> get isPlayingStream
Stream<Duration> get positionStream
Stream<Duration> get durationStream
Stream<bool> get isBufferingStream
```

### ThemeService

Manages app theming and appearance.

#### Constructor
```dart
ThemeService()
```

#### Properties
```dart
ThemeMode get currentThemeMode
bool get isDarkMode
bool get isLightMode
bool get isSystemMode
```

#### Methods
```dart
void setThemeMode(ThemeMode mode)
void toggleTheme()
void setDarkMode()
void setLightMode()
void setSystemMode()
```

## Widgets

### EpisodeListItem

Reusable widget for displaying episode information.

#### Constructor
```dart
EpisodeListItem({
  super.key,
  required this.episode,
  this.onPlay,
  this.onLongPress,
  this.showTranscriptIcon = false,
  this.showArchived = false,
  this.playProgress,
  this.isCurrentlyPlaying = false,
})
```

#### Properties
```dart
final Map<String, dynamic> episode
final VoidCallback? onPlay
final VoidCallback? onLongPress
final bool showTranscriptIcon
final bool showArchived
final double? playProgress
final bool isCurrentlyPlaying
```

### EpisodeDetailModal

Modal for displaying detailed episode information.

#### Constructor
```dart
EpisodeDetailModal({
  super.key,
  required this.episode,
  required this.episodes,
  required this.episodeIndex,
})
```

#### Properties
```dart
final Map<String, dynamic> episode
final List<Map<String, dynamic>> episodes
final int episodeIndex
```

### FloatingMiniPlayerOverlay

Persistent mini-player overlay.

#### Constructor
```dart
FloatingMiniPlayerOverlay({
  super.key,
  this.child,
})
```

### EnhancedLoadingWidget

Enhanced loading indicator with multiple animation types.

#### Constructor
```dart
EnhancedLoadingWidget({
  super.key,
  this.message,
  this.type = LoadingType.spinner,
  this.color,
  this.size = 60.0,
  this.showMessage = true,
  this.onRetry,
})
```

#### Properties
```dart
final String? message
final LoadingType type
final Color? color
final double size
final bool showMessage
final VoidCallback? onRetry
```

#### Loading Types
```dart
enum LoadingType {
  spinner,
  dots,
  bars,
  circle,
  ripple,
  pulse,
  wave,
  heartbeat,
}
```

### EnhancedAccessibilityWidget

Widget with comprehensive accessibility support.

#### Constructor
```dart
EnhancedAccessibilityWidget({
  super.key,
  required this.child,
  this.label,
  this.hint,
  this.value,
  this.isButton = false,
  this.isHeader = false,
  this.isImage = false,
  this.isTextField = false,
  this.isSlider = false,
  this.isCheckbox = false,
  this.isRadioButton = false,
  this.isSwitch = false,
  this.isTab = false,
  this.isSelected = false,
  this.isEnabled = true,
  this.isRequired = false,
  this.onTap,
  this.onLongPress,
  this.onDoubleTap,
  this.onValueChanged,
  this.onCheckedChanged,
  this.onSliderChanged,
  this.maxValueLength,
  this.minValue,
  this.maxValue,
  this.currentValue,
  this.actions,
  this.customProperties,
})
```

## Utilities

### MiniPlayerPositioning

Utility for managing mini-player positioning.

#### Static Methods
```dart
// Position setting
static void setAboveNavPosition()
static void setBelowNavPosition()
static void setNoNavPosition()
static void resetToAutoDetect()

// Spacing calculations
static double get bottomPaddingForScrollables
static double get spacing
static double get miniPlayerVisualHeight

// Debug
static void debugCurrentPosition()
```

### AppTheme

App-wide theme configuration.

#### Properties
```dart
static ThemeData get lightTheme
static ThemeData get darkTheme
static ThemeData getTheme(bool isDarkMode)
```

### AppRoutes

App navigation routes.

#### Constants
```dart
static const String home = '/home'
static const String podcastDetail = '/podcast-detail'
static const String podcastPlayer = '/podcast-player'
static const String library = '/library'
static const String profile = '/profile'
static const String progressTracking = '/progress-tracking'
```

## Error Handling

### Error Categories
```dart
enum ErrorCategory {
  network,
  database,
  validation,
  permission,
  system,
  unknown,
}
```

### Error Handling Patterns
```dart
// Try-catch with user feedback
try {
  await someOperation();
} catch (e) {
  EnhancedErrorHandler().handleError(e);
}

// Error categorization
if (e is NetworkException) {
  // Handle network errors
} else if (e is DatabaseException) {
  // Handle database errors
} else {
  // Handle unknown errors
}
```

## Performance Patterns

### Lazy Loading
```dart
// Lazy load data
FutureBuilder<List<Episode>>(
  future: _loadEpisodes(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    return ListView.builder(
      itemCount: snapshot.data?.length ?? 0,
      itemBuilder: (context, index) => EpisodeListItem(
        episode: snapshot.data![index],
      ),
    );
  },
)
```

### Caching
```dart
// Cache expensive operations
final cachedData = await MemoryManagementService().getCachedData('key');
if (cachedData != null) {
  return cachedData;
}

final data = await expensiveOperation();
await MemoryManagementService().cacheData('key', data);
return data;
```

### Performance Monitoring
```dart
// Monitor operation performance
final result = await PerformanceMonitorService().monitorOperation(
  'loadEpisodes',
  () => _loadEpisodes(),
);
```

## Testing Patterns

### Demo Widgets
```dart
// Create demo data
final List<Map<String, dynamic>> _demoEpisodes = [
  {
    'id': '1',
    'title': 'Demo Episode 1',
    'duration': '30:00',
    'playProgress': 0.5,
    'isCurrentlyPlaying': false,
  },
  // ... more demo episodes
];

// Use in demo widgets
Phase9Demo()
EnhancedEpisodeDemo()
PerformanceDashboard()
AnalyticsDashboard()
```

### Mock Services
```dart
// Mock service for testing
class MockEpisodeProgressService extends EpisodeProgressService {
  @override
  Future<List<EpisodeBookmark>> getBookmarks(String episodeId) async {
    return [
      EpisodeBookmark(
        episodeId: episodeId,
        podcastId: 'mock_podcast',
        position: 300,
        title: 'Mock Bookmark',
        notes: 'Mock notes',
      ),
    ];
  }
}
```

## Best Practices

### State Management
- Use Provider pattern for state management
- Keep providers focused on specific concerns
- Use ChangeNotifier for reactive state updates
- Dispose of controllers and listeners properly

### Error Handling
- Always wrap async operations in try-catch blocks
- Provide user-friendly error messages
- Log errors for debugging
- Implement retry mechanisms for transient failures

### Performance
- Use lazy loading for large lists
- Implement efficient caching strategies
- Monitor performance metrics
- Optimize animations and transitions

### Accessibility
- Provide semantic labels for all interactive elements
- Support screen readers with proper descriptions
- Implement keyboard navigation
- Use appropriate contrast ratios

### Testing
- Create comprehensive demo widgets
- Test error scenarios
- Verify accessibility features
- Monitor performance metrics

