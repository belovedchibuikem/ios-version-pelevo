import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'media_session_service.dart';
import '../../providers/podcast_player_provider.dart';

/// Service to handle app-wide initialization including media session
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  final MediaSessionService _mediaSessionService = MediaSessionService();
  bool _isInitialized = false;

  /// Initialize all app services
  Future<void> initialize({PodcastPlayerProvider? playerProvider}) async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Starting app initialization...');

      // CRITICAL: Set up audio session first
      debugPrint('🎵 Setting up audio session...');
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.music());
      debugPrint('✅ Audio session configured successfully');

      // Initialize media session after audio session is ready
      await _mediaSessionService.initialize(playerProvider: playerProvider);

      // Set up system UI
      await _setupSystemUI();

      _isInitialized = true;
      debugPrint('✅ App initialization completed successfully');
    } catch (e) {
      debugPrint('❌ Error during app initialization: $e');
      // Don't rethrow - continue without media session
      debugPrint('⚠️ Continuing without media session functionality');
    }
  }

  /// Set up system UI for media playback
  Future<void> _setupSystemUI() async {
    try {
      // Set preferred orientations for media playback
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      debugPrint('✅ System UI configured for media playback');
    } catch (e) {
      debugPrint('❌ Error setting up system UI: $e');
    }
  }

  /// Get the media session service instance
  MediaSessionService get mediaSessionService => _mediaSessionService;

  /// Check if app is initialized
  bool get isInitialized => _isInitialized;
}
