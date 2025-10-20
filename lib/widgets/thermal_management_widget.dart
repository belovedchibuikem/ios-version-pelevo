// lib/widgets/thermal_management_widget.dart

import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';

class ThermalManagementWidget extends StatefulWidget {
  const ThermalManagementWidget({Key? key}) : super(key: key);

  @override
  State<ThermalManagementWidget> createState() =>
      _ThermalManagementWidgetState();
}

class _ThermalManagementWidgetState extends State<ThermalManagementWidget> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _batterySavingMode = false;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  'Thermal Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Temperature indicator
            _buildTemperatureIndicator(),
            const SizedBox(height: 16),

            // Battery saving mode toggle
            _buildBatterySavingToggle(),
            const SizedBox(height: 16),

            // Thermal stats
            _buildThermalStats(),
            const SizedBox(height: 16),

            // Cooling button
            _buildCoolingButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureIndicator() {
    return StreamBuilder<double>(
      stream: _audioService.thermalService.temperatureStream,
      builder: (context, snapshot) {
        final temperature = snapshot.data ?? 25.0;
        final isThrottling = _audioService.isThermalThrottling;

        Color temperatureColor;
        IconData temperatureIcon;

        if (temperature < 35) {
          temperatureColor = Colors.green;
          temperatureIcon = Icons.thermostat;
        } else if (temperature < 45) {
          temperatureColor = Colors.orange;
          temperatureIcon = Icons.thermostat_outlined;
        } else {
          temperatureColor = Colors.red;
          temperatureIcon = Icons.thermostat_auto;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: temperatureColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: temperatureColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(temperatureIcon, color: temperatureColor),
              const SizedBox(width: 8),
              Text(
                'Temperature: ${temperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                  color: temperatureColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isThrottling)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'THROTTLING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatterySavingToggle() {
    return Row(
      children: [
        const Icon(Icons.battery_saver, color: Colors.blue),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Battery Saving Mode'),
        ),
        Switch(
          value: _batterySavingMode,
          onChanged: (value) {
            setState(() {
              _batterySavingMode = value;
            });
            _audioService.enableBatterySavingMode(value);
          },
        ),
      ],
    );
  }

  Widget _buildThermalStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: Stream.periodic(
        const Duration(seconds: 2),
        (_) => _audioService.getThermalStats(),
      ),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thermal Statistics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text('Throttling: ${stats['isThermalThrottling'] ?? false}'),
              Text(
                  'Reduced Updates: ${stats['reducedUpdateFrequency'] ?? false}'),
              Text('Debug Disabled: ${stats['debugLoggingDisabled'] ?? false}'),
              Text(
                  'Battery Saving: ${stats['aggressiveBatterySaving'] ?? false}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoolingButton() {
    return StreamBuilder<bool>(
      stream: _audioService.thermalService.thermalThrottlingStream,
      builder: (context, snapshot) {
        final isThrottling = snapshot.data ?? false;

        if (!isThrottling) {
          return const SizedBox.shrink();
        }

        return SizedBox(
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
            label: const Text('Force Cooling'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

/// Compact thermal indicator for status bars
class CompactThermalIndicator extends StatelessWidget {
  const CompactThermalIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: AudioPlayerService().thermalService.temperatureStream,
      builder: (context, snapshot) {
        final temperature = snapshot.data ?? 25.0;

        Color color;
        IconData icon;

        if (temperature < 35) {
          color = Colors.green;
          icon = Icons.thermostat;
        } else if (temperature < 45) {
          color = Colors.orange;
          icon = Icons.thermostat_outlined;
        } else {
          color = Colors.red;
          icon = Icons.thermostat_auto;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 2),
              Text(
                '${temperature.toStringAsFixed(0)}°C',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
