import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/episode.dart';
import '../../providers/podcast_player_provider.dart';

class SimpleMediaSession {
  static final SimpleMediaSession _instance = SimpleMediaSession._internal();
  factory SimpleMediaSession() => _instance;
  SimpleMediaSession._internal();

  AudioHandler? _audioHandler;
  bool _isInitialized = false;
  PodcastPlayerProvider? _playerProvider;

  // Current state
  Episode? _currentEpisode;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Stream controllers
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

  Future<void> initialize({PodcastPlayerProvider? playerProvider}) async {
    if (_isInitialized) return;

    try {
      _playerProvider = playerProvider;

      // Initialize audio service with a simple handler
      _audioHandler = await AudioService.init(
        builder: () => SimpleAudioHandler(playerProvider),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.pelevo.podcast.media',
          androidNotificationChannelName: 'Pelevo Podcast',
          androidNotificationChannelDescription: 'Podcast playback controls',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'drawable/ic_stat_music_note',
          notificationColor: Color(0xFF2196F3),
        ),
      );

      _isInitialized = true;
      debugPrint('✅ SimpleMediaSession initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing SimpleMediaSession: $e');
      _isInitialized = true; // Continue without media session
    }
  }

  void setEpisode(Episode episode) {
    _currentEpisode = episode;
    _episodeController.add(episode);

    if (_audioHandler != null) {
      // Update the media item with episode info
      final handler = _audioHandler as SimpleAudioHandler;
      handler.setMediaItem(MediaItem(
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
      ));

      debugPrint('🎵 Media session updated with episode: ${episode.title}');
    }
  }

  void updatePlaybackState(
      {required bool isPlaying, Duration? position, Duration? duration}) {
    if (_audioHandler != null) {
      _isPlaying = isPlaying;
      if (position != null) _position = position;
      if (duration != null) _duration = duration;

      _playingController.add(isPlaying);
      if (position != null) _positionController.add(position);
      if (duration != null) _durationController.add(duration);

      // Use the helper method instead of trying to call add() directly
      final handler = _audioHandler as SimpleAudioHandler;
      handler.setPlaybackState(PlaybackState(
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
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: isPlaying,
        updatePosition: position ?? Duration.zero,
        bufferedPosition: duration ?? Duration.zero,
        speed: 1.0,
      ));

      debugPrint(
          '🎵 Playback state updated: ${isPlaying ? 'Playing' : 'Paused'}');
    }
  }

  Future<void> dispose() async {
    try {
      await _audioHandler?.stop();
      _episodeController.close();
      _playingController.close();
      _positionController.close();
      _durationController.close();
      debugPrint('✅ SimpleMediaSession disposed');
    } catch (e) {
      debugPrint('❌ Error disposing SimpleMediaSession: $e');
    }
  }
}

class SimpleAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final PodcastPlayerProvider? _playerProvider;

  SimpleAudioHandler(this._playerProvider) {
    _setupPlayer();
  }

  // Helper methods to update the ValueStream
  void setMediaItem(MediaItem item) {
    mediaItem.value = item;
  }

  void setPlaybackState(PlaybackState state) {
    playbackState.value = state;
  }

  void _setupPlayer() {
    // Listen to player state changes
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.value = playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: {
          AudioProcessingState.idle: AudioProcessingState.idle,
          AudioProcessingState.loading: AudioProcessingState.loading,
          AudioProcessingState.buffering: AudioProcessingState.buffering,
          AudioProcessingState.ready: AudioProcessingState.ready,
          AudioProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      );
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.value = newQueue;
      mediaItem.value = newMediaItem;
    });

    // Listen to current index changes
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      mediaItem.value = playlist[index];
    });
  }

  @override
  Future<void> play() async {
    if (_playerProvider != null) {
      await _playerProvider!.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_playerProvider != null) {
      await _playerProvider!.pause();
    }
  }

  @override
  Future<void> stop() async {
    if (_playerProvider != null) {
      await _playerProvider!.pause();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playerProvider != null) {
      _playerProvider!.seekTo(position);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_playerProvider != null) {
      _playerProvider!.playNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playerProvider != null) {
      _playerProvider!.playPrevious();
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}
