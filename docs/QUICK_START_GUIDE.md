# Podcast App Quick Start Guide

## Getting Started

This guide will help you quickly understand the podcast app architecture and start developing with it.

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Git

## Project Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd pelevo/frontend
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

## Project Structure Overview

```
frontend/lib/
├── core/                    # Core utilities and configurations
│   ├── app_export.dart     # Main app exports
│   ├── routes/             # App routing
│   └── theme/              # App theming
├── data/                   # Data layer
│   └── models/             # Data models
├── models/                 # Domain models
├── presentation/           # UI screens
├── providers/              # State management
├── services/               # Business logic
├── widgets/                # Reusable components
└── docs/                   # Documentation
```

## Key Concepts

### 1. Phase-Based Development
The app is developed in phases, each building upon the previous:

- **Phases 1-5**: Core functionality (episodes, playback, progress, bookmarks)
- **Phase 6**: Performance and reliability
- **Phase 7**: Cross-device synchronization
- **Phase 8**: Analytics and insights
- **Phase 9**: Enhanced UX and accessibility

### 2. State Management
Uses Provider pattern with dedicated providers for different concerns:

```dart
// Example: Using PodcastPlayerProvider
Consumer<PodcastPlayerProvider>(
  builder: (context, playerProvider, child) {
    return Text('Current: ${playerProvider.currentEpisode?.title}');
  },
)
```

### 3. Service Architecture
Services handle business logic and data operations:

```dart
// Example: Using EpisodeProgressService
final progressService = EpisodeProgressService();
await progressService.initialize();
final progress = await progressService.getProgress(episodeId);
```

## Common Development Tasks

### 1. Adding a New Episode Feature

#### Step 1: Create the Model
```dart
// models/episode_feature.dart
class EpisodeFeature {
  final String id;
  final String name;
  final String description;
  
  const EpisodeFeature({
    required this.id,
    required this.name,
    required this.description,
  });
  
  factory EpisodeFeature.fromJson(Map<String, dynamic> json) {
    return EpisodeFeature(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
```

#### Step 2: Create the Service
```dart
// services/episode_feature_service.dart
class EpisodeFeatureService {
  Future<List<EpisodeFeature>> getFeatures(String episodeId) async {
    // Implementation
  }
  
  Future<void> addFeature(EpisodeFeature feature) async {
    // Implementation
  }
}
```

#### Step 3: Create the Widget
```dart
// widgets/episode_feature_widget.dart
class EpisodeFeatureWidget extends StatelessWidget {
  final EpisodeFeature feature;
  
  const EpisodeFeatureWidget({
    super.key,
    required this.feature,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(feature.name),
        subtitle: Text(feature.description),
      ),
    );
  }
}
```

### 2. Adding a New Screen

#### Step 1: Create the Screen
```dart
// presentation/feature_screen/feature_screen.dart
class FeatureScreen extends StatefulWidget {
  const FeatureScreen({super.key});
  
  @override
  State<FeatureScreen> createState() => _FeatureScreenState();
}

class _FeatureScreenState extends State<FeatureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature')),
      body: const Center(child: Text('Feature Content')),
    );
  }
}
```

#### Step 2: Add the Route
```dart
// core/routes/app_routes.dart
class AppRoutes {
  static const String feature = '/feature';
  // ... other routes
}
```

#### Step 3: Register the Route
```dart
// main.dart or route configuration
MaterialApp(
  routes: {
    AppRoutes.feature: (context) => const FeatureScreen(),
    // ... other routes
  },
)
```

### 3. Adding a New Service

#### Step 1: Create the Service Class
```dart
// services/new_service.dart
class NewService {
  static final NewService _instance = NewService._internal();
  factory NewService() => _instance;
  NewService._internal();
  
  Future<void> initialize() async {
    // Initialization logic
  }
  
  Future<void> performOperation() async {
    // Operation logic
  }
}
```

#### Step 2: Use the Service
```dart
// In your widget or other service
final newService = NewService();
await newService.initialize();
await newService.performOperation();
```

## Working with Existing Features

### 1. Episode Progress Tracking

The app automatically tracks episode playback progress. To use this feature:

```dart
// Get progress for an episode
final progress = await progressService.getProgress(episodeId);

// Update progress
await progressService.saveProgress(
  episodeId: episodeId,
  currentPosition: currentPosition,
  totalDuration: totalDuration,
);
```

### 2. Bookmark System

Create and manage episode bookmarks:

```dart
// Add a bookmark
await progressService.addBookmark(
  episodeId: episodeId,
  podcastId: podcastId,
  position: position,
  title: 'Important Point',
  notes: 'Remember this concept',
);

// Get bookmarks for an episode
final bookmarks = await progressService.getBookmarks(episodeId);
```

### 3. Auto-play Functionality

The app supports automatic episode continuation:

```dart
// Enable auto-play
playerProvider.setAutoPlayNextEpisode(true);

// Set episode queue
playerProvider.setEpisodeQueue(episodes, startIndex: 0);
```

## Performance Best Practices

### 1. Use Lazy Loading
```dart
FutureBuilder<List<Episode>>(
  future: _loadEpisodes(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
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

### 2. Monitor Performance
```dart
// Monitor operation performance
final result = await PerformanceMonitorService().monitorOperation(
  'operationName',
  () => expensiveOperation(),
);
```

### 3. Use Caching
```dart
// Cache expensive data
final cachedData = await MemoryManagementService().getCachedData('key');
if (cachedData != null) {
  return cachedData;
}

final data = await expensiveOperation();
await MemoryManagementService().cacheData('key', data);
return data;
```

## Error Handling

### 1. Use Enhanced Error Handler
```dart
try {
  await someOperation();
} catch (e) {
  EnhancedErrorHandler().handleError(e);
}
```

### 2. Provide User Feedback
```dart
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Operation completed successfully'),
      backgroundColor: Colors.green,
    ),
  );
}
```

## Testing and Debugging

### 1. Use Demo Widgets
The app includes comprehensive demo widgets for testing:

```dart
// Test Phase 9 features
Phase9Demo()

// Test episode features
EnhancedEpisodeDemo()

// Monitor performance
PerformanceDashboard()

// View analytics
AnalyticsDashboard()
```

### 2. Debug Mode Features
In debug mode, you can access additional debugging features:

```dart
if (kDebugMode) {
  print('Debug information');
  // Additional debug features
}
```

### 3. Performance Monitoring
Monitor app performance in real-time:

```dart
// Get performance statistics
final stats = PerformanceMonitorService().getPerformanceStats();
print('Performance stats: $stats');

// Get performance warnings
final warnings = PerformanceMonitorService().getPerformanceWarnings();
for (final warning in warnings) {
  print('Warning: $warning');
}
```

## Common Issues and Solutions

### 1. Provider Not Found
```dart
// Error: ProviderNotFoundException
// Solution: Ensure the provider is properly registered in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PodcastPlayerProvider()),
    ChangeNotifierProvider(create: (_) => ThemeService()),
    // ... other providers
  ],
  child: MyApp(),
)
```

### 2. Mini-Player Positioning Issues
```dart
// Use MiniPlayerPositioning utility
MiniPlayerPositioning.setAboveNavPosition();
MiniPlayerPositioning.setBelowNavPosition();
MiniPlayerPositioning.setNoNavPosition();
```

### 3. Progress Sync Issues
```dart
// Ensure service is initialized
await progressService.initialize();

// Check network status
if (await progressService.isOnline) {
  await progressService.syncProgress();
}
```

## Contributing Guidelines

### 1. Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### 2. Testing
- Test new features thoroughly
- Use existing demo widgets as templates
- Verify accessibility features
- Monitor performance impact

### 3. Documentation
- Update relevant documentation
- Add code comments for complex logic
- Document new API endpoints
- Update this guide as needed

## Next Steps

1. **Explore the Codebase**: Familiarize yourself with the existing structure
2. **Run the App**: Test all features and understand the user experience
3. **Study the Services**: Understand how business logic is implemented
4. **Review the Widgets**: See how UI components are built
5. **Check the Documentation**: Read the comprehensive implementation documentation

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Provider Package](https://pub.dev/packages/provider)
- [Material Design Guidelines](https://material.io/design)

## Support

If you encounter issues or have questions:

1. Check the existing documentation
2. Review the demo widgets for examples
3. Check the issue tracker
4. Ask questions in the development team

Happy coding! 🚀

