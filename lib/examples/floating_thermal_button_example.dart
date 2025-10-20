// lib/examples/floating_thermal_button_example.dart
// Example of how to add a floating thermal management button

import 'package:flutter/material.dart';
import '../widgets/thermal_management_widget.dart';
import '../services/audio_player_service.dart';

class HomeScreenWithThermalButton extends StatefulWidget {
  const HomeScreenWithThermalButton({Key? key}) : super(key: key);

  @override
  State<HomeScreenWithThermalButton> createState() =>
      _HomeScreenWithThermalButtonState();
}

class _HomeScreenWithThermalButtonState
    extends State<HomeScreenWithThermalButton> {
  final AudioPlayerService _audioService = AudioPlayerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcast App'),
        actions: [
          // Temperature indicator in app bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactThermalIndicator(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Your main content here'),
      ),

      // Floating thermal management button
      floatingActionButton: StreamBuilder<bool>(
        stream: _audioService.thermalService.thermalThrottlingStream,
        builder: (context, snapshot) {
          final isThrottling = snapshot.data ?? false;

          // Show floating button when device is overheating
          if (!isThrottling) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _showThermalManagement(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.thermostat_auto),
            label: const Text('Device Hot'),
          );
        },
      ),
    );
  }

  void _showThermalManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.thermostat, color: Colors.red),
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

            const Divider(),

            // Thermal management content
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: ThermalManagementWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick thermal status widget for any screen
class QuickThermalStatus extends StatelessWidget {
  const QuickThermalStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AudioPlayerService().thermalService.thermalThrottlingStream,
      builder: (context, snapshot) {
        final isThrottling = snapshot.data ?? false;

        if (!isThrottling) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Device is overheating - Thermal management active',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to thermal settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThermalSettingsScreen(),
                    ),
                  );
                },
                child: const Text('Manage'),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
