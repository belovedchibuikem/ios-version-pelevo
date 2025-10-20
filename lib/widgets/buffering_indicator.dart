// lib/widgets/buffering_indicator.dart

import 'package:flutter/material.dart';
import '../services/smart_buffering_service.dart';

class BufferingIndicator extends StatefulWidget {
  final Widget child;
  final bool showProgress;
  final bool showStatus;

  const BufferingIndicator({
    Key? key,
    required this.child,
    this.showProgress = true,
    this.showStatus = true,
  }) : super(key: key);

  @override
  State<BufferingIndicator> createState() => _BufferingIndicatorState();
}

class _BufferingIndicatorState extends State<BufferingIndicator>
    with TickerProviderStateMixin {
  final SmartBufferingService _bufferingService = SmartBufferingService();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation when buffering
    _bufferingService.bufferingStream.listen((isBuffering) {
      if (isBuffering) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _bufferingService.bufferingStream,
      initialData: false,
      builder: (context, bufferingSnapshot) {
        final isBuffering = bufferingSnapshot.data ?? false;

        return Stack(
          children: [
            widget.child,
            if (isBuffering) _buildBufferingOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildBufferingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spinning indicator
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value * 2 * 3.14159,
                    child: const Icon(
                      Icons.radio,
                      color: Colors.white,
                      size: 32,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Buffering text
              const Text(
                'Buffering...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              if (widget.showProgress) ...[
                const SizedBox(height: 12),
                _buildProgressIndicator(),
              ],

              if (widget.showStatus) ...[
                const SizedBox(height: 8),
                _buildStatusText(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return StreamBuilder<double>(
      stream: _bufferingService.progressStream,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0.0;

        return Column(
          children: [
            // Progress bar
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Progress percentage
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusText() {
    return StreamBuilder<String>(
      stream: _bufferingService.statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'Ready';

        return Text(
          status,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

/// Compact buffering indicator for small spaces
class CompactBufferingIndicator extends StatelessWidget {
  final double size;

  const CompactBufferingIndicator({
    Key? key,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: SmartBufferingService().bufferingStream,
      initialData: false,
      builder: (context, snapshot) {
        final isBuffering = snapshot.data ?? false;

        if (!isBuffering) {
          return const SizedBox.shrink();
        }

        return Container(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      },
    );
  }
}

/// Buffering status chip for displaying current buffering state
class BufferingStatusChip extends StatelessWidget {
  const BufferingStatusChip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: SmartBufferingService().statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'Ready';

        if (status == 'Ready') {
          return const SizedBox.shrink();
        }

        Color chipColor;
        IconData icon;

        if (status.contains('Buffering')) {
          chipColor = Colors.orange;
          icon = Icons.radio;
        } else if (status.contains('Preloading')) {
          chipColor = Colors.blue;
          icon = Icons.download;
        } else {
          chipColor = Colors.green;
          icon = Icons.check_circle;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chipColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: chipColor,
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: chipColor,
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
