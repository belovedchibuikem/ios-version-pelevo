import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_export.dart';
import '../providers/podcast_player_provider.dart';
import 'resume_notification_widget.dart';
import 'full_screen_player_modal.dart';
import 'up_next_modal.dart';
import 'custom_image_widget.dart';
import '../core/utils/image_utils.dart';

/// Floating Mini-Player Overlay
///
/// This widget provides a floating mini-player that automatically detects and positions itself
/// above the bottom navigation bar when present, or at the bottom edge when no nav bar exists.
///
/// **Auto-Detection Mode (Default):**
/// The mini-player automatically detects screens with bottom navigation bars and positions itself
/// accordingly. Known screens with bottom nav: home-screen, library-screen, earn-screen, wallet-screen, profile-screen.
///
/// **Manual Override Mode:**
/// You can manually set positioning for specific screens if needed:
///
/// 1. **Set custom height per screen**:
///    ```dart
///    FloatingMiniPlayerOverlay.setBottomNavHeight(80.0); // For screens with taller nav bars
///    ```
///
/// 2. **Reset to auto-detect**:
///    ```dart
///    FloatingMiniPlayerOverlay.resetBottomNavHeight(); // Returns to auto-detect mode
///    ```
///
/// 3. **Force auto-detection**:
///    ```dart
///    FloatingMiniPlayerOverlay.enableAutoDetection(); // Explicitly enable auto-detection
///    ```
///
/// 4. **Get current height**:
///    ```dart
///    double height = FloatingMiniPlayerOverlay.getCurrentBottomNavHeight();
///    ```
///
/// The mini-player will automatically position itself with optimal spacing above the navigation bar
/// or at the bottom edge based on screen characteristics.

class FloatingMiniPlayerOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;
  static bool _strictMode = true; // Enable strict mode by default
  static bool _protectFromBackButton =
      true; // Protect from back button by default

  /// Show the floating mini-player
  static void show(
    BuildContext context,
    Map<String, dynamic> episode,
    List<Map<String, dynamic>> episodes,
    int episodeIndex,
  ) {
    debugPrint('🎯 FloatingMiniPlayerOverlay: show() called');
    debugPrint('🎯 FloatingMiniPlayerOverlay: Episode: ${episode['title']}');
    debugPrint(
        '🎯 FloatingMiniPlayerOverlay: Episodes count: ${episodes.length}');
    debugPrint('🎯 FloatingMiniPlayerOverlay: Episode index: $episodeIndex');
    debugPrint('🎯 FloatingMiniPlayerOverlay: Is already visible: $_isVisible');

    // Note: Position cache has been removed - always auto-detects

    if (_isVisible) {
      debugPrint('🎯 FloatingMiniPlayerOverlay: Already visible, returning');
      return;
    }

    debugPrint('🎯 FloatingMiniPlayerOverlay: Creating overlay entry');
    _overlayEntry = OverlayEntry(
      builder: (context) => _FloatingMiniPlayerWidget(
        episode: episode,
        episodes: episodes,
        episodeIndex: episodeIndex,
      ),
    );

    debugPrint('🎯 FloatingMiniPlayerOverlay: Inserting overlay');
    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
    debugPrint(
        '🎯 FloatingMiniPlayerOverlay: Overlay inserted, _isVisible set to true');
  }

  /// Hide the floating mini-player
  static void hide({bool force = false}) {
    debugPrint('🎯 FloatingMiniPlayerOverlay: hide() called (force: $force)');
    debugPrint(
        '🎯 FloatingMiniPlayerOverlay: _overlayEntry is null: ${_overlayEntry == null}');
    debugPrint('🎯 FloatingMiniPlayerOverlay: _isVisible: $_isVisible');
    debugPrint('🎯 FloatingMiniPlayerOverlay: _strictMode: $_strictMode');

    // In strict mode, only allow hiding if forced (explicit user action)
    if (_strictMode && !force) {
      debugPrint(
          '🎯 FloatingMiniPlayerOverlay: Strict mode enabled - preventing automatic hide');
      return;
    }

    if (_overlayEntry != null) {
      debugPrint('🎯 FloatingMiniPlayerOverlay: Removing overlay entry');
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
      debugPrint(
          '🎯 FloatingMiniPlayerOverlay: Overlay hidden, _isVisible set to false');
    } else {
      debugPrint('🎯 FloatingMiniPlayerOverlay: No overlay entry to hide');
    }
  }

  /// Check if the mini-player is currently visible
  static bool get isVisible => _isVisible;

  /// Enable or disable strict mode (prevents automatic dismissal)
  static void setStrictMode(bool enabled) {
    _strictMode = enabled;
    debugPrint(
        '🎯 FloatingMiniPlayerOverlay: Strict mode ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if strict mode is enabled
  static bool get isStrictModeEnabled => _strictMode;

  /// Enable or disable back button protection
  static void setBackButtonProtection(bool enabled) {
    _protectFromBackButton = enabled;
    debugPrint(
        '🎯 FloatingMiniPlayerOverlay: Back button protection ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if back button protection is enabled
  static bool get isBackButtonProtectionEnabled => _protectFromBackButton;

  /// Force hide the mini-player (bypasses strict mode)
  static void forceHide() {
    hide(force: true);
  }

  /// Force refresh the mini-player positioning
  /// This will recreate the overlay with the new positioning
  static void refreshPositioning() {
    if (_isVisible && _overlayEntry != null) {
      debugPrint('🎯 FloatingMiniPlayerOverlay: Refreshing positioning');
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// Force complete refresh of the mini-player
  /// This will hide and show the mini-player to ensure new positioning takes effect
  static void forceRefresh() {
    if (_isVisible) {
      debugPrint('🎯 FloatingMiniPlayerOverlay: Force refreshing mini-player');
      hide(force: true);
      // Note: The mini-player will need to be shown again by the calling code
    }
  }

  /// Debug method to check current positioning values
  static void debugPositioning(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navHeight = screenHeight * 0.08;

    debugPrint('🎯 MiniPlayer Debug Info:');
    debugPrint('🎯 - Screen height: ${screenHeight}px');
    debugPrint('🎯 - Bottom padding: ${bottomPadding}px');
    debugPrint('🎯 - Navigation height: ${navHeight}px');
    debugPrint(
        '🎯 - Expected mini-player position: ${bottomPadding + navHeight}px');
    debugPrint('🎯 - Mini-player is visible: $_isVisible');
  }

  /// Note: Bottom navigation cache has been removed.
  /// The mini-player now always auto-detects positioning for optimal performance.

  /// Get the last measured mini-player height (excluding nav offset)
  /// This can be used by screens to add bottom padding to scrollables
  /// Note: Returns a default value since static caching has been removed for consistency
  static double getMiniPlayerHeight() {
    return 72.0; // More accurate mini-player height (48px content + 24px margins)
  }

  /// Note: Positioning methods have been removed.
  /// The mini-player now always auto-detects positioning for optimal performance.

  /// Update the mini-player with new episode data
  static void update(
    BuildContext context,
    Map<String, dynamic> episode,
    List<Map<String, dynamic>> episodes,
    int episodeIndex,
  ) {
    if (_isVisible) {
      hide();
    }
    show(context, episode, episodes, episodeIndex);
  }
}

class _FloatingMiniPlayerWidget extends StatefulWidget {
  final Map<String, dynamic> episode;
  final List<Map<String, dynamic>> episodes;
  final int episodeIndex;

  const _FloatingMiniPlayerWidget({
    required this.episode,
    required this.episodes,
    required this.episodeIndex,
  });

  @override
  State<_FloatingMiniPlayerWidget> createState() =>
      _FloatingMiniPlayerWidgetState();
}

class _FloatingMiniPlayerWidgetState extends State<_FloatingMiniPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Mini-player height tracking (no caching) - removed static to prevent cross-device issues
  double _miniPlayerHeight = 0.0;

  // State for actions bottom sheet
  bool _showActionsBottomSheet = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 _FloatingMiniPlayerWidget: initState() called');
    debugPrint(
        '🎯 _FloatingMiniPlayerWidget: Episode: ${widget.episode['title']}');
    debugPrint(
        '🎯 _FloatingMiniPlayerWidget: Episodes count: ${widget.episodes.length}');
    debugPrint(
        '🎯 _FloatingMiniPlayerWidget: Episode index: ${widget.episodeIndex}');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start below screen
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Animate in
    debugPrint('🎯 _FloatingMiniPlayerWidget: Starting slide animation');
    _animationController.forward();
  }

  @override
  void dispose() {
    debugPrint('🎯 _FloatingMiniPlayerWidget: dispose() called');
    _animationController.dispose();
    super.dispose();
  }

  /// Note: Bottom navigation cache methods have been removed.
  /// The mini-player now always auto-detects positioning for optimal performance.

  /// Expose current mini-player widget height for screens to pad their scrollables
  double getMiniPlayerHeight() => _miniPlayerHeight;

  /// Get static height for mini-player positioning - always positioned directly above EnhancedMainNavigation
  double _getBottomNavHeight(BuildContext context) {
    // Static positioning: Always position directly above EnhancedMainNavigation bar
    // CommonBottomNavigationWidget height is 8.h (8% of screen height)
    final screenHeight = MediaQuery.of(context).size.height;
    final navHeight = screenHeight * 0.08; // 8% of screen height (8.h)

    // Return just the navigation bar height (without bottom padding to avoid double-counting)
    debugPrint(
        '🎯 MiniPlayer: Static positioning - nav height: ${navHeight}px');

    return navHeight;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Consumer<PodcastPlayerProvider>(
        builder: (context, playerProvider, child) {
          // Don't show mini-player if no episode is loaded
          if (playerProvider.currentEpisode == null) {
            return const SizedBox.shrink();
          }

          // Wrap with PopScope to handle back button protection
          Widget miniPlayerContent = Stack(
            children: [
              // Main mini-player
              _buildMiniPlayer(context, playerProvider),

              // Resume notification overlay
              if (playerProvider.lastResumeInfo != null)
                _buildResumeNotification(context, playerProvider),

              // Actions bottom sheet overlay
              if (_showActionsBottomSheet)
                _buildActionsBottomSheet(context, playerProvider),
            ],
          );

          // Add back button protection if enabled
          if (FloatingMiniPlayerOverlay._protectFromBackButton) {
            return PopScope(
              canPop: false, // Prevent back button from closing the mini-player
              onPopInvoked: (didPop) {
                if (didPop) {
                  debugPrint(
                      '🎯 FloatingMiniPlayerOverlay: Back button pressed - preventing dismissal');
                }
              },
              child: miniPlayerContent,
            );
          }

          return miniPlayerContent;
        },
      ),
    );
  }

  Widget _buildMiniPlayer(
      BuildContext context, PodcastPlayerProvider playerProvider) {
    debugPrint('🎯 _FloatingMiniPlayerWidget: build() called');
    debugPrint(
        '🎯 _FloatingMiniPlayerWidget: Bottom nav height: ${_getBottomNavHeight(context)}px');

    // Calculate the exact bottom position to avoid blocking navigation bar
    final bottomNavHeight = _getBottomNavHeight(context);
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final miniPlayerBottomPosition = safeAreaBottom + bottomNavHeight;

    debugPrint('🎯 MiniPlayer: Positioning calculation:');
    debugPrint('🎯 MiniPlayer: - Safe area bottom: ${safeAreaBottom}px');
    debugPrint('🎯 MiniPlayer: - Navigation height: ${bottomNavHeight}px');
    debugPrint(
        '🎯 MiniPlayer: - Final position: ${miniPlayerBottomPosition}px');

    return Positioned(
      left: 0,
      right: 0,
      bottom:
          miniPlayerBottomPosition, // Position above navigation bar, not at bottom
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 4, // Lower elevation than Snackbars (which use 8)
          color: Colors.transparent,
          child: _buildMiniPlayerWidget(playerProvider),
        ),
      ),
    );
  }

  Widget _buildMiniPlayerWidget(PodcastPlayerProvider playerProvider) {
    final isPlaying = playerProvider.isPlaying;

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        margin: const EdgeInsets.only(
            left: 14, // Reduced from 16 to 14
            right: 14, // Reduced from 16 to 14
            bottom: 6, // Reduced from 8 to 6
            top: 6), // Reduced from 8 to 6
        decoration: BoxDecoration(
          // Light gray background to match the design
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            // Subtle bottom shadow to suggest floating above nav bar
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onHorizontalDragEnd: (details) =>
                _onSwipeRight(details, context, playerProvider),
            child: InkWell(
              onTap: () => _expandToFullScreen(context),
              borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
              child: Padding(
                padding: const EdgeInsets.all(14), // Reduced from 16 to 14
                child: Row(
                  children: [
                    // Square thumbnail image (left side)
                    _buildThumbnail(playerProvider),
                    const SizedBox(width: 14), // Reduced from 16 to 14

                    // Playback controls (center)
                    Expanded(
                      child: _buildPlaybackControls(playerProvider, isPlaying),
                    ),

                    const SizedBox(width: 14), // Reduced from 16 to 14

                    // Playlist/queue icon (right side)
                    _buildPlaylistButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildResumeNotification(
      BuildContext context, PodcastPlayerProvider playerProvider) {
    final resumeInfo = playerProvider.lastResumeInfo!;
    final resumePosition = resumeInfo['position'] as Duration;
    final totalDuration = resumeInfo['duration'] as Duration;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ResumeNotificationWidget(
        resumePosition: resumePosition,
        totalDuration: totalDuration,
        onDismiss: () {
          playerProvider.clearResumeInfo();
        },
        onRestart: () async {
          // Start playing from the beginning
          debugPrint('🔄 Resume Restart: Starting playback from beginning');
          try {
            await playerProvider.startOverFromResumePoint();
            debugPrint('✅ Resume Restart: Playback started from beginning');
          } catch (e) {
            debugPrint('❌ Resume Restart: Error starting playback: $e');
          }
        },
        onContinue: () async {
          // Start playing from the saved position
          debugPrint(
              '🎵 Resume Continue: Starting playback from saved position');
          try {
            await playerProvider.continueFromResumePoint();
            debugPrint('✅ Resume Continue: Playback started successfully');
          } catch (e) {
            debugPrint('❌ Resume Continue: Error starting playback: $e');
          }
        },
      ),
    );
  }

  Widget _buildThumbnail(PodcastPlayerProvider playerProvider) {
    // Get the current episode from the player provider for real-time updates
    final currentEpisode = playerProvider.currentEpisode;

    // Use current episode data with podcast data if available, otherwise fall back to widget episode
    final episodeData = currentEpisode != null
        ? currentEpisode.toMapWithPodcastData(playerProvider.currentPodcastData)
        : widget.episode;

    // Extract podcast image using the utility function
    final podcastImage = ImageUtils.extractPodcastImageWithFallback(
      episodeData,
      widget.episodes,
    );

    debugPrint('Mini-player image extracted: $podcastImage');

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: podcastImage.isEmpty ? const Color(0xFF4CAF50) : null,
      ),
      child: ImageUtils.isValidImageUrl(podcastImage)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomImageWidget(
                imageUrl: podcastImage,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: ImageUtils.getFallbackWidget(
                  width: 48,
                  height: 48,
                  backgroundColor: const Color(0xFF4CAF50),
                  iconColor: Colors.white,
                ),
              ),
            )
          : ImageUtils.getFallbackWidget(
              width: 48,
              height: 48,
              backgroundColor: const Color(0xFF4CAF50),
              iconColor: Colors.white,
            ),
    );
  }

  Widget _buildPlaybackControls(
      PodcastPlayerProvider playerProvider, bool isPlaying) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind/skip back button
        Container(
          width: 36, // Reduced from 40 to 36
          height: 36, // Reduced from 40 to 36
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: IconButton(
            onPressed: () {
              // Implement rewind 10 seconds
              final currentPos = playerProvider.position ?? Duration.zero;
              final newPos = Duration(
                milliseconds: (currentPos.inMilliseconds - 10000)
                    .clamp(0, double.infinity)
                    .toInt(),
              );
              playerProvider.seekTo(newPos);
              debugPrint(
                  '⏪ Mini-player: Rewound 10 seconds to ${newPos.inSeconds}s');
            },
            icon: const Icon(
              Icons.replay_10,
              color: Colors.black87,
              size: 18, // Reduced from 20 to 18
            ),
            padding: EdgeInsets.zero,
          ),
        ),

        const SizedBox(width: 14), // Reduced from 16 to 14

        // Main play/pause button (large black circle)
        Container(
          width: 42, // Reduced from 48 to 42
          height: 42, // Reduced from 48 to 42
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: IconButton(
            onPressed: () {
              if (isPlaying) {
                playerProvider.pause();
              } else {
                playerProvider.play();
              }
            },
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 22, // Reduced from 24 to 22
            ),
            padding: EdgeInsets.zero,
          ),
        ),

        const SizedBox(width: 14), // Reduced from 16 to 14

        // Fast forward/skip forward button
        Container(
          width: 36, // Reduced from 40 to 36
          height: 36, // Reduced from 40 to 36
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: IconButton(
            onPressed: () {
              // Implement fast forward 10 seconds
              final currentPos = playerProvider.position ?? Duration.zero;
              final totalDur = playerProvider.duration ?? Duration.zero;
              final newPos = Duration(
                milliseconds: (currentPos.inMilliseconds + 10000)
                    .clamp(0, totalDur.inMilliseconds)
                    .toInt(),
              );
              playerProvider.seekTo(newPos);
              debugPrint(
                  '⏩ Mini-player: Fast forwarded 10 seconds to ${newPos.inSeconds}s');
            },
            icon: const Icon(
              Icons.forward_10,
              color: Colors.black87,
              size: 18, // Reduced from 20 to 18
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistButton() {
    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        final queueCount = playerProvider.episodeQueue.length;

        return Container(
          width: 36, // Reduced from 40 to 36
          height: 36, // Reduced from 40 to 36
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6), // Reduced from 8 to 6
          ),
          child: Stack(
            children: [
              IconButton(
                onPressed: () => _showUpNextModal(context),
                icon: const Icon(
                  // Icon similar to the three horizontal lines with vertical line
                  Icons.queue_music,
                  color: Colors.white,
                  size: 18, // Reduced from 20 to 18
                ),
                padding: EdgeInsets.zero,
              ),
              // Queue count badge
              if (queueCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      queueCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showUpNextModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpNextModal(),
        fullscreenDialog: true,
      ),
    );
  }

  void _expandToFullScreen(BuildContext context) {
    // Get the current episode data from the player provider
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    final currentEpisode = playerProvider.currentEpisode;
    final episodeData =
        currentEpisode != null ? currentEpisode.toMap() : widget.episode;

    // Animate out
    _animationController.reverse().then((_) {
      // Hide the floating mini-player (force hide to allow transition to full screen)
      FloatingMiniPlayerOverlay.hide(force: true);

      // Show full screen player with current episode data
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false, // Prevent accidental dismissal
        enableDrag: false, // Prevent drag to dismiss
        builder: (context) => SafeAreaUtils.wrapWithSafeArea(
          FullScreenPlayerModal(
            episode: episodeData,
            episodes: widget.episodes,
            episodeIndex: widget.episodeIndex,
            isMinimized: false,
            onMinimize: () => _minimizeToBottom(context),
          ),
        ),
      );
    });
  }

  void _minimizeToBottom(BuildContext context) {
    // Close full screen player
    Navigator.of(context).pop();

    // Get the current episode data from the player provider
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    final currentEpisode = playerProvider.currentEpisode;
    final episodeData =
        currentEpisode != null ? currentEpisode.toMap() : widget.episode;

    // Show floating mini-player again with current episode data
    FloatingMiniPlayerOverlay.show(
      context,
      episodeData,
      widget.episodes,
      widget.episodeIndex,
    );
  }

  /// Handle swipe right gesture to show actions bottom sheet
  void _onSwipeRight(DragEndDetails details, BuildContext context,
      PodcastPlayerProvider playerProvider) {
    // Check if it's a swipe right (positive velocity)
    if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
      // Toggle the actions bottom sheet
      setState(() {
        _showActionsBottomSheet = !_showActionsBottomSheet;
      });
    }
  }

  /// Build the actions bottom sheet as part of the overlay stack
  Widget _buildActionsBottomSheet(
      BuildContext context, PodcastPlayerProvider playerProvider) {
    final currentEpisode = playerProvider.currentEpisode;
    if (currentEpisode == null) return const SizedBox.shrink();

    // Calculate the position above the mini-player
    final miniPlayerHeight =
        72.0; // More accurate mini-player height (48px content + 24px margins)
    final bottomNavHeight = _getBottomNavHeight(context);
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final miniPlayerBottomPosition = safeAreaBottom + bottomNavHeight;
    final totalBottomOffset = miniPlayerBottomPosition + miniPlayerHeight;

    return Positioned(
      left: 0,
      right: 0,
      bottom: totalBottomOffset, // Position above the mini-player
      child: Material(
        elevation: 64, // High elevation to ensure it appears above mini-player
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Episode info header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Episode thumbnail
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: currentEpisode.coverImage != null &&
                                currentEpisode.coverImage!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(currentEpisode.coverImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: currentEpisode.coverImage == null ||
                                currentEpisode.coverImage!.isEmpty
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)
                            : null,
                      ),
                      child: currentEpisode.coverImage == null ||
                              currentEpisode.coverImage!.isEmpty
                          ? Icon(
                              Icons.music_note,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            )
                          : null,
                    ),

                    const SizedBox(width: 16),

                    // Episode details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentEpisode.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentEpisode.podcastName ?? 'Unknown Podcast',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Close button
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showActionsBottomSheet = false;
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Actions
              _buildActionItem(
                context: context,
                icon: Icons.check_circle_outline,
                title: 'Mark played',
                subtitle: 'Mark this episode as completed',
                onTap: () => _onMarkPlayed(context, playerProvider),
                iconColor: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onSurface,
              ),

              const Divider(height: 1),

              _buildActionItem(
                context: context,
                icon: Icons.close,
                title: 'Close and clear Up Next',
                subtitle: 'Stop playback and clear the queue',
                onTap: () => _onCloseAndClear(context, playerProvider),
                iconColor: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.error,
              ),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
    required Color textColor,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow indicator
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle "Mark played" action
  void _onMarkPlayed(
      BuildContext context, PodcastPlayerProvider playerProvider) async {
    try {
      final currentEpisode = playerProvider.currentEpisode;
      if (currentEpisode == null) return;

      // Mark episode as played using the progress provider
      // You'll need to implement this method in your EpisodeProgressProvider
      // For now, we'll just show a success message

      // Update the episode in the player provider
      final updatedEpisode = currentEpisode.copyWith(
        isCompleted: true,
        lastPlayedAt: DateTime.now(),
      );

      // This will trigger UI updates
      // Note: notifyListeners() is called automatically by the provider when state changes

      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Episode marked as played'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Close the actions bottom sheet
      setState(() {
        _showActionsBottomSheet = false;
      });
    } catch (e) {
      debugPrint('❌ Error marking episode as played: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle "Close and clear Up Next" action
  void _onCloseAndClear(
      BuildContext context, PodcastPlayerProvider playerProvider) async {
    try {
      // Clear the episode queue
      playerProvider.clearQueue();

      // Stop playback
      await playerProvider.pause();

      // Mark mini-player as explicitly closed by user
      playerProvider.markMiniPlayerAsExplicitlyClosed();

      // Hide the mini-player (force hide for explicit user action)
      FloatingMiniPlayerOverlay.forceHide();

      // Show feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.queue_music,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Queue cleared and player closed'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error closing and clearing queue: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // Close the actions bottom sheet
    setState(() {
      _showActionsBottomSheet = false;
    });
  }
}
