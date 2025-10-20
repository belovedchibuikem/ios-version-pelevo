// lib/examples/mini_player_integration_example.dart
// Example of how to integrate thermal management into your mini player

import 'package:flutter/material.dart';
import '../widgets/thermal_management_widget.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Episode artwork
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note),
          ),

          // Episode info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Episode Title',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Podcast Name',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Progress bar
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 2,
                  child: const LinearProgressIndicator(value: 0.3),
                ),
              ],
            ),
          ),

          // Thermal indicator (compact)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CompactThermalIndicator(),
          ),

          // Play/Pause button
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {},
          ),

          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'thermal') {
                _showThermalDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'thermal',
                child: Row(
                  children: [
                    Icon(Icons.thermostat, size: 16),
                    SizedBox(width: 8),
                    Text('Thermal Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 16),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  void _showThermalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.thermostat, color: Colors.orange),
            SizedBox(width: 8),
            Text('Device Temperature'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: const ThermalManagementWidget(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
