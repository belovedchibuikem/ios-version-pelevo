import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/buffering_models.dart';
import '../data/models/episode.dart' as episode_model;
import '../core/services/media_session_service.dart';

class EnhancedAudioPlayerService {
  static final EnhancedAudioPlayerService _instance =
      EnhancedAudioPlayerService._internal();
  factory EnhancedAudioPlayerService() => _instance;
  EnhancedAudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Media session integration
  final MediaSessionService _mediaSession = MediaSessionService();

  episode_model.Episode? _currentEpisode;
  BufferingState _bufferingState = BufferingState.idle;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  final StreamController<BufferingState> _bufferingStateController =
      StreamController<BufferingState>.broadcast();
  final StreamController<bool> _playingStateController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<episode_model.Episode?> _currentEpisodeController =
      StreamController<episode_model.Episode?>.broadcast();

  episode_model.Episode? get currentEpisode => _currentEpisode;
  BufferingState get bufferingState => _bufferingState;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  Stream<BufferingState> get bufferingStateStream =>
      _bufferingStateController.stream;
  Stream<bool> get playingStateStream => _playingStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<episode_model.Episode?> get currentEpisodeStream =>
      _currentEpisodeController.stream;

  // Additional streams for compatibility
  Stream<Duration> get durationStream => Stream.value(_totalDuration);
  Stream<void> get onEpisodeComplete => _audioPlayer.onPlayerComplete;

  Future<void> initialize({dynamic playerProvider}) async {
    await _audioPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
        ),
      ),
    );

    _audioPlayer.onPlayerStateChanged.listen(_handlePlayerStateChange);
    _audioPlayer.onPositionChanged.listen(_handlePositionChange);
    _audioPlayer.onDurationChanged.listen(_handleDurationChange);

    // Initialize media session with player provider
    debugPrint('🎵 EnhancedAudioPlayerService: Initializing media session...');
    await _mediaSession.initialize(playerProvider: playerProvider);
    debugPrint(
        '🎵 EnhancedAudioPlayerService: Media session initialized successfully');
  }

  Future<void> loadAndPlayEpisode(episode_model.Episode episode) async {
    try {
      _updateBufferingState(BufferingState.loading);
      _currentEpisode = episode;
      _currentEpisodeController.add(_currentEpisode);

      if (episode.audioUrl == null || episode.audioUrl!.isEmpty) {
        _updateBufferingState(BufferingState.error);
        throw Exception(
            'No audio URL available for this episode. Please try another episode or check your internet connection.');
      }

      debugPrint(
          'EnhancedAudioPlayerService: Loading episode: ${episode.title}');
      debugPrint('EnhancedAudioPlayerService: Audio URL: ${episode.audioUrl}');

      // Check if the audio URL is a local file path
      if (episode.audioUrl!.startsWith('/') ||
          episode.audioUrl!.startsWith('file://')) {
        // Local file - use DeviceFileSource
        debugPrint(
            'EnhancedAudioPlayerService: Loading local file: ${episode.audioUrl}');
        await _audioPlayer.setSource(DeviceFileSource(episode.audioUrl!));
      } else {
        // Remote URL - use UrlSource
        debugPrint(
            'EnhancedAudioPlayerService: Loading remote URL: ${episode.audioUrl}');
        await _audioPlayer.setSource(UrlSource(episode.audioUrl!));
      }

      _updateBufferingState(BufferingState.ready);

      // Update media session with episode info
      _mediaSession.setEpisode(episode);

      await play();
    } catch (e) {
      _updateBufferingState(BufferingState.error);
      debugPrint('EnhancedAudioPlayerService: Error loading episode: $e');
      rethrow;
    }
  }

  /// Load and play episode from Map format (for compatibility)
  Future<void> loadAndPlayEpisodeFromMap(
      Map<String, dynamic> episodeMap) async {
    final episode = episode_model.Episode.fromJson(episodeMap);
    await loadAndPlayEpisode(episode);
  }

  void _handlePlayerStateChange(PlayerState state) {
    switch (state) {
      case PlayerState.playing:
        _isPlaying = true;
        _playingStateController.add(_isPlaying);
        _updateBufferingState(BufferingState.ready);
        // Update media session
        _mediaSession.updatePlaybackState(
          isPlaying: true,
          position: _currentPosition,
          duration: _totalDuration,
        );
        break;
      case PlayerState.paused:
        _isPlaying = false;
        _playingStateController.add(_isPlaying);
        _updateBufferingState(BufferingState.paused);
        // Update media session
        _mediaSession.updatePlaybackState(
          isPlaying: false,
          position: _currentPosition,
          duration: _totalDuration,
        );
        break;
      case PlayerState.stopped:
        _isPlaying = false;
        _playingStateController.add(_isPlaying);
        _updateBufferingState(BufferingState.idle);
        // Update media session
        _mediaSession.updatePlaybackState(
          isPlaying: false,
          position: Duration.zero,
          duration: _totalDuration,
        );
        break;
      default:
        _updateBufferingState(BufferingState.idle);
    }
  }

  void _handlePositionChange(Duration position) {
    _currentPosition = position;
    _positionController.add(_currentPosition);
    // Update media session position
    _mediaSession.updatePosition(position);
  }

  void _handleDurationChange(Duration duration) {
    _totalDuration = duration;
    // Update media session duration
    _mediaSession.updateDuration(duration);
  }

  void _updateBufferingState(BufferingState state) {
    _bufferingState = state;
    _bufferingStateController.add(_bufferingState);
  }

  Future<void> play() async {
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    try {
      debugPrint(
          '🎵 EnhancedAudioPlayerService: Seeking to ${position.inSeconds}s');
      await _audioPlayer.seek(position);
      _currentPosition = position;
      _positionController.add(_currentPosition);
      debugPrint('🎵 EnhancedAudioPlayerService: Seek completed successfully');
    } catch (e) {
      debugPrint('❌ EnhancedAudioPlayerService: Error seeking: $e');
      rethrow;
    }
  }

  Future<void> skipForward([int seconds = 30]) async {
    final newPosition = _currentPosition + Duration(seconds: seconds);
    if (newPosition <= _totalDuration) {
      await seek(newPosition);
    } else {
      await seek(_totalDuration);
    }
  }

  Future<void> skipBackward([int seconds = 15]) async {
    final newPosition = _currentPosition - Duration(seconds: seconds);
    if (newPosition >= Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  void dispose() {
    _bufferingStateController.close();
    _playingStateController.close();
    _positionController.close();
    _currentEpisodeController.close();
    _mediaSession.dispose();
    _audioPlayer.dispose();
  }
}
