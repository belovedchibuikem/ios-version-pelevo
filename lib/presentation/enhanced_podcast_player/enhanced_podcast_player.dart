import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/buffering_models.dart';
import '../../data/models/episode.dart' as episode_model;
import '../../services/enhanced_audio_player_service.dart';
import '../../services/network_quality_service.dart';
import '../widgets/buffering_indicator.dart';
import '../../widgets/custom_image_widget.dart';

/// Enhanced podcast player screen with buffering features
class EnhancedPodcastPlayer extends StatefulWidget {
  final Episode episode;

  const EnhancedPodcastPlayer({
    super.key,
    required this.episode,
  });

  @override
  State<EnhancedPodcastPlayer> createState() => _EnhancedPodcastPlayerState();
}

class _EnhancedPodcastPlayerState extends State<EnhancedPodcastPlayer> {
  late EnhancedAudioPlayerService _audioPlayerService;
  late NetworkQualityService _networkQualityService;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = EnhancedAudioPlayerService();
    _networkQualityService = NetworkQualityService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _audioPlayerService.initialize(playerProvider: null);
    await _networkQualityService.initialize();

    // Load and play the episode
    final episodeModel =
        episode_model.Episode.fromJson(widget.episode.toJson());
    await _audioPlayerService.loadAndPlayEpisode(episodeModel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Episode artwork and info
          Expanded(
            flex: 3,
            child: _buildEpisodeInfo(),
          ),

          // Progress and controls
          Expanded(
            flex: 2,
            child: _buildPlayerControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeInfo() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Episode artwork
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomImageWidget(
                imageUrl: widget.episode.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Episode title
          Text(
            widget.episode.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Podcast title
          if (widget.episode.podcastTitle != null)
            Text(
              widget.episode.podcastTitle!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 16),

          // Network quality indicator
          StreamBuilder<NetworkQuality>(
            stream: _networkQualityService.qualityStream,
            builder: (context, snapshot) {
              final quality = snapshot.data ?? NetworkQuality.unknown;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NetworkQualityIndicator(quality: quality),
                  const SizedBox(width: 8),
                  Text(
                    _networkQualityService.qualityDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Progress bar
          StreamBuilder<Duration>(
            stream: _audioPlayerService.positionStream,
            builder: (context, positionSnapshot) {
              final position = positionSnapshot.data ?? Duration.zero;

              return Column(
                children: [
                  // Progress slider
                  Slider(
                    value: _audioPlayerService.totalDuration.inMilliseconds > 0
                        ? position.inMilliseconds /
                            _audioPlayerService.totalDuration.inMilliseconds
                        : 0.0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (value *
                                _audioPlayerService
                                    .totalDuration.inMilliseconds)
                            .round(),
                      );
                      _audioPlayerService.seek(newPosition);
                    },
                  ),

                  // Time display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _formatDuration(_audioPlayerService.totalDuration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip backward
              IconButton(
                onPressed: () => _audioPlayerService.skipBackward(15),
                icon: const Icon(Icons.replay),
                iconSize: 32,
              ),

              // Play/Pause button
              StreamBuilder<bool>(
                stream: _audioPlayerService.playingStateStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;

                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (isPlaying) {
                          _audioPlayerService.pause();
                        } else {
                          _audioPlayerService.play();
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),

              // Skip forward
              IconButton(
                onPressed: () => _audioPlayerService.skipForward(30),
                icon: const Icon(Icons.fast_forward),
                iconSize: 32,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Buffering indicator
          StreamBuilder<BufferingState>(
            stream: _audioPlayerService.bufferingStateStream,
            builder: (context, snapshot) {
              final bufferingState = snapshot.data ?? BufferingState.idle;

              if (bufferingState == BufferingState.ready ||
                  bufferingState == BufferingState.idle) {
                return const SizedBox.shrink();
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BufferingIndicator(state: bufferingState),
                  const SizedBox(width: 12),
                  Text(
                    _getBufferingMessage(bufferingState),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  String _getBufferingMessage(BufferingState state) {
    switch (state) {
      case BufferingState.loading:
        return 'Loading episode...';
      case BufferingState.buffering:
        return 'Buffering...';
      case BufferingState.error:
        return 'Error loading episode';
      case BufferingState.paused:
        return 'Paused';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    _networkQualityService.dispose();
    super.dispose();
  }
}
