import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/episode.dart';
import '../../providers/podcast_player_provider.dart';

/// Centralized Media Session Service - Single instance for the entire app
class MediaSessionService {
  static final MediaSessionService _instance = MediaSessionService._internal();
  factory MediaSessionService() => _instance;
  MediaSessionService._internal();

  AudioHandler? _audioHandler;
  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<void>? _initializingCompleter;
  PodcastPlayerProvider? _playerProvider;

  // Current state
  Episode? _currentEpisode;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Getters
  bool get isInitialized => _isInitialized;
  Episode? get currentEpisode => _currentEpisode;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  /// Initialize the media session service
  Future<void> initialize({PodcastPlayerProvider? playerProvider}) async {
    // If already initialized, just update provider and return
    if (_isInitialized && _audioHandler != null) {
      debugPrint(
          '🎵 MediaSessionService: Already initialized with AudioHandler, skipping...');
      if (playerProvider != null) {
        _playerProvider = playerProvider;
        // Update the player provider in the existing handler
        if (_audioHandler is PodcastAudioHandler) {
          (_audioHandler as PodcastAudioHandler)
              .updatePlayerProvider(playerProvider);
        }
      }
      return;
    }

    // Prevent concurrent initialization attempts that can trip audio_service internals
    if (_isInitializing) {
      debugPrint(
          '🎵 MediaSessionService: Initialization already in progress, awaiting...');
      try {
        await _initializingCompleter?.future;
      } catch (_) {}
      // After the in-flight init completes, ensure provider is wired up
      if (playerProvider != null && _audioHandler is PodcastAudioHandler) {
        (_audioHandler as PodcastAudioHandler)
            .updatePlayerProvider(playerProvider);
      }
      return;
    }

    try {
      _isInitializing = true;
      _initializingCompleter = Completer<void>();
      debugPrint('🎵 MediaSessionService: Starting initialization...');
      _playerProvider = playerProvider;
      debugPrint(
          '🎵 MediaSessionService: Player provider set: ${playerProvider != null}');

      // Wait for FlutterEngine to be fully ready
      debugPrint(
          '🎵 MediaSessionService: Waiting for FlutterEngine to be ready...');
      await Future.delayed(Duration(milliseconds: 500));

      // Initialize audio service with our custom handler
      debugPrint('🎵 MediaSessionService: Initializing AudioService...');

      _audioHandler = await AudioService.init(
        builder: () => PodcastAudioHandler(_playerProvider),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'pelevo_podcast_media',
          androidNotificationChannelName: 'Pelevo Podcast',
          androidNotificationChannelDescription: 'Podcast playback controls',
        ),
      );

      if (_audioHandler != null) {
        _isInitialized = true;
        debugPrint('✅ MediaSessionService: Initialized successfully');
      } else {
        debugPrint(
            '❌ MediaSessionService: AudioHandler is null after initialization');
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('❌ Error initializing MediaSessionService: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      _isInitialized = false;

      // Don't rethrow the error - continue without media session
      // This allows the app to function even if media session fails
      debugPrint('⚠️ Continuing without media session functionality');
    } finally {
      _isInitializing = false;
      _initializingCompleter?.complete();
      _initializingCompleter = null;
    }
  }

  /// Update the current episode in the media session
  void setEpisode(Episode episode) {
    debugPrint(
        '🎵 MediaSessionService: setEpisode called with: ${episode.title}');
    _currentEpisode = episode;

    if (_audioHandler != null) {
      debugPrint(
          '🎵 MediaSessionService: AudioHandler available, creating MediaItem...');

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
      if (_audioHandler is PodcastAudioHandler) {
        (_audioHandler as PodcastAudioHandler).setMediaItem(mediaItem);
      } else {
        // Fallback for generic AudioHandler
        (_audioHandler as BaseAudioHandler).mediaItem.value = mediaItem;
      }

      debugPrint(
          '✅ MediaSessionService: Media session updated with episode: ${episode.title}');
    } else {
      debugPrint(
          '❌ MediaSessionService: AudioHandler is null, cannot update episode');
    }
  }

  /// Update playback state in the media session
  void updatePlaybackState({
    required bool isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    debugPrint(
        '🎵 MediaSessionService: updatePlaybackState called - isPlaying: $isPlaying');

    if (_audioHandler == null) {
      debugPrint(
          '❌ MediaSessionService: AudioHandler is null, cannot update playback state');
      return;
    }

    _isPlaying = isPlaying;
    if (position != null) _position = position;
    if (duration != null) _duration = duration;

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
      updatePosition: position ?? _position,
      bufferedPosition: duration ?? _duration,
      speed: 1.0,
    );

    // Update the playback state
    if (_audioHandler is PodcastAudioHandler) {
      (_audioHandler as PodcastAudioHandler).setPlaybackState(playbackState);
    } else {
      // Fallback for generic AudioHandler
      (_audioHandler as BaseAudioHandler).playbackState.value = playbackState;
    }

    debugPrint(
        '✅ MediaSessionService: Playback state updated: ${isPlaying ? 'Playing' : 'Paused'}');
  }

  /// Update position in the media session
  void updatePosition(Duration position) {
    if (_audioHandler == null) return;

    _position = position;

    if (_audioHandler is PodcastAudioHandler) {
      final handler = _audioHandler as PodcastAudioHandler;
      final currentState = handler.playbackState.value;

      handler.setPlaybackState(currentState.copyWith(
        updatePosition: position,
      ));
    }
  }

  /// Update duration in the media session
  void updateDuration(Duration duration) {
    if (_audioHandler == null) return;

    _duration = duration;

    if (_audioHandler is PodcastAudioHandler) {
      final handler = _audioHandler as PodcastAudioHandler;
      final currentState = handler.playbackState.value;

      handler.setPlaybackState(currentState.copyWith(
        bufferedPosition: duration,
      ));
    }
  }

  /// Set player provider (useful for late initialization)
  void setPlayerProvider(PodcastPlayerProvider? playerProvider) {
    _playerProvider = playerProvider;
    if (_audioHandler is PodcastAudioHandler) {
      (_audioHandler as PodcastAudioHandler)
          .updatePlayerProvider(playerProvider);
    }
  }

  /// Force re-initialization (useful when AudioHandler is null)
  Future<void> forceReinitialize(
      {PodcastPlayerProvider? playerProvider}) async {
    debugPrint('🔄 MediaSessionService: Force re-initializing...');
    _isInitialized = false;
    _audioHandler = null;
    await initialize(playerProvider: playerProvider);
  }

  /// Dispose the media session service
  Future<void> dispose() async {
    try {
      await _audioHandler?.stop();
      debugPrint('✅ MediaSessionService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing MediaSessionService: $e');
    }
  }
}

/// Custom Audio Handler that integrates with the podcast player provider
class PodcastAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  PodcastPlayerProvider? _playerProvider;

  PodcastAudioHandler(this._playerProvider);

  /// Update the player provider reference
  void updatePlayerProvider(PodcastPlayerProvider? playerProvider) {
    _playerProvider = playerProvider;
    debugPrint('🎵 PodcastAudioHandler: Player provider updated');
  }

  // Helper methods to update the ValueStream
  void setMediaItem(MediaItem item) {
    mediaItem.value = item;
  }

  void setPlaybackState(PlaybackState state) {
    playbackState.value = state;
  }

  @override
  Future<void> play() async {
    debugPrint('🎵 Media session: Play requested');
    if (_playerProvider != null) {
      await _playerProvider!.play();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> pause() async {
    debugPrint('🎵 Media session: Pause requested');
    if (_playerProvider != null) {
      await _playerProvider!.pause();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> stop() async {
    debugPrint('🎵 Media session: Stop requested');
    if (_playerProvider != null) {
      await _playerProvider!.pause();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('🎵 Media session: Seek to ${position.inSeconds}s requested');
    if (_playerProvider != null) {
      _playerProvider!.seekTo(position);
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('🎵 Media session: Skip to next requested');
    if (_playerProvider != null) {
      _playerProvider!.playNext();
    } else {
      debugPrint('❌ Media session: Player provider is null');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('🎵 Media session: Skip to previous requested');
    if (_playerProvider != null) {
      _playerProvider!.playPrevious();
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
