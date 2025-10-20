import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'download_service.dart';

/// Service for handling offline episode playback
class OfflinePlayerService {
  static final OfflinePlayerService _instance =
      OfflinePlayerService._internal();
  factory OfflinePlayerService() => _instance;
  OfflinePlayerService._internal();

  final DownloadService _downloadService = DownloadService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Internal state tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;

  /// Check if episode is available offline
  Future<bool> isEpisodeAvailableOffline(String episodeId) async {
    return await _downloadService.isEpisodeDownloaded(episodeId);
  }

  /// Get offline episode file path
  Future<String?> getOfflineEpisodePath(String episodeId) async {
    return await _downloadService.getDownloadedFilePath(episodeId);
  }

  /// Play episode from offline storage
  Future<void> playOfflineEpisode({
    required String episodeId,
    required String episodeTitle,
    required BuildContext context,
  }) async {
    try {
      final filePath = await getOfflineEpisodePath(episodeId);
      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Episode not found in offline storage'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offline file not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Load and play the offline file
      await _audioPlayer.setSource(DeviceFileSource(filePath));
      await _audioPlayer.resume();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing offline: $episodeTitle'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error playing offline episode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing offline episode: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Check if current episode is playing in offline mode
  Future<bool> isPlayingOffline(String episodeId) async {
    return await isEpisodeAvailableOffline(episodeId);
  }

  /// Get offline playback info
  Future<Map<String, dynamic>> getOfflinePlaybackInfo(String episodeId) async {
    final isOffline = await isEpisodeAvailableOffline(episodeId);
    final filePath = await getOfflineEpisodePath(episodeId);

    return {
      'isOffline': isOffline,
      'filePath': filePath,
      'canPlayOffline': isOffline && filePath != null,
    };
  }

  /// Stop offline playback
  Future<void> stopOfflinePlayback() async {
    await _audioPlayer.stop();
  }

  /// Pause offline playback
  Future<void> pauseOfflinePlayback() async {
    await _audioPlayer.pause();
  }

  /// Resume offline playback
  Future<void> resumeOfflinePlayback() async {
    await _audioPlayer.resume();
  }

  /// Get offline player state
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  /// Get offline player position
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;

  /// Get offline player duration
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  /// Get current position
  Duration get currentPosition => _currentPosition;

  /// Get current duration
  Duration get totalDuration => _totalDuration;

  /// Get player state
  PlayerState get playerState => _audioPlayer.state;

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    await _audioPlayer.setPlaybackRate(speed);
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Initialize the offline player
  Future<void> initialize() async {
    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
