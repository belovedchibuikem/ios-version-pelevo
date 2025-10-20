// lib/examples/settings_integration_example.dart
// Example of how to integrate thermal management into your existing settings screen

import 'package:flutter/material.dart';
import '../widgets/thermal_management_widget.dart';
import '../widgets/thermal_management_widget.dart'; // CompactThermalIndicator
import '../services/audio_player_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          // Show temperature in app bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactThermalIndicator(),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Your existing settings sections
          _buildAudioSettings(),
          _buildDownloadSettings(),
          _buildNotificationSettings(),

          // NEW: Thermal Management Section
          _buildThermalManagementSection(),

          // More existing settings...
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildAudioSettings() {
    return ExpansionTile(
      title: const Text('Audio Settings'),
      leading: const Icon(Icons.volume_up),
      children: [
        const ListTile(
          title: Text('Audio Quality'),
          subtitle: Text('High quality audio'),
          trailing: Icon(Icons.check),
        ),
        const ListTile(
          title: Text('Volume Boost'),
          subtitle: Text('Increase volume by 20%'),
        ),
        const ListTile(
          title: Text('Trim Silence'),
          subtitle: Text('Remove silent parts'),
        ),
      ],
    );
  }

  Widget _buildDownloadSettings() {
    return ExpansionTile(
      title: const Text('Download Settings'),
      leading: const Icon(Icons.download),
      children: [
        const ListTile(
          title: Text('Download Quality'),
          subtitle: Text('High quality downloads'),
        ),
        const ListTile(
          title: Text('WiFi Only'),
          subtitle: Text('Download only on WiFi'),
          trailing: Switch(value: true, onChanged: null),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return ExpansionTile(
      title: const Text('Notifications'),
      leading: const Icon(Icons.notifications),
      children: [
        const ListTile(
          title: Text('New Episode Alerts'),
          subtitle: Text('Get notified of new episodes'),
          trailing: Switch(value: true, onChanged: null),
        ),
        const ListTile(
          title: Text('Download Complete'),
          subtitle: Text('Notify when downloads finish'),
          trailing: Switch(value: false, onChanged: null),
        ),
      ],
    );
  }

  // NEW SECTION: Thermal Management
  Widget _buildThermalManagementSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.thermostat, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Device Temperature Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Thermal management widget
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ThermalManagementWidget(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return const ListTile(
      title: Text('About'),
      subtitle: Text('Version 4.0.0'),
      leading: Icon(Icons.info),
    );
  }
}
