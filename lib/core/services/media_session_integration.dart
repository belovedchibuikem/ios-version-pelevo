import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/episode.dart';
import '../../providers/podcast_player_provider.dart';
import 'media_session_service.dart';

/// Integration service that connects media session to actual audio players
class MediaSessionIntegration {
  static final MediaSessionIntegration _instance =
      MediaSessionIntegration._internal();
  factory MediaSessionIntegration() => _instance;
  MediaSessionIntegration._internal();

  final MediaSessionService _mediaSessionService = MediaSessionService();
  PodcastPlayerProvider? _playerProvider;
  StreamSubscription? _playingStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _episodeSubscription;

  bool _isInitialized = false;

  /// Initialize the media session integration
  Future<void> initialize({PodcastPlayerProvider? playerProvider}) async {
    if (_isInitialized) return;

    try {
      _playerProvider = playerProvider;

      // Initialize media session service
      await _mediaSessionService.initialize(playerProvider: playerProvider);

      // Set up listeners to sync audio player state with media session
      _setupAudioPlayerListeners();

      _isInitialized = true;
      debugPrint('✅ MediaSessionIntegration initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing MediaSessionIntegration: $e');
      rethrow;
    }
  }

  /// Set up listeners to sync audio player state with media session
  void _setupAudioPlayerListeners() {
    if (_playerProvider == null) return;

    // Note: All updates will be handled manually through the public methods
    // when called from the PodcastPlayerProvider or other services

    debugPrint('✅ Media session integration ready for manual updates');
  }

  /// Manually update episode in media session
  void setEpisode(Episode episode) {
    _mediaSessionService.setEpisode(episode);
  }

  /// Manually update playback state
  void updatePlaybackState({
    required bool isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    _mediaSessionService.updatePlaybackState(
      isPlaying: isPlaying,
      position: position,
      duration: duration,
    );
  }

  /// Manually update position
  void updatePosition(Duration position) {
    _mediaSessionService.updatePosition(position);
  }

  /// Manually update duration
  void updateDuration(Duration duration) {
    _mediaSessionService.updateDuration(duration);
  }

  /// Dispose the integration
  Future<void> dispose() async {
    await _playingStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _episodeSubscription?.cancel();
    await _mediaSessionService.dispose();
    _isInitialized = false;
    debugPrint('✅ MediaSessionIntegration disposed');
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}
