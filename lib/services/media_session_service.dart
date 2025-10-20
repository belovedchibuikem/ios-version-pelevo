import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/models/episode.dart';
import '../providers/podcast_player_provider.dart';

/// Media Session Service for Lock Screen Integration
///
/// This service handles media session integration for both Android and iOS
/// to display what's playing on the lock screen with proper controls.
class MediaSessionService {
  static final MediaSessionService _instance = MediaSessionService._internal();
  factory MediaSessionService() => _instance;
  MediaSessionService._internal();

  // Platform channel for native media session integration
  static const MethodChannel _channel = MethodChannel('media_session_service');

  // Player provider reference
  PodcastPlayerProvider? _playerProvider;

  // Current media state
  Episode? _currentEpisode;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isInitialized = false;

  /// Initialize the media session service
  Future<void> initialize({
    required PodcastPlayerProvider playerProvider,
  }) async {
    if (_isInitialized) return;

    try {
      _playerProvider = playerProvider;

      // Set up method call handler for native callbacks
      _channel.setMethodCallHandler(_handleMethodCall);

      // Initialize native media session
      await _channel.invokeMethod('initialize');

      _isInitialized = true;
      debugPrint('🎵 MediaSessionService: Initialized successfully');
    } catch (e) {
      debugPrint('❌ MediaSessionService: Initialization failed: $e');
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onPlay':
          await _handlePlay();
          break;
        case 'onPause':
          await _handlePause();
          break;
        case 'onSkipToNext':
          await _handleSkipToNext();
          break;
        case 'onSkipToPrevious':
          await _handleSkipToPrevious();
          break;
        case 'onSeekTo':
          final position =
              Duration(milliseconds: call.arguments['position'] as int);
          await _handleSeekTo(position);
          break;
        case 'onStop':
          await _handleStop();
          break;
        case 'onMediaSessionAction':
          await _handleMediaSessionAction(call.arguments);
          break;
        case 'onMediaButtonPress':
          await _handleMediaButtonPress(call.arguments);
          break;
        default:
          debugPrint(
              '🎵 MediaSessionService: Unknown method call: ${call.method}');
      }
    } catch (e) {
      debugPrint(
          '❌ MediaSessionService: Error handling method call ${call.method}: $e');
    }
  }

  /// Handle play action from lock screen
  Future<void> _handlePlay() async {
    try {
      if (_playerProvider != null) {
        await _playerProvider!.play();
        debugPrint('🎵 MediaSessionService: Play action handled');
      }
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error handling play: $e');
    }
  }

  /// Handle pause action from lock screen
  Future<void> _handlePause() async {
    try {
      if (_playerProvider != null) {
        await _playerProvider!.pause();
        debugPrint('🎵 MediaSessionService: Pause action handled');
      }
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error handling pause: $e');
    }
  }

  /// Handle skip to next action from lock screen
  Future<void> _handleSkipToNext() async {
    try {
      if (_playerProvider != null) {
        // Use the existing playNextEpisode method
        await _playerProvider!.playNextEpisode();
        debugPrint('🎵 MediaSessionService: Skip to next action handled');
      }
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error handling skip to next: $e');
    }
  }

  /// Handle skip to previous action from lock screen
  Future<void> _handleSkipToPrevious() async {
    try {
      if (_playerProvider != null) {
        // Use the existing playPreviousEpisode method
        await _playerProvider!.playPreviousEpisode();
        debugPrint('🎵 MediaSessionService: Skip to previous action handled');
      }
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error handling skip to previous: $e');
    }
  }

  /// Handle seek action from lock screen
  Future<void> _handleSeekTo(Duration position) async {
    try {
      if (_playerProvider != null) {
        _playerProvider!.seekTo(position);
        debugPrint(
            '🎵 MediaSessionService: Seek to ${position.inSeconds}s handled');
      }
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error handling seek: $e');
    }
  }

  /// Handle stop action from lock screen
  Future<void> _handleStop() async {
    try {
      if (_playerProvider != null) {
        await _playerProvider!.pause();
        debugPrint('🎵 MediaSessionService: Stop action handled');
      }
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error handling stop: $e');
    }
  }

  /// Handle media session action from Android notification
  Future<void> _handleMediaSessionAction(dynamic arguments) async {
    try {
      if (arguments is Map<String, dynamic>) {
        final action = arguments['action'] as String?;
        if (action != null) {
          switch (action) {
            case 'play':
              await _handlePlay();
              break;
            case 'pause':
              await _handlePause();
              break;
            case 'next':
              await _handleSkipToNext();
              break;
            case 'previous':
              await _handleSkipToPrevious();
              break;
            case 'stop':
              await _handleStop();
              break;
            default:
              debugPrint('🎵 MediaSessionService: Unknown action: $action');
          }
        }
      }
    } catch (e) {
      debugPrint(
          '❌ MediaSessionService: Error handling media session action: $e');
    }
  }

  /// Handle media button press from hardware controls
  Future<void> _handleMediaButtonPress(dynamic arguments) async {
    try {
      if (arguments is Map<String, dynamic>) {
        final action = arguments['action'] as String?;
        if (action != null) {
          switch (action) {
            case 'play_pause':
              if (_isPlaying) {
                await _handlePause();
              } else {
                await _handlePlay();
              }
              break;
            case 'play':
              await _handlePlay();
              break;
            case 'pause':
              await _handlePause();
              break;
            case 'next':
              await _handleSkipToNext();
              break;
            case 'previous':
              await _handleSkipToPrevious();
              break;
            case 'stop':
              await _handleStop();
              break;
            default:
              debugPrint(
                  '🎵 MediaSessionService: Unknown media button action: $action');
          }
        }
      }
    } catch (e) {
      debugPrint(
          '❌ MediaSessionService: Error handling media button press: $e');
    }
  }

  /// Update media session with current episode and state
  Future<void> updateMediaSession({
    required Episode episode,
    required Duration position,
    required Duration duration,
    required bool isPlaying,
  }) async {
    if (!_isInitialized) return;

    try {
      _currentEpisode = episode;
      _currentPosition = position;
      _currentDuration = duration;
      _isPlaying = isPlaying;

      // Prepare media metadata
      final mediaMetadata = {
        'title': episode.title,
        'artist': episode.podcastName,
        'album': episode.podcastName,
        'duration': duration.inMilliseconds,
        'position': position.inMilliseconds,
        'isPlaying': isPlaying,
        'artwork': episode.coverImage,
        'genre': 'Podcast', // Default genre for podcasts
        'trackNumber': 1,
        'totalTracks': 1,
      };

      // Update native media session
      await _channel.invokeMethod('updateMediaSession', mediaMetadata);

      debugPrint(
          '🎵 MediaSessionService: Media session updated for "${episode.title}"');
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error updating media session: $e');
    }
  }

  /// Update playback state (position, duration, playing state)
  Future<void> updatePlaybackState({
    required Duration position,
    required Duration duration,
    required bool isPlaying,
  }) async {
    if (!_isInitialized) return;

    try {
      _currentPosition = position;
      _currentDuration = duration;
      _isPlaying = isPlaying;

      final playbackState = {
        'position': position.inMilliseconds,
        'duration': duration.inMilliseconds,
        'isPlaying': isPlaying,
      };

      await _channel.invokeMethod('updatePlaybackState', playbackState);
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error updating playback state: $e');
    }
  }

  /// Clear media session (when no episode is playing)
  Future<void> clearMediaSession() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('clearMediaSession');
      _currentEpisode = null;
      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
      _isPlaying = false;

      debugPrint('🎵 MediaSessionService: Media session cleared');
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error clearing media session: $e');
    }
  }

  /// Set available actions for the media session
  Future<void> setAvailableActions({
    bool canPlay = true,
    bool canPause = true,
    bool canSkipToNext = true,
    bool canSkipToPrevious = true,
    bool canSeek = true,
    bool canStop = true,
  }) async {
    if (!_isInitialized) return;

    try {
      final actions = {
        'canPlay': canPlay,
        'canPause': canPause,
        'canSkipToNext': canSkipToNext,
        'canSkipToPrevious': canSkipToPrevious,
        'canSeek': canSeek,
        'canStop': canStop,
      };

      await _channel.invokeMethod('setAvailableActions', actions);
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error setting available actions: $e');
    }
  }

  /// Dispose the media session service
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('dispose');
      _isInitialized = false;
      _playerProvider = null;
      _currentEpisode = null;

      debugPrint('🎵 MediaSessionService: Disposed');
    } catch (e) {
      debugPrint('❌ MediaSessionService: Error disposing: $e');
    }
  }

  // Getters for current state
  Episode? get currentEpisode => _currentEpisode;
  Duration get currentPosition => _currentPosition;
  Duration get currentDuration => _currentDuration;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
}
