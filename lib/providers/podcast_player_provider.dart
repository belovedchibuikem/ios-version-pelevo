import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/episode.dart';
import '../services/audio_player_service.dart';
import '../services/episode_progress_service.dart';
import '../providers/episode_progress_provider.dart';
import '../widgets/floating_mini_player_overlay.dart';
import '../core/services/service_manager.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/persistent_state_manager.dart';
import '../core/services/playback_persistence_service.dart';
import '../core/services/media_session_service.dart';
import '../services/playback_effects_service.dart';

class PodcastPlayerProvider extends ChangeNotifier {
  // Audio service
  final AudioPlayerService _audioService = AudioPlayerService();

  // Media session service
  final MediaSessionService _mediaSessionService = MediaSessionService();

  // Local storage and sync services
  LocalStorageService? _localStorage;
  ServiceManager? _serviceManager;
  final EpisodeProgressService _progressService = EpisodeProgressService();
  EpisodeProgressProvider? _progressProvider;
  PlaybackPersistenceService? _playbackPersistenceService;
  final PlaybackEffectsService _playbackEffectsService =
      PlaybackEffectsService();

  // Player UI States
  bool _isMinimized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isPaused = false;
  bool _isIntentionallyPaused =
      false; // Track intentional pause to prevent auto-resume
  bool _isEpisodeDetailModalOpen = false;

  // Playback State
  Duration _position = Duration.zero;
  Duration? _duration;
  double _playbackSpeed = 1.0;
  bool _isShuffled = false;
  bool _isRepeating = false; // Default to false

  // Episode Data
  Episode? _currentEpisode;
  List<Episode> _episodeQueue = [];
  int _currentEpisodeIndex = 0;
  String? _currentPodcastId; // Store the current podcast ID
  Map<String, dynamic>? _currentPodcastData; // Store the current podcast data

  // Player Settings
  bool _autoPlayNext = true;
  bool _showSleepTimer = false;
  // Note: _keepScreenOn removed to allow screen to sleep during audio playback
  Duration _sleepTimerDuration = Duration.zero;

  // Mini-player persistence settings
  bool _isMiniPlayerExplicitlyClosed = false;
  bool _shouldShowMiniPlayerPersistently = true;

  // Add persistent state manager
  final PersistentStateManager _persistentStateManager =
      PersistentStateManager();

  // Throttling constants for real-time updates
  static const Duration _positionUpdateThrottle = Duration(milliseconds: 500);

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isPaused => _isPaused;
  bool get isMinimized => _isMinimized;
  bool get isEpisodeDetailModalOpen => _isEpisodeDetailModalOpen;
  Duration get position => _position;
  Duration get duration => _duration ?? Duration.zero;
  double get playbackSpeed => _playbackSpeed;
  bool get isShuffled => _isShuffled;
  bool get isRepeating => _isRepeating;
  Episode? get currentEpisode => _currentEpisode;
  List<Episode> get episodeQueue => _episodeQueue;
  int get currentEpisodeIndex => _currentEpisodeIndex;
  String? get currentPodcastId => _currentPodcastId;
  Map<String, dynamic>? get currentPodcastData => _currentPodcastData;
  bool get autoPlayNext => _autoPlayNext;
  bool get showSleepTimer => _showSleepTimer;
  // Note: keepScreenOn getter removed - screen now sleeps naturally during audio playback
  Duration get sleepTimerDuration => _sleepTimerDuration;
  bool get isMiniPlayerExplicitlyClosed => _isMiniPlayerExplicitlyClosed;
  bool get shouldShowMiniPlayerPersistently =>
      _shouldShowMiniPlayerPersistently;

  // Progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (_duration == null || _duration!.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration!.inMilliseconds;
  }

  // Formatted position strings
  String get formattedPosition => _formatDuration(_position);
  String get formattedDuration => _formatDuration(_duration ?? Duration.zero);
  String get formattedRemainingTime => _formatDuration(_duration! - _position);

  PodcastPlayerProvider() {
    _loadPlayerState();
    _initializeAudioService();
    _initializeServices();
  }

  Future<void> _initializeAudioService() async {
    try {
      debugPrint(
          '🎵 PodcastPlayerProvider: Initializing audio service with provider: ${this != null}');
      await _audioService.initialize(playerProvider: this);
      _audioService.setPlayerProvider(this);

      // Initialize media session service with a small delay to ensure provider is ready
      debugPrint(
          '🎵 PodcastPlayerProvider: Initializing media session service with provider: ${this != null}');
      await Future.delayed(Duration(milliseconds: 100));
      await _mediaSessionService.initialize(playerProvider: this);
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
    }
  }

  // Initialize local storage and sync services
  Future<void> _initializeServices() async {
    try {
      // Get service manager from provider context
      // This will be set when the provider is created with context
      debugPrint('🔄 Initializing podcast player services...');
    } catch (e) {
      debugPrint('❌ Error initializing podcast player services: $e');
    }
  }

  /// Clear old episode data and prepare for new series
  Future<void> _clearOldEpisodeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear old episode queue data
      await prefs.remove('player_episode_queue');
      await prefs.remove('player_current_episode');
      await prefs.remove('player_current_index');
      await prefs.remove('player_position_ms');
      await prefs.remove('player_duration_ms');

      debugPrint('🗑️ Cleared old episode data from local storage');
    } catch (e) {
      debugPrint('❌ Error clearing old episode data: $e');
    }
  }

  // MARK: - Episode Management

  /// Set the current episode and update player state
  void setCurrentEpisode(Episode episode, {bool preservePlayingState = false}) {
    // Check if this is the same episode
    final isSameEpisode = _currentEpisode?.id == episode.id;

    // Save progress of current episode before switching (if different episode)
    if (!isSameEpisode &&
        _currentEpisode != null &&
        _position.inMilliseconds > 0) {
      _saveProgressBeforeSwitching();
    }

    // Update progress provider for episode switching
    if (!isSameEpisode && _progressProvider != null) {
      final previousEpisodeId = _currentEpisode?.id.toString();
      _progressProvider!
          .onEpisodeSwitched(episode.id.toString(), previousEpisodeId);
    }

    _currentEpisode = episode;

    // Only reset position and duration if it's a different episode
    if (!isSameEpisode) {
      _position = Duration.zero;
      _duration = Duration.zero;

      // Update episode queue to ensure the new episode is properly positioned
      _updateEpisodeQueueForNewEpisode(episode);

      // Update media session with new episode (including artwork)
      _updateMediaSessionWithEpisode(episode);
    }

    // Only reset playing state if not preserving it AND it's a different episode
    if (!preservePlayingState && !isSameEpisode) {
      _isPlaying = false;
    }

    // Reset mini-player explicit close state when starting a new episode
    if (!isSameEpisode) {
      resetMiniPlayerExplicitCloseState();
    }

    _savePlayerState();

    // Also save to persistent storage
    if (_persistentStateManager != null) {
      _persistentStateManager.savePlayerState({
        'episode_id': episode.id,
        'episode_title': episode.title,
        'podcast_title': episode.podcastName,
        'position': _position.inMilliseconds,
        'duration': _duration?.inMilliseconds ?? 0,
        'is_playing': _isPlaying,
        'playback_speed': _playbackSpeed,
        'episode_queue': _episodeQueue.map((e) => e.toJson()).toList(),
        'current_queue_index': _currentEpisodeIndex,
        'timestamp': DateTime.now().toIso8601String(),
        'podcast_id': _currentPodcastId,
      });
    }

    notifyListeners();

    debugPrint(
        '✅ Current episode set: ${episode.title} (same: $isSameEpisode, preserve: $preservePlayingState)');
  }

  /// Save progress before switching to a new episode
  Future<void> _saveProgressBeforeSwitching() async {
    try {
      if (_currentEpisode != null && _position.inMilliseconds > 0) {
        debugPrint(
            '💾 Saving progress before switching: ${_currentEpisode!.title} at ${_position.inSeconds}s');
        await updateEpisodeProgress(
            _currentEpisode!, _position, _duration ?? Duration.zero);
      }
    } catch (e) {
      debugPrint('⚠️ Error saving progress before switching: $e');
    }
  }

  /// Update episode queue to ensure proper positioning of new episode
  void _updateEpisodeQueueForNewEpisode(Episode newEpisode) {
    try {
      // Find the episode in the current queue
      final existingIndex =
          _episodeQueue.indexWhere((e) => e.id == newEpisode.id);

      if (existingIndex != -1) {
        // Episode exists in queue, update current index
        _currentEpisodeIndex = existingIndex;
        debugPrint('🔄 Episode found in queue at index $_currentEpisodeIndex');
      } else {
        // Episode not in queue, add it and set as current
        _episodeQueue.add(newEpisode);
        _currentEpisodeIndex = _episodeQueue.length - 1;
        debugPrint('🔄 Episode added to queue at index $_currentEpisodeIndex');
      }

      // Ensure queue doesn't get too long
      if (_episodeQueue.length > 100) {
        _episodeQueue.removeRange(0, 50);
        _currentEpisodeIndex =
            _currentEpisodeIndex > 50 ? _currentEpisodeIndex - 50 : 0;
        debugPrint('🔄 Queue trimmed to prevent memory issues');
      }
    } catch (e) {
      debugPrint('⚠️ Error updating episode queue: $e');
    }
  }

  /// Update media session with current episode (including artwork)
  void _updateMediaSessionWithEpisode(Episode episode) {
    try {
      // Use the audio service's media session service that was initialized with this provider
      _audioService.setEpisode(episode);
      debugPrint(
          '🎨 Updated MediaSession with episode artwork: ${episode.coverImage}');
    } catch (e) {
      debugPrint('⚠️ Failed to update MediaSession with episode: $e');
    }
  }

  /// Load and play a new episode
  Future<void> loadAndPlayEpisode(Episode episode,
      {bool clearQueue = true, BuildContext? context}) async {
    try {
      debugPrint(
          'Provider loadAndPlayEpisode(): Loading episode: ${episode.title}');

      // Set buffering state
      _isBuffering = true;
      _isPlaying = false;
      _isPaused = false;
      notifyListeners();

      // Only clear old episode queue when manually playing a new episode (not from episode detail modal)
      if (clearQueue) {
        debugPrint('🔄 Manual episode selection - clearing old episode queue');
        _episodeQueue.clear();
        _currentEpisodeIndex = 0;

        // Clear old episode data from local storage
        await _clearOldEpisodeData();
      } else {
        debugPrint(
            '🔄 Episode detail modal - preserving episode queue for auto-play');
      }

      // Set the current episode with preserved playing state for smooth transitions
      setCurrentEpisode(episode, preservePlayingState: true);

      // Check for saved progress first
      final hasResumePoint = await _checkForResumePoint(episode);

      if (hasResumePoint) {
        // Don't start playing automatically - wait for user to choose Continue or Start Over
        debugPrint('🔄 Episode has resume point - waiting for user choice');
        _isBuffering = false;
        notifyListeners();
        return; // Exit early, don't start playing
      } else {
        // No resume point, start playing normally from the beginning
        debugPrint(
            '🔄 No resume point found - starting playback from beginning');
        await _audioService.playEpisode(episode, skipResumeLogic: true);
      }

      // Set playing state to true after successful load
      _isPlaying = true;
      _isBuffering = false;
      _isPaused = false;

      // Save the updated state
      _savePlayerState();
      notifyListeners();

      debugPrint('✅ Episode loaded and playing: ${episode.title}');

      // Refresh mini-player if it's visible to show new episode data
      if (isFloatingMiniPlayerVisible) {
        debugPrint('🔄 Refreshing mini-player with new episode data');
        // Note: We can't call refreshMiniPlayer here because we don't have context
        // The mini-player will be updated through the Consumer widget in the UI
      }

      // Show mini-player if context is provided and conditions are met
      if (context != null) {
        showMiniPlayerIfAppropriate(context);
      }
    } catch (e) {
      debugPrint('❌ Error loading and playing episode: $e');
      debugPrint('❌ Episode that failed: ${episode.title}');
      debugPrint('❌ Episode audioUrl: ${episode.audioUrl}');
      debugPrint('❌ Episode data: ${episode.toJson()}');

      _isPlaying = false;
      _isBuffering = false;
      _isPaused = false;
      notifyListeners();

      // Show user-friendly error message
      if (e.toString().contains('No audio URL')) {
        throw Exception('This episode has no audio file available');
      } else if (e.toString().contains('Invalid audio URL format')) {
        throw Exception('The audio file format is not supported');
      } else if (e.toString().contains('Timeout loading audio source')) {
        throw Exception(
            'The audio file is taking too long to load. Please check your internet connection.');
      } else if (e.toString().contains('Source error')) {
        throw Exception(
            'Unable to play this audio file. It may be corrupted or in an unsupported format.');
      } else {
        throw Exception('Failed to play episode: ${e.toString()}');
      }
    }
  }

  /// Check if episode has a resume point and show notification if it does
  Future<bool> _checkForResumePoint(Episode episode) async {
    try {
      debugPrint(
          '🔄 Checking for saved progress for episode: ${episode.title}');

      // Get saved progress from the progress service
      final savedProgress =
          await _progressService.getProgress(episode.id.toString());

      if (savedProgress != null && savedProgress.currentPosition > 0) {
        final resumePosition =
            Duration(milliseconds: savedProgress.currentPosition);
        final totalDuration =
            Duration(milliseconds: savedProgress.totalDuration);

        debugPrint(
            '✅ Found saved progress: ${resumePosition.inSeconds}s / ${totalDuration.inSeconds}s');

        // Check if episode was nearly completed (90% or more)
        if (savedProgress.isCompleted) {
          debugPrint('📝 Episode was completed, starting from beginning');
          return false; // No resume point for completed episodes
        }

        // Check if user wants to resume (position > 10% of total duration)
        final progressPercentage = savedProgress.progressPercentage;
        if (progressPercentage > 10.0) {
          debugPrint(
              '🔄 Episode has resume point: ${resumePosition.inSeconds}s (${progressPercentage.toStringAsFixed(1)}%)');

          // Set the position and duration for the audio service to resume from
          _position = resumePosition;
          _duration = totalDuration;

          // Update the current episode with the resume position so audio service can find it
          if (_currentEpisode != null) {
            _currentEpisode = _currentEpisode!.copyWith(
              lastPlayedPosition: resumePosition.inMilliseconds,
              totalDuration: totalDuration.inMilliseconds,
            );
          }

          // Show user feedback about resume
          _showResumeNotification(resumePosition, totalDuration);

          debugPrint(
              '✅ Resume notification shown: ${resumePosition.inSeconds}s / ${totalDuration.inSeconds}s');
          return true; // Has resume point
        } else {
          debugPrint(
              '📝 Progress too low (${progressPercentage.toStringAsFixed(1)}%), starting from beginning');
          return false; // No resume point
        }
      } else {
        debugPrint('📝 No saved progress found, starting from beginning');
        return false; // No resume point
      }
    } catch (e) {
      debugPrint('⚠️ Error checking saved progress: $e');
      return false; // Continue with default behavior (start from beginning)
    }
  }

  /// Show user notification about resume functionality
  void _showResumeNotification(
      Duration resumePosition, Duration totalDuration) {
    // This will be handled by the UI layer
    debugPrint(
        '🔄 Resume notification: Resuming from ${resumePosition.inSeconds}s of ${totalDuration.inSeconds}s total');

    // Notify listeners so UI can show resume notification
    notifyListeners();

    // Store resume info for UI to access
    _lastResumeInfo = {
      'position': resumePosition,
      'duration': totalDuration,
      'timestamp': DateTime.now(),
    };
  }

  // Resume notification data for UI
  Map<String, dynamic>? _lastResumeInfo;
  Map<String, dynamic>? get lastResumeInfo => _lastResumeInfo;

  /// Clear resume notification info
  void clearResumeInfo() {
    _lastResumeInfo = null;
    notifyListeners();
  }

  /// Handle Continue action from resume notification
  Future<void> continueFromResumePoint() async {
    try {
      debugPrint('🔄 Continue from resume point');

      if (_currentEpisode == null) {
        debugPrint('❌ No current episode to continue');
        return;
      }

      // Clear resume info first
      clearResumeInfo();

      // Start playing the episode (don't skip resume logic - let audio service handle it)
      await _audioService.playEpisode(_currentEpisode!, skipResumeLogic: false);

      // Set playing state
      _isPlaying = true;
      _isBuffering = false;
      _isPaused = false;
      notifyListeners();

      debugPrint('✅ Continued playback from resume point');
    } catch (e) {
      debugPrint('❌ Error continuing from resume point: $e');
      _isPlaying = false;
      _isBuffering = false;
      _isPaused = false;
      notifyListeners();
    }
  }

  /// Handle Start Over action from resume notification
  Future<void> startOverFromResumePoint() async {
    try {
      debugPrint('🔄 Start over from resume point');

      if (_currentEpisode == null) {
        debugPrint('❌ No current episode to start over');
        return;
      }

      // Clear resume info first
      clearResumeInfo();

      // Reset position to beginning
      _position = Duration.zero;

      // Start playing the episode from the beginning
      await _audioService.playEpisode(_currentEpisode!, skipResumeLogic: true);

      // Set playing state
      _isPlaying = true;
      _isBuffering = false;
      _isPaused = false;
      notifyListeners();

      debugPrint('✅ Started playback from beginning');
    } catch (e) {
      debugPrint('❌ Error starting over: $e');
      _isPlaying = false;
      _isBuffering = false;
      _isPaused = false;
      notifyListeners();
    }
  }

  // MARK: - Playback Control

  Future<void> play() async {
    try {
      // Clear the intentionally paused flag when user explicitly plays
      _isIntentionallyPaused = false;

      if (_currentEpisode != null) {
        debugPrint(
            'Provider play(): Playing current episode: ${_currentEpisode!.title}');
        debugPrint(
            'Provider play(): Current position: ${_position.inSeconds}s');
        debugPrint(
            'Provider play(): Current duration: ${_duration?.inSeconds ?? 0}s');

        // Check if we're already playing this episode
        if (_isPlaying) {
          debugPrint('Already playing, no action needed');
          return;
        }

        // Immediately update UI state for responsive feedback
        _isPlaying = true;
        notifyListeners();

        // Update media session
        _updateMediaSession();

        // Resume playback if episode is already loaded, otherwise load and play
        debugPrint('Provider play(): Calling _audioService.play() to resume');
        await _audioService.play();
      } else {
        debugPrint(
            'Provider play(): No current episode, calling audio service play()');
        // Immediately update UI state for responsive feedback
        _isPlaying = true;
        notifyListeners();

        // Update media session
        _updateMediaSession();

        await _audioService.play();
      }
      // The audio service listener will handle the final state sync
    } catch (e) {
      debugPrint('Error playing episode: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      // Mark as intentionally paused to prevent auto-resume
      _isIntentionallyPaused = true;

      // Immediately update UI state for responsive feedback
      _isPlaying = false;
      notifyListeners();

      // Update media session
      _updateMediaSession();

      await _audioService.pause();
      // The audio service listener will handle the final state sync
    } catch (e) {
      debugPrint('Error pausing episode: $e');
      // Keep the paused state on error
      _isPlaying = false;
      notifyListeners();
    }
  }

  void togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  void seekTo(Duration position) {
    debugPrint('🎵 Provider seekTo: Seeking to ${position.inSeconds}s');

    // Validate position is within bounds
    if (_duration != null &&
        _duration!.inMilliseconds > 0 &&
        position > _duration!) {
      position = _duration!;
      debugPrint('🎵 Provider seekTo: Clamped position to duration limit');
    }

    // Update position immediately for responsive UI
    _position = position;
    _savePlayerState();
    notifyListeners();

    // Update media session position
    _mediaSessionService.updatePosition(position);

    // Seek the actual audio player
    if (_audioService != null) {
      _audioService.seekTo(position).then((_) {
        debugPrint('🎵 Provider seekTo: Audio seek completed successfully');

        // Ensure playback continues after seeking if it was playing before
        if (_isPlaying) {
          debugPrint(
              '🎵 Provider seekTo: Playback was active, ensuring continuation');
          // The audio service should maintain playback state
          // If playback stopped during seek, resume it
          _ensurePlaybackContinuity();
        }
      }).catchError((error) {
        debugPrint('❌ Provider seekTo: Error during seek: $error');
        // Reset position on error
        _position = Duration.zero;
        notifyListeners();
      });
    } else {
      debugPrint('❌ Provider seekTo: Audio service not available');
    }
  }

  /// Ensure playback continues smoothly after seek operations
  void _ensurePlaybackContinuity() {
    // Small delay to allow seek to complete
    Future.delayed(const Duration(milliseconds: 100), () {
      // Only resume if we're still supposed to be playing AND not intentionally paused AND the audio service is available
      if (_isPlaying &&
          !_isIntentionallyPaused &&
          _audioService != null &&
          _currentEpisode != null) {
        // Check if playback actually stopped during seek
        final isActuallyPlaying = _audioService!.isPlaying;
        if (!isActuallyPlaying) {
          debugPrint('🎵 Provider: Resuming playback after seek');
          _audioService!.play().catchError((e) {
            debugPrint('❌ Error resuming playback after seek: $e');
          });
        }
      } else {
        debugPrint(
            '🎵 Provider: Not resuming playback - _isPlaying: $_isPlaying, _isIntentionallyPaused: $_isIntentionallyPaused, _audioService: ${_audioService != null}, _currentEpisode: ${_currentEpisode != null}');
      }
    });
  }

  void updatePosition(Duration position) {
    debugPrint(
        'Provider updatePosition: Updating from ${_position.inSeconds}s to ${position.inSeconds}s');
    _position = position;
    _savePlayerState();
    notifyListeners();
  }

  void updateDuration(Duration duration) {
    _duration = duration;
    _savePlayerState();
    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    debugPrint('🎵 PodcastPlayerProvider: Setting playback speed to ${speed}x');

    _playbackSpeed = speed;

    // Notify listeners immediately for UI updates
    notifyListeners();

    // Apply to audio service immediately
    if (_audioService != null) {
      _audioService.setPlaybackSpeed(speed).catchError((e) {
        debugPrint('❌ Error setting audio playback speed: $e');
      });
    }

    // Save to playback effects service (async, non-blocking)
    _playbackEffectsService.setPlaybackSpeed(speed).catchError((e) {
      debugPrint('❌ Error saving playback speed to effects service: $e');
    });

    // Save player state (async, non-blocking)
    _savePlayerState().catchError((e) {
      debugPrint('❌ Error saving player state: $e');
    });

    debugPrint('🎵 PodcastPlayerProvider: Playback speed set to ${speed}x');
  }

  /// Sync playing state from audio service (internal use only)
  void syncPlayingState(bool isPlaying) {
    if (_isPlaying != isPlaying) {
      _isPlaying = isPlaying;
      _savePlayerState();
      notifyListeners();
    }
  }

  // MARK: - Player UI State Management

  void toggleMinimized() {
    _isMinimized = !_isMinimized;
    _savePlayerState();
    notifyListeners();
  }

  void setMinimized(bool minimized) {
    _isMinimized = minimized;
    _savePlayerState();
    notifyListeners();
  }

  void openEpisodeDetailModal() {
    _isEpisodeDetailModalOpen = true;
    _isMinimized = false;
    _savePlayerState();
    notifyListeners();
  }

  void closeEpisodeDetailModal() {
    _isEpisodeDetailModalOpen = false;
    _savePlayerState();
    notifyListeners();
  }

  // MARK: - Floating Mini-Player Management

  /// Show the floating mini-player overlay
  void showFloatingMiniPlayer(
    BuildContext context,
    Map<String, dynamic> episode,
    List<Map<String, dynamic>> episodes,
    int episodeIndex,
  ) {
    try {
      // Ensure we have valid episode data
      if (episode.isEmpty) {
        debugPrint('⚠️ Warning: Empty episode data provided to mini-player');
        return;
      }

      // Validate episode index
      if (episodeIndex < 0 || episodeIndex >= episodes.length) {
        debugPrint(
            '⚠️ Warning: Invalid episode index: $episodeIndex (total: ${episodes.length})');
        episodeIndex = 0; // Use first episode as fallback
      }

      debugPrint(
          '🎵 Showing mini-player for episode: ${episode['title']} at index $episodeIndex');

      FloatingMiniPlayerOverlay.show(context, episode, episodes, episodeIndex);

      // Update current episode if it's different
      if (_currentEpisode?.id.toString() != episode['id'].toString()) {
        debugPrint('🔄 Updating current episode from mini-player data');
        try {
          final episodeModel = Episode.fromJson(episode);
          setCurrentEpisode(episodeModel, preservePlayingState: true);
        } catch (e) {
          debugPrint('⚠️ Error converting episode data: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error showing mini-player: $e');
    }
  }

  /// Hide the floating mini-player overlay
  void hideFloatingMiniPlayer({bool force = false}) {
    try {
      debugPrint('🎵 Hiding mini-player (force: $force)');
      FloatingMiniPlayerOverlay.hide(force: force);
    } catch (e) {
      debugPrint('❌ Error hiding mini-player: $e');
    }
  }

  /// Force hide the floating mini-player overlay (bypasses strict mode)
  void forceHideFloatingMiniPlayer() {
    try {
      debugPrint('🎵 Force hiding mini-player');
      FloatingMiniPlayerOverlay.forceHide();
    } catch (e) {
      debugPrint('❌ Error force hiding mini-player: $e');
    }
  }

  /// Check if floating mini-player is visible
  bool get isFloatingMiniPlayerVisible {
    try {
      return FloatingMiniPlayerOverlay.isVisible;
    } catch (e) {
      debugPrint('❌ Error checking mini-player visibility: $e');
      return false;
    }
  }

  /// Enable or disable strict mode for mini-player
  void setMiniPlayerStrictMode(bool enabled) {
    try {
      FloatingMiniPlayerOverlay.setStrictMode(enabled);
      debugPrint(
          '🎵 Mini-player strict mode ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Error setting mini-player strict mode: $e');
    }
  }

  /// Enable or disable back button protection for mini-player
  void setMiniPlayerBackButtonProtection(bool enabled) {
    try {
      FloatingMiniPlayerOverlay.setBackButtonProtection(enabled);
      debugPrint(
          '🎵 Mini-player back button protection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Error setting mini-player back button protection: $e');
    }
  }

  /// Check if mini-player strict mode is enabled
  bool get isMiniPlayerStrictModeEnabled {
    try {
      return FloatingMiniPlayerOverlay.isStrictModeEnabled;
    } catch (e) {
      debugPrint('❌ Error checking mini-player strict mode: $e');
      return false;
    }
  }

  /// Check if mini-player back button protection is enabled
  bool get isMiniPlayerBackButtonProtectionEnabled {
    try {
      return FloatingMiniPlayerOverlay.isBackButtonProtectionEnabled;
    } catch (e) {
      debugPrint('❌ Error checking mini-player back button protection: $e');
      return false;
    }
  }

  /// Set current podcast data for proper image display
  void setCurrentPodcastData(Map<String, dynamic>? podcastData) {
    _currentPodcastData = podcastData;
    debugPrint('🎵 Podcast data set: ${podcastData?['title'] ?? 'null'}');
  }

  /// Force refresh mini-player with current episode data
  void refreshMiniPlayer(BuildContext context) {
    try {
      if (_currentEpisode != null && isFloatingMiniPlayerVisible) {
        debugPrint(
            '🔄 Refreshing mini-player with current episode: ${_currentEpisode!.title}');

        // Convert current episode to map format with podcast data
        final episodeMap =
            _currentEpisode!.toMapWithPodcastData(_currentPodcastData);

        // Show mini-player with current data
        showFloatingMiniPlayer(
          context,
          episodeMap,
          _episodeQueue
              .map((e) => e.toMapWithPodcastData(_currentPodcastData))
              .toList(),
          _currentEpisodeIndex,
        );
      }
    } catch (e) {
      debugPrint('❌ Error refreshing mini-player: $e');
    }
  }

  // MARK: - Local Storage Integration

  /// Set local storage service (called from main app)
  void setLocalStorage(LocalStorageService localStorage) {
    _localStorage = localStorage;
    debugPrint('✅ Local storage service connected to podcast player');
  }

  /// Set service manager (called from main app)
  void setServiceManager(ServiceManager serviceManager) {
    _serviceManager = serviceManager;
    debugPrint('✅ Service manager connected to podcast player');
  }

  /// Set progress provider for real-time updates
  void setProgressProvider(EpisodeProgressProvider progressProvider) {
    _progressProvider = progressProvider;
    debugPrint('✅ EpisodeProgressProvider connected to podcast player');

    // Set up real-time progress listening
    _setupProgressListening();
  }

  /// Set the PlaybackPersistenceService for state persistence
  void setPlaybackPersistenceService(PlaybackPersistenceService service) {
    _playbackPersistenceService = service;
    debugPrint('✅ PlaybackPersistenceService set in PodcastPlayerProvider');
  }

  /// Set up real-time progress listening
  void _setupProgressListening() {
    if (_progressProvider == null) return;

    try {
      // Throttling variables for position updates
      DateTime _lastPositionUpdate = DateTime.now();

      // Listen to position updates for real-time progress (THROTTLED)
      _audioService.positionStream?.listen((position) {
        if (_currentEpisode != null &&
            _progressProvider != null &&
            _duration != null &&
            position != null) {
          // Throttle position updates to prevent excessive UI rebuilds
          final now = DateTime.now();
          if (now.difference(_lastPositionUpdate) >= _positionUpdateThrottle) {
            _lastPositionUpdate = now;

            final progress = _duration!.inMilliseconds > 0
                ? (position.inMilliseconds / _duration!.inMilliseconds)
                    .clamp(0.0, 1.0)
                : 0.0;

            // Update progress provider with real-time data
            _progressProvider!.updateEpisodeProgressRealTime(
              _currentEpisode!.id.toString(),
              progress,
              position,
              _duration!,
            );
          }
        }
      });

      // Listen to duration updates
      _audioService.durationStream?.listen((duration) {
        if (_currentEpisode != null &&
            _progressProvider != null &&
            _position != null &&
            duration != null) {
          _progressProvider!.updateEpisodeProgressRealTime(
            _currentEpisode!.id.toString(),
            _position!.inMilliseconds > 0
                ? (_position!.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0)
                : 0.0,
            _position!,
            duration,
          );
        }
      });

      // Listen to playing state changes
      _audioService.playingStream?.listen((isPlaying) {
        if (_currentEpisode != null &&
            _progressProvider != null &&
            _duration != null &&
            _position != null) {
          if (isPlaying) {
            _progressProvider!.setEpisodePlaying(
              _currentEpisode!.id.toString(),
              progress: _duration!.inMilliseconds > 0
                  ? (_position!.inMilliseconds / _duration!.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0,
              position: _position!,
              duration: _duration!,
            );
          } else {
            _progressProvider!.setEpisodePaused(
              _currentEpisode!.id.toString(),
              progress: _duration!.inMilliseconds > 0
                  ? (_position!.inMilliseconds / _duration!.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0,
              position: _position!,
              duration: _duration!,
            );
          }
        }
      });

      debugPrint(
          '✅ Real-time progress listening set up with throttling (500ms)');
    } catch (e) {
      debugPrint('❌ Error setting up progress listening: $e');
    }
  }

  /// Save current playback state to local storage
  Future<void> _savePlaybackState() async {
    if (_localStorage == null || _currentEpisode == null) return;

    try {
      final playbackData = {
        'episodeId': _currentEpisode!.id,
        'position': _position?.inMilliseconds ?? 0,
        'duration': _duration?.inMilliseconds ?? 0,
        'isPlaying': _isPlaying,
        'timestamp': DateTime.now().toIso8601String(),
        'playbackSpeed': _playbackSpeed,
        'autoPlayNext': _autoPlayNext,
      };

      await _localStorage!.saveUserData('current_playback_state', playbackData);

      // Also save to playback history
      if (_currentEpisode != null && _position != null && _duration != null) {
        await _localStorage!.updatePlaybackPosition(
          _currentEpisode!.id,
          _position!.inMilliseconds,
          _duration!.inMilliseconds,
        );
      }

      debugPrint('💾 Playback state saved to local storage');
    } catch (e) {
      debugPrint('❌ Error saving playback state: $e');
    }
  }

  /// Load playback state from local storage
  Future<void> _loadPlaybackState() async {
    if (_localStorage == null) return;

    try {
      final playbackData = _localStorage!.getUserData('current_playback_state');
      if (playbackData != null) {
        final data = jsonDecode(playbackData);

        // Restore playback settings
        _playbackSpeed = (data['playbackSpeed'] ?? 1.0).toDouble();
        _autoPlayNext = data['autoPlayNext'] ?? true;

        // Restore mini-player persistence settings
        _isMiniPlayerExplicitlyClosed =
            data['isMiniPlayerExplicitlyClosed'] ?? false;
        _shouldShowMiniPlayerPersistently =
            data['shouldShowMiniPlayerPersistently'] ?? true;

        // Restore episode if available
        if (data['episodeId'] != null) {
          // Try to load episode from local storage
          // Note: Episode restoration will be handled by the episode repository
          // For now, we'll just restore the position and duration
          _position = Duration(milliseconds: data['position'] ?? 0);
          _duration = Duration(milliseconds: data['duration'] ?? 0);
          _isPlaying = data['isPlaying'] ?? false;

          debugPrint('📱 Playback state restored from local storage');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading playback state: $e');
    }
  }

  void setEpisodeQueue(List<Episode> episodes,
      {int startIndex = 0, String? podcastId}) {
    debugPrint('🔄 setEpisodeQueue() called - START');
    debugPrint('🔄 IMMEDIATE CHECK - Received ${episodes.length} episodes');
    debugPrint('🔄 IMMEDIATE CHECK - Start index: $startIndex');
    debugPrint(
        '🔄 Setting episode queue: ${episodes.length} episodes, startIndex: $startIndex');
    debugPrint('🔄 Episode titles: ${episodes.map((e) => e.title).toList()}');

    if (episodes.isEmpty) {
      debugPrint('⚠️ Warning: Empty episode queue provided');
      _episodeQueue.clear();
      _currentEpisodeIndex = 0;
      _currentEpisode = null;
      _savePlayerState();
      notifyListeners();
      return;
    }

    // Validate start index
    if (startIndex < 0 || startIndex >= episodes.length) {
      debugPrint('⚠️ Warning: Invalid start index: $startIndex, using 0');
      startIndex = 0;
    }

    // Clear old episode queue and start fresh
    debugPrint('🔄 Clearing old episode queue and starting fresh');
    _episodeQueue.clear();

    // Clear old episode data from local storage
    _clearOldEpisodeData();

    // Set new episode queue with proper validation
    _episodeQueue = List.from(episodes);

    // Store the podcast ID if provided
    if (podcastId != null) {
      _currentPodcastId = podcastId;
      debugPrint('🔄 Podcast ID set: $podcastId');
    }

    // Reset to start index for new podcast series
    _currentEpisodeIndex = startIndex;
    _currentEpisode = episodes[startIndex];

    // Reset position/duration for new episode series
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;

    // Keep repeat mode as per user preference (default false)
    // _isRepeating remains as user set it

    debugPrint(
        '🔄 New episode series loaded: ${_currentEpisode?.title ?? "Unknown"}');
    debugPrint('🔄 Total episodes in series: ${_episodeQueue.length}');
    debugPrint(
        '🔄 Starting at episode: ${startIndex + 1} of ${_episodeQueue.length}');
    debugPrint(
        '🔄 Queue after setup: ${_episodeQueue.map((e) => e.title).toList()}');

    // Always save the queue to ensure it persists
    _savePlayerState();
    notifyListeners();

    debugPrint(
        '✅ Episode queue set successfully. Current episode: ${_currentEpisode?.title}, Index: $_currentEpisodeIndex');
    debugPrint('✅ setEpisodeQueue() completed');

    // Ensure episodes remain visible by notifying listeners again
    Future.delayed(Duration(milliseconds: 100), () {
      notifyListeners();
      debugPrint('🔄 Episode queue visibility refresh completed');
    });
  }

  void playNext() {
    debugPrint('🔄 playNext() called - START');
    debugPrint('🔄 IMMEDIATE CHECK - Queue length: ${_episodeQueue.length}');
    debugPrint('🔄 IMMEDIATE CHECK - Current index: $_currentEpisodeIndex');
    debugPrint(
        '🔄 IMMEDIATE CHECK - Current episode: ${_currentEpisode?.title ?? "NULL"}');

    if (_episodeQueue.isEmpty) {
      debugPrint('❌ No episodes in queue for auto-play - EXITING HERE');
      return;
    }
    debugPrint('🔄 Queue is NOT empty, continuing...');

    int nextIndex;
    if (_currentEpisodeIndex >= _episodeQueue.length - 1) {
      if (_isRepeating) {
        nextIndex = 0;
        debugPrint('🔄 Repeating playlist, starting from first episode');
      } else {
        debugPrint('⏹️ Reached end of playlist, no more episodes');
        return; // No more episodes
      }
    } else {
      nextIndex = _currentEpisodeIndex + 1;
      debugPrint('🔄 Moving to next episode in series');
    }

    debugPrint('🔄 Next index: $nextIndex');
    debugPrint('🔄 Next episode: ${_episodeQueue[nextIndex].title}');

    try {
      final nextEpisode = _episodeQueue[nextIndex];
      debugPrint(
          '🔄 Auto-playing next episode: ${nextEpisode.title} (index: $nextIndex)');

      // Update current episode and index
      _currentEpisodeIndex = nextIndex;
      _currentEpisode = nextEpisode;

      // Reset position and duration for new episode
      _position = Duration.zero;
      _duration = Duration.zero;

      // Set playing state to true for auto-play
      _isPlaying = true;

      debugPrint('🔄 About to call _loadAndPlayNextEpisode...');
      // Load and play the episode
      _loadAndPlayNextEpisode(nextEpisode);

      _savePlayerState();
      notifyListeners();
      debugPrint('✅ playNext completed successfully');
      debugPrint(
          '✅ Now playing: ${nextEpisode.title} (${nextIndex + 1} of ${_episodeQueue.length})');
    } catch (e) {
      debugPrint('❌ Error playing next episode: $e');
      // Try to recover by attempting to play the next available episode
      _tryRecoverFromPlayNextError();
    }
  }

  /// Load and play the next episode with error handling
  Future<void> _loadAndPlayNextEpisode(Episode episode) async {
    try {
      debugPrint('🔄 Loading and playing next episode: ${episode.title}');
      debugPrint('🔄 Episode audio URL: ${episode.audioUrl}');
      debugPrint('🔄 Current episode queue length: ${_episodeQueue.length}');
      debugPrint('🔄 Current episode index: $_currentEpisodeIndex');

      // Ensure the episode is set as current before playing
      setCurrentEpisode(episode, preservePlayingState: false);

      debugPrint('🔄 Episode set as current, now calling audio service...');

      // Load and play the episode (skip resume logic for auto-play)
      await _audioService.playEpisode(episode, skipResumeLogic: true);

      debugPrint(
          '✅ Successfully started playing next episode: ${episode.title}');
    } catch (e) {
      debugPrint('❌ Failed to load next episode: ${episode.title}, error: $e');
      // If auto-play fails, try the next episode in queue
      _isPlaying = false;
      notifyListeners();

      // Attempt to play the next episode in queue
      Future.delayed(Duration(milliseconds: 500), () {
        if (_autoPlayNext) {
          debugPrint('🔄 Retrying auto-play after failure...');
          playNext();
        }
      });
    }
  }

  /// Try to recover from playNext errors by attempting to play next available episode
  void _tryRecoverFromPlayNextError() {
    if (_episodeQueue.isEmpty) return;

    // Try to find the next playable episode
    for (int i = _currentEpisodeIndex + 1; i < _episodeQueue.length; i++) {
      final episode = _episodeQueue[i];
      if (episode.audioUrl != null && episode.audioUrl!.isNotEmpty) {
        debugPrint(
            'Attempting to recover by playing episode at index $i: ${episode.title}');
        _currentEpisodeIndex = i;
        _currentEpisode = episode;
        _position = Duration.zero;
        _duration = Duration.zero;
        _isPlaying = false;

        if (_autoPlayNext) {
          _isPlaying = true;
          _loadAndPlayNextEpisode(episode);
        }

        _savePlayerState();
        notifyListeners();
        return;
      }
    }

    debugPrint('No playable episodes found for recovery');
  }

  void playPrevious() {
    if (_episodeQueue.isEmpty) {
      debugPrint('❌ No episodes in queue for previous playback');
      return;
    }

    int previousIndex;
    if (_currentEpisodeIndex <= 0) {
      if (_isRepeating) {
        previousIndex = _episodeQueue.length - 1;
        debugPrint('🔄 Repeating playlist, going to last episode');
      } else {
        debugPrint('⏹️ Reached beginning of playlist, no previous episodes');
        return; // No previous episodes
      }
    } else {
      previousIndex = _currentEpisodeIndex - 1;
    }

    try {
      final previousEpisode = _episodeQueue[previousIndex];
      debugPrint(
          '🔄 Playing previous episode: ${previousEpisode.title} (index: $previousIndex)');

      // Update current episode and index
      _currentEpisodeIndex = previousIndex;
      _currentEpisode = previousEpisode;

      // Reset position and duration for new episode
      _position = Duration.zero;
      _duration = Duration.zero;

      // Set playing state to true for auto-play
      _isPlaying = true;

      // Load and play the episode
      _loadAndPlayPreviousEpisode(previousEpisode);

      _savePlayerState();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error playing previous episode: $e');
      // Try to recover by attempting to play the previous available episode
      _tryRecoverFromPlayPreviousError();
    }
  }

  /// Load and play the previous episode with error handling
  Future<void> _loadAndPlayPreviousEpisode(Episode episode) async {
    try {
      debugPrint('🔄 Loading and playing previous episode: ${episode.title}');

      // Ensure the episode is set as current before playing
      setCurrentEpisode(episode, preservePlayingState: false);

      // Load and play the episode (skip resume logic for auto-play)
      await _audioService.playEpisode(episode, skipResumeLogic: true);

      debugPrint(
          '✅ Successfully started playing previous episode: ${episode.title}');
    } catch (e) {
      debugPrint(
          '❌ Failed to load previous episode: ${episode.title}, error: $e');
      // If auto-play fails, try the previous episode in queue
      _isPlaying = false;
      notifyListeners();

      // Attempt to play the previous episode in queue
      Future.delayed(Duration(milliseconds: 500), () {
        if (_autoPlayNext) {
          debugPrint('🔄 Retrying auto-play after failure...');
          playPrevious();
        }
      });
    }
  }

  /// Try to recover from playPrevious errors by attempting to play previous available episode
  void _tryRecoverFromPlayPreviousError() {
    if (_episodeQueue.isEmpty) return;

    // Try to find the previous playable episode
    for (int i = _currentEpisodeIndex - 1; i >= 0; i--) {
      final episode = _episodeQueue[i];
      if (episode.audioUrl != null && episode.audioUrl!.isNotEmpty) {
        debugPrint(
            'Attempting to recover by playing episode at index $i: ${episode.title}');
        _currentEpisodeIndex = i;
        _currentEpisode = episode;
        _position = Duration.zero;
        _duration = Duration.zero;
        _isPlaying = false;

        if (_autoPlayNext) {
          _isPlaying = true;
          _loadAndPlayPreviousEpisode(episode);
        }

        _savePlayerState();
        notifyListeners();
        return;
      }
    }

    debugPrint('No playable episodes found for recovery');
  }

  void skipToEpisode(int index) {
    if (index < 0 || index >= _episodeQueue.length) {
      debugPrint(
          'Invalid episode index: $index, queue length: ${_episodeQueue.length}');
      return;
    }

    try {
      final targetEpisode = _episodeQueue[index];
      debugPrint('Skipping to episode: ${targetEpisode.title} (index: $index)');

      // Update current episode and index
      _currentEpisodeIndex = index;
      _currentEpisode = targetEpisode;

      // Reset position and duration for new episode
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;

      // Auto-play if enabled
      if (_autoPlayNext) {
        _isPlaying = true;
        // Load and play the episode
        _loadAndPlayTargetEpisode(targetEpisode);
      }

      _savePlayerState();
      notifyListeners();
    } catch (e) {
      debugPrint('Error skipping to episode at index $index: $e');
      // Try to recover by attempting to play the target episode
      _tryRecoverFromSkipToEpisodeError(index);
    }
  }

  /// Load and play the target episode with error handling
  Future<void> _loadAndPlayTargetEpisode(Episode episode) async {
    try {
      debugPrint('Loading and playing target episode: ${episode.title}');
      await _audioService.playEpisode(episode, skipResumeLogic: true);
      debugPrint(
          'Successfully started playing target episode: ${episode.title}');
    } catch (e) {
      debugPrint('Failed to load target episode: ${episode.title}, error: $e');
      // If auto-play fails, reset playing state
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Try to recover from skipToEpisode errors
  void _tryRecoverFromSkipToEpisodeError(int targetIndex) {
    if (_episodeQueue.isEmpty) return;

    // Try to find a playable episode around the target index
    final searchRange = 3; // Look within 3 episodes of target
    final startIndex =
        (targetIndex - searchRange).clamp(0, _episodeQueue.length - 1);
    final endIndex =
        (targetIndex + searchRange).clamp(0, _episodeQueue.length - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      final episode = _episodeQueue[i];
      if (episode.audioUrl != null && episode.audioUrl!.isNotEmpty) {
        debugPrint(
            'Attempting to recover by playing episode at index $i: ${episode.title}');
        _currentEpisodeIndex = i;
        _currentEpisode = episode;
        _position = Duration.zero;
        _duration = Duration.zero;
        _isPlaying = false;

        if (_autoPlayNext) {
          _isPlaying = true;
          _loadAndPlayTargetEpisode(episode);
        }

        _savePlayerState();
        notifyListeners();
        return;
      }
    }

    debugPrint(
        'No playable episodes found for recovery around index $targetIndex');
  }

  // MARK: - Queue Management

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    _savePlayerState();
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeating = !_isRepeating;
    _savePlayerState();
    notifyListeners();
  }

  void addToQueue(Episode episode) {
    _episodeQueue.add(episode);
    _savePlayerState();
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _episodeQueue.length) {
      _episodeQueue.removeAt(index);
      if (_currentEpisodeIndex >= index && _currentEpisodeIndex > 0) {
        _currentEpisodeIndex--;
      }
      _savePlayerState();
      notifyListeners();
    }
  }

  void clearQueue() {
    _episodeQueue.clear();
    _currentEpisodeIndex = 0;
    _savePlayerState();
    notifyListeners();
  }

  /// Shuffle the episode queue
  void shuffleQueue() {
    if (_episodeQueue.length <= 1) return;

    debugPrint('🔄 Shuffling episode queue');
    final currentEpisode = _currentEpisode;
    final currentIndex = _currentEpisodeIndex;

    // Remove current episode from queue temporarily
    if (currentEpisode != null && currentIndex < _episodeQueue.length) {
      _episodeQueue.removeAt(currentIndex);
    }

    // Shuffle the remaining episodes
    _episodeQueue.shuffle();

    // Re-insert current episode at the beginning
    if (currentEpisode != null) {
      _episodeQueue.insert(0, currentEpisode);
      _currentEpisodeIndex = 0;
    }

    _savePlayerState();
    notifyListeners();
  }

  /// Sort the episode queue
  void sortQueue(String sortBy) {
    if (_episodeQueue.length <= 1) return;

    debugPrint('🔄 Sorting episode queue by: $sortBy');
    final currentEpisode = _currentEpisode;
    final currentIndex = _currentEpisodeIndex;

    // Remove current episode from queue temporarily
    if (currentEpisode != null && currentIndex < _episodeQueue.length) {
      _episodeQueue.removeAt(currentIndex);
    }

    // Sort the remaining episodes
    switch (sortBy) {
      case 'date':
        _episodeQueue.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        break;
      case 'duration':
        _episodeQueue.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'title':
        _episodeQueue.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    // Re-insert current episode at the beginning
    if (currentEpisode != null) {
      _episodeQueue.insert(0, currentEpisode);
      _currentEpisodeIndex = 0;
    }

    _savePlayerState();
    notifyListeners();
  }

  /// Play a specific episode from the queue
  Future<void> playEpisode(Episode episode, {BuildContext? context}) async {
    debugPrint('🔄 Playing specific episode: ${episode.title}');

    // Find the episode in the queue
    final index = _episodeQueue.indexWhere((e) => e.id == episode.id);

    if (index != -1) {
      // Episode is in queue, set as current and play
      _currentEpisodeIndex = index;
      _currentEpisode = episode;
      await play();
    } else {
      // Episode not in queue, add it and play
      _episodeQueue.add(episode);
      _currentEpisodeIndex = _episodeQueue.length - 1;
      _currentEpisode = episode;
      await play();
    }

    _savePlayerState();
    notifyListeners();

    // Show mini-player if context is provided and conditions are met
    if (context != null) {
      showMiniPlayerIfAppropriate(context);
    }
  }

  // MARK: - Settings

  void toggleAutoPlayNext() {
    _autoPlayNext = !_autoPlayNext;
    _savePlayerState();
    notifyListeners();
  }

  // Note: toggleKeepScreenOn removed - screen now sleeps naturally during audio playback

  void setSleepTimer(Duration duration) {
    _sleepTimerDuration = duration;
    _showSleepTimer = duration > Duration.zero;
    _savePlayerState();
    notifyListeners();

    // Set the actual sleep timer in the audio service
    if (_audioService != null) {
      _audioService.setSleepTimer(duration);
    }
  }

  /// Set sleep timer to end of current episode
  void setSleepTimerAtEndOfEpisode() {
    if (_currentEpisode != null && _duration != null) {
      final remainingTime = _duration! - _position;
      _sleepTimerDuration = remainingTime;
      _showSleepTimer = true;
      _savePlayerState();
      notifyListeners();

      // Set the actual sleep timer in the audio service
      if (_audioService != null) {
        _audioService.setSleepTimer(remainingTime);
      }
    }
  }

  void clearSleepTimer() {
    _sleepTimerDuration = Duration.zero;
    _showSleepTimer = false;
    _savePlayerState();
    notifyListeners();

    // Clear the actual sleep timer in the audio service
    if (_audioService != null) {
      _audioService.clearSleepTimer();
    }
  }

  // MARK: - Playback Effects

  /// Set trim silence
  Future<void> setTrimSilence(bool enabled) async {
    try {
      debugPrint('🎵 PodcastPlayerProvider: Setting trim silence to $enabled');

      // Notify listeners immediately for UI updates
      notifyListeners();

      // Apply to playback effects service (async, non-blocking)
      _playbackEffectsService.setTrimSilence(enabled).catchError((e) {
        debugPrint('❌ Error setting trim silence in effects service: $e');
      });

      // Apply to audio service (async, non-blocking)
      if (_audioService != null) {
        _audioService.setTrimSilence(enabled).catchError((e) {
          debugPrint('❌ Error setting trim silence in audio service: $e');
        });
      }

      debugPrint('🎵 PodcastPlayerProvider: Trim silence set to $enabled');
    } catch (e) {
      debugPrint('❌ Error setting trim silence: $e');
    }
  }

  /// Set volume boost
  Future<void> setVolumeBoost(bool enabled) async {
    try {
      debugPrint('🎵 PodcastPlayerProvider: Setting volume boost to $enabled');

      // Notify listeners immediately for UI updates
      notifyListeners();

      // Apply to playback effects service (async, non-blocking)
      _playbackEffectsService.setVolumeBoost(enabled).catchError((e) {
        debugPrint('❌ Error setting volume boost in effects service: $e');
      });

      // Apply to audio service (async, non-blocking)
      if (_audioService != null) {
        _audioService.setVolumeBoost(enabled).catchError((e) {
          debugPrint('❌ Error setting volume boost in audio service: $e');
        });
      }

      debugPrint('🎵 PodcastPlayerProvider: Volume boost set to $enabled');
    } catch (e) {
      debugPrint('❌ Error setting volume boost: $e');
    }
  }

  /// Set apply to all podcasts
  Future<void> setApplyToAllPodcasts(bool enabled) async {
    try {
      await _playbackEffectsService.setApplyToAllPodcasts(enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting apply to all podcasts: $e');
    }
  }

  /// Get playback effects settings
  Future<Map<String, dynamic>> getPlaybackEffectsSettings() async {
    try {
      await _playbackEffectsService.initialize();
      return _playbackEffectsService.getSettings();
    } catch (e) {
      debugPrint('Error getting playback effects settings: $e');
      return {};
    }
  }

  /// Get available playback speeds
  List<double> getAvailablePlaybackSpeeds() {
    return _playbackEffectsService.getAvailableSpeeds();
  }

  /// Get speed label
  String getSpeedLabel(double speed) {
    return _playbackEffectsService.getSpeedLabel(speed);
  }

  /// Toggle shuffle mode
  void toggleShuffleMode() {
    _isShuffled = !_isShuffled;
    _savePlayerState();
    notifyListeners();

    debugPrint('🔀 Shuffle mode ${_isShuffled ? 'enabled' : 'disabled'}');

    if (_isShuffled && _episodeQueue.isNotEmpty) {
      // Store current episode position before shuffling
      final currentEpisode = _currentEpisode;
      final currentIndex = _currentEpisodeIndex;

      // Shuffle the episode queue
      _episodeQueue.shuffle();

      // Find the current episode in the new shuffled queue and update index
      if (currentEpisode != null) {
        final newIndex =
            _episodeQueue.indexWhere((ep) => ep.id == currentEpisode.id);
        if (newIndex != -1) {
          _currentEpisodeIndex = newIndex;
          debugPrint('🔀 Current episode found at new index: $newIndex');
        } else {
          // If current episode not found, reset to first
          _currentEpisodeIndex = 0;
          debugPrint(
              '🔀 Current episode not found in shuffled queue, resetting to first');
        }
      } else {
        _currentEpisodeIndex = 0;
      }

      debugPrint(
          '🔀 Episode queue shuffled (${_episodeQueue.length} episodes)');
      debugPrint('🔀 Current episode index: $_currentEpisodeIndex');

      // Update the provider state
      notifyListeners();
    } else if (!_isShuffled) {
      debugPrint('🔀 Shuffle disabled - queue order preserved');
    }
  }

  /// Toggle repeat mode
  void toggleRepeatMode() {
    _isRepeating = !_isRepeating;
    _savePlayerState();
    notifyListeners();

    debugPrint('🔁 Repeat mode ${_isRepeating ? 'enabled' : 'disabled'}');

    // If repeat is enabled and we have a current episode, prepare for repeat
    if (_isRepeating && _currentEpisode != null) {
      debugPrint('🔁 Repeat mode: Current episode will repeat when finished');
    }
  }

  // MARK: - Mini-Player Persistence Management

  /// Check if mini-player should be shown based on queue data and user preferences
  bool shouldShowMiniPlayer() {
    // Don't show if explicitly closed by user
    if (_isMiniPlayerExplicitlyClosed) {
      return false;
    }

    // Show if there's data in the queue (current episode or queue)
    return _currentEpisode != null || _episodeQueue.isNotEmpty;
  }

  /// Mark mini-player as explicitly closed by user
  void markMiniPlayerAsExplicitlyClosed() {
    _isMiniPlayerExplicitlyClosed = true;
    _savePlayerState();
    notifyListeners();
    debugPrint('🎵 Mini-player marked as explicitly closed by user');
  }

  /// Reset mini-player explicit close state (when new episode starts)
  void resetMiniPlayerExplicitCloseState() {
    _isMiniPlayerExplicitlyClosed = false;
    _savePlayerState();
    notifyListeners();
    debugPrint('🎵 Mini-player explicit close state reset');
  }

  /// Enable/disable persistent mini-player behavior
  void setMiniPlayerPersistentMode(bool enabled) {
    _shouldShowMiniPlayerPersistently = enabled;
    _savePlayerState();
    notifyListeners();
    debugPrint(
        '🎵 Mini-player persistent mode ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Show mini-player if conditions are met (respects user preferences)
  void showMiniPlayerIfAppropriate(BuildContext context) {
    try {
      if (!_shouldShowMiniPlayerPersistently) {
        debugPrint('🎵 Mini-player persistent mode disabled, not showing');
        return;
      }

      if (!shouldShowMiniPlayer()) {
        debugPrint(
            '🎵 Mini-player should not be shown (explicitly closed or no queue data)');
        return;
      }

      if (_currentEpisode == null) {
        debugPrint('🎵 No current episode, cannot show mini-player');
        return;
      }

      // Validate context
      if (!context.mounted) {
        debugPrint('🎵 Context not mounted, cannot show mini-player');
        return;
      }

      // Show mini-player with current data
      showFloatingMiniPlayer(
        context,
        _currentEpisode!.toMapWithPodcastData(_currentPodcastData),
        _episodeQueue
            .map((e) => e.toMapWithPodcastData(_currentPodcastData))
            .toList(),
        _currentEpisodeIndex,
      );

      debugPrint('🎵 Mini-player shown automatically (persistent mode)');
    } catch (e) {
      debugPrint('❌ Error showing mini-player automatically: $e');
    }
  }

  /// Force show mini-player (bypasses user preferences - for system actions)
  void forceShowMiniPlayer(BuildContext context) {
    try {
      if (_currentEpisode == null) {
        debugPrint('🎵 No current episode, cannot force show mini-player');
        return;
      }

      // Validate context
      if (!context.mounted) {
        debugPrint('🎵 Context not mounted, cannot force show mini-player');
        return;
      }

      // Temporarily reset explicit close state for system actions
      final wasExplicitlyClosed = _isMiniPlayerExplicitlyClosed;
      _isMiniPlayerExplicitlyClosed = false;

      // Show mini-player with current data
      showFloatingMiniPlayer(
        context,
        _currentEpisode!.toMapWithPodcastData(_currentPodcastData),
        _episodeQueue
            .map((e) => e.toMapWithPodcastData(_currentPodcastData))
            .toList(),
        _currentEpisodeIndex,
      );

      // Restore explicit close state
      _isMiniPlayerExplicitlyClosed = wasExplicitlyClosed;

      debugPrint('🎵 Mini-player force shown (system action)');
    } catch (e) {
      debugPrint('❌ Error force showing mini-player: $e');
    }
  }

  /// Get mini-player persistence status for debugging
  Map<String, dynamic> getMiniPlayerPersistenceStatus() {
    return {
      'isExplicitlyClosed': _isMiniPlayerExplicitlyClosed,
      'shouldShowPersistently': _shouldShowMiniPlayerPersistently,
      'hasCurrentEpisode': _currentEpisode != null,
      'hasQueueData': _episodeQueue.isNotEmpty,
      'shouldShow': shouldShowMiniPlayer(),
      'isVisible': isFloatingMiniPlayerVisible,
    };
  }

  // MARK: - State Persistence

  Future<void> _loadPlayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isMinimized = prefs.getBool('player_is_minimized') ?? false;
      _isPlaying = prefs.getBool('player_is_playing') ?? false;
      _isEpisodeDetailModalOpen = prefs.getBool('player_modal_open') ?? false;

      final positionMs = prefs.getInt('player_position_ms') ?? 0;
      final durationMs = prefs.getInt('player_duration_ms') ?? 0;
      _position = Duration(milliseconds: positionMs);
      _duration = Duration(milliseconds: durationMs);

      _playbackSpeed = prefs.getDouble('player_speed') ?? 1.0;
      _isShuffled = prefs.getBool('player_shuffled') ?? false;
      _isRepeating = prefs.getBool('player_repeating') ?? false;

      _autoPlayNext = prefs.getBool('player_auto_play_next') ?? true;
      // Note: keepScreenOn setting removed - screen now sleeps naturally during audio playback

      final sleepTimerMs = prefs.getInt('player_sleep_timer_ms') ?? 0;
      _sleepTimerDuration = Duration(milliseconds: sleepTimerMs);
      _showSleepTimer = sleepTimerMs > 0;

      // Load episode data if available
      final episodeJson = prefs.getString('player_current_episode');
      if (episodeJson != null) {
        try {
          _currentEpisode = Episode.fromJson(jsonDecode(episodeJson));
        } catch (e) {
          debugPrint('Error loading current episode: $e');
        }
      }

      final queueJson = prefs.getString('player_episode_queue');
      if (queueJson != null) {
        try {
          final queueList = jsonDecode(queueJson) as List;
          _episodeQueue = queueList.map((e) => Episode.fromJson(e)).toList();
        } catch (e) {
          debugPrint('Error loading episode queue: $e');
        }
      }

      _currentEpisodeIndex = prefs.getInt('player_current_index') ?? 0;
    } catch (e) {
      debugPrint('Error loading player state: $e');
    }
  }

  /// Save player state to persistent storage
  Future<void> _savePlayerState() async {
    try {
      if (_currentEpisode == null) return;

      final state = {
        'episode_id': _currentEpisode!.id,
        'episode_title': _currentEpisode!.title,
        'podcast_title': _currentEpisode!.podcastName,
        'position': _position.inMilliseconds,
        'duration': _duration?.inMilliseconds ?? 0,
        'is_playing': _isPlaying,
        'playback_speed': _playbackSpeed,
        'episode_queue': _episodeQueue.map((e) => e.toJson()).toList(),
        'current_queue_index': _currentEpisodeIndex,
        'timestamp': DateTime.now().toIso8601String(),
        'podcast_id': _currentPodcastId,
        'isMiniPlayerExplicitlyClosed': _isMiniPlayerExplicitlyClosed,
        'shouldShowMiniPlayerPersistently': _shouldShowMiniPlayerPersistently,
      };

      await _persistentStateManager.savePlayerState(state);
      debugPrint('💾 Player state saved to persistent storage');
    } catch (e) {
      debugPrint('❌ Failed to save player state: $e');
    }
  }

  /// Restore player state from persistent storage
  Future<void> restoreFromPersistedState() async {
    try {
      final state = await _persistentStateManager.restorePlayerState();
      if (state == null) {
        debugPrint('ℹ️ No persisted player state found');
        return;
      }

      // Check if state is stale (older than 24 hours)
      if (await _persistentStateManager.isPlayerStateStale()) {
        debugPrint('ℹ️ Player state is stale, clearing');
        await _persistentStateManager.clearPlayerState();
        return;
      }

      debugPrint('🔄 Restoring player state: ${state['episode_title']}');

      // Restore episode queue
      if (state['episode_queue'] != null) {
        final queueData = state['episode_queue'] as List;
        _episodeQueue = queueData.map((e) => Episode.fromJson(e)).toList();
        _currentEpisodeIndex = state['current_queue_index'] ?? 0;
      }

      // Restore current episode
      if (state['episode_id'] != null && _episodeQueue.isNotEmpty) {
        final episodeId = state['episode_id'];
        final episodeIndex = _episodeQueue.indexWhere((e) => e.id == episodeId);

        if (episodeIndex != -1) {
          _currentEpisode = _episodeQueue[episodeIndex];
          _currentEpisodeIndex = episodeIndex;

          // Restore position and duration
          if (state['position'] != null) {
            _position = Duration(milliseconds: state['position']);
          }
          if (state['duration'] != null) {
            _duration = Duration(milliseconds: state['duration']);
          }

          // Restore playback speed
          if (state['playback_speed'] != null) {
            _playbackSpeed = state['playback_speed'].toDouble();
          }

          // Restore podcast ID
          if (state['podcast_id'] != null) {
            _currentPodcastId = state['podcast_id'];
          }

          // Restore mini-player persistence settings
          if (state['isMiniPlayerExplicitlyClosed'] != null) {
            _isMiniPlayerExplicitlyClosed =
                state['isMiniPlayerExplicitlyClosed'];
          }
          if (state['shouldShowMiniPlayerPersistently'] != null) {
            _shouldShowMiniPlayerPersistently =
                state['shouldShowMiniPlayerPersistently'];
          }

          debugPrint('✅ Player state restored successfully');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to restore player state: $e');
    }
  }

  /// Update media session with current state
  void _updateMediaSession() {
    try {
      if (_currentEpisode != null) {
        // Check if media session needs re-initialization
        if (!_mediaSessionService.isInitialized ||
            _mediaSessionService.currentEpisode == null) {
          debugPrint(
              '🔄 Media session not properly initialized, attempting re-initialization...');
          _mediaSessionService.forceReinitialize(playerProvider: this);
        }

        _mediaSessionService.setEpisode(_currentEpisode!);
        _mediaSessionService.updatePlaybackState(
          isPlaying: _isPlaying,
          position: _position,
          duration: _duration,
        );
      }
    } catch (e) {
      debugPrint('Error updating media session: $e');
    }
  }

  /// Check if player state should be preserved
  bool get shouldPreserveState {
    return _currentEpisode != null && _episodeQueue.isNotEmpty;
  }

  /// Clear persisted player state
  Future<void> clearPersistedState() async {
    try {
      await _persistentStateManager.clearPlayerState();
      debugPrint('🗑️ Persisted player state cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear persisted player state: $e');
    }
  }

  /// Note: Mini-player positioning cache has been removed.
  /// The mini-player now always auto-detects positioning for optimal performance.

  // MARK: - Utility Methods

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // MARK: - Episode Progress Management

  /// Update episode progress with enhanced error handling and retry logic
  Future<void> updateEpisodeProgress(
      Episode episode, Duration position, Duration duration,
      {String? podcastId}) async {
    try {
      debugPrint(
          '💾 Updating episode progress: ${episode.title} at ${position.inSeconds}s / ${duration.inSeconds}s');

      // Update the episode with new progress
      final updatedEpisode = episode.copyWith(
        lastPlayedPosition: position.inMilliseconds,
        totalDuration: duration.inMilliseconds,
        lastPlayedAt: DateTime.now(),
        isCompleted: position >= duration,
      );

      // Update current episode if it's the same one
      if (_currentEpisode?.id == episode.id) {
        _currentEpisode = updatedEpisode;
      }

      // Save progress to cloud via EpisodeProgressService
      // Use provided podcastId, stored podcast ID, or fallback
      final finalPodcastId =
          podcastId ?? _currentPodcastId ?? 'episode_${episode.id}_podcast';

      // Save progress using EpisodeProgressProvider for real-time updates
      if (_progressProvider != null) {
        final success = await _progressProvider!.saveProgress(
          episodeId: episode.id.toString(),
          podcastId: finalPodcastId,
          currentPosition: position.inMilliseconds,
          totalDuration: duration.inMilliseconds,
          playbackData: {
            'playback_speed': _playbackSpeed,
            'is_shuffled': _isShuffled,
            'is_repeating': _isRepeating,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (success) {
          debugPrint(
              '✅ Progress saved via provider: ${episode.title} - ${position.inSeconds}s / ${duration.inSeconds}s');
        } else {
          debugPrint(
              '⚠️ Progress save failed via provider: ${episode.title} - ${position.inSeconds}s / ${duration.inSeconds}s');

          // Fallback to direct service call
          await _fallbackProgressSave(
              episode, position, duration, finalPodcastId);
        }
      } else {
        // Fallback to direct service call
        await _fallbackProgressSave(
            episode, position, duration, finalPodcastId);
      }

      // Also save to local storage for offline access
      if (_localStorage != null) {
        try {
          await _localStorage!.updatePlaybackPosition(
            episode.id,
            position.inMilliseconds,
            duration.inMilliseconds,
          );
          debugPrint('💾 Progress also saved to local storage');
        } catch (localError) {
          debugPrint('⚠️ Local storage save failed: $localError');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating episode progress: $e');

      // Try to save at least to local storage as last resort
      if (_localStorage != null) {
        try {
          await _localStorage!.updatePlaybackPosition(
            episode.id,
            position.inMilliseconds,
            duration.inMilliseconds,
          );
          debugPrint('💾 Progress saved to local storage as fallback');
        } catch (fallbackError) {
          debugPrint('❌ Even local storage fallback failed: $fallbackError');
        }
      }
    }
  }

  /// Fallback progress saving when provider fails
  Future<void> _fallbackProgressSave(Episode episode, Duration position,
      Duration duration, String podcastId) async {
    try {
      final success = await _progressService.saveProgress(
        episodeId: episode.id.toString(),
        podcastId: podcastId,
        currentPosition: position.inMilliseconds,
        totalDuration: duration.inMilliseconds,
        playbackData: {
          'playback_speed': _playbackSpeed,
          'is_shuffled': _isShuffled,
          'is_repeating': _isRepeating,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (success) {
        debugPrint(
            '✅ Progress saved via fallback service: ${episode.title} - ${position.inSeconds}s / ${duration.inSeconds}s');
      } else {
        debugPrint('❌ Even fallback progress save failed: ${episode.title}');
      }
    } catch (e) {
      debugPrint('❌ Error in fallback progress save: $e');
    }
  }

  /// Load episode progress from local storage and cloud
  Future<Map<String, dynamic>?> loadEpisodeProgress(int episodeId) async {
    try {
      // First try to get from EpisodeProgressProvider for real-time updates
      if (_progressProvider != null) {
        final progress =
            await _progressProvider!.loadProgress(episodeId.toString());

        if (progress != null) {
          debugPrint(
              '✅ Progress loaded via provider: ${progress.episodeId} at ${progress.formattedCurrentPosition}');
          return {
            'position': progress.currentPosition,
            'duration': progress.totalDuration,
            'progress_percentage': progress.progressPercentage,
            'is_completed': progress.isCompleted,
            'last_played_at': progress.lastPlayedAt?.toIso8601String(),
            'completed_at': progress.completedAt?.toIso8601String(),
          };
        }
      }

      // Fallback to direct service call
      final progress = await _progressService.getProgress(episodeId.toString());

      if (progress != null) {
        debugPrint(
            '✅ Progress loaded from cloud: ${progress.episodeId} at ${progress.formattedCurrentPosition}');
        return {
          'position': progress.currentPosition,
          'duration': progress.totalDuration,
          'progress_percentage': progress.progressPercentage,
          'is_completed': progress.isCompleted,
          'last_played_at': progress.lastPlayedAt?.toIso8601String(),
          'completed_at': progress.completedAt?.toIso8601String(),
        };
      }

      // Fallback to local storage
      if (_localStorage != null) {
        final localProgress =
            await _localStorage!.getPlaybackProgress(episodeId);
        if (localProgress != null) {
          debugPrint('📱 Progress loaded from local storage: $episodeId');
          return localProgress;
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading episode progress: $e');
    }
    return null;
  }

  /// Resume episode from saved position
  Future<void> resumeEpisode(Episode episode) async {
    try {
      debugPrint('🔄 Resuming episode: ${episode.title}');

      // Load progress from local storage
      final progress = await loadEpisodeProgress(episode.id);

      if (progress != null && progress['position'] != null) {
        final savedPosition = Duration(milliseconds: progress['position']);
        final savedDuration = Duration(milliseconds: progress['duration'] ?? 0);

        debugPrint(
            '📱 Found saved position: ${savedPosition.inSeconds}s / ${savedDuration.inSeconds}s');

        // Set the episode with preserved progress
        setCurrentEpisode(episode, preservePlayingState: true);

        // Update position and duration
        _position = savedPosition;
        _duration = savedDuration;

        // Start playing from saved position
        _isPlaying = true;
        await _audioService.playEpisode(episode, skipResumeLogic: true);

        // Seek to saved position
        if (savedPosition.inMilliseconds > 0) {
          _audioService.seekTo(savedPosition);
        }

        debugPrint('✅ Episode resumed from saved position');
      } else {
        debugPrint('📱 No saved progress found, starting from beginning');
        // No saved progress, start from beginning
        setCurrentEpisode(episode, preservePlayingState: false);
        _isPlaying = true;
        await _audioService.playEpisode(episode, skipResumeLogic: true);
      }

      _savePlayerState();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error resuming episode: $e');
      // Fallback to normal play
      await loadAndPlayEpisode(episode);
    }
  }

  /// Check if episode has progress to resume
  bool hasEpisodeProgress(Episode episode) {
    return episode.lastPlayedPosition != null &&
        episode.lastPlayedPosition! > 0 &&
        episode.totalDuration != null &&
        episode.lastPlayedPosition! < episode.totalDuration!;
  }

  /// Get episode progress percentage
  double getEpisodeProgress(Episode episode) {
    if (episode.lastPlayedPosition == null ||
        episode.totalDuration == null ||
        episode.totalDuration == 0) {
      return 0.0;
    }
    return (episode.lastPlayedPosition! / episode.totalDuration!)
        .clamp(0.0, 1.0);
  }

  /// Handle episode abandonment - save progress when switching to another episode
  Future<void> abandonCurrentEpisode() async {
    if (_currentEpisode != null && _position.inMilliseconds > 0) {
      debugPrint(
          '🔄 Abandoning current episode: ${_currentEpisode!.title} at ${_position.inSeconds}s');

      try {
        // Save current progress before switching
        await updateEpisodeProgress(
            _currentEpisode!, _position, _duration ?? Duration.zero);

        // Mark as not completed since it was abandoned
        final abandonedEpisode = _currentEpisode!.copyWith(
          isCompleted: false,
          lastPlayedAt: DateTime.now(),
        );

        // Update current episode reference
        _currentEpisode = abandonedEpisode;

        debugPrint('✅ Episode progress saved before abandonment');
      } catch (e) {
        debugPrint('❌ Error saving episode progress before abandonment: $e');
      }
    }
  }

  /// Enhanced episode switching with progress preservation
  Future<void> switchToEpisode(Episode newEpisode,
      {bool preserveCurrentProgress = true}) async {
    try {
      debugPrint('🔄 Switching to episode: ${newEpisode.title}');

      // Save progress of current episode if requested
      if (preserveCurrentProgress && _currentEpisode != null) {
        await abandonCurrentEpisode();
      }

      // Set the new episode with preserved playing state for smooth transition
      setCurrentEpisode(newEpisode, preservePlayingState: true);

      // Check if new episode has saved progress
      if (hasEpisodeProgress(newEpisode)) {
        debugPrint(
            '📱 New episode has saved progress, will resume from saved position');
        // The audio service will handle position restoration
      } else {
        debugPrint(
            '📱 No saved progress for new episode, starting from beginning');
      }

      // Start playing the new episode
      _isPlaying = true;
      await _audioService.playEpisode(newEpisode, skipResumeLogic: true);

      _savePlayerState();
      notifyListeners();

      debugPrint('✅ Successfully switched to episode: ${newEpisode.title}');
    } catch (e) {
      debugPrint('❌ Error switching to episode: $e');

      // Set playing state to false on error
      _isPlaying = false;
      notifyListeners();

      // Fallback to normal episode loading
      try {
        await loadAndPlayEpisode(newEpisode);
      } catch (fallbackError) {
        debugPrint('❌ Even fallback episode loading failed: $fallbackError');
        // Continue anyway to prevent app from hanging
      }
    }
  }

  /// Handle app lifecycle events to save progress
  void onAppLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _saveProgressOnAppBackground();
        break;
      case AppLifecycleState.resumed:
        // App resumed, no action needed
        break;
      default:
        break;
    }
  }

  /// Save progress when app goes to background
  Future<void> _saveProgressOnAppBackground() async {
    if (_currentEpisode != null && _position.inMilliseconds > 0) {
      debugPrint('📱 App going to background, saving episode progress...');
      try {
        await updateEpisodeProgress(
            _currentEpisode!, _position, _duration ?? Duration.zero);
        debugPrint('✅ Episode progress saved on app background');
      } catch (e) {
        debugPrint('❌ Error saving episode progress on app background: $e');
      }
    }
  }

  /// Force save current progress (useful for manual saves)
  Future<void> forceSaveProgress() async {
    if (_currentEpisode != null && _position.inMilliseconds > 0) {
      debugPrint('💾 Force saving episode progress...');
      try {
        await updateEpisodeProgress(
            _currentEpisode!, _position, _duration ?? Duration.zero);
        debugPrint('✅ Episode progress force saved');
      } catch (e) {
        debugPrint('❌ Error force saving episode progress: $e');
      }
    }
  }

  // MARK: - Mark Episode as Completed

  /// Mark episode as completed
  Future<void> markEpisodeCompleted(Episode episode) async {
    try {
      debugPrint('✅ Marking episode as completed: ${episode.title}');

      // Mark as completed in progress service
      final success =
          await _progressService.markCompleted(episode.id.toString());

      if (success) {
        debugPrint('✅ Episode marked as completed in cloud: ${episode.title}');
      } else {
        debugPrint(
            '⚠️ Episode marked as completed locally only: ${episode.title}');
      }

      // Update local episode state
      final updatedEpisode = episode.copyWith(
        isCompleted: true,
        lastPlayedAt: DateTime.now(),
      );

      // Update current episode if it's the same one
      if (_currentEpisode?.id == episode.id) {
        _currentEpisode = updatedEpisode;
      }

      // Update local storage
      if (_localStorage != null) {
        await _localStorage!.updatePlaybackPosition(
          episode.id,
          episode.totalDuration ?? 0,
          episode.totalDuration ?? 0,
        );
      }

      _savePlayerState();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error marking episode as completed: $e');
    }
  }

  /// Get all episode progress for current user
  Future<List<Map<String, dynamic>>> getAllEpisodeProgress({
    String? podcastId,
    bool? completed,
  }) async {
    try {
      final progressList = await _progressService.getAllProgress(
        podcastId: podcastId,
        completed: completed,
      );

      return progressList
          .map((progress) => {
                'episode_id': progress.episodeId,
                'podcast_id': progress.podcastId,
                'position': progress.currentPosition,
                'duration': progress.totalDuration,
                'progress_percentage': progress.progressPercentage,
                'is_completed': progress.isCompleted,
                'last_played_at': progress.lastPlayedAt?.toIso8601String(),
                'completed_at': progress.completedAt?.toIso8601String(),
                'remaining_time': progress.formattedRemainingTime,
              })
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting all episode progress: $e');
      return [];
    }
  }

  /// Sync progress with cloud
  Future<bool> syncProgressWithCloud() async {
    try {
      debugPrint('🔄 Syncing progress with cloud...');
      final success = await _progressService.syncProgress();

      if (success) {
        debugPrint('✅ Progress synced with cloud successfully');
      } else {
        debugPrint('⚠️ Progress sync failed, using local data only');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error syncing progress with cloud: $e');
      return false;
    }
  }

  // MARK: - Episode Queue Management

  /// Check if episode is in current queue
  bool isEpisodeInQueue(Episode episode) {
    return _episodeQueue.any((e) => e.id == episode.id);
  }

  /// Get episode index in queue
  int getEpisodeIndexInQueue(Episode episode) {
    return _episodeQueue.indexWhere((e) => e.id == episode.id);
  }

  /// Move to next episode in queue
  Future<void> playNextEpisode() async {
    if (_episodeQueue.isEmpty ||
        _currentEpisodeIndex >= _episodeQueue.length - 1) {
      debugPrint('⚠️ No next episode available');
      return;
    }

    try {
      final nextEpisode = _episodeQueue[_currentEpisodeIndex + 1];
      debugPrint('🔄 Playing next episode: ${nextEpisode.title}');

      await switchToEpisode(nextEpisode, preserveCurrentProgress: true);
    } catch (e) {
      debugPrint('❌ Error playing next episode: $e');
    }
  }

  /// Move to previous episode in queue
  Future<void> playPreviousEpisode() async {
    if (_episodeQueue.isEmpty || _currentEpisodeIndex <= 0) {
      debugPrint('⚠️ No previous episode available');
      return;
    }

    try {
      final prevEpisode = _episodeQueue[_currentEpisodeIndex - 1];
      debugPrint('🔄 Playing previous episode: ${prevEpisode.title}');

      await switchToEpisode(prevEpisode, preserveCurrentProgress: true);
    } catch (e) {
      debugPrint('❌ Error playing previous episode: $e');
    }
  }

  /// Jump to specific episode in queue
  Future<void> jumpToEpisodeInQueue(int index) async {
    if (_episodeQueue.isEmpty || index < 0 || index >= _episodeQueue.length) {
      debugPrint(
          '⚠️ Invalid episode index: $index (total: ${_episodeQueue.length})');
      return;
    }

    try {
      final targetEpisode = _episodeQueue[index];
      debugPrint(
          '🔄 Jumping to episode at index $index: ${targetEpisode.title}');

      await switchToEpisode(targetEpisode, preserveCurrentProgress: true);
    } catch (e) {
      debugPrint('❌ Error jumping to episode: $e');
    }
  }

  // MARK: - Cleanup

  // Override dispose to save state
  @override
  void dispose() {
    if (shouldPreserveState) {
      _savePlayerState();
    }
    super.dispose();
  }
}
