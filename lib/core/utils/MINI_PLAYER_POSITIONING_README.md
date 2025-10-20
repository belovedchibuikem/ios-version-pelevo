# Mini-Player Positioning System

## Overview

The mini-player positioning system ensures consistent positioning across different screens with varying bottom navigation bar heights. This solves the issue where the mini-player appears at different positions on different screens.

## Problem Solved

- **Home screen**: Bottom navigation bar height = 56px
- **Library screen**: Bottom navigation bar height = 80px (example)
- **Other screens**: Different heights
- **Result**: Mini-player appears at different positions, creating inconsistent UI

## Solution

The system provides **adaptive positioning** that automatically detects whether a screen has a bottom navigation bar:

- **Screens WITH bottom navigation** → Mini-player positioned above the navbar with 4px spacing
- **Screens WITHOUT bottom navigation** → Mini-player positioned at the bottom edge of the screen

This ensures optimal positioning regardless of screen layout while maintaining consistent user experience.

## Usage

### 1. Basic Usage (Direct API)

```dart
import '../../widgets/floating_mini_player_overlay.dart';

// Set custom height for current screen
FloatingMiniPlayerOverlay.setBottomNavHeight(80.0);

// Reset to default (auto-detect)
FloatingMiniPlayerOverlay.resetBottomNavHeight();

// Get current height
double height = FloatingMiniPlayerOverlay.getCurrentBottomNavHeight();
```

### 2. Recommended Usage (Utility Class)

```dart
import '../../core/utils/mini_player_positioning.dart';

// Set positioning for specific screen types
MiniPlayerPositioning.setHomeScreenPosition();      // 56px + 4px spacing
MiniPlayerPositioning.setLibraryScreenPosition();   // 80px + 4px spacing
MiniPlayerPositioning.setSearchScreenPosition();    // 70px + 4px spacing
MiniPlayerPositioning.setProfileScreenPosition();   // 65px + 4px spacing

// Custom positioning
MiniPlayerPositioning.setCustomPosition(75.0);      // 75px + 4px spacing

// Force specific positioning
MiniPlayerPositioning.setBottomEdgePosition();      // Bottom edge (no nav bar)
MiniPlayerPositioning.setAboveNavPosition();        // Above navigation bar

// Reset to default
MiniPlayerPositioning.resetToDefault();

// Debug current position
MiniPlayerPositioning.debugCurrentPosition();
```

## Implementation in Screens

### Home Screen
```dart
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Set mini-player positioning for home screen
    MiniPlayerPositioning.setHomeScreenPosition();
  }
  
  // ... rest of the screen implementation
}
```

### Library Screen
```dart
class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Set mini-player positioning for library screen
    MiniPlayerPositioning.setLibraryScreenPosition();
  }
  
  // ... rest of the screen implementation
}
```

### Custom Screen
```dart
class CustomScreen extends StatefulWidget {
  @override
  _CustomScreenState createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen> {
  @override
  void initState() {
    super.initState();
    // Set custom mini-player positioning
    MiniPlayerPositioning.setCustomPosition(90.0); // 90px nav height
  }
  
  // ... rest of the screen implementation
}
```

### Screen Without Navigation Bar
```dart
class FullScreenContent extends StatefulWidget {
  @override
  _FullScreenContentState createState() => _FullScreenContentState();
}

class _FullScreenContentState extends State<FullScreenContent> {
  @override
  void initState() {
    super.initState();
    // Force mini-player to bottom edge (no navigation bar)
    MiniPlayerPositioning.setBottomEdgePosition();
  }
  
  // ... rest of the screen implementation
}
```

### Screen With Navigation Bar
```dart
class NavigationScreen extends StatefulWidget {
  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Force mini-player above navigation bar
    MiniPlayerPositioning.setAboveNavPosition();
  }
  
  // ... rest of the screen implementation
}
```

## How It Works

### Automatic Detection (Default)
1. **Smart Detection**: System automatically detects if screen has bottom navigation bar
2. **Adaptive Positioning**: 
   - **With nav bar** → Position above navigation with 4px spacing
   - **Without nav bar** → Position at bottom edge of screen
3. **Fallback Logic**: Uses MediaQuery bottom padding to determine navigation presence

### Manual Override
1. **Custom Heights**: Set specific navigation bar heights for precise control
2. **Force Positioning**: Override automatic detection for specific screen layouts
3. **Consistent Spacing**: 4px spacing automatically applied for visual separation

### Priority System
1. **Manual Override** (highest priority) - Use custom methods
2. **Custom Height** - Use `setBottomNavHeight()`
3. **Automatic Detection** (lowest priority) - Fallback to smart detection

## Benefits

- ✅ **Consistent UI**: Mini-player appears at the same relative position on all screens
- ✅ **Easy Maintenance**: Set heights once per screen, no need to modify the mini-player widget
- ✅ **Flexible**: Support for any custom navigation bar height
- ✅ **Debugging**: Built-in debug methods to troubleshoot positioning issues
- ✅ **Performance**: No complex calculations, just simple height values

## Troubleshooting

### Mini-player appears too high/low
- Check the height value being set for the current screen
- Verify the actual bottom navigation bar height on the device
- Use `MiniPlayerPositioning.debugCurrentPosition()` to see current settings

### Mini-player position changes unexpectedly
- Ensure positioning is set in `initState()` of each screen
- Check if `resetToDefault()` is being called somewhere
- Verify the mini-player is being shown after positioning is set

### Positioning not working
- Make sure the positioning method is called before showing the mini-player
- Check that the import path is correct
- Verify the method is being called in the correct screen's `initState()`

## Example Values

| Screen Type | Nav Height | Total Height (with spacing) |
|-------------|------------|------------------------------|
| Home        | 56px       | 60px                         |
| Library     | 80px       | 84px                         |
| Search      | 70px       | 74px                         |
| Profile     | 65px       | 69px                         |
| Custom      | 90px       | 94px                         |

## Migration Guide

### From Fixed Positioning
1. Import the positioning utility
2. Add positioning call in `initState()` of each screen
3. Remove any hardcoded positioning values
4. Test on different screens to verify consistency

### From Auto-Detection Only
1. Import the positioning utility
2. Add positioning call in `initState()` of each screen
3. Keep auto-detection as fallback
4. Test positioning consistency across screens
