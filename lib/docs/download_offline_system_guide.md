# Download and Offline System Guide

## Overview

This system provides comprehensive download and offline playback capabilities for podcast episodes. It includes:

- **Download Service**: Handles file downloads with progress tracking
- **Offline Player Service**: Manages offline playback
- **Download Manager**: Coordinates between services
- **UI Components**: Download progress widgets and offline indicators

## Architecture

### Core Services

#### 1. DownloadService (`download_service.dart`)
- Handles actual file downloads using Dio
- Tracks download progress and status
- Manages local file storage
- Integrates with backend API

**Key Features:**
- Progress tracking with real-time updates
- Download cancellation support
- Local file management
- Backend synchronization

#### 2. OfflinePlayerService (`offline_player_service.dart`)
- Manages offline episode playback
- Uses audioplayers package for compatibility
- Provides offline detection capabilities
- Handles local file playback

**Key Features:**
- Offline episode detection
- Local file playback
- Player state management
- Audio controls (play, pause, seek)

#### 3. DownloadManager (`download_manager.dart`)
- Coordinates between all services
- Provides unified interface for downloads and playback
- Handles podcast/episode validation
- Manages offline vs online playback decisions

**Key Features:**
- Unified download and playback interface
- Automatic offline detection
- Podcast/episode validation
- Error handling and retry logic

### UI Components

#### 1. DownloadProgressWidget (`download_progress_widget.dart`)
- Shows download progress and controls
- Displays download status (pending, downloading, completed, failed)
- Provides cancel and delete options
- Real-time progress updates

#### 2. OfflineModeIndicator (`offline_mode_indicator.dart`)
- Indicates when playing in offline mode
- Shows episode title in offline mode
- Compact version for player controls

## Usage Examples

### Downloading an Episode

```dart
final downloadManager = DownloadManager();

await downloadManager.downloadEpisodeWithValidation(
  episodeId: 'episode_123',
  episodeTitle: 'Episode Title',
  audioUrl: 'https://example.com/episode.mp3',
  context: context,
  onDownloadComplete: () {
    print('Download completed!');
  },
  onDownloadError: () {
    print('Download failed!');
  },
);
```

### Playing with Offline Detection

```dart
await downloadManager.playEpisodeWithOfflineDetection(
  episodeId: 'episode_123',
  episodeTitle: 'Episode Title',
  audioUrl: 'https://example.com/episode.mp3',
  context: context,
);
```

### Checking Download Status

```dart
final playbackInfo = await downloadManager.getEpisodePlaybackInfo('episode_123');
print('Is offline: ${playbackInfo['isOffline']}');
print('Is downloading: ${playbackInfo['isDownloading']}');
print('Download progress: ${playbackInfo['downloadProgress']}');
```

### Using Download Progress Widget

```dart
DownloadProgressWidget(
  episodeId: 'episode_123',
  episodeTitle: 'Episode Title',
  audioUrl: 'https://example.com/episode.mp3',
  onDownloadComplete: () {
    print('Download completed!');
  },
  onDownloadError: () {
    print('Download failed!');
  },
)
```

### Using Offline Mode Indicator

```dart
OfflineModeIndicator(
  isOffline: true,
  episodeTitle: 'Episode Title',
)
```

## Backend Integration

### Download API Endpoints

The system integrates with the following backend endpoints:

- `POST /library/downloads` - Add download
- `DELETE /library/downloads/{episodeId}` - Remove download
- `GET /library/downloads` - Get downloads list
- `POST /library/downloads/batch-destroy` - Batch remove downloads
- `DELETE /library/downloads/clear-all` - Clear all downloads

### Database Schema

The backend uses a `downloads` table with the following structure:

```sql
CREATE TABLE downloads (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  episode_id VARCHAR(255) NOT NULL,
  file_path VARCHAR(500),
  file_name VARCHAR(255),
  file_size BIGINT,
  downloaded_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

## File Storage

### Local Storage Structure

```
app_documents/
└── downloads/
    ├── episode_123.mp3
    ├── episode_456.mp3
    └── episode_789.mp3
```

### File Naming Convention

- Files are named using the episode ID: `{episodeId}.mp3`
- This ensures unique file names and easy lookup

## Permissions

The system requires the following permissions:

- **Storage Permission**: For saving downloaded files
- **Internet Permission**: For downloading files (already included)

## Error Handling

### Download Errors

- Network connectivity issues
- Storage permission denied
- File system errors
- Backend API errors

### Offline Playback Errors

- File not found
- Corrupted files
- Audio format issues

### Recovery Strategies

- Automatic retry for network errors
- Graceful fallback to online playback
- User notification for all errors
- Cleanup of failed downloads

## Performance Considerations

### Download Management

- Concurrent downloads are limited to prevent overwhelming the device
- Downloads are queued and managed efficiently
- Progress updates are throttled to prevent UI lag

### Storage Management

- Downloaded files are stored in app-specific directory
- File sizes are tracked and reported
- Users can delete individual downloads or clear all

### Memory Management

- Audio players are properly disposed
- Stream controllers are cleaned up
- Resources are released when not in use

## Security Considerations

### File Security

- Downloaded files are stored in app-specific directory
- Files are not accessible to other apps
- No sensitive data is stored in file names

### API Security

- All API calls require authentication
- Episode IDs are validated before download
- File paths are sanitized

## Testing

### Unit Tests

- Download service functionality
- Offline player operations
- File management operations
- Error handling scenarios

### Integration Tests

- End-to-end download flow
- Offline playback scenarios
- Backend API integration
- UI component behavior

### Manual Testing

- Download progress tracking
- Offline mode detection
- File cleanup operations
- Error recovery scenarios

## Future Enhancements

### Planned Features

1. **Background Downloads**: Download episodes while app is in background
2. **Download Queue**: Manage multiple downloads with priority
3. **Storage Management**: Automatic cleanup of old downloads
4. **Download Scheduling**: Schedule downloads for specific times
5. **Quality Selection**: Choose download quality (if available)

### Performance Improvements

1. **Chunked Downloads**: Download large files in chunks
2. **Resume Downloads**: Resume interrupted downloads
3. **Compression**: Compress downloaded files to save space
4. **Caching**: Cache frequently accessed episodes

## Troubleshooting

### Common Issues

1. **Download Fails**
   - Check internet connectivity
   - Verify storage permissions
   - Check available storage space

2. **Offline Playback Fails**
   - Verify file exists in downloads directory
   - Check file integrity
   - Ensure audio format is supported

3. **Progress Not Updating**
   - Check if download is still active
   - Verify UI is properly connected to streams
   - Check for memory issues

### Debug Information

The system provides comprehensive debug logging:

```dart
debugPrint('Download started: $episodeId');
debugPrint('Download progress: ${progress * 100}%');
debugPrint('Download completed: $episodeId');
debugPrint('Offline playback started: $episodeId');
```

## Conclusion

This download and offline system provides a comprehensive solution for podcast episode downloads and offline playback. It integrates seamlessly with the existing audio player infrastructure while providing users with the ability to enjoy their favorite podcasts without an internet connection.

The system is designed to be robust, user-friendly, and maintainable, with proper error handling, progress tracking, and resource management. 