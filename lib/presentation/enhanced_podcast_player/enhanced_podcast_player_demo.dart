import 'package:flutter/material.dart';
import '../../models/buffering_models.dart';
import 'enhanced_podcast_player.dart';

/// Demo screen to showcase the enhanced audio player
class EnhancedPodcastPlayerDemo extends StatelessWidget {
  const EnhancedPodcastPlayerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a sample episode for demo
    final demoEpisode = Episode(
      id: 'demo-1',
      title: 'Sample Podcast Episode',
      description:
          'This is a sample episode to demonstrate the enhanced audio player with buffering features.',
      duration: const Duration(minutes: 45, seconds: 30),
      imageUrl:
          'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=Podcast',
      audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
      podcastTitle: 'Sample Podcast',
      podcastAuthor: 'Sample Author',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Audio Player Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Demo description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enhanced Audio Player Features',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This demo showcases the enhanced audio player with:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                        '🎵 Real-time buffering state management'),
                    _buildFeatureItem(
                        '🌐 Network quality detection and adaptation'),
                    _buildFeatureItem('📊 Visual buffering indicators'),
                    _buildFeatureItem(
                        '⚡ Adaptive audio quality based on connection'),
                    _buildFeatureItem('🔄 Seamless episode transitions'),
                    _buildFeatureItem('📱 Background audio support'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Launch enhanced player button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnhancedPodcastPlayer(
                      episode: demoEpisode,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Launch Enhanced Player'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 16),

            // Feature comparison
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feature Comparison',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonRow('Buffering State', '✅', '❌'),
                    _buildComparisonRow('Network Quality', '✅', '❌'),
                    _buildComparisonRow('Adaptive Quality', '✅', '❌'),
                    _buildComparisonRow('Visual Indicators', '✅', '❌'),
                    _buildComparisonRow('Background Audio', '✅', '❌'),
                    _buildComparisonRow('Seamless Transitions', '✅', '❌'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, String enhanced, String basic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(feature)),
          Expanded(
              child: Center(
                  child: Text(enhanced, style: const TextStyle(fontSize: 18)))),
          Expanded(
              child: Center(
                  child: Text(basic, style: const TextStyle(fontSize: 18)))),
        ],
      ),
    );
  }
}
