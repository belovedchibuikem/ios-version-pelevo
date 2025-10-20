import 'package:flutter/material.dart';
import '../../services/player_settings_service.dart';
import '../../services/hybrid_audio_player_service.dart';
import '../../providers/podcast_player_provider.dart';
import '../../core/app_export.dart';
import 'package:provider/provider.dart';

/// Widget for player settings and implementation switching
class PlayerSettingsWidget extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const PlayerSettingsWidget({
    super.key,
    this.onSettingsChanged,
  });

  @override
  State<PlayerSettingsWidget> createState() => _PlayerSettingsWidgetState();
}

class _PlayerSettingsWidgetState extends State<PlayerSettingsWidget> {
  final PlayerSettingsService _settingsService = PlayerSettingsService();
  final HybridAudioPlayerService _hybridService = HybridAudioPlayerService();

  bool _useEnhancedPlayer = false;
  bool _autoSwitchToEnhanced = true;
  bool _showBufferingIndicators = true;
  bool _networkQualityMonitoring = true;
  bool _adaptiveBuffering = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.initialize();
    setState(() {
      _useEnhancedPlayer = _settingsService.useEnhancedPlayer;
      _autoSwitchToEnhanced = _settingsService.autoSwitchToEnhanced;
      _showBufferingIndicators = _settingsService.showBufferingIndicators;
      _networkQualityMonitoring = _settingsService.networkQualityMonitoring;
      _adaptiveBuffering = _settingsService.adaptiveBuffering;
    });
  }

  Future<void> _toggleEnhancedPlayer(bool value) async {
    setState(() => _isLoading = true);

    try {
      await _settingsService.setUseEnhancedPlayer(value);
      await _hybridService.switchImplementation(value);

      setState(() {
        _useEnhancedPlayer = value;
        _isLoading = false;
      });

      widget.onSettingsChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Switched to Enhanced Player with buffering features'
              : 'Switched to Legacy Player'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error switching player: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Settings'),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildImplementationSection(),
                const SizedBox(height: 24),
                _buildAutoPlaySection(),
                const SizedBox(height: 24),
                _buildEnhancedFeaturesSection(),
                const SizedBox(height: 24),
                _buildInfoSection(),
              ],
            ),
    );
  }

  Widget _buildImplementationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player Implementation',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enhanced Player'),
              subtitle: const Text(
                'Advanced buffering, network quality monitoring, and adaptive playback',
              ),
              value: _useEnhancedPlayer,
              onChanged: _toggleEnhancedPlayer,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Auto-switch to Enhanced'),
              subtitle: const Text(
                'Automatically use enhanced player when available',
              ),
              value: _autoSwitchToEnhanced,
              onChanged: (value) async {
                await _settingsService.setAutoSwitchToEnhanced(value);
                setState(() => _autoSwitchToEnhanced = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoPlaySection() {
    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Play Settings',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Control how the player behaves when it reaches the end of the current episode.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Auto-play next episode'),
                  subtitle: const Text(
                    'Automatically start playing the next episode after the current one finishes.',
                  ),
                  value: playerProvider.autoPlayNext,
                  onChanged: (value) {
                    playerProvider.toggleAutoPlayNext();
                  },
                ),
                SwitchListTile(
                  title: const Text('Repeat playlist'),
                  subtitle: const Text(
                    'When reaching the end of the playlist, start from the beginning.',
                  ),
                  value: playerProvider.isRepeating,
                  onChanged: (value) {
                    playerProvider.toggleRepeat();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhanced Features',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'These features are only available with the Enhanced Player',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Buffering Indicators'),
              subtitle: const Text('Show buffering progress and status'),
              value: _showBufferingIndicators,
              onChanged: _useEnhancedPlayer
                  ? (value) async {
                      await _settingsService.setShowBufferingIndicators(value);
                      setState(() => _showBufferingIndicators = value);
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('Network Quality Monitoring'),
              subtitle: const Text(
                  'Monitor connection quality for adaptive buffering'),
              value: _networkQualityMonitoring,
              onChanged: _useEnhancedPlayer
                  ? (value) async {
                      await _settingsService.setNetworkQualityMonitoring(value);
                      setState(() => _networkQualityMonitoring = value);
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('Adaptive Buffering'),
              subtitle:
                  const Text('Adjust buffer size based on network quality'),
              value: _adaptiveBuffering,
              onChanged: _useEnhancedPlayer
                  ? (value) async {
                      await _settingsService.setAdaptiveBuffering(value);
                      setState(() => _adaptiveBuffering = value);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Player Implementations',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              'Legacy Player',
              'Basic audio playback with standard features. Stable and reliable.',
              Icons.play_circle_outline,
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Enhanced Player',
              'Advanced features including buffering, network monitoring, and adaptive playback.',
              Icons.tune,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can switch between implementations at any time. The enhanced player provides better buffering and network adaptation.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color:
                            AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
