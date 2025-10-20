// lib/services/smart_buffering_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/models/episode.dart';

enum BufferingStrategy {
  conservative, // Slow connections, battery saving
  balanced, // Normal connections
  aggressive // Fast connections, preload more
}

class SmartBufferingService {
  static final SmartBufferingService _instance =
      SmartBufferingService._internal();
  factory SmartBufferingService() => _instance;
  SmartBufferingService._internal();

  // Audio players for preloading
  final Map<String, AudioPlayer> _preloadPlayers = {};
  final Map<String, Episode> _preloadedEpisodes = {};

  // Buffering state tracking
  bool _isBuffering = false;
  double _bufferingProgress = 0.0;
  String? _currentBufferingEpisode;

  // Network monitoring
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  Timer? _connectivityTimer;

  // Configuration
  BufferingStrategy _currentStrategy = BufferingStrategy.balanced;
  int _maxPreloadPlayers = 2;
  Duration _preloadDelay = const Duration(seconds: 5);

  // Stream controllers for UI updates
  final StreamController<bool> _bufferingController =
      StreamController<bool>.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  // Getters for UI
  bool get isBuffering => _isBuffering;
  double get bufferingProgress => _bufferingProgress;
  String? get currentBufferingEpisode => _currentBufferingEpisode;
  BufferingStrategy get currentStrategy => _currentStrategy;

  // Streams for UI updates
  Stream<bool> get bufferingStream => _bufferingController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;

  /// Initialize the smart buffering service
  Future<void> initialize() async {
    try {
      // Monitor network connectivity
      _startConnectivityMonitoring();

      // Set initial strategy based on connectivity
      await _updateBufferingStrategy();

      debugPrint(
          '🧠 SmartBufferingService initialized with ${_currentStrategy.name} strategy');
    } catch (e) {
      debugPrint('❌ Error initializing SmartBufferingService: $e');
    }
  }

  /// Start monitoring network connectivity
  void _startConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen((result) {
      _currentConnectivity = result;
      _updateBufferingStrategy();
      debugPrint('🌐 Network changed to: ${result.name}');
    });
  }

  /// Update buffering strategy based on network conditions
  Future<void> _updateBufferingStrategy() async {
    final oldStrategy = _currentStrategy;

    switch (_currentConnectivity) {
      case ConnectivityResult.wifi:
        _currentStrategy = BufferingStrategy.aggressive;
        _maxPreloadPlayers = 3;
        _preloadDelay = const Duration(seconds: 2);
        break;
      case ConnectivityResult.mobile:
        _currentStrategy = BufferingStrategy.balanced;
        _maxPreloadPlayers = 2;
        _preloadDelay = const Duration(seconds: 5);
        break;
      case ConnectivityResult.ethernet:
        _currentStrategy = BufferingStrategy.aggressive;
        _maxPreloadPlayers = 3;
        _preloadDelay = const Duration(seconds: 1);
        break;
      default:
        _currentStrategy = BufferingStrategy.conservative;
        _maxPreloadPlayers = 1;
        _preloadDelay = const Duration(seconds: 10);
    }

    if (oldStrategy != _currentStrategy) {
      debugPrint(
          '🧠 Buffering strategy changed: ${oldStrategy.name} → ${_currentStrategy.name}');
      _statusController.add('Strategy: ${_currentStrategy.name}');
    }
  }

  /// Start smart buffering for an episode
  Future<void> startSmartBuffering(
      Episode episode, AudioPlayer audioPlayer) async {
    if (episode.audioUrl == null || episode.audioUrl!.isEmpty) {
      return;
    }

    try {
      _setBufferingState(true, episode.title);
      _statusController.add('Buffering: ${episode.title}');

      // Monitor buffering progress
      _monitorBufferingProgress(audioPlayer);

      // Start preloading next episodes if strategy allows
      if (_currentStrategy != BufferingStrategy.conservative) {
        _schedulePreloading(episode);
      }

      debugPrint('🧠 Started smart buffering for: ${episode.title}');
    } catch (e) {
      debugPrint('❌ Error starting smart buffering: $e');
      _setBufferingState(false);
    }
  }

  /// Monitor buffering progress
  void _monitorBufferingProgress(AudioPlayer audioPlayer) {
    audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      final duration = audioPlayer.duration;
      if (duration != null && duration.inMilliseconds > 0) {
        final progress =
            bufferedPosition.inMilliseconds / duration.inMilliseconds;
        _updateBufferingProgress(progress);
      }
    });
  }

  /// Update buffering progress
  void _updateBufferingProgress(double progress) {
    _bufferingProgress = progress.clamp(0.0, 1.0);
    _progressController.add(_bufferingProgress);

    // Consider buffering complete when we have enough buffered
    final bufferThreshold = _getBufferThreshold();
    if (_bufferingProgress >= bufferThreshold && _isBuffering) {
      _completeBuffering();
    }
  }

  /// Get buffer threshold based on strategy
  double _getBufferThreshold() {
    switch (_currentStrategy) {
      case BufferingStrategy.conservative:
        return 0.1; // 10% buffered
      case BufferingStrategy.balanced:
        return 0.2; // 20% buffered
      case BufferingStrategy.aggressive:
        return 0.3; // 30% buffered
    }
  }

  /// Complete buffering process
  void _completeBuffering() {
    _setBufferingState(false);
    _statusController.add('Ready to play');
    debugPrint('🧠 Buffering completed');
  }

  /// Set buffering state
  void _setBufferingState(bool isBuffering, [String? episodeTitle]) {
    _isBuffering = isBuffering;
    _currentBufferingEpisode = episodeTitle;
    _bufferingController.add(_isBuffering);

    if (!isBuffering) {
      _bufferingProgress = 0.0;
      _progressController.add(0.0);
    }
  }

  /// Schedule preloading of next episodes
  void _schedulePreloading(Episode currentEpisode) {
    Timer(_preloadDelay, () {
      _preloadNextEpisodes(currentEpisode);
    });
  }

  /// Preload next episodes in queue
  Future<void> _preloadNextEpisodes(Episode currentEpisode) async {
    try {
      // This would need access to PodcastPlayerProvider
      // For now, we'll implement a basic preloading mechanism
      debugPrint('🧠 Scheduling preload of next episodes...');

      // Clean up old preloaded players
      _cleanupPreloadedPlayers();

      // Only preload if we have capacity
      if (_preloadPlayers.length < _maxPreloadPlayers) {
        await _preloadNextEpisode(currentEpisode);
      }
    } catch (e) {
      debugPrint('❌ Error preloading episodes: $e');
    }
  }

  /// Preload the next episode
  Future<void> _preloadNextEpisode(Episode currentEpisode) async {
    try {
      debugPrint('🧠 Preloading next episode after: ${currentEpisode.title}');

      // This is a simplified preloading implementation
      // In a full implementation, you would:
      // 1. Get the next episode from PodcastPlayerProvider
      // 2. Create a new AudioPlayer instance
      // 3. Start buffering the audio URL
      // 4. Store the preloaded player for quick access

      // For now, we'll simulate preloading with a timer
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('🧠 Preloading simulation completed');
    } catch (e) {
      debugPrint('❌ Error preloading episode: $e');
    }
  }

  /// Clean up preloaded players
  void _cleanupPreloadedPlayers() {
    final playersToRemove = <String>[];

    _preloadPlayers.forEach((key, player) {
      if (player.processingState == ProcessingState.completed ||
          player.processingState == ProcessingState.idle) {
        playersToRemove.add(key);
      }
    });

    for (final key in playersToRemove) {
      _preloadPlayers[key]?.dispose();
      _preloadPlayers.remove(key);
      _preloadedEpisodes.remove(key);
    }
  }

  /// Get preloaded player for episode (if available)
  AudioPlayer? getPreloadedPlayer(String episodeId) {
    return _preloadPlayers[episodeId];
  }

  /// Check if episode is preloaded
  bool isEpisodePreloaded(String episodeId) {
    return _preloadPlayers.containsKey(episodeId);
  }

  /// Set custom buffering strategy
  void setBufferingStrategy(BufferingStrategy strategy) {
    _currentStrategy = strategy;
    debugPrint('🧠 Buffering strategy set to: ${strategy.name}');
    _statusController.add('Strategy: ${strategy.name}');
  }

  /// Get buffering status message
  String getBufferingStatus() {
    if (_isBuffering) {
      return 'Buffering: ${(_bufferingProgress * 100).toStringAsFixed(0)}%';
    } else if (_preloadPlayers.isNotEmpty) {
      return 'Preloading ${_preloadPlayers.length} episodes';
    } else {
      return 'Ready';
    }
  }

  /// Get buffering statistics
  Map<String, dynamic> getBufferingStats() {
    return {
      'isBuffering': _isBuffering,
      'bufferingProgress': _bufferingProgress,
      'currentStrategy': _currentStrategy.name,
      'preloadedCount': _preloadPlayers.length,
      'maxPreloadPlayers': _maxPreloadPlayers,
      'connectivity': _currentConnectivity.name,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      // Dispose all preloaded players
      for (final player in _preloadPlayers.values) {
        await player.dispose();
      }
      _preloadPlayers.clear();
      _preloadedEpisodes.clear();

      // Cancel connectivity monitoring
      _connectivityTimer?.cancel();

      // Close stream controllers
      await _bufferingController.close();
      await _progressController.close();
      await _statusController.close();

      debugPrint('🧠 SmartBufferingService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing SmartBufferingService: $e');
    }
  }
}
