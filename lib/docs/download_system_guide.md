# Download and Offline System

## Overview

This system provides comprehensive download and offline playback capabilities for podcast episodes.

## Core Components

### 1. DownloadService
- Handles file downloads using Dio
- Tracks progress and status
- Manages local storage
- Integrates with backend API

### 2. OfflinePlayerService  
- Manages offline episode playback
- Uses audioplayers package
- Provides offline detection
- Handles local file playback

### 3. DownloadManager
- Coordinates between services
- Provides unified interface
- Handles offline vs online playback
- Manages podcast/episode validation

### 4. UI Components
- DownloadProgressWidget: Shows download progress
- OfflineModeIndicator: Shows offline mode status

## Usage

### Download Episode
```dart
final downloadManager = DownloadManager();
await downloadManager.downloadEpisodeWithValidation(
  episodeId: 'episode_123',
  episodeTitle: 'Episode Title', 
  audioUrl: 'https://example.com/episode.mp3',
  context: context,
);
```

### Play with Offline Detection
```dart
await downloadManager.playEpisodeWithOfflineDetection(
  episodeId: 'episode_123',
  episodeTitle: 'Episode Title',
  audioUrl: 'https://example.com/episode.mp3', 
  context: context,
);
```

### Check Status
```dart
final info = await downloadManager.getEpisodePlaybackInfo('episode_123');
print('Is offline: ${info['isOffline']}');
```

## Features

- ✅ Download episodes with progress tracking
- ✅ Offline playback detection
- ✅ Local file storage management
- ✅ Backend synchronization
- ✅ Download cancellation
- ✅ Error handling and retry
- ✅ UI progress indicators
- ✅ Offline mode indicators

## File Structure

```
app_documents/downloads/
├── episode_123.mp3
├── episode_456.mp3
└── episode_789.mp3
```

## Permissions Required

- Storage permission for downloads
- Internet permission for downloading

## Backend Integration

Uses existing download API endpoints:
- POST /library/downloads
- DELETE /library/downloads/{episodeId}
- GET /library/downloads 