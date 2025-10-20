// lib/examples/player_screen_integration_example.dart
// Example of how to integrate thermal management into your player screen

import 'package:flutter/material.dart';
import '../widgets/thermal_management_widget.dart';
import '../services/audio_player_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _showThermalDetails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          // Compact thermal indicator - always visible
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactThermalIndicator(),
          ),

          // Thermal details button
          IconButton(
            icon: const Icon(Icons.thermostat),
            onPressed: () {
              setState(() {
                _showThermalDetails = !_showThermalDetails;
              });
            },
            tooltip: 'Thermal Management',
          ),
        ],
      ),
      body: Column(
        children: [
          // Your existing player content
          Expanded(
            child: _buildPlayerContent(),
          ),

          // Thermal management details (expandable)
          if (_showThermalDetails) _buildThermalDetails(),

          // Your existing player controls
          _buildPlayerControls(),
        ],
      ),
    );
  }

  Widget _buildPlayerContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Episode artwork
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note, size: 100),
          ),
          const SizedBox(height: 20),

          // Episode title
          const Text(
            'Episode Title',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Podcast name
          const Text(
            'Podcast Name',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // Progress bar
          const LinearProgressIndicator(value: 0.3),
          const SizedBox(height: 10),

          // Time display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('5:30'),
              const Text('18:45'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThermalDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.thermostat, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Device Temperature',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showThermalDetails = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Temperature status
              StreamBuilder<double>(
                stream: _audioService.thermalService.temperatureStream,
                builder: (context, snapshot) {
                  final temperature = snapshot.data ?? 25.0;
                  final isThrottling = _audioService.isThermalThrottling;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isThrottling
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isThrottling ? Colors.red : Colors.green,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isThrottling ? Icons.warning : Icons.check_circle,
                          color: isThrottling ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isThrottling
                              ? 'Device is overheating (${temperature.toStringAsFixed(1)}°C)'
                              : 'Device temperature normal (${temperature.toStringAsFixed(1)}°C)',
                          style: TextStyle(
                            color: isThrottling ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _audioService.enableBatterySavingMode(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Battery saving mode enabled to reduce heating'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.battery_saver),
                      label: const Text('Reduce Heating'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _audioService.forceThermalCooling();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thermal cooling initiated'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.ac_unit),
                      label: const Text('Cool Device'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Link to full thermal settings
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThermalSettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Advanced Thermal Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () {},
            iconSize: 40,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {},
            iconSize: 60,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () {},
            iconSize: 40,
          ),
        ],
      ),
    );
  }
}

// Dedicated thermal settings screen
class ThermalSettingsScreen extends StatelessWidget {
  const ThermalSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Management'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ThermalManagementWidget(),
      ),
    );
  }
}
