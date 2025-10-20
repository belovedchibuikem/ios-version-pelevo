import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_service.dart';
import 'enhanced_audio_player_service.dart';
import '../models/buffering_models.dart' as buffering;
import '../data/models/episode.dart';

/// Hybrid audio player service that can switch between implementations
class HybridAudioPlayerService {
  static final HybridAudioPlayerService _instance =
      HybridAudioPlayerService._internal();
  factory HybridAudioPlayerService() => _instance;
  HybridAudioPlayerService._internal();

  // Services
  final AudioPlayerService _legacyService = AudioPlayerService();
  final EnhancedAudioPlayerService _enhancedService =
      EnhancedAudioPlayerService();

  // Current implementation
  bool _useEnhancedImplementation = false;

  // State tracking
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  Map<String, dynamic>? _currentEpisode;
  buffering.BufferingState _bufferingState = buffering.BufferingState.idle;

  // Stream controllers
  final StreamController<bool> _playingStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _loadingStateController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<double> _speedController =
      StreamController<double>.broadcast();
  final StreamController<Map<String, dynamic>?> _currentEpisodeController =
      StreamController<Map<String, dynamic>?>.broadcast();
  final StreamController<buffering.BufferingState> _bufferingStateController =
      StreamController<buffering.BufferingState>.broadcast();

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  Map<String, dynamic>? get currentEpisode => _currentEpisode;
  buffering.BufferingState get bufferingState => _bufferingState;
  bool get useEnhancedImplementation => _useEnhancedImplementation;

  // Streams
  Stream<bool> get playingStateStream => _playingStateController.stream;
  Stream<bool> get loadingStateStream => _loadingStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<Map<String, dynamic>?> get currentEpisodeStream =>
      _currentEpisodeController.stream;
  Stream<buffering.BufferingState> get bufferingStateStream =>
      _bufferingStateController.stream;
  // AudioPlayerService doesn't have onEpisodeComplete stream
  Stream<void> get onEpisodeComplete => _useEnhancedImplementation
      ? _enhancedService.onEpisodeComplete
      : Stream.empty();

  /// Initialize the hybrid service
  Future<void> initialize({dynamic playerProvider}) async {
    if (_isInitialized) return;

    try {
      await _legacyService.initialize(playerProvider: playerProvider);
      await _enhancedService.initialize(playerProvider: playerProvider);
      _setupListeners();
      _isInitialized = true;
      debugPrint('HybridAudioPlayerService: Initialized successfully');
    } catch (e) {
      debugPrint('HybridAudioPlayerService: Error initializing: $e');
      rethrow;
    }
  }

  /// Switch between legacy and enhanced implementations
  Future<void> switchImplementation(bool useEnhanced) async {
    if (_useEnhancedImplementation == useEnhanced) return;

    debugPrint(
        'HybridAudioPlayerService: Switching to ${useEnhanced ? "enhanced" : "legacy"} implementation');

    if (_isPlaying) {
      await pause();
    }

    _useEnhancedImplementation = useEnhanced;
    _setupListeners();

    if (_currentEpisode != null) {
      await loadAndPlayEpisode(_currentEpisode!);
    }
  }

  /// Set up listeners for the current implementation
  void _setupListeners() {
    if (_useEnhancedImplementation) {
      _enhancedService.playingStateStream.listen((playing) {
        _isPlaying = playing;
        _playingStateController.add(_isPlaying);
      });

      _enhancedService.bufferingStateStream.listen((bufferingState) {
        _bufferingState = bufferingState;
        _isLoading = bufferingState == buffering.BufferingState.loading ||
            bufferingState == buffering.BufferingState.buffering;
        _loadingStateController.add(_isLoading);
        _bufferingStateController.add(_bufferingState);
      });

      _enhancedService.positionStream.listen((position) {
        _currentPosition = position;
        _positionController.add(_currentPosition);
      });

      _enhancedService.durationStream.listen((duration) {
        _totalDuration = duration;
        _durationController.add(_totalDuration);
      });

      _enhancedService.currentEpisodeStream.listen((episode) {
        if (episode != null) {
          _currentEpisode = episode.toJson();
          _currentEpisodeController.add(_currentEpisode);
        }
      });
    } else {
      _legacyService.playingStream.listen((playing) {
        _isPlaying = playing;
        _playingStateController.add(_isPlaying);
      });

      // AudioPlayerService doesn't have loadingStateStream, use playerStateStream instead
      _legacyService.playerStateStream.listen((state) {
        _isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        _loadingStateController.add(_isLoading);
        _bufferingState = _isLoading
            ? buffering.BufferingState.loading
            : buffering.BufferingState.ready;
        _bufferingStateController.add(_bufferingState);
      });

      _legacyService.positionStream.listen((position) {
        _currentPosition = position ?? Duration.zero;
        _positionController.add(_currentPosition);
      });

      _legacyService.durationStream.listen((duration) {
        _totalDuration = duration ?? Duration.zero;
        _durationController.add(_totalDuration);
      });

      // AudioPlayerService doesn't have speedStream, manage speed locally
      _speedController.add(_playbackSpeed);

      // AudioPlayerService doesn't have currentEpisodeStream, manage episode locally
      _currentEpisodeController.add(_currentEpisode);
    }
  }

  /// Load and play episode
  Future<void> loadAndPlayEpisode(Map<String, dynamic> episode) async {
    try {
      _currentEpisode = episode;
      debugPrint(
          'HybridAudioPlayerService: Loading episode: ${episode['title']}');
      debugPrint('HybridAudioPlayerService: Episode data: $episode');

      if (_useEnhancedImplementation) {
        debugPrint('HybridAudioPlayerService: Using enhanced implementation');

        // Convert to buffering model Episode format
        final audioUrl = episode['audioUrl'] ??
            episode['enclosureUrl'] ??
            episode['audio_url'];
        debugPrint('HybridAudioPlayerService: Audio URL: $audioUrl');

        final enhancedEpisode = buffering.Episode(
          id: episode['id']?.toString() ?? '',
          title: episode['title'] ?? '',
          description: episode['description'],
          duration: _parseDuration(episode['duration']),
          imageUrl: episode['coverImage'] ?? episode['imageUrl'],
          audioUrl: audioUrl,
          podcastTitle: episode['podcastTitle'] ?? episode['podcast']?['title'],
          podcastAuthor:
              episode['podcastAuthor'] ?? episode['podcast']?['author'],
          publishedAt: episode['datePublished'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  episode['datePublished'] * 1000)
              : episode['publishedAt'] != null
                  ? DateTime.parse(episode['publishedAt'])
                  : null,
        );

        debugPrint(
            'HybridAudioPlayerService: Enhanced episode: ${enhancedEpisode.toJson()}');

        // Check if audio URL is available
        if (enhancedEpisode.audioUrl == null ||
            enhancedEpisode.audioUrl?.isEmpty == true) {
          debugPrint('HybridAudioPlayerService: No audio URL available');
          throw Exception(
              'No audio URL available for this episode. Please try another episode or check your internet connection.');
        }

        // Convert to the correct Episode type for enhanced service
        final episodeModel = Episode.fromJson(enhancedEpisode.toJson());
        await _enhancedService.loadAndPlayEpisode(episodeModel);
      } else {
        debugPrint('HybridAudioPlayerService: Using legacy implementation');
        final episodeModel = Episode.fromJson(episode);
        await _legacyService.playEpisode(episodeModel);
      }
    } catch (e) {
      debugPrint('HybridAudioPlayerService: Error loading episode: $e');
      rethrow;
    }
  }

  /// Play audio
  Future<void> play() async {
    if (_useEnhancedImplementation) {
      await _enhancedService.play();
    } else {
      await _legacyService.play();
    }
  }

  /// Pause audio
  Future<void> pause() async {
    if (_useEnhancedImplementation) {
      await _enhancedService.pause();
    } else {
      await _legacyService.pause();
    }
  }

  /// Stop audio
  Future<void> stop() async {
    if (_useEnhancedImplementation) {
      await _enhancedService.stop();
    } else {
      await _legacyService.stop();
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    if (_useEnhancedImplementation) {
      await _enhancedService.seek(position);
    } else {
      await _legacyService.seekTo(position);
    }
  }

  /// Skip forward
  Future<void> skipForward([int seconds = 30]) async {
    if (_useEnhancedImplementation) {
      await _enhancedService.skipForward(seconds);
    } else {
      final newPosition = _legacyService.position + Duration(seconds: seconds);
      await _legacyService.seekTo(newPosition);
    }
  }

  /// Skip backward
  Future<void> skipBackward([int seconds = 15]) async {
    if (_useEnhancedImplementation) {
      await _enhancedService.skipBackward(seconds);
    } else {
      final newPosition = _legacyService.position - Duration(seconds: seconds);
      await _legacyService.seekTo(newPosition);
    }
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    if (!_useEnhancedImplementation) {
      await _legacyService.setPlaybackSpeed(speed);
    }
  }

  /// Get saved progress for episode
  int getSavedProgress(String episodeId) {
    if (!_useEnhancedImplementation) {
      // AudioPlayerService doesn't have getSavedProgress method
      return 0;
    }
    return 0;
  }

  /// Parse duration string to Duration object
  Duration? _parseDuration(dynamic duration) {
    if (duration == null) return null;

    if (duration is int) {
      return Duration(seconds: duration);
    }

    if (duration is String) {
      // Parse duration strings like "45m", "1h 30m", "3600"
      final str = duration.trim();

      // If it's just a number, treat as seconds
      if (int.tryParse(str) != null) {
        return Duration(seconds: int.parse(str));
      }

      // Parse "Xh Ym" format
      int totalSeconds = 0;
      final parts = str.split(' ');

      for (final part in parts) {
        if (part.endsWith('h')) {
          final hours = int.tryParse(part.substring(0, part.length - 1));
          if (hours != null) totalSeconds += hours * 3600;
        } else if (part.endsWith('m')) {
          final minutes = int.tryParse(part.substring(0, part.length - 1));
          if (minutes != null) totalSeconds += minutes * 60;
        } else if (part.endsWith('s')) {
          final seconds = int.tryParse(part.substring(0, part.length - 1));
          if (seconds != null) totalSeconds += seconds;
        }
      }

      return totalSeconds > 0 ? Duration(seconds: totalSeconds) : null;
    }

    return null;
  }

  /// Format duration
  String formatDuration(Duration duration) {
    if (!_useEnhancedImplementation) {
      return _legacyService.formatDuration(duration);
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    _legacyService.dispose();
    _enhancedService.dispose();
    _playingStateController.close();
    _loadingStateController.close();
    _positionController.close();
    _durationController.close();
    _speedController.close();
    _currentEpisodeController.close();
    _bufferingStateController.close();
  }
}
