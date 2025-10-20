// lib/presentation/profile_screen/thermal_management_screen.dart
// Thermal management screen for the profile section

import 'package:flutter/material.dart';
import '../../widgets/thermal_management_widget.dart';
import '../../services/audio_player_service.dart';

class ThermalManagementScreen extends StatefulWidget {
  const ThermalManagementScreen({Key? key}) : super(key: key);

  @override
  State<ThermalManagementScreen> createState() =>
      _ThermalManagementScreenState();
}

class _ThermalManagementScreenState extends State<ThermalManagementScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Temperature Management'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header information
            _buildHeaderCard(theme),
            const SizedBox(height: 20),

            // Thermal management widget
            const ThermalManagementWidget(),
            const SizedBox(height: 20),

            // Quick actions
            _buildQuickActionsCard(theme),
            const SizedBox(height: 20),

            // Information section
            _buildInformationCard(theme),
            const SizedBox(height: 20),

            // Statistics section
            _buildStatisticsCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.thermostat,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Temperature Management',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optimize your device temperature and battery usage while listening to podcasts',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
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
                      _showSnackBar(
                        'Battery saving mode enabled to reduce device heating',
                        theme,
                      );
                    },
                    icon: const Icon(Icons.battery_saver),
                    label: const Text('Enable Battery Saving'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _audioService.enableBatterySavingMode(false);
                      _showSnackBar(
                        'Battery saving mode disabled',
                        theme,
                      );
                    },
                    icon: const Icon(Icons.battery_std),
                    label: const Text('Normal Mode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
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
                  _showSnackBar(
                    'Thermal cooling initiated - device will cool down',
                    theme,
                  );
                },
                icon: const Icon(Icons.ac_unit),
                label: const Text('Force Device Cooling'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.auto_awesome,
              title: 'Automatic Optimization',
              description:
                  'The app automatically adjusts performance based on your device temperature',
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.battery_saver,
              title: 'Battery Saving Mode',
              description:
                  'Reduces CPU usage and update frequency to prevent overheating',
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.ac_unit,
              title: 'Force Cooling',
              description:
                  'Temporarily pauses playback to allow device to cool down',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: theme.textTheme.titleMedium?.copyWith(
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
                    _buildStatRow(
                      'Temperature',
                      '${stats['estimatedTemperature']?.toStringAsFixed(1) ?? 'N/A'}°C',
                      _getTemperatureColor(
                          stats['estimatedTemperature'] ?? 25.0),
                      theme,
                    ),
                    _buildStatRow(
                      'Thermal Throttling',
                      stats['isThermalThrottling'] ?? false
                          ? 'Active'
                          : 'Inactive',
                      (stats['isThermalThrottling'] ?? false)
                          ? Colors.red
                          : Colors.green,
                      theme,
                    ),
                    _buildStatRow(
                      'Battery Saving',
                      stats['aggressiveBatterySaving'] ?? false
                          ? 'Enabled'
                          : 'Disabled',
                      (stats['aggressiveBatterySaving'] ?? false)
                          ? Colors.blue
                          : Colors.grey,
                      theme,
                    ),
                    _buildStatRow(
                      'Update Frequency',
                      (stats['reducedUpdateFrequency'] ?? false)
                          ? 'Reduced'
                          : 'Normal',
                      (stats['reducedUpdateFrequency'] ?? false)
                          ? Colors.orange
                          : Colors.green,
                      theme,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, Color valueColor, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: valueColor.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature < 35) return Colors.green;
    if (temperature < 45) return Colors.orange;
    return Colors.red;
  }

  void _showSnackBar(String message, ThemeData theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
