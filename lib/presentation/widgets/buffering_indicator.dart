import 'package:flutter/material.dart';
import '../../models/buffering_models.dart';

/// Simple buffering indicator
class BufferingIndicator extends StatelessWidget {
  final BufferingState state;
  final double size;

  const BufferingIndicator({
    super.key,
    required this.state,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state == BufferingState.ready || state == BufferingState.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Network quality indicator
class NetworkQualityIndicator extends StatelessWidget {
  final NetworkQuality quality;

  const NetworkQualityIndicator({
    super.key,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (quality) {
      case NetworkQuality.excellent:
        icon = Icons.wifi;
        color = Colors.green;
        break;
      case NetworkQuality.good:
        icon = Icons.wifi;
        color = Colors.orange;
        break;
      case NetworkQuality.poor:
        icon = Icons.wifi_off;
        color = Colors.red;
        break;
      case NetworkQuality.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
        break;
    }

    return Icon(
      icon,
      size: 20,
      color: color,
    );
  }
}
