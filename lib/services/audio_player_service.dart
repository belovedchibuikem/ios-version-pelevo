// lib/services/audio_player_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/models/episode.dart';
import '../providers/podcast_player_provider.dart';
import '../core/services/media_session_service.dart';
import '../core/services/battery_optimization_service.dart';
import 'smart_buffering_service.dart';
import 'thermal_optimization_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // Configure audio player with position preservation
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioSession? _audioSession;
  bool _isInitialized = false;
  PodcastPlayerProvider? _playerProvider;
  bool _wakelockEnabled = false;

  // Media session service for lock screen integration
  final MediaSessionService _mediaSessionService = MediaSessionService();

  // Battery optimization service
  final BatteryOptimizationService _batteryService =
      BatteryOptimizationService();

  // Smart buffering service
  final SmartBufferingService _bufferingService = SmartBufferingService();

  // Thermal optimization service
  final ThermalOptimizationService _thermalService =
      ThermalOptimizationService();

  // Audio state
  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  // Debug verbosity control
  bool _verboseDebug = false;
  bool get verboseDebug => _verboseDebug;

  /// Enable/disable verbose debug logging during playback
  void setVerboseDebug(bool enabled) {
    _verboseDebug = enabled;
    debugPrint(
        '🔊 AudioPlayerService: Verbose debug ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable partial wakelock for background audio (screen can turn off)
  Future<void> _enableWakelock() async {
    if (!_wakelockEnabled) {
      try {
        // Use partial wakelock - allows screen to turn off but keeps CPU active for audio
        await WakelockPlus.enable();
        _wakelockEnabled = true;
        debugPrint(
            '🔒 Partial wakelock enabled - screen can turn off, audio continues');
      } catch (e) {
        debugPrint('⚠️ Failed to enable partial wakelock: $e');
      }
    }
  }

  /// Disable wakelock to allow device to sleep
  Future<void> _disableWakelock() async {
    if (_wakelockEnabled) {
      try {
        await WakelockPlus.disable();
        _wakelockEnabled = false;
        debugPrint('🔓 Wakelock disabled');
      } catch (e) {
        debugPrint('⚠️ Failed to disable wakelock: $e');
      }
    }
  }

  /// Check and request battery optimization settings for background audio
  Future<void> ensureBatteryOptimizationDisabled() async {
    try {
      final isOptimized = await _batteryService.isBatteryOptimizationEnabled();
      if (!isOptimized) {
        debugPrint(
            '🔋 Battery optimization is enabled, requesting to disable...');
        final success =
            await _batteryService.requestBatteryOptimizationDisabled();
        if (!success) {
          debugPrint('⚠️ Could not disable battery optimization automatically');
          debugPrint('ℹ️ ${_batteryService.getBatteryOptimizationMessage()}');
        }
      } else {
        debugPrint('✅ Battery optimization is already disabled');
      }
    } catch (e) {
      debugPrint('❌ Error checking battery optimization: $e');
    }
  }

  /// Initialize the audio service
  Future<void> initialize({PodcastPlayerProvider? playerProvider}) async {
    if (_isInitialized) return;

    try {
      _playerProvider = playerProvider;

      // Configure audio session for background playback with simplified settings
      _audioSession = await AudioSession.instance;

      // Add a small delay to ensure iOS audio system is ready
      await Future.delayed(Duration(milliseconds: 100));

      // Try the full configuration first
      try {
        await _audioSession!.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth |
                  AVAudioSessionCategoryOptions.allowAirPlay,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.audibilityEnforced,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ));
        debugPrint('✅ Audio session configured with full options');
      } catch (e) {
        debugPrint(
            '⚠️ Full audio session config failed, trying simplified: $e');

        // Fallback to simplified configuration
        await _audioSession!.configure(AudioSessionConfiguration.music());
        debugPrint('✅ Audio session configured with simplified settings');
      }

      // Set up audio player event listeners
      _setupAudioPlayerListeners();

      // Note: Media session service will be initialized by PodcastPlayerProvider
      // to avoid duplicate initialization

      // Check battery optimization settings for background audio
      await ensureBatteryOptimizationDisabled();

      // Initialize smart buffering service
      await _bufferingService.initialize();

      // Initialize thermal optimization service
      await _thermalService.initialize();

      _isInitialized = true;
      debugPrint('✅ AudioPlayerService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AudioPlayerService: $e');

      // If audio session configuration fails, try to continue with minimal setup
      if (e.toString().contains('OSStatus error -50') ||
          e.toString().contains('PlatformException(-50')) {
        debugPrint(
            '⚠️ Audio session configuration failed, continuing with minimal setup');
        try {
          // Try to set up just the audio player without session configuration
          _setupAudioPlayerListeners();
          _isInitialized = true;
          debugPrint('✅ AudioPlayerService initialized with minimal setup');
        } catch (fallbackError) {
          debugPrint('❌ Even minimal setup failed: $fallbackError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Set up audio player event listeners
  void _setupAudioPlayerListeners() {
    // Position updates - stream with thermal optimization
    _audioPlayer.positionStream.listen((position) {
      if (_playerProvider != null) {
        // Only update if not in thermal throttling mode or update is significant
        if (!_thermalService.shouldReduceUpdateFrequency() ||
            position.inSeconds % 2 == 0) {
          // Update every 2 seconds during throttling
          _playerProvider!.updatePosition(position);
        }

        // Auto-save progress with thermal-aware intervals
        _autoSaveProgress(position);
      }
    });

    // Duration updates
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null && _playerProvider != null) {
        _playerProvider!.updateDuration(duration);
      }
    });

    // Playing state changes - sync with provider
    _audioPlayer.playingStream.listen((isPlaying) {
      if (_playerProvider != null) {
        // Update provider state without calling play/pause methods
        _playerProvider!.syncPlayingState(isPlaying);
      }
    });

    // Playback state changes with thermal-aware logging
    _audioPlayer.playerStateStream.listen((state) {
      if (_playerProvider != null) {
        // Only log if verbose debug is enabled and not in thermal throttling
        if (_verboseDebug && !_thermalService.isThermalThrottling) {
          debugPrint('🎵 Audio player state changed: ${state.processingState}');
        }

        switch (state.processingState) {
          case ProcessingState.completed:
            if (_verboseDebug) debugPrint('🎯 Episode completed detected!');
            _handlePlaybackCompleted();
            break;
          case ProcessingState.ready:
            if (_verboseDebug) debugPrint('✅ Audio is ready to play');
            break;
          case ProcessingState.buffering:
            if (_verboseDebug) debugPrint('⏳ Audio is buffering');
            break;
          case ProcessingState.idle:
            if (_verboseDebug) debugPrint('💤 Audio is idle');
            break;
          case ProcessingState.loading:
            if (_verboseDebug) debugPrint('📥 Audio is loading');
            break;
        }
      }
    });
  }

  /// Auto-save progress to avoid losing playback position
  void _autoSaveProgress(Duration position) {
    if (_playerProvider != null && _playerProvider!.currentEpisode != null) {
      final episode = _playerProvider!.currentEpisode!;
      final duration = _playerProvider!.duration;

      // Save progress more frequently for better tracking
      final shouldSave = _shouldSaveProgress(position, duration);

      if (shouldSave) {
        // Save progress immediately
        _playerProvider!.updateEpisodeProgress(episode, position, duration);

        // Update last saved position
        _lastSavedPosition = position;

        // Reduce debug noise during playback - only log significant saves
        if (position.inSeconds % 30 == 0) {
          // Log every 30 seconds instead of every save
          debugPrint(
              '💾 Auto-saved progress: ${episode.title} at ${position.inSeconds}s');
        }
      }
    }
  }

  /// Determine if progress should be saved based on time and position changes
  bool _shouldSaveProgress(Duration position, Duration duration) {
    // Get thermal-aware save interval
    final saveInterval =
        _thermalService.getOptimalProgressSaveInterval().inSeconds;

    // Save based on thermal-optimized interval
    if (position.inSeconds % saveInterval == 0) return true;

    // Save if position changed by more than 30 seconds (less sensitive to reduce noise)
    final lastSavedPosition = _lastSavedPosition;
    if (lastSavedPosition != null) {
      final difference = (position - lastSavedPosition).abs();
      if (difference.inSeconds > 30) return true;
    }

    // Save if this is the first position update
    if (lastSavedPosition == null) return true;

    // Save if we're near the end (last 10% of episode)
    if (duration.inMilliseconds > 0) {
      final progressRatio = position.inMilliseconds / duration.inMilliseconds;
      if (progressRatio >= 0.9) return true; // Save frequently near completion
    }

    return false;
  }

  // Track last saved position to avoid unnecessary saves
  Duration? _lastSavedPosition;

  /// Play an episode
  Future<void> playEpisode(Episode episode,
      {bool skipResumeLogic = false}) async {
    try {
      debugPrint('=== AUDIO SERVICE: PLAYING EPISODE ===');
      debugPrint('Episode title: ${episode.title}');
      debugPrint('Episode audioUrl: ${episode.audioUrl}');
      debugPrint('Episode data: ${episode.toJson()}');
      debugPrint('Skip resume logic: $skipResumeLogic');

      if (!_isInitialized) {
        debugPrint('Audio service not initialized, initializing now...');
        await initialize();
      }

      // Update player provider FIRST with the new episode
      if (_playerProvider != null) {
        _playerProvider!.setCurrentEpisode(episode, preservePlayingState: true);
        // Set playing state to true since we're about to start playback
        _playerProvider!.syncPlayingState(true);
      }

      // Check if we're already playing this episode
      final currentSource = _audioPlayer.audioSource;
      final isSameEpisode = currentSource != null &&
          currentSource.toString().contains(episode.audioUrl ?? '');

      if (isSameEpisode) {
        debugPrint('Same episode, resuming playback...');
        await _audioPlayer.play();
        return;
      }

      // Set audio source
      if (episode.audioUrl != null && episode.audioUrl!.isNotEmpty) {
        debugPrint('🔊 Setting audio source to: ${episode.audioUrl}');

        try {
          // Check if the audio URL is a local file path
          if (episode.audioUrl!.startsWith('/') ||
              episode.audioUrl!.startsWith('file://')) {
            // Local file - use setFilePath
            debugPrint('🔊 Loading local file: ${episode.audioUrl}');

            // Check if file exists
            final file = File(episode.audioUrl!);
            final exists = await file.exists();
            debugPrint('🔊 Local file exists: $exists');

            if (!exists) {
              throw Exception('Local file does not exist: ${episode.audioUrl}');
            }

            await _audioPlayer.setFilePath(episode.audioUrl!);
            debugPrint('✅ Local file path set successfully');
          } else if (episode.audioUrl!.startsWith('http://') ||
              episode.audioUrl!.startsWith('https://')) {
            // Remote URL - use setUrl
            debugPrint('🔊 Loading remote URL: ${episode.audioUrl}');
            await _audioPlayer.setUrl(episode.audioUrl!, headers: {
              'User-Agent': 'Pelevo/4.0.1 (Flutter; Android; iOS)',
            });
            debugPrint('✅ Remote URL set successfully');
          } else {
            debugPrint('❌ Invalid audio URL format: ${episode.audioUrl}');
            throw Exception(
                'Invalid audio URL format. URL must start with http://, https://, file://, or be a local file path');
          }
          debugPrint('✅ Audio source set successfully');

          // Wait for audio to be ready before seeking
          debugPrint('🔊 Waiting for audio to be ready...');
          await _audioPlayer.playerStateStream
              .firstWhere(
            (state) => state.processingState == ProcessingState.ready,
          )
              .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('❌ Timeout waiting for audio to be ready');
              throw Exception('Timeout loading audio source');
            },
          );
          debugPrint('✅ Audio is ready for playback');
        } catch (e) {
          debugPrint('❌ Error setting audio URL: $e');
          debugPrint('❌ Audio URL that failed: ${episode.audioUrl}');
          throw Exception('Failed to load audio source: $e');
        }

        // Only handle resume logic if not already handled by provider
        if (!skipResumeLogic) {
          debugPrint('🔄 Audio service handling resume logic...');
          await _handleResumeFromProgress(episode);
        } else {
          debugPrint('🔄 Skipping resume logic - already handled by provider');
        }

        // Start smart buffering before playback
        debugPrint('Starting smart buffering...');
        await _bufferingService.startSmartBuffering(episode, _audioPlayer);

        // Start playback
        debugPrint('Starting audio playback...');
        await _audioPlayer.play();

        // Note: Wake lock removed to allow screen to sleep during audio playback

        // Update media session for lock screen
        await _updateMediaSession();

        debugPrint('✅ Successfully started playing episode: ${episode.title}');
      } else {
        debugPrint('❌ No audio URL available for episode');
        debugPrint('Episode data: ${episode.toJson()}');
        debugPrint('Episode audioUrl field: ${episode.audioUrl}');
        debugPrint('Episode audioUrl is null: ${episode.audioUrl == null}');
        debugPrint(
            'Episode audioUrl is empty: ${episode.audioUrl?.isEmpty ?? true}');

        // Reset playing state if no audio URL
        if (_playerProvider != null) {
          _playerProvider!.syncPlayingState(false);
        }
        throw Exception('No audio URL available for episode: ${episode.title}');
      }
    } catch (e) {
      debugPrint('❌ Error playing episode: $e');
      // Reset playing state on error
      if (_playerProvider != null) {
        _playerProvider!.syncPlayingState(false);
      }
      rethrow;
    }
  }

  /// Handle resume functionality from saved progress
  Future<void> _handleResumeFromProgress(Episode episode) async {
    try {
      // First check if episode has local progress data
      if (episode.lastPlayedPosition != null &&
          episode.lastPlayedPosition! > 0) {
        final savedPosition =
            Duration(milliseconds: episode.lastPlayedPosition!);
        final savedDuration = episode.totalDuration != null
            ? Duration(milliseconds: episode.totalDuration!)
            : Duration.zero;

        debugPrint(
            '🔄 Found local progress: ${savedPosition.inSeconds}s / ${savedDuration.inSeconds}s');

        // Only resume if progress is significant (>10% and not completed)
        if (savedDuration.inMilliseconds > 0) {
          final progressPercentage =
              (savedPosition.inMilliseconds / savedDuration.inMilliseconds) *
                  100;

          if (progressPercentage > 10.0 && progressPercentage < 90.0) {
            debugPrint(
                '🔄 Resuming from local progress: ${progressPercentage.toStringAsFixed(1)}%');
            await _resumeToPosition(savedPosition, savedDuration);
            return;
          } else if (progressPercentage >= 90.0) {
            debugPrint(
                '📝 Episode nearly completed (${progressPercentage.toStringAsFixed(1)}%), starting from beginning');
            return;
          }
        }
      }

      // If no local progress or insufficient progress, check with progress service
      if (_playerProvider != null) {
        final currentPosition = _playerProvider!.position;
        final currentDuration = _playerProvider!.duration;

        if (currentPosition.inMilliseconds > 0 &&
            currentDuration.inMilliseconds > 0) {
          final progressPercentage = (currentPosition.inMilliseconds /
                  currentDuration.inMilliseconds) *
              100;

          if (progressPercentage > 10.0 && progressPercentage < 90.0) {
            debugPrint(
                '🔄 Resuming from provider progress: ${progressPercentage.toStringAsFixed(1)}%');
            await _resumeToPosition(currentPosition, currentDuration);
            return;
          }
        }
      }

      debugPrint('📝 No significant progress found, starting from beginning');
    } catch (e) {
      debugPrint('⚠️ Error handling resume: $e');
      // Continue without resume on error
    }
  }

  /// Resume playback to a specific position
  Future<void> _resumeToPosition(Duration position, Duration duration) async {
    try {
      debugPrint(
          '🔄 Seeking to resume position: ${position.inSeconds}s / ${duration.inSeconds}s');

      // Seek to the saved position
      await _audioPlayer.seek(position);

      // Update provider with restored position and duration
      if (_playerProvider != null) {
        _playerProvider!.updatePosition(position);
        _playerProvider!.updateDuration(duration);
      }

      debugPrint('✅ Successfully resumed to position: ${position.inSeconds}s');
    } catch (e) {
      debugPrint('⚠️ Error seeking to resume position: $e');
      // Continue without resume on error
    }
  }

  /// Resume playback
  Future<void> play() async {
    try {
      debugPrint('AudioService play(): Resuming playback');
      debugPrint(
          'AudioService play(): Current position: ${_audioPlayer.position.inSeconds}s');
      debugPrint(
          'AudioService play(): Current duration: ${_audioPlayer.duration?.inSeconds}s');
      debugPrint(
          'AudioService play(): Has audio source: ${_audioPlayer.audioSource != null}');

      // Check if we need to restore position from provider
      if (_playerProvider != null &&
          _audioPlayer.position.inMilliseconds == 0) {
        final providerPosition = _playerProvider!.position;
        if (providerPosition.inMilliseconds > 0) {
          debugPrint(
              'AudioService play(): Restoring position to: ${providerPosition.inSeconds}s');
          await _audioPlayer.seek(providerPosition);
        }
      }

      await _audioPlayer.play();

      // Enable partial wakelock for background audio playback (screen can turn off)
      await _enableWakelock();

      // Update media session for lock screen
      await _updateMediaSession();

      debugPrint('AudioService play(): Playback resumed successfully');
      // Don't call provider.play() here to avoid circular dependency
      // The playingStream listener will update the provider state
    } catch (e) {
      debugPrint('Error resuming playback: $e');
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();

      // Disable wakelock when pausing
      await _disableWakelock();

      // Update media session for lock screen
      await _updateMediaSession();

      // Don't call provider.pause() here to avoid circular dependency
      // The playingStream listener will update the provider state
    } catch (e) {
      debugPrint('Error pausing playback: $e');
      rethrow;
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();

      // Disable wakelock when stopping
      await _disableWakelock();

      if (_playerProvider != null) {
        _playerProvider!.pause();
        _playerProvider!.updatePosition(Duration.zero);
      }
    } catch (e) {
      debugPrint('Error stopping playback: $e');
      rethrow;
    }
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    try {
      debugPrint('🎵 AudioPlayerService: Seeking to ${position.inSeconds}s');
      await _audioPlayer.seek(position);

      // Update provider position without triggering another seek call
      if (_playerProvider != null) {
        _playerProvider!.updatePosition(position);
      }

      debugPrint('🎵 AudioPlayerService: Seek completed successfully');
    } catch (e) {
      debugPrint('❌ Error seeking to position: $e');
      rethrow;
    }
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      debugPrint('🎵 AudioPlayerService: Setting playback speed to ${speed}x');
      await _audioPlayer.setSpeed(speed);
      debugPrint('🎵 AudioPlayerService: Playback speed set successfully');

      // Don't call playerProvider.setPlaybackSpeed here to avoid circular calls
      // The provider will handle the state update
    } catch (e) {
      debugPrint('❌ Error setting playback speed: $e');
      rethrow;
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting volume: $e');
      rethrow;
    }
  }

  /// Get current volume
  double get volume => _audioPlayer.volume;

  /// Apply trim silence effect (placeholder for future implementation)
  Future<void> setTrimSilence(bool enabled) async {
    try {
      // TODO: Implement actual trim silence functionality
      // This would require audio processing capabilities
      debugPrint('Trim silence ${enabled ? 'enabled' : 'disabled'}');

      // For now, we'll just log the setting
      // In a production app, this would integrate with audio processing libraries
      // like flutter_sound, audio_waveforms, or custom audio processing
    } catch (e) {
      debugPrint('Error setting trim silence: $e');
      rethrow;
    }
  }

  /// Apply volume boost effect
  Future<void> setVolumeBoost(bool enabled) async {
    try {
      if (enabled) {
        // Boost volume by 20% (clamp to max 1.0)
        final currentVolume = _audioPlayer.volume;
        final boostedVolume = (currentVolume * 1.2).clamp(0.0, 1.0);
        await _audioPlayer.setVolume(boostedVolume);
        debugPrint(
            'Volume boost enabled: ${currentVolume} -> ${boostedVolume}');
      } else {
        // Restore normal volume (reduce by 20% to get back to original)
        final currentVolume = _audioPlayer.volume;
        final normalVolume = (currentVolume / 1.2).clamp(0.0, 1.0);
        await _audioPlayer.setVolume(normalVolume);
        debugPrint(
            'Volume boost disabled: ${currentVolume} -> ${normalVolume}');
      }
    } catch (e) {
      debugPrint('Error setting volume boost: $e');
      rethrow;
    }
  }

  /// Get current audio effects state
  Map<String, dynamic> getAudioEffectsState() {
    return {
      'volume': _audioPlayer.volume,
      'speed': _audioPlayer.speed,
      'isPlaying': _audioPlayer.playing,
    };
  }

  /// Handle playback completion
  void _handlePlaybackCompleted() {
    debugPrint('🎯 Playback completed, handling completion logic...');
    debugPrint('🎯 Player provider available: ${_playerProvider != null}');

    if (_playerProvider != null) {
      debugPrint(
          '🎯 Current episode: ${_playerProvider!.currentEpisode?.title}');
      debugPrint(
          '🎯 Episode queue length: ${_playerProvider!.episodeQueue.length}');
      debugPrint(
          '🎯 Current episode index: ${_playerProvider!.currentEpisodeIndex}');
      debugPrint('🎯 Auto-play next enabled: ${_playerProvider!.autoPlayNext}');
      debugPrint('🎯 Is repeating: ${_playerProvider!.isRepeating}');
      debugPrint('🎯 Is shuffled: ${_playerProvider!.isShuffled}');

      // Don't pause here - let the completion logic handle the state
      // Just reset position for the completed episode
      _playerProvider!.updatePosition(Duration.zero);

      // Check repeat mode first (highest priority)
      if (_playerProvider!.isRepeating) {
        debugPrint('🔁 Repeat mode enabled, repeating current episode...');

        // Add a small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 300), () {
          try {
            debugPrint('🔁 Seeking to beginning for repeat...');

            // Seek to beginning and play again
            seekTo(Duration.zero).then((_) {
              debugPrint('🔁 Repeat: Seeking completed, starting playback...');
              play();
            }).catchError((e) {
              debugPrint('❌ Error seeking to beginning for repeat: $e');
              // Fallback: try to recover
              _handleAutoPlayFailure();
            });
          } catch (e) {
            debugPrint('❌ Error in repeat logic: $e');
            _handleAutoPlayFailure();
          }
        });
      }
      // Then check auto-play next episode
      else if (_playerProvider!.autoPlayNext) {
        debugPrint(
            '🔄 Auto-play next enabled, attempting to play next episode...');

        // Add a small delay to ensure smooth transition
        Future.delayed(Duration(milliseconds: 300), () {
          try {
            debugPrint('🔄 Calling playNext() from audio service...');
            debugPrint('🔄 About to call playerProvider.playNext()...');

            // Check if provider is still valid
            if (_playerProvider != null) {
              debugPrint(
                  '🔄 Player provider is still valid, calling playNext()...');
              _playerProvider!.playNext();
              debugPrint('🔄 playNext() call completed successfully');
            } else {
              debugPrint(
                  '❌ Player provider is null when trying to call playNext()');
            }
          } catch (e) {
            debugPrint('❌ Error in auto-play next: $e');
            debugPrint('❌ Error stack trace: ${StackTrace.current}');
            // If auto-play fails, try to recover
            _handleAutoPlayFailure();
          }
        });
      } else {
        debugPrint('⏸️ No repeat or auto-play enabled, stopping playback');
        // Only pause if neither repeat nor auto-play is enabled
        _playerProvider!.pause();
      }
    } else {
      debugPrint('⚠️ No player provider available for completion handling');
    }
  }

  /// Handle auto-play failures gracefully
  void _handleAutoPlayFailure() {
    if (_playerProvider != null) {
      debugPrint('🔄 Attempting to recover from auto-play failure...');

      // Try to find the next playable episode in the queue
      final currentIndex = _playerProvider!.currentEpisodeIndex;
      final episodeQueue = _playerProvider!.episodeQueue;

      if (episodeQueue.isNotEmpty && currentIndex < episodeQueue.length - 1) {
        // Look for the next playable episode
        for (int i = currentIndex + 1; i < episodeQueue.length; i++) {
          final episode = episodeQueue[i];
          if (episode.audioUrl != null && episode.audioUrl!.isNotEmpty) {
            debugPrint(
                '🔄 Found playable episode at index $i: ${episode.title}');

            // Update the provider state
            _playerProvider!
                .setCurrentEpisode(episode, preservePlayingState: false);
            _playerProvider!.play();
            return;
          }
        }
      }

      debugPrint('❌ No playable episodes found for auto-play recovery');
      // Reset playing state
      _playerProvider!.syncPlayingState(false);
    }
  }

  /// Set sleep timer
  Future<void> setSleepTimer(Duration duration) async {
    try {
      if (duration > Duration.zero) {
        // Cancel existing timer if any
        await _audioPlayer.stop();

        // Set up new timer
        Future.delayed(duration, () {
          if (_audioPlayer.playing) {
            pause();
          }
        });

        if (_playerProvider != null) {
          _playerProvider!.setSleepTimer(duration);
        }
      }
    } catch (e) {
      debugPrint('Error setting sleep timer: $e');
    }
  }

  /// Clear sleep timer
  void clearSleepTimer() {
    if (_playerProvider != null) {
      _playerProvider!.clearSleepTimer();
    }
  }

  /// Update player provider reference
  void setPlayerProvider(PodcastPlayerProvider provider) {
    _playerProvider = provider;
  }

  /// Set episode for media session
  void setEpisode(Episode episode) {
    _mediaSessionService.setEpisode(episode);
  }

  /// Get current audio source
  AudioSource? get currentAudioSource => _audioPlayer.audioSource;

  /// Check if audio is ready
  bool get isReady => _audioPlayer.processingState == ProcessingState.ready;

  /// Check if audio is buffering
  bool get isBuffering =>
      _audioPlayer.processingState == ProcessingState.buffering;

  /// Check if audio is completed
  bool get isCompleted =>
      _audioPlayer.processingState == ProcessingState.completed;

  /// Get buffered position
  Duration get bufferedPosition => _audioPlayer.bufferedPosition;

  /// Get audio session
  AudioSession? get audioSession => _audioSession;

  // Partial wakelock is used to allow screen to turn off while keeping audio playing
  // This ensures background audio playback works when screen is off

  /// Dispose resources
  Future<void> dispose() async {
    try {
      // Clear media session first
      await _mediaSessionService.dispose();

      // Dispose buffering service
      await _bufferingService.dispose();

      // Dispose thermal optimization service
      await _thermalService.dispose();

      await _audioPlayer.dispose();

      // Disable wakelock during cleanup
      await _disableWakelock();

      _isInitialized = false;
    } catch (e) {
      debugPrint('Error disposing AudioPlayerService: $e');
    }
  }

  /// Format duration to readable string
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Update media session for lock screen integration
  Future<void> _updateMediaSession() async {
    try {
      if (_playerProvider != null && _playerProvider!.currentEpisode != null) {
        final episode = _playerProvider!.currentEpisode!;
        final position = _playerProvider!.position;
        final duration = _playerProvider!.duration;
        final isPlaying = _playerProvider!.isPlaying;

        // Set the episode first
        _mediaSessionService.setEpisode(episode);

        // Update playback state
        _mediaSessionService.updatePlaybackState(
          isPlaying: isPlaying,
          position: position,
          duration: duration,
        );

        debugPrint('🎵 Media session updated for lock screen');
      }
    } catch (e) {
      debugPrint('❌ Error updating media session: $e');
    }
  }

  /// Save progress when user leaves an episode
  Future<void> saveProgressOnLeave() async {
    if (_playerProvider != null && _playerProvider!.currentEpisode != null) {
      final episode = _playerProvider!.currentEpisode!;
      final position = _playerProvider!.position;
      final duration = _playerProvider!.duration;

      debugPrint(
          '💾 Saving progress on leave: ${episode.title} at ${position.inSeconds}s');

      // Save progress immediately
      await _playerProvider!.updateEpisodeProgress(episode, position, duration);

      // Update last saved position
      _lastSavedPosition = position;
    }
  }

  /// Get saved progress for an episode
  int? getSavedProgress(String episodeId) {
    if (_playerProvider != null) {
      final episode = _playerProvider!.currentEpisode;
      if (episode != null && episode.id.toString() == episodeId) {
        return episode.lastPlayedPosition;
      }
    }
    return null;
  }

  /// Get buffering service for external access
  SmartBufferingService get bufferingService => _bufferingService;

  /// Check if currently buffering
  bool get isCurrentlyBuffering => _bufferingService.isBuffering;

  /// Get buffering progress (0.0 to 1.0)
  double get bufferingProgress => _bufferingService.bufferingProgress;

  /// Get buffering status message
  String get bufferingStatus => _bufferingService.getBufferingStatus();

  /// Set buffering strategy
  void setBufferingStrategy(BufferingStrategy strategy) {
    _bufferingService.setBufferingStrategy(strategy);
  }

  /// Get buffering statistics
  Map<String, dynamic> getBufferingStats() {
    return _bufferingService.getBufferingStats();
  }

  /// Enable battery saving mode to reduce heating
  void enableBatterySavingMode(bool enabled) {
    _thermalService.enableBatterySavingMode(enabled);
    debugPrint('🔋 Battery saving mode ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if thermal throttling is active
  bool get isThermalThrottling => _thermalService.isThermalThrottling;

  /// Get estimated device temperature
  double get estimatedTemperature => _thermalService.estimatedTemperature;

  /// Force thermal cooling (pause briefly to cool device)
  Future<void> forceThermalCooling() async {
    await _thermalService.forceThermalCooling();
  }

  /// Get thermal statistics
  Map<String, dynamic> getThermalStats() {
    return _thermalService.getThermalStats();
  }

  /// Get thermal service for external access
  ThermalOptimizationService get thermalService => _thermalService;
}
