import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/episode.dart';
import '../../providers/podcast_player_provider.dart';

/// Enhanced Audio Handler for system media controls integration
/// This class extends BaseAudioHandler to provide full system media control support
class EnhancedPodcastAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final PodcastPlayerProvider _playerProvider;

  EnhancedPodcastAudioHandler(this._playerProvider) {
    _setupAudioHandler();
    _connectToPlayerProvider();
  }

  /// Set up the audio handler with initial configuration
  void _setupAudioHandler() {
    // Set up initial playback state
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
      queueIndex: 0,
    ));

    // Set up empty queue initially
    queue.add([]);
  }

  /// Connect to the player provider for real-time updates
  void _connectToPlayerProvider() {
    // Listen to player provider changes
    _playerProvider.addListener(() {
      _updatePlaybackState();
      _updateMediaItem();
    });
  }

  /// Update the current media item based on current episode
  void _updateMediaItem() {
    final episode = _playerProvider.currentEpisode;
    if (episode != null) {
      final mediaItem = MediaItem(
        id: episode.id.toString(),
        album: episode.podcastName ?? 'Unknown Podcast',
        title: episode.title,
        artist: episode.podcastName ?? 'Unknown Podcast',
        duration: _playerProvider.duration,
        artUri: episode.coverImage != null && episode.coverImage!.isNotEmpty
            ? Uri.parse(episode.coverImage!)
            : null,
        extras: {
          'episodeId': episode.id.toString(),
          'podcastId': episode.podcastId,
          'description': episode.description ?? '',
          'publishedAt': episode.releaseDate.toIso8601String(),
          'duration': episode.duration,
        },
      );

      // Update the current media item
      this.mediaItem.add(mediaItem);

      // Update queue if we have episodes
      if (_playerProvider.episodeQueue.isNotEmpty) {
        final queueItems = _playerProvider.episodeQueue
            .map((ep) => MediaItem(
                  id: ep.id.toString(),
                  album: ep.podcastName ?? 'Unknown Podcast',
                  title: ep.title,
                  artist: ep.podcastName ?? 'Unknown Podcast',
                  duration: ep.duration != null
                      ? Duration(seconds: int.tryParse(ep.duration) ?? 0)
                      : Duration.zero,
                  artUri: ep.coverImage != null && ep.coverImage!.isNotEmpty
                      ? Uri.parse(ep.coverImage!)
                      : null,
                ))
            .toList();

        queue.add(queueItems);
      }
    }
  }

  /// Update playback state based on current player state
  void _updatePlaybackState() {
    final isPlaying = _playerProvider.isPlaying;
    final position = _playerProvider.position;
    final duration = _playerProvider.duration;
    final isBuffering = _playerProvider.isBuffering;

    final processingState = isBuffering
        ? AudioProcessingState.buffering
        : (isPlaying ? AudioProcessingState.ready : AudioProcessingState.idle);

    final controls = [
      MediaControl.skipToPrevious,
      isPlaying ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];

    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: isPlaying,
      updatePosition: position,
      bufferedPosition: position,
      speed: _playerProvider.playbackSpeed,
      queueIndex: _playerProvider.currentEpisodeIndex,
    ));
  }

  // MARK: - Required Audio Handler Methods

  @override
  Future<void> play() async {
    try {
      await _playerProvider.play();
      _updatePlaybackState();
      debugPrint('🎵 EnhancedAudioHandler: Play command executed');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Play command failed: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _playerProvider.pause();
      _updatePlaybackState();
      debugPrint('⏸️ EnhancedAudioHandler: Pause command executed');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Pause command failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      // Use pause instead of stop since PodcastPlayerProvider doesn't have stop method
      await _playerProvider.pause();
      _updatePlaybackState();
      debugPrint(
          '⏹️ EnhancedAudioHandler: Stop command executed (using pause)');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Stop command failed: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      // Use seekTo method from PodcastPlayerProvider
      _playerProvider.seekTo(position);
      _updatePlaybackState();
      debugPrint(
          '⏩ EnhancedAudioHandler: Seek to ${position.inSeconds}s executed');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Seek command failed: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      _playerProvider.playNext();
      _updateMediaItem();
      _updatePlaybackState();
      debugPrint('⏭️ EnhancedAudioHandler: Skip to next executed');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Skip to next failed: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      _playerProvider.playPrevious();
      _updateMediaItem();
      _updatePlaybackState();
      debugPrint('⏮️ EnhancedAudioHandler: Skip to previous executed');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Skip to previous failed: $e');
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      _playerProvider.setPlaybackSpeed(speed);
      _updatePlaybackState();
      debugPrint('⚡ EnhancedAudioHandler: Speed set to ${speed}x');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Speed change failed: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      // Note: Volume control might need to be implemented in the audio service
      debugPrint(
          '🔊 EnhancedAudioHandler: Volume set to ${(volume * 100).round()}%');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Volume change failed: $e');
    }
  }

  /// Handle custom actions like sleep timer, shuffle, etc.
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    try {
      switch (name) {
        case 'sleep_timer':
          final minutes = extras?['minutes'] as int? ?? 30;
          _playerProvider.setSleepTimer(Duration(minutes: minutes));
          debugPrint(
              '⏰ EnhancedAudioHandler: Sleep timer set to $minutes minutes');
          break;
        case 'shuffle':
          _playerProvider.toggleShuffle();
          debugPrint('🔀 EnhancedAudioHandler: Shuffle toggled');
          break;
        case 'repeat':
          _playerProvider.toggleRepeat();
          debugPrint('🔁 EnhancedAudioHandler: Repeat toggled');
          break;
        default:
          debugPrint('⚠️ EnhancedAudioHandler: Unknown custom action: $name');
      }
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler: Custom action $name failed: $e');
    }
  }

  /// Dispose resources
  @override
  Future<void> dispose() async {
    try {
      await _player.dispose();
      debugPrint('✅ EnhancedAudioHandler disposed successfully');
    } catch (e) {
      debugPrint('❌ EnhancedAudioHandler disposal failed: $e');
    }
    // Note: BaseAudioHandler doesn't have dispose method, so we don't call super.dispose()
  }
}
