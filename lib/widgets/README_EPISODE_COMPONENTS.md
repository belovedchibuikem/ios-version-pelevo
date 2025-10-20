# Episode Components Documentation

This document describes the new episode components that have been redesigned to match the modern podcast app design shown in the reference image.

## Components Overview

### 1. EpisodeListItem
A clean, minimalist episode display component that can be used anywhere in the app where episodes are listed.

**Features:**
- Clean, modern design matching the reference image
- Episode title with proper text overflow handling
- Duration display with transcript icon support
- Circular play button with border
- Consistent spacing and typography
- Reusable across different screens

**Usage:**
```dart
EpisodeListItem(
  episode: episodeData,
  onPlay: () => playEpisode(episodeData),
  showTranscriptIcon: true, // Shows transcript icon if episode has transcript
  showArchived: false, // For archived episodes styling
)
```

**Required episode data structure:**
```dart
{
  'title': 'Episode Title',
  'duration': 1620, // Duration in seconds or formatted string
  'hasTranscript': true, // Boolean for transcript availability
}
```

### 2. EnhancedSearchBar
An improved search bar with modern design and additional functionality.

**Features:**
- Search icon on the left
- Placeholder text
- Three-dot menu on the right for additional options
- Clear button when text is present
- Customizable options menu
- Consistent with app theme

**Usage:**
```dart
EnhancedSearchBar(
  hintText: 'Search episodes',
  onChanged: (query) => handleSearch(query),
  onMoreOptionsTap: () => showMoreOptions(),
  showClearButton: true, // Default: true
)
```

### 3. RedesignedEpisodesTabWidget
A complete episodes tab that implements the new design with date grouping.

**Features:**
- Enhanced search bar integration
- Episode count summary with archived toggle
- Date-based episode grouping (Today, Yesterday, August 13, etc.)
- Uses EpisodeListItem for consistent episode display
- Search functionality with real-time filtering
- More options menu for bulk actions

**Usage:**
```dart
RedesignedEpisodesTabWidget(
  episodes: episodeList,
  onPlayEpisode: (episode) => playEpisode(episode),
  onDownloadEpisode: (episode) => downloadEpisode(episode),
  onShareEpisode: (episode) => shareEpisode(episode),
  totalEpisodes: 1857,
  archivedEpisodes: 0,
  showArchived: false,
  onShowArchivedToggle: () => toggleArchived(),
)
```

## Date Grouping Utilities

### DateGroupingUtils
Utility class for grouping episodes by date and creating sorted headers.

**Features:**
- Groups episodes by Today, Yesterday, or specific dates
- Sorts episodes within each group (newest first)
- Handles various date formats
- Returns sorted headers for proper display order

**Usage:**
```dart
// Group episodes by date
final groupedEpisodes = DateGroupingUtils.groupEpisodesByDate(episodes);

// Get sorted headers (Today, Yesterday, August 13, etc.)
final sortedHeaders = DateGroupingUtils.getSortedDateHeaders(groupedEpisodes);
```

## Implementation Examples

### In Podcast Detail Screen
The main podcast detail screen now uses `RedesignedEpisodesTabWidget` instead of the old episodes tab.

### In Library Screen
```dart
class LibraryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          EnhancedSearchBar(
            hintText: 'Search library',
            onChanged: (query) => searchLibrary(query),
            onMoreOptionsTap: () => showLibraryOptions(),
          ),
          Expanded(
            child: LibraryEpisodeList(
              episodes: libraryEpisodes,
              onPlayEpisode: (episode) => playEpisode(episode),
            ),
          ),
        ],
      ),
    );
  }
}
```

### In Search Results
```dart
class SearchResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SearchResultsEpisodeList(
      searchResults: searchResults,
      onPlayEpisode: (episode) => playEpisode(episode),
    );
  }
}
```

## Styling and Theme

All components use the app's theme system (`AppTheme.lightTheme`) for consistent:
- Colors
- Typography
- Spacing
- Shadows and borders

## Customization

### EpisodeListItem Customization
- `showTranscriptIcon`: Control transcript icon display
- `showArchived`: Different styling for archived episodes
- `onLongPress`: Custom long press behavior

### EnhancedSearchBar Customization
- `onMoreOptionsTap`: Custom options menu
- `showClearButton`: Control clear button visibility
- `controller`: Custom text controller

### RedesignedEpisodesTabWidget Customization
- `onShowArchivedToggle`: Custom archived episodes handling
- Episode count display
- Search and filtering options

## Migration Guide

### From Old EpisodeCardWidget
1. Replace `EpisodeCardWidget` with `EpisodeListItem`
2. Update data structure to include required fields
3. Remove old styling and layout code
4. Use new date grouping for better organization

### From Old EpisodesTabWidget
1. Replace `EpisodesTabWidget` with `RedesignedEpisodesTabWidget`
2. Update method calls to match new interface
3. Add episode count and archived episodes data
4. Implement archived episodes toggle if needed

## Benefits

1. **Consistency**: All episode displays now use the same component
2. **Maintainability**: Single source of truth for episode display logic
3. **Modern Design**: Matches current podcast app design standards
4. **Reusability**: Components can be used across different screens
5. **Better UX**: Date grouping and improved search functionality
6. **Accessibility**: Better text contrast and touch targets

## Future Enhancements

- [ ] Add episode progress indicators
- [ ] Support for episode thumbnails
- [ ] Enhanced filtering options
- [ ] Bulk download functionality
- [ ] Episode playlists support
- [ ] Offline episode management
