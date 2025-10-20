import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/episode.dart';
import '../../providers/podcast_player_provider.dart';
import 'unified_media_session.dart';

/// Media Session Manager that coordinates between different audio services
class MediaSessionManager {
  static final MediaSessionManager _instance = MediaSessionManager._internal();
  factory MediaSessionManager() => _instance;
  MediaSessionManager._internal();

  final UnifiedMediaSession _mediaSession = UnifiedMediaSession();
  bool _isInitialized = false;
  PodcastPlayerProvider? _playerProvider;

  // Current state tracking
  Episode? _currentEpisode;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Stream controllers for state updates
  final StreamController<Episode?> _episodeController =
      StreamController<Episode?>.broadcast();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  Episode? get currentEpisode => _currentEpisode;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  // Streams
  Stream<Episode?> get episodeStream => _episodeController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  /// Initialize the media session manager
  Future<void> initialize({PodcastPlayerProvider? playerProvider}) async {
    if (_isInitialized) return;

    try {
      _playerProvider = playerProvider;

      // Initialize the unified media session
      await _mediaSession.initialize(playerProvider: playerProvider);

      _isInitialized = true;
      debugPrint('✅ MediaSessionManager initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing MediaSessionManager: $e');
      _isInitialized = true; // Continue without media session
    }
  }

  /// Update the current episode
  void setEpisode(Episode episode) {
    _currentEpisode = episode;
    _episodeController.add(episode);

    // Update the media session
    _mediaSession.setEpisode(episode);

    debugPrint('🎵 MediaSessionManager: Episode set to ${episode.title}');
  }

  /// Update playback state
  void updatePlaybackState({
    required bool isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    _isPlaying = isPlaying;
    if (position != null) _position = position;
    if (duration != null) _duration = duration;

    // Update internal streams
    _playingController.add(isPlaying);
    if (position != null) _positionController.add(position);
    if (duration != null) _durationController.add(duration);

    // Update the media session
    _mediaSession.updatePlaybackState(
      isPlaying: isPlaying,
      position: position,
      duration: duration,
    );

    debugPrint(
        '🎵 MediaSessionManager: Playback state updated - ${isPlaying ? 'Playing' : 'Paused'}');
  }

  /// Update position
  void updatePosition(Duration position) {
    _position = position;
    _positionController.add(position);

    // Update the media session
    _mediaSession.updatePosition(position);
  }

  /// Update duration
  void updateDuration(Duration duration) {
    _duration = duration;
    _durationController.add(duration);

    // Update the media session
    _mediaSession.updateDuration(duration);
  }

  /// Handle play action from media session
  Future<void> handlePlay() async {
    if (_playerProvider != null) {
      await _playerProvider!.play();
    }
  }

  /// Handle pause action from media session
  Future<void> handlePause() async {
    if (_playerProvider != null) {
      await _playerProvider!.pause();
    }
  }

  /// Handle stop action from media session
  Future<void> handleStop() async {
    if (_playerProvider != null) {
      await _playerProvider!.pause();
    }
  }

  /// Handle seek action from media session
  Future<void> handleSeek(Duration position) async {
    if (_playerProvider != null) {
      _playerProvider!.seekTo(position);
    }
  }

  /// Handle skip to next action from media session
  Future<void> handleSkipToNext() async {
    if (_playerProvider != null) {
      _playerProvider!.playNext();
    }
  }

  /// Handle skip to previous action from media session
  Future<void> handleSkipToPrevious() async {
    if (_playerProvider != null) {
      _playerProvider!.playPrevious();
    }
  }

  /// Dispose the media session manager
  Future<void> dispose() async {
    try {
      await _mediaSession.dispose();
      _episodeController.close();
      _playingController.close();
      _positionController.close();
      _durationController.close();
      debugPrint('✅ MediaSessionManager disposed');
    } catch (e) {
      debugPrint('❌ Error disposing MediaSessionManager: $e');
    }
  }
}
