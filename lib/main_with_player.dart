import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'core/app_export.dart';
import 'providers/podcast_player_provider.dart';
import 'widgets/podcast_player.dart';
import 'widgets/episode_detail_modal.dart';
import 'data/models/episode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PodcastPlayerProvider()),
        // Add other providers here
      ],
      child: MaterialApp(
        title: 'Pelevo Podcast',
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // App header
                Container(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic,
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 32,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Pelevo Podcast',
                        style: AppTheme.lightTheme.textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Demo content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 80,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Welcome to Pelevo Podcast',
                          style: AppTheme.lightTheme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Your podcast player is ready!\nTap the demo button to test the player.',
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),

                        // Demo buttons
                        ElevatedButton.icon(
                          onPressed: () {
                            _showDemoPlayer(context);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Test Player'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                          ),
                        ),

                        SizedBox(height: 2.h),

                        OutlinedButton.icon(
                          onPressed: () {
                            _showEpisodeDetailModal(context);
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Episode Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                AppTheme.lightTheme.colorScheme.primary,
                            side: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Podcast Player (floating at bottom)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PodcastPlayer(),
          ),
        ],
      ),
    );
  }

  void _showDemoPlayer(BuildContext context) {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);

    // Create a demo episode
    final demoEpisode = {
      'id': 'demo_1',
      'title': 'Demo Episode: Introduction to Pelevo',
      'description':
          'This is a demo episode to showcase the podcast player functionality. It includes all the features like play/pause, seeking, bookmarks, and more.',
      'duration': '15:30',
      'coverImage':
          'https://via.placeholder.com/300x300/2196F3/FFFFFF?text=Demo',
      'podcastName': 'Demo Podcast',
      'creator': 'Pelevo Team',
      'publishDate': '2024-01-15',
      'audioUrl':
          'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav', // Demo audio
    };

    // Set the demo episode
    final episode = Episode.fromJson(demoEpisode);
    playerProvider.setCurrentEpisode(episode);

    // Show the full player
    playerProvider.setMinimized(false);

    // Show a snackbar to confirm
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo player activated! Check the bottom player.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEpisodeDetailModal(BuildContext context) {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);

    // Create demo episodes
    final demoEpisodes = [
      {
        'id': 'demo_1',
        'title': 'Demo Episode 1: Introduction',
        'description': 'This is the first demo episode.',
        'duration': '15:30',
        'coverImage':
            'https://via.placeholder.com/300x300/2196F3/FFFFFF?text=Demo+1',
        'podcastName': 'Demo Podcast',
        'creator': 'Pelevo Team',
        'publishDate': '2024-01-15',
        'audioUrl': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
      },
      {
        'id': 'demo_2',
        'title': 'Demo Episode 2: Features',
        'description': 'This episode showcases all the features.',
        'duration': '22:45',
        'coverImage':
            'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=Demo+2',
        'podcastName': 'Demo Podcast',
        'creator': 'Pelevo Team',
        'publishDate': '2024-01-16',
        'audioUrl': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
      },
    ];

    // Show the episode detail modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeAreaUtils.wrapWithSafeArea(
        DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => EpisodeDetailModal(
            episode: demoEpisodes[0],
            episodes: demoEpisodes,
            episodeIndex: 0,
          ),
        ),
      ),
    );
  }
}
