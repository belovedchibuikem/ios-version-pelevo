import 'package:flutter/material.dart';
import '../../data/models/episode.dart';
import '../../providers/podcast_player_provider.dart';
import 'media_session_manager.dart';

/// Example implementation showing how to use the Media Session Manager
/// This file demonstrates the proper integration pattern
class MediaSessionExample {
  static final MediaSessionManager _mediaSessionManager = MediaSessionManager();

  /// Initialize media session in your main app
  static Future<void> initializeMediaSession(
      PodcastPlayerProvider playerProvider) async {
    try {
      await _mediaSessionManager.initialize(playerProvider: playerProvider);
      debugPrint('✅ Media session initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize media session: $e');
    }
  }

  /// Example: Play an episode with media session integration
  static Future<void> playEpisodeWithMediaSession(
    PodcastPlayerProvider playerProvider,
    Episode episode,
  ) async {
    try {
      // Set the episode in media session
      _mediaSessionManager.setEpisode(episode);

      // Play the episode using your existing player
      await playerProvider.playEpisode(episode);

      // Update media session state
      _mediaSessionManager.updatePlaybackState(
        isPlaying: true,
        position: Duration.zero,
        duration: Duration(seconds: int.tryParse(episode.duration) ?? 0),
      );

      debugPrint('🎵 Episode started with media session: ${episode.title}');
    } catch (e) {
      debugPrint('❌ Error playing episode with media session: $e');
    }
  }

  /// Example: Update playback state when player state changes
  static void updatePlaybackState(
    bool isPlaying,
    Duration position,
    Duration duration,
  ) {
    _mediaSessionManager.updatePlaybackState(
      isPlaying: isPlaying,
      position: position,
      duration: duration,
    );
  }

  /// Example: Listen to media session events
  static void setupMediaSessionListeners() {
    // Listen to episode changes
    _mediaSessionManager.episodeStream.listen((episode) {
      if (episode != null) {
        debugPrint('🎵 Media session episode changed: ${episode.title}');
      }
    });

    // Listen to playing state changes
    _mediaSessionManager.playingStream.listen((isPlaying) {
      debugPrint(
          '🎵 Media session playing state: ${isPlaying ? 'Playing' : 'Paused'}');
    });

    // Listen to position changes
    _mediaSessionManager.positionStream.listen((position) {
      debugPrint('🎵 Media session position: ${position.inSeconds}s');
    });

    // Listen to duration changes
    _mediaSessionManager.durationStream.listen((duration) {
      debugPrint('🎵 Media session duration: ${duration.inSeconds}s');
    });
  }

  /// Dispose media session when app is closed
  static Future<void> disposeMediaSession() async {
    await _mediaSessionManager.dispose();
  }
}

/// Widget that demonstrates media session integration
class MediaSessionDemoWidget extends StatefulWidget {
  final PodcastPlayerProvider playerProvider;
  final Episode episode;

  const MediaSessionDemoWidget({
    Key? key,
    required this.playerProvider,
    required this.episode,
  }) : super(key: key);

  @override
  State<MediaSessionDemoWidget> createState() => _MediaSessionDemoWidgetState();
}

class _MediaSessionDemoWidgetState extends State<MediaSessionDemoWidget> {
  @override
  void initState() {
    super.initState();
    // Setup media session listeners
    MediaSessionExample.setupMediaSessionListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Media Session Demo'),
        Text('Episode: ${widget.episode.title}'),
        ElevatedButton(
          onPressed: () async {
            await MediaSessionExample.playEpisodeWithMediaSession(
              widget.playerProvider,
              widget.episode,
            );
          },
          child: Text('Play with Media Session'),
        ),
        ElevatedButton(
          onPressed: () {
            MediaSessionExample.updatePlaybackState(
              true,
              Duration(seconds: 30),
              Duration(minutes: 5),
            );
          },
          child: Text('Update Playback State'),
        ),
      ],
    );
  }
}
