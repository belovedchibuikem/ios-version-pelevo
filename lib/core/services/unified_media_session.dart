import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/episode.dart';
import '../../providers/podcast_player_provider.dart';

/// Unified Media Session Service that works with both just_audio and audioplayers
class UnifiedMediaSession {
  static final UnifiedMediaSession _instance = UnifiedMediaSession._internal();
  factory UnifiedMediaSession() => _instance;
  UnifiedMediaSession._internal();

  AudioHandler? _audioHandler;
  bool _isInitialized = false;

  // Current state
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

  /// Initialize the media session service
  Future<void> initialize({PodcastPlayerProvider? playerProvider}) async {
    if (_isInitialized) return;

    try {
      // Skip audio service initialization on iOS simulator to prevent crashes
      if (Platform.isIOS && kDebugMode) {
        debugPrint('🎵 Skipping AudioService initialization on iOS simulator');
        _isInitialized = true;
        return;
      }

      // Initialize audio service with our custom handler
      _audioHandler = await AudioService.init(
        builder: () => UnifiedAudioHandler(playerProvider),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.pelevo.podcast.media',
          androidNotificationChannelName: 'Pelevo Podcast',
          androidNotificationChannelDescription: 'Podcast playback controls',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'drawable/ic_stat_music_note',
          notificationColor: Color(0xFF2196F3),
          androidShowNotificationBadge: true,
          androidNotificationClickStartsActivity: true,
        ),
      );

      _isInitialized = true;
      debugPrint('✅ UnifiedMediaSession initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing UnifiedMediaSession: $e');
      _isInitialized = true; // Continue without media session
    }
  }

  /// Update the current episode in the media session
  void setEpisode(Episode episode) {
    _currentEpisode = episode;
    _episodeController.add(episode);

    final audioHandler = _audioHandler;
    if (audioHandler != null) {
      // Create media item with episode information
      final mediaItem = MediaItem(
        id: episode.id.toString(),
        title: episode.title,
        artist: episode.podcastName,
        album: episode.podcastName,
        duration: Duration(seconds: int.tryParse(episode.duration) ?? 0),
        artUri: episode.coverImage.isNotEmpty
            ? Uri.parse(episode.coverImage)
            : null,
        genre: 'Podcast',
        playable: true,
        extras: {
          'episode_id': episode.id,
          'podcast_id': episode.podcastId,
          'description': episode.description,
          'creator': episode.creator,
        },
      );

      // Update the media item
      final handler = audioHandler as UnifiedAudioHandler;
      handler.setMediaItem(mediaItem);

      debugPrint('🎵 Media session updated with episode: ${episode.title}');
    }
  }

  /// Update playback state in the media session
  void updatePlaybackState({
    required bool isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    final audioHandler = _audioHandler;
    if (audioHandler == null) return;

    _isPlaying = isPlaying;
    if (position != null) _position = position;
    if (duration != null) _duration = duration;

    // Update internal streams
    _playingController.add(isPlaying);
    if (position != null) _positionController.add(position);
    if (duration != null) _durationController.add(duration);

    // Create playback state
    final playbackState = PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.playPause,
        MediaAction.stop,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: isPlaying,
      updatePosition: position ?? Duration.zero,
      bufferedPosition: duration ?? Duration.zero,
      speed: 1.0,
    );

    // Update the playback state
    final handler = audioHandler as UnifiedAudioHandler;
    handler.setPlaybackState(playbackState);

    debugPrint(
        '🎵 Playback state updated: ${isPlaying ? 'Playing' : 'Paused'}');
  }

  /// Update position in the media session
  void updatePosition(Duration position) {
    final audioHandler = _audioHandler;
    if (audioHandler == null) return;

    _position = position;
    _positionController.add(position);

    // Update playback state with new position
    final handler = audioHandler as UnifiedAudioHandler;
    final currentState = handler.playbackState.value;

    handler.setPlaybackState(currentState.copyWith(
      updatePosition: position,
    ));
  }

  /// Update duration in the media session
  void updateDuration(Duration duration) {
    final audioHandler = _audioHandler;
    if (audioHandler == null) return;

    _duration = duration;
    _durationController.add(duration);

    // Update playback state with new duration
    final handler = audioHandler as UnifiedAudioHandler;
    final currentState = handler.playbackState.value;

    handler.setPlaybackState(currentState.copyWith(
      bufferedPosition: duration,
    ));
  }

  /// Dispose the media session service
  Future<void> dispose() async {
    try {
      await _audioHandler?.stop();
      await _episodeController.close();
      await _playingController.close();
      await _positionController.close();
      await _durationController.close();
      debugPrint('✅ UnifiedMediaSession disposed');
    } catch (e) {
      debugPrint('❌ Error disposing UnifiedMediaSession: $e');
    }
  }
}

/// Custom Audio Handler that integrates with the podcast player provider
class UnifiedAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final PodcastPlayerProvider? _playerProvider;

  UnifiedAudioHandler(this._playerProvider);

  // Helper methods to update the ValueStream
  void setMediaItem(MediaItem item) {
    mediaItem.add(item);
  }

  void setPlaybackState(PlaybackState state) {
    playbackState.add(state);
  }

  @override
  Future<void> play() async {
    debugPrint('🎵 Media session: Play requested');
    final provider = _playerProvider;
    if (provider != null) {
      await provider.play();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> pause() async {
    debugPrint('🎵 Media session: Pause requested');
    final provider = _playerProvider;
    if (provider != null) {
      await provider.pause();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> stop() async {
    debugPrint('🎵 Media session: Stop requested');
    final provider = _playerProvider;
    if (provider != null) {
      await provider.pause();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('🎵 Media session: Seek to ${position.inSeconds}s requested');
    final provider = _playerProvider;
    if (provider != null) {
      provider.seekTo(position);
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('🎵 Media session: Skip to next requested');
    final provider = _playerProvider;
    if (provider != null) {
      provider.playNext();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('🎵 Media session: Skip to previous requested');
    final provider = _playerProvider;
    if (provider != null) {
      provider.playPrevious();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    debugPrint('🎵 Media session: Task removed');
    await stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    debugPrint('🎵 Media session: Notification deleted');
    await stop();
  }
}
