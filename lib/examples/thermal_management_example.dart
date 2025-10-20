// lib/examples/thermal_management_example.dart
// Example showing how to use thermal management features

import 'package:flutter/material.dart';
import '../widgets/thermal_management_widget.dart';
import '../services/audio_player_service.dart';

class ThermalManagementExample extends StatefulWidget {
  const ThermalManagementExample({Key? key}) : super(key: key);

  @override
  State<ThermalManagementExample> createState() =>
      _ThermalManagementExampleState();
}

class _ThermalManagementExampleState extends State<ThermalManagementExample> {
  final AudioPlayerService _audioService = AudioPlayerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Management'),
        actions: [
          // Compact thermal indicator in app bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactThermalIndicator(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Thermal management widget
            const ThermalManagementWidget(),
            const SizedBox(height: 20),

            // Quick actions
            _buildQuickActions(),
            const SizedBox(height: 20),

            // Thermal statistics
            _buildThermalStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _audioService.enableBatterySavingMode(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Battery saving mode enabled'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.battery_saver),
                    label: const Text('Enable Battery Saving'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _audioService.enableBatterySavingMode(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Battery saving mode disabled'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.battery_std),
                    label: const Text('Disable Battery Saving'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
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
                label: const Text('Force Thermal Cooling'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThermalStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thermal Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, dynamic>>(
              stream: Stream.periodic(
                const Duration(seconds: 2),
                (_) => _audioService.getThermalStats(),
              ),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {};

                return Column(
                  children: [
                    _buildStatRow('Thermal Throttling',
                        stats['isThermalThrottling'] ?? false),
                    _buildStatRow('Reduced Updates',
                        stats['reducedUpdateFrequency'] ?? false),
                    _buildStatRow('Debug Disabled',
                        stats['debugLoggingDisabled'] ?? false),
                    _buildStatRow('Battery Saving',
                        stats['aggressiveBatterySaving'] ?? false),
                    _buildStatRow('Temperature',
                        '${stats['estimatedTemperature']?.toStringAsFixed(1) ?? 'N/A'}°C'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getValueColor(value),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getValueColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green : Colors.red;
    } else if (value is String && value.contains('°C')) {
      final temp = double.tryParse(value.replaceAll('°C', '')) ?? 0;
      if (temp < 35) return Colors.green;
      if (temp < 45) return Colors.orange;
      return Colors.red;
    }
    return Colors.blue;
  }
}

/// Example of how to add thermal management to your settings screen
class SettingsWithThermalManagement extends StatelessWidget {
  const SettingsWithThermalManagement({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Your existing settings
          const ListTile(
            title: Text('Audio Quality'),
            subtitle: Text('High quality audio'),
          ),
          const ListTile(
            title: Text('Download Settings'),
            subtitle: Text('WiFi only'),
          ),

          // Thermal management section
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Thermal Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ThermalManagementWidget(),

          // More settings...
        ],
      ),
    );
  }
}
