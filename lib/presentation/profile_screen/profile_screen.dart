import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

import '../../core/app_export.dart';
import '../../core/theme_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/logout_service.dart';
import '../../core/services/persistent_state_manager.dart';
import '../../core/utils/snackbar_manager.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import '../../widgets/logout_confirmation_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import '../../data/repositories/podcast_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user.dart';
import '../../services/profile_stats_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/mini_player_positioning.dart';
import '../../providers/podcast_player_provider.dart';
import '../../widgets/sync_status_widget.dart';
import '../../widgets/thermal_management_widget.dart';
import '../../services/audio_player_service.dart';
import '../../services/smart_buffering_service.dart';
import 'thermal_management_screen.dart';

// lib/presentation/profile_screen/profile_screen.dart

// Add a global ValueNotifier for refresh events
class PodcastRefreshNotifier {
  static final ValueNotifier<bool> refresh = ValueNotifier(false);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NavigationService _navigationService = NavigationService();
  final ProfileStatsService _profileStatsService = ProfileStatsService();
  final PersistentStateManager _persistentStateManager =
      PersistentStateManager();
  final AudioPlayerService _audioService = AudioPlayerService();
  bool notificationsEnabled = true;
  bool autoDownloadEnabled = false;
  bool offlineMode = false;
  String selectedLanguage = 'English';
  String selectedQuality = 'High';
  int _selectedTabIndex = 4; // Profile tab is index 4

  late Future<User?> _userFuture;
  late Future<Map<String, dynamic>> _profileStatsFuture;

  @override
  void initState() {
    super.initState();

    // Mini-player will auto-detect bottom navigation positioning

    _navigationService.trackNavigation(AppRoutes.profileScreen);
    _userFuture = UserRepository().getCurrentUser();
    _profileStatsFuture = _profileStatsService.getProfileStats();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    switch (index) {
      case 0:
        _navigationService.navigateTo(AppRoutes.homeScreen);
        break;
      case 1:
        _navigationService.navigateTo(AppRoutes.earnScreen);
        break;
      case 2:
        _navigationService.navigateTo(AppRoutes.libraryScreen);
        break;
      case 3:
        _navigationService.navigateTo(AppRoutes.walletScreen);
        break;
      case 4:
        // Already on Profile
        break;
    }
  }

  void _onSettingChanged(String setting, dynamic value) {
    setState(() {
      switch (setting) {
        case 'notifications':
          notificationsEnabled = value;
          break;
        case 'darkMode':
          // Handle dark mode through ThemeService
          final themeService =
              Provider.of<ThemeService>(context, listen: false);
          themeService.toggleTheme();
          break;
        case 'autoDownload':
          autoDownloadEnabled = value;
          break;
        case 'offlineMode':
          offlineMode = value;
          break;
        case 'language':
          selectedLanguage = value;
          break;
        case 'quality':
          selectedQuality = value;
          break;
      }
    });

    if (setting != 'darkMode') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Setting updated: $setting'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          behavior: SnackBarBehavior.floating));
    }
  }

  void _onSettingTap(String key) {
    switch (key) {
      case 'subscription':
        _navigateToSubscription();
        break;
      case 'downloads':
        _navigateToDownloads();
        break;
      case 'listening_stats':
        _navigateToListeningStats();
        break;
      case 'listening_history':
        _navigateToListeningHistory();
        break;
      case 'notifications':
        _onSettingChanged('notifications', !notificationsEnabled);
        break;
      case 'darkMode':
        _onSettingChanged('darkMode', null);
        break;
      case 'autoDownload':
        _onSettingChanged('autoDownload', !autoDownloadEnabled);
        break;
      case 'offlineMode':
        _onSettingChanged('offlineMode', !offlineMode);
        break;
      case 'autoPlay':
        // Toggle auto-play through the PodcastPlayerProvider
        final playerProvider =
            Provider.of<PodcastPlayerProvider>(context, listen: false);
        playerProvider.toggleAutoPlayNext();
        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(playerProvider.autoPlayNext
                ? 'Auto-play enabled'
                : 'Auto-play disabled'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'progress_tracking':
        Navigator.pushNamed(context, AppRoutes.progressTrackingScreen);
        break;
      case 'performance_dashboard':
        _navigateToPerformanceDashboard();
        break;
      case 'debug_screen':
        _navigateToDebugScreen();
        break;
      case 'language':
        _showLanguageDialog();
        break;
      case 'quality':
        _showQualityDialog();
        break;
      case 'privacy':
        _navigateToPrivacy();
        break;
      case 'terms':
        _navigateToTerms();
        break;
      case 'help':
        _navigateToHelp();
        break;
      case 'feedback':
        _navigateToFeedback();
        break;
      case 'about':
        _navigateToAbout();
        break;
      case 'logout':
        _onLogout();
        break;
      case 'delete_account':
        _onDeleteAccount();
        break;
      case 'manual_reload':
        _onManualAppReload();
        break;
      case 'thermal_management':
        _navigateToThermalManagement();
        break;
      case 'shuffle_mode':
        _toggleShuffleMode();
        break;
      case 'repeat_mode':
        _toggleRepeatMode();
        break;
      case 'buffering_strategy':
        _showBufferingStrategyDialog();
        break;
      case 'battery_saving_mode':
        _toggleBatterySavingMode();
        break;
    }
  }

  void _onEditProfile() {
    _navigationService.navigateTo(AppRoutes.editProfileScreen);
  }

  void _showLanguageDialog() {
    final currentTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Language',
              style: currentTheme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Spanish', 'French', 'German']
                .map((language) => RadioListTile<String>(
                      title: Text(language),
                      value: language,
                      groupValue: selectedLanguage,
                      onChanged: (value) {
                        if (value != null) {
                          _onSettingChanged('language', value);
                          Navigator.of(context).pop();
                        }
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  void _showQualityDialog() {
    final currentTheme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Audio Quality',
              style: currentTheme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Low', 'Medium', 'High', 'Very High']
                .map((quality) => RadioListTile<String>(
                      title: Text(quality),
                      subtitle: Text(_getQualityDescription(quality)),
                      value: quality,
                      groupValue: selectedQuality,
                      onChanged: (value) {
                        if (value != null) {
                          _onSettingChanged('quality', value);
                          Navigator.of(context).pop();
                        }
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  String _getQualityDescription(String quality) {
    switch (quality) {
      case 'Low':
        return '64 kbps - Data saver';
      case 'Medium':
        return '128 kbps - Balanced';
      case 'High':
        return '256 kbps - Recommended';
      case 'Very High':
        return '320 kbps - Best quality';
      default:
        return '';
    }
  }

  void _navigateToPrivacy() {
    _navigationService.navigateTo(AppRoutes.privacyPolicyScreen);
  }

  void _navigateToTerms() {
    _navigationService.navigateTo(AppRoutes.termsScreen);
  }

  void _navigateToHelp() {
    _navigationService.navigateTo(AppRoutes.helpCenter);
  }

  void _navigateToFeedback() {
    _navigationService.navigateTo(AppRoutes.feedbackScreen);
  }

  void _navigateToAbout() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('About Pelevo feature coming soon'),
        behavior: SnackBarBehavior.floating));
  }

  void _navigateToSubscription() {
    _navigationService.navigateTo(AppRoutes.subscriptionManagementScreen);
  }

  void _navigateToDownloads() {
    _navigationService.navigateTo(AppRoutes.downloadedEpisodesScreen);
  }

  void _navigateToListeningStats() {
    _navigationService.navigateTo(AppRoutes.listeningStatisticsScreen);
  }

  void _navigateToListeningHistory() {
    _navigationService.navigateTo(AppRoutes.listeningHistoryScreen);
  }

  void _navigateToPerformanceDashboard() {
    _navigationService.navigateTo(AppRoutes.performanceDashboardScreen);
  }

  void _navigateToDebugScreen() {
    _navigationService.navigateTo(AppRoutes.debugScreen);
  }

  void _navigateToThermalManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ThermalManagementScreen(),
      ),
    );
  }

  void _toggleShuffleMode() {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    final queueLength = playerProvider.episodeQueue.length;
    playerProvider.toggleShuffleMode();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(playerProvider.isShuffled
            ? 'Shuffle mode enabled - ${queueLength} episodes shuffled'
            : 'Shuffle mode disabled - episodes in original order'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleRepeatMode() {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    playerProvider.toggleRepeatMode();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(playerProvider.isRepeating
            ? 'Repeat mode enabled - current episode will repeat'
            : 'Repeat mode disabled - episodes will advance normally'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showBufferingStrategyDialog() {
    final currentTheme = Theme.of(context);
    final currentStrategy = _audioService.bufferingService.currentStrategy;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Buffering Strategy',
              style: currentTheme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStrategyOption(
                BufferingStrategy.conservative,
                'Conservative',
                'Save data and battery - slower buffering',
                currentStrategy,
                context,
              ),
              _buildStrategyOption(
                BufferingStrategy.balanced,
                'Balanced',
                'Good for most connections - recommended',
                currentStrategy,
                context,
              ),
              _buildStrategyOption(
                BufferingStrategy.aggressive,
                'Aggressive',
                'Fast connections - preload more content',
                currentStrategy,
                context,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStrategyOption(
    BufferingStrategy strategy,
    String title,
    String description,
    BufferingStrategy currentStrategy,
    BuildContext context,
  ) {
    return RadioListTile<BufferingStrategy>(
      title: Text(title),
      subtitle: Text(description),
      value: strategy,
      groupValue: currentStrategy,
      onChanged: (value) {
        if (value != null) {
          _audioService.setBufferingStrategy(value);
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Buffering strategy set to $title'),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _toggleBatterySavingMode() {
    final currentMode = _audioService.thermalService.isOptimizedForBattery;
    _audioService.enableBatterySavingMode(!currentMode);

    // Force a rebuild to update the UI state
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!currentMode
            ? 'Battery saving mode enabled - CPU usage reduced'
            : 'Battery saving mode disabled - normal performance restored'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getBufferingStrategyLabel(BufferingStrategy strategy) {
    switch (strategy) {
      case BufferingStrategy.conservative:
        return 'Conservative';
      case BufferingStrategy.balanced:
        return 'Balanced';
      case BufferingStrategy.aggressive:
        return 'Aggressive';
    }
  }

  void _onLogout() async {
    // Show enhanced logout confirmation dialog
    final shouldLogout =
        await LogoutConfirmationWidget.showLogoutDialog(context);

    if (!shouldLogout) return;

    // Show logout progress
    LogoutConfirmationWidget.showLogoutProgress(context);

    try {
      final logoutService = LogoutService();
      final result = await logoutService.performLogout(
        reason: 'User initiated logout',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show result message
      if (mounted) {
        LogoutConfirmationWidget.showLogoutResult(context, result);
      }

      // Navigate to authentication screen
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        _navigationService.navigateAndClearStack(
          AppRoutes.authenticationScreen,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message with force logout option
      if (mounted) {
        LogoutConfirmationWidget.showLogoutError(
          context,
          e.toString(),
          () => _forceLogout(),
        );
      }

      // Still navigate to authentication screen for security
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        _navigationService.navigateAndClearStack(
          AppRoutes.authenticationScreen,
        );
      }
    }
  }

  void _forceLogout() async {
    final currentTheme = Theme.of(context);

    try {
      final logoutService = LogoutService();
      await logoutService.forceLogout(
        reason: 'Force logout due to error',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Force logout completed'),
            backgroundColor: currentTheme.colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Navigate to authentication screen
      if (mounted) {
        _navigationService.navigateAndClearStack(
          AppRoutes.authenticationScreen,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Force logout failed: ${e.toString()}'),
            backgroundColor: currentTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onDeleteAccount() {
    final currentTheme = Theme.of(context);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Delete Account',
                  style: currentTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: currentTheme.colorScheme.error)),
              content: Text(
                  'This action cannot be undone. All your data, including earnings and subscriptions, will be permanently deleted.',
                  style: currentTheme.textTheme.bodyMedium),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: currentTheme.textTheme.labelLarge?.copyWith(
                            color: currentTheme.colorScheme.onSurfaceVariant))),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Account deletion feature coming soon'),
                          backgroundColor: currentTheme.colorScheme.error,
                          behavior: SnackBarBehavior.floating));
                    },
                    child: Text('Delete',
                        style: currentTheme.textTheme.labelLarge?.copyWith(
                            color: currentTheme.colorScheme.error,
                            fontWeight: FontWeight.w600))),
              ]);
        });
  }

  String _formatMemberSince(DateTime date) {
    // Format as "Member Since : Month Year"
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final month = monthNames[date.month - 1];
    final year = date.year;

    return '$month $year';
  }

  Future<void> _onRefreshPodcasts() async {
    // Clear cache and notify listeners
    await PodcastRepository().clearCache();
    PodcastRefreshNotifier.refresh.value =
        !PodcastRefreshNotifier.refresh.value;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Podcast data refreshed!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Manual app reload option for users
  Future<void> _onManualAppReload() async {
    try {
      // Show confirmation dialog
      final shouldReload = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Reload App'),
            content: Text(
              'This will reload the app and clear any cached data. '
              'Your current playback will be preserved. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Reload'),
              ),
            ],
          );
        },
      );

      if (shouldReload == true) {
        // Clear persisted state to force full reload
        await _persistentStateManager.clearPlayerState();

        // Show success message
        SnackbarManager.showSuccess(
          context,
          'App will reload on next launch',
          duration: Duration(seconds: 3),
        );

        // Navigate to splash screen to trigger reload
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.splashScreen,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error during manual app reload: $e');
      SnackbarManager.showError(
        context,
        'Failed to reload app: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final currentTheme = Theme.of(context);

        return Scaffold(
            backgroundColor: currentTheme.scaffoldBackgroundColor,
            appBar: AppBar(
                backgroundColor: currentTheme.colorScheme.surface,
                elevation: 0,
                title: Text('Profile',
                    style: currentTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: currentTheme.colorScheme.onSurface)),
                centerTitle: true,
                leading: IconButton(
                    icon: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: currentTheme.colorScheme.onSurface,
                        size: 24),
                    onPressed: () => _navigationService.goBack()),
                actions: [
                  // Compact thermal indicator
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CompactThermalIndicator(),
                  ),
                  IconButton(
                      icon: CustomIconWidget(
                          iconName: 'refresh',
                          color: currentTheme.colorScheme.primary,
                          size: 24),
                      onPressed: () {
                        setState(() {
                          _userFuture = UserRepository().getCurrentUser();
                          _profileStatsFuture =
                              _profileStatsService.getProfileStats();
                        });
                      }),
                  IconButton(
                      icon: CustomIconWidget(
                          iconName: 'edit',
                          color: currentTheme.colorScheme.onSurface,
                          size: 24),
                      onPressed: _onEditProfile),
                ]),
            body: FutureBuilder<User?>(
              future: _userFuture,
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (userSnapshot.hasError) {
                  return Center(child: Text('Failed to load profile'));
                } else if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return Center(child: Text('No user data found'));
                }

                final user = userSnapshot.data!;

                return FutureBuilder<Map<String, dynamic>>(
                  future: _profileStatsFuture,
                  builder: (context, statsSnapshot) {
                    // Default values if stats are still loading or failed
                    final subscriptionsCount =
                        statsSnapshot.data?['subscriptionsCount'] ?? 0;
                    final downloadsCount =
                        statsSnapshot.data?['downloadsCount'] ?? 0;
                    final listeningHours =
                        statsSnapshot.data?['listeningHours'] ?? 0;

                    return SingleChildScrollView(
                        child: Column(children: [
                      SizedBox(height: 2.h),
                      // Profile header
                      ProfileHeaderWidget(
                        userProfile: {
                          'name': user.name,
                          'email': user.email,
                          'profileImage': user.profileImageUrl,
                          'memberSince': user.memberSince ??
                              (user.createdAt != null
                                  ? _formatMemberSince(user.createdAt!)
                                  : 'Member since registration'),
                          'subscriptionsCount': subscriptionsCount,
                          'listeningHours': listeningHours,
                          'totalCoins': user.balance,
                          // Add other fields as needed
                        },
                        onEditTap: _onEditProfile,
                      ),

                      SizedBox(height: 3.h),

                      SizedBox(height: 2.h),

                      // Account Management
                      SettingsSectionWidget(
                        title: 'Account',
                        items: [
                          //{
                          //  'key': 'subscription',
                          //  'title': 'Subscription Management',
                          //  'subtitle': 'Manage your premium plan',
                          //  'icon': 'card_membership',
                          //  'iconColor': 'primary',
                          //  'type': 'navigation',
                          //},
                          {
                            'key': 'downloads',
                            'title': 'Downloaded Episodes',
                            'subtitle': '$downloadsCount episodes',
                            'icon': 'download',
                            'iconColor': 'secondary',
                            'type': 'navigation',
                          },
                          {
                            'key': 'listening_stats',
                            'title': 'Listening Statistics',
                            'subtitle': 'View your podcast analytics',
                            'icon': 'analytics',
                            'iconColor': 'tertiary',
                            'type': 'navigation',
                          },
                          {
                            'key': 'listening_history',
                            'title': 'Listening History',
                            'subtitle': 'View your episode history',
                            'icon': 'history',
                            'iconColor': 'secondary',
                            'type': 'navigation',
                          },
                        ],
                        onItemTap: _onSettingTap,
                      ),

                      SizedBox(height: 3.h),

                      // Preferences
                      Consumer<PodcastPlayerProvider>(
                        builder: (context, playerProvider, child) {
                          return SettingsSectionWidget(
                            title: 'Preferences',
                            items: [
                              {
                                'key': 'notifications',
                                'title': 'Push Notifications',
                                'subtitle':
                                    'Receive updates about new episodes',
                                'icon': 'notifications',
                                'iconColor': 'primary',
                                'type': 'switch',
                                'value': notificationsEnabled,
                              },
                              {
                                'key': 'darkMode',
                                'title': 'Dark Mode',
                                'subtitle': 'Switch to dark theme',
                                'icon': 'dark_mode',
                                'iconColor': 'primary',
                                'type': 'switch',
                                'value': themeService.isDarkMode,
                              },
                              {
                                'key': 'autoDownload',
                                'title': 'Auto Download',
                                'subtitle':
                                    'Download new episodes automatically',
                                'icon': 'file_download',
                                'iconColor': 'secondary',
                                'type': 'switch',
                                'value': autoDownloadEnabled,
                              },
                              {
                                'key': 'offlineMode',
                                'title': 'Offline Mode',
                                'subtitle': 'Only show downloaded content',
                                'icon': 'offline_bolt',
                                'iconColor': 'secondary',
                                'type': 'switch',
                                'value': offlineMode,
                              },
                              {
                                'key': 'autoPlay',
                                'title': 'Auto-play Next Episode',
                                'subtitle':
                                    'Automatically play next episode when current one finishes',
                                'icon': 'playlist_play',
                                'iconColor': 'primary',
                                'type': 'switch',
                                'value': playerProvider.autoPlayNext,
                              },
                              {
                                'key': 'shuffle_mode',
                                'title': 'Shuffle Mode',
                                'subtitle': 'Play episodes in random order',
                                'icon': 'shuffle',
                                'iconColor': 'secondary',
                                'type': 'switch',
                                'value': playerProvider.isShuffled,
                              },
                              {
                                'key': 'repeat_mode',
                                'title': 'Repeat Mode',
                                'subtitle':
                                    'Repeat current episode or entire queue',
                                'icon': 'repeat',
                                'iconColor': 'secondary',
                                'type': 'switch',
                                'value': playerProvider.isRepeating,
                              },
                              {
                                'key': 'progress_tracking',
                                'title': 'Episode Progress Tracking',
                                'subtitle':
                                    'Track and sync your listening progress',
                                'icon': 'track_changes',
                                'iconColor': 'primary',
                                'type': 'navigation',
                              },
                              {
                                'key': 'performance_dashboard',
                                'title': 'Performance Dashboard',
                                'subtitle':
                                    'Monitor app performance and system health',
                                'icon': 'analytics',
                                'iconColor': 'primary',
                                'type': 'navigation',
                              },
                              {
                                'key': 'language',
                                'title': 'Language',
                                'subtitle': 'App language preference',
                                'currentValue': selectedLanguage,
                                'icon': 'language',
                                'iconColor': 'tertiary',
                                'type': 'selection',
                              },
                              {
                                'key': 'quality',
                                'title': 'Audio Quality',
                                'subtitle': 'Streaming and download quality',
                                'currentValue': selectedQuality,
                                'icon': 'high_quality',
                                'iconColor': 'tertiary',
                                'type': 'selection',
                              },
                              {
                                'key': 'sync_status',
                                'title': 'Sync Status',
                                'subtitle': 'Check your sync status',
                                'icon': 'sync',
                                'iconColor': 'primary',
                                'type': 'widget',
                                'widget': SyncStatusWidget(),
                              },
                              {
                                'key': 'thermal_management',
                                'title': 'Device Temperature Management',
                                'subtitle':
                                    'Manage device heating and battery optimization',
                                'icon': 'thermostat',
                                'iconColor': 'secondary',
                                'type': 'navigation',
                              },
                              {
                                'key': 'buffering_strategy',
                                'title': 'Buffering Strategy',
                                'subtitle':
                                    'Optimize buffering for your connection',
                                'currentValue': _getBufferingStrategyLabel(
                                    _audioService
                                        .bufferingService.currentStrategy),
                                'icon': 'speed',
                                'iconColor': 'tertiary',
                                'type': 'selection',
                              },
                              {
                                'key': 'battery_saving_mode',
                                'title': 'Battery Saving Mode',
                                'subtitle':
                                    'Reduce CPU usage and update frequency',
                                'icon': 'battery_saver',
                                'iconColor': 'secondary',
                                'type': 'switch',
                                'value': _audioService
                                    .thermalService.isOptimizedForBattery,
                              },
                            ],
                            onItemTap: _onSettingTap,
                          );
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Developer Tools (only show in debug mode)
                      if (kDebugMode) ...[
                        SettingsSectionWidget(
                          title: 'Developer Tools',
                          items: [
                            {
                              'key': 'performance_dashboard',
                              'title': 'Performance Dashboard',
                              'subtitle':
                                  'Monitor app performance and system health',
                              'icon': 'analytics',
                              'iconColor': 'primary',
                              'type': 'navigation',
                            },
                            {
                              'key': 'debug_screen',
                              'title': 'Debug Console',
                              'subtitle': 'Advanced debugging and diagnostics',
                              'icon': 'bug_report',
                              'iconColor': 'secondary',
                              'type': 'navigation',
                            },
                          ],
                          onItemTap: _onSettingTap,
                        ),
                        SizedBox(height: 3.h),
                      ],

                      // Support & Information
                      SettingsSectionWidget(
                        title: 'Support & Information',
                        items: [
                          {
                            'key': 'help',
                            'title': 'Help Center',
                            'subtitle': 'Get help and support',
                            'icon': 'help',
                            'iconColor': 'primary',
                            'type': 'navigation',
                          },
                          {
                            'key': 'feedback',
                            'title': 'Send Feedback',
                            'subtitle': 'Help us improve the app',
                            'icon': 'feedback',
                            'iconColor': 'secondary',
                            'type': 'navigation',
                          },
                          {
                            'key': 'manual_reload',
                            'title': 'Manual App Reload',
                            'subtitle': 'Reload app when needed',
                            'icon': 'refresh',
                            'iconColor': 'primary',
                            'type': 'action',
                          },
                          {
                            'key': 'privacy',
                            'title': 'Privacy Policy',
                            'subtitle': 'How we protect your data',
                            'icon': 'privacy_tip',
                            'iconColor': 'tertiary',
                            'type': 'navigation',
                          },
                          {
                            'key': 'terms',
                            'title': 'Terms of Service',
                            'subtitle': 'App usage terms and conditions',
                            'icon': 'description',
                            'iconColor': 'tertiary',
                            'type': 'navigation',
                          },
                          {
                            'key': 'about',
                            'title': 'About Pelevo',
                            'subtitle': 'App version and information',
                            'icon': 'info',
                            'iconColor': 'tertiary',
                            'type': 'navigation',
                          },
                        ],
                        onItemTap: _onSettingTap,
                      ),

                      SizedBox(height: 3.h),

                      // Account Actions
                      SettingsSectionWidget(
                        title: 'Account Actions',
                        items: [
                          {
                            'key': 'logout',
                            'title': 'Logout',
                            'subtitle': 'Sign out of your account',
                            'icon': 'logout',
                            'iconColor': 'error',
                            'type': 'action',
                          },
                          {
                            'key': 'delete_account',
                            'title': 'Delete Account',
                            'subtitle': 'Permanently delete your account',
                            'icon': 'delete_forever',
                            'iconColor': 'error',
                            'type': 'action',
                          },
                        ],
                        onItemTap: _onSettingTap,
                      ),

                      SizedBox(height: 12.h), // Space for bottom navigation
                    ]));
                  },
                );
              },
            ));
      },
    );
  }
}
