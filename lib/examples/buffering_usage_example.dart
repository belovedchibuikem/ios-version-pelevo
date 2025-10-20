// lib/examples/buffering_usage_example.dart
// Example showing how to use the smart buffering features

import 'package:flutter/material.dart';
import '../widgets/buffering_indicator.dart';
import '../services/audio_player_service.dart';
import '../services/smart_buffering_service.dart';

class BufferingUsageExample extends StatefulWidget {
  const BufferingUsageExample({Key? key}) : super(key: key);

  @override
  State<BufferingUsageExample> createState() => _BufferingUsageExampleState();
}

class _BufferingUsageExampleState extends State<BufferingUsageExample> {
  final AudioPlayerService _audioService = AudioPlayerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Buffering Demo'),
        actions: [
          // Compact buffering indicator in app bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactBufferingIndicator(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Buffering status chip
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Status: '),
                BufferingStatusChip(),
              ],
            ),
          ),

          // Main content with buffering overlay
          Expanded(
            child: BufferingIndicator(
              showProgress: true,
              showStatus: true,
              child: _buildMainContent(),
            ),
          ),

          // Buffering controls
          _buildBufferingControls(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Your podcast content goes here',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),

          // Example: Show buffering stats
          StreamBuilder<Map<String, dynamic>>(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (_) => _audioService.getBufferingStats(),
            ),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {};

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buffering Statistics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Strategy: ${stats['currentStrategy'] ?? 'Unknown'}'),
                      Text('Is Buffering: ${stats['isBuffering'] ?? false}'),
                      Text(
                          'Progress: ${((stats['bufferingProgress'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                      Text(
                          'Preloaded: ${stats['preloadedCount'] ?? 0} episodes'),
                      Text(
                          'Connectivity: ${stats['connectivity'] ?? 'Unknown'}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBufferingControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buffering Strategy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _audioService
                      .setBufferingStrategy(BufferingStrategy.conservative),
                  child: const Text('Conservative'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _audioService
                      .setBufferingStrategy(BufferingStrategy.balanced),
                  child: const Text('Balanced'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _audioService
                      .setBufferingStrategy(BufferingStrategy.aggressive),
                  child: const Text('Aggressive'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Example of how to wrap your existing player screen with buffering indicators
class PlayerScreenWithBuffering extends StatelessWidget {
  final Widget playerContent;

  const PlayerScreenWithBuffering({
    Key? key,
    required this.playerContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BufferingIndicator(
      showProgress: true,
      showStatus: true,
      child: playerContent,
    );
  }
}

/// Example of how to add buffering status to your mini player
class MiniPlayerWithBuffering extends StatelessWidget {
  const MiniPlayerWithBuffering({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Your mini player content
          const Expanded(
            child: Text('Now Playing: Episode Title'),
          ),

          // Compact buffering indicator
          CompactBufferingIndicator(size: 16),

          const SizedBox(width: 8),

          // Buffering status text
          StreamBuilder<String>(
            stream: AudioPlayerService().bufferingService.statusStream,
            builder: (context, snapshot) {
              final status = snapshot.data ?? '';
              if (status.isEmpty || status == 'Ready') {
                return const SizedBox.shrink();
              }

              return Text(
                status,
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ],
      ),
    );
  }
}
