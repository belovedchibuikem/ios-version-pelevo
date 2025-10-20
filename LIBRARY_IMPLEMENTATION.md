# Library Implementation Documentation

This document outlines the complete implementation of the Library tab functionality for the Pelevo podcast app, including downloads, subscriptions, play history, and playlists.

## Backend Implementation

### Database Schema

The following migrations were created to support the library functionality:

1. **Downloads Table** (`create_downloads_table.php`)
   - `id`, `user_id`, `episode_id`, `file_path`, `file_name`, `file_size`, `downloaded_at`, `created_at`, `updated_at`

2. **Subscriptions Table** (`create_subscriptions_table.php`)
   - `id`, `user_id`, `podcast_id`, `subscribed_at`, `unsubscribed_at`, `is_active`, `created_at`, `updated_at`

3. **Play History Table** (`create_play_history_table.php`)
   - `id`, `user_id`, `episode_id`, `progress_seconds`, `status`, `last_played_at`, `created_at`, `updated_at`

4. **Playlists Table** (`create_playlists_table.php`)
   - `id`, `user_id`, `name`, `description`, `order`, `created_at`, `updated_at`

5. **Playlist Items Table** (`create_playlist_items_table.php`)
   - `id`, `playlist_id`, `episode_id`, `order`, `added_at`, `created_at`, `updated_at`

### Models

All models include proper relationships and are located in `backend/app/Models/`:

- `Download.php` - Manages downloaded episodes
- `Subscription.php` - Manages podcast subscriptions
- `PlayHistory.php` - Tracks listening history
- `Playlist.php` - Manages user playlists
- `PlaylistItem.php` - Manages playlist items

### API Controllers

RESTful API controllers with full CRUD operations:

- `DownloadsController.php` - `/api/library/downloads`
- `SubscriptionsController.php` - `/api/library/subscriptions`
- `PlayHistoryController.php` - `/api/library/play-history`
- `PlaylistsController.php` - `/api/library/playlists`
- `PlaylistItemsController.php` - `/api/library/playlist-items`

### API Endpoints

#### Downloads
- `GET /api/library/downloads` - Get user downloads
- `POST /api/library/downloads` - Add download
- `DELETE /api/library/downloads/{id}` - Remove download
- `POST /api/library/downloads/batch-destroy` - Batch remove downloads
- `DELETE /api/library/downloads/clear-all` - Clear all downloads

#### Subscriptions
- `GET /api/library/subscriptions` - Get user subscriptions
- `POST /api/library/subscriptions/subscribe` - Subscribe to podcast
- `POST /api/library/subscriptions/unsubscribe` - Unsubscribe from podcast
- `POST /api/library/subscriptions/batch-destroy` - Batch unsubscribe

#### Play History
- `GET /api/library/play-history` - Get play history
- `POST /api/library/play-history` - Update play history
- `GET /api/library/play-history/recent` - Get recent play history
- `DELETE /api/library/play-history/clear-all` - Clear all history
- `POST /api/library/play-history/batch-destroy` - Batch remove history

#### Playlists
- `GET /api/library/playlists` - Get user playlists
- `POST /api/library/playlists` - Create playlist
- `PUT /api/library/playlists/{id}` - Update playlist
- `DELETE /api/library/playlists/{id}` - Delete playlist
- `POST /api/library/playlists/{id}/add-episode` - Add episode to playlist
- `DELETE /api/library/playlists/{id}/remove-episode` - Remove episode from playlist
- `POST /api/library/playlists/{id}/reorder` - Reorder playlist items
- `POST /api/library/playlists/batch-destroy` - Batch delete playlists

#### Playlist Items
- `GET /api/library/playlist-items` - Get playlist items
- `POST /api/library/playlist-items/batch-destroy` - Batch remove items

## Frontend Implementation

### Models

Dart models for type-safe data handling:

- `download.dart` - Download model with Episode and Podcast relationships
- `subscription.dart` - Subscription model with Podcast relationship
- `play_history.dart` - PlayHistory model with Episode and Podcast relationships
- `playlist.dart` - Playlist and PlaylistItem models with Episode relationships

### API Service

`LibraryApiService` provides a comprehensive interface for all library operations:

```dart
class LibraryApiService {
  // Downloads
  Future<List<Download>> getDownloads({int page = 1});
  Future<Download> addDownload(Map<String, dynamic> downloadData);
  Future<void> removeDownload(int downloadId);
  Future<void> batchRemoveDownloads(List<int> downloadIds);
  Future<void> clearAllDownloads();

  // Subscriptions
  Future<List<Subscription>> getSubscriptions({int page = 1});
  Future<Subscription> subscribeToPodcast(int podcastId);
  Future<void> unsubscribeFromPodcast(int podcastId);
  Future<void> batchUnsubscribe(List<int> subscriptionIds);

  // Play History
  Future<List<PlayHistory>> getPlayHistory({int page = 1});
  Future<PlayHistory> updatePlayHistory(Map<String, dynamic> historyData);
  Future<List<PlayHistory>> getRecentPlayHistory();
  Future<void> clearAllPlayHistory();
  Future<void> batchRemovePlayHistory(List<int> historyIds);

  // Playlists
  Future<List<Playlist>> getPlaylists({int page = 1});
  Future<Playlist> createPlaylist(Map<String, dynamic> playlistData);
  Future<Playlist> updatePlaylist(int playlistId, Map<String, dynamic> playlistData);
  Future<void> deletePlaylist(int playlistId);
  Future<Playlist> addEpisodeToPlaylist(int playlistId, int episodeId);
  Future<void> removeEpisodeFromPlaylist(int playlistId, int episodeId);
  Future<Playlist> reorderPlaylist(int playlistId, List<Map<String, dynamic>> itemOrders);
  Future<void> batchDeletePlaylists(List<int> playlistIds);

  // Playlist Items
  Future<List<PlaylistItem>> getPlaylistItems(int playlistId, {int page = 1});
  Future<void> batchRemovePlaylistItems(List<int> itemIds);
}
```

### UI Components

#### Library Screen
- `LibraryScreen` - Main library screen with 4 tabs
- `TabContentWidget` - Displays content for each tab with real API integration

#### Playlist Management
- `PlaylistDetailScreen` - Detailed view of playlist with drag-and-drop reordering
- `AddToPlaylistWidget` - Modal for adding episodes to playlists

#### Tab Content Widget
Updated `TabContentWidget` supports:
- Real-time data loading from API
- Error handling and retry functionality
- Pull-to-refresh
- Proper state management
- Type-safe data handling

### Features Implemented

#### Downloads Tab
- View downloaded episodes
- Play downloaded episodes
- Delete individual downloads
- Batch delete downloads
- Clear all downloads
- File size display
- Download date tracking

#### Subscriptions Tab
- View subscribed podcasts
- Subscribe/unsubscribe toggle
- Podcast information display
- Episode count badges
- Batch unsubscribe functionality

#### History Tab
- View listening history
- Progress indicators
- Last played timestamps
- Play status display
- Clear all history
- Batch remove history entries

#### Playlists Tab
- View user playlists
- Create new playlists
- Edit playlist details
- Delete playlists
- Episode count display
- Creation date tracking

#### Playlist Detail Screen
- View playlist items
- Drag-and-drop reordering
- Add episodes to playlist
- Remove episodes from playlist
- Batch operations
- Edit playlist name and description

#### Add to Playlist Widget
- Create new playlists
- Add to existing playlists
- Modal bottom sheet interface
- Success callbacks
- Error handling

### Integration with Player

The podcast player now includes:
- "Add to Playlist" button in episode description
- Integration with `AddToPlaylistWidget`
- Real-time playlist status updates
- Success feedback

## Usage Examples

### Adding an Episode to Playlist
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => AddToPlaylistWidget(
    episodeId: episodeId,
    onSuccess: () {
      // Handle success
    },
  ),
);
```

### Loading Library Data
```dart
final apiService = LibraryApiService();
final downloads = await apiService.getDownloads();
final subscriptions = await apiService.getSubscriptions();
final playHistory = await apiService.getPlayHistory();
final playlists = await apiService.getPlaylists();
```

### Creating a Playlist
```dart
final newPlaylist = await apiService.createPlaylist({
  'name': 'My Favorites',
  'description': 'My favorite episodes',
});
```

### Reordering Playlist Items
```dart
final itemOrders = [
  {'playlist_item_id': 1, 'order': 1},
  {'playlist_item_id': 2, 'order': 2},
  {'playlist_item_id': 3, 'order': 3},
];
await apiService.reorderPlaylist(playlistId, itemOrders);
```

## Authentication

All API endpoints require authentication via Bearer token:
```dart
apiService.setToken('your-auth-token');
```

## Error Handling

Comprehensive error handling implemented:
- Network errors
- API errors
- Validation errors
- User-friendly error messages
- Retry functionality

## Performance Considerations

- Pagination support for large datasets
- Efficient data loading
- Optimistic UI updates
- Proper state management
- Memory-efficient list rendering

## Future Enhancements

Potential improvements:
- Offline support for downloaded content
- Sync across devices
- Advanced playlist features (smart playlists)
- Social features (share playlists)
- Analytics and insights
- Bulk operations UI
- Search and filtering
- Export/import functionality 