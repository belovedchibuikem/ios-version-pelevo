import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_export.dart';
import '../providers/podcast_player_provider.dart';
import 'full_screen_player_modal.dart';
import 'floating_mini_player_overlay.dart';

class PlayerModalController {
  static void showMiniPlayer(
    BuildContext context,
    Map<String, dynamic> episode,
    List<Map<String, dynamic>> episodes,
    int episodeIndex,
  ) {
    // Show floating mini player overlay
    FloatingMiniPlayerOverlay.show(context, episode, episodes, episodeIndex);
  }

  static void _expandToFullScreen(
    BuildContext context,
    Map<String, dynamic> episode,
    List<Map<String, dynamic>> episodes,
    int episodeIndex,
  ) {
    // Hide floating mini player and show full screen (force hide for user action)
    FloatingMiniPlayerOverlay.hide(force: true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent accidental dismissal
      enableDrag: false, // Prevent drag to dismiss
      builder: (context) => SafeAreaUtils.wrapWithSafeArea(
        FullScreenPlayerModal(
          episode: episode,
          episodes: episodes,
          episodeIndex: episodeIndex,
          isMinimized: false,
          onMinimize: () => _minimizeToBottom(
            context,
            episode,
            episodes,
            episodeIndex,
          ),
        ),
      ),
    );
  }

  static void _minimizeToBottom(
    BuildContext context,
    Map<String, dynamic> episode,
    List<Map<String, dynamic>> episodes,
    int episodeIndex,
  ) {
    // Close full screen and show floating mini player
    Navigator.of(context).pop();

    FloatingMiniPlayerOverlay.show(context, episode, episodes, episodeIndex);
  }

  static void closePlayer(BuildContext context) {
    FloatingMiniPlayerOverlay.forceHide();
  }
}
