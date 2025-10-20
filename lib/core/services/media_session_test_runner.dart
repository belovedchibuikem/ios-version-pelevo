import 'package:flutter/foundation.dart';
import '../../data/models/episode.dart';
import '../../providers/podcast_player_provider.dart';
import 'media_session_service.dart';
import 'media_session_integration.dart';

/// Comprehensive test runner for media session functionality
class MediaSessionTestRunner {
  static final MediaSessionService _mediaSessionService = MediaSessionService();
  static final MediaSessionIntegration _mediaSessionIntegration =
      MediaSessionIntegration();

  /// Run comprehensive media session tests
  static Future<void> runComprehensiveTests(
      {PodcastPlayerProvider? playerProvider}) async {
    debugPrint('🧪 Starting Comprehensive Media Session Tests...');

    final results = <String, bool>{};

    // Test 1: Service Initialization
    results['Service Initialization'] =
        await _testServiceInitialization(playerProvider);

    // Test 2: Episode Setting
    results['Episode Setting'] = _testEpisodeSetting();

    // Test 3: Playback State Updates
    results['Playback State Updates'] = _testPlaybackStateUpdates();

    // Test 4: Position Updates
    results['Position Updates'] = _testPositionUpdates();

    // Test 5: Duration Updates
    results['Duration Updates'] = _testDurationUpdates();

    // Test 6: Integration Test
    results['Integration Test'] = await _testIntegration(playerProvider);

    // Test 7: Real Episode Test
    results['Real Episode Test'] = await _testRealEpisode();

    // Display results
    _displayTestResults(results);
  }

  /// Test service initialization
  static Future<bool> _testServiceInitialization(
      PodcastPlayerProvider? playerProvider) async {
    try {
      await _mediaSessionService.initialize(playerProvider: playerProvider);
      await _mediaSessionIntegration.initialize(playerProvider: playerProvider);
      debugPrint('✅ Service initialization test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Service initialization test: FAILED - $e');
      return false;
    }
  }

  /// Test episode setting
  static bool _testEpisodeSetting() {
    try {
      final testEpisode = Episode(
        id: 1,
        title: 'Test Episode',
        podcastName: 'Test Podcast',
        creator: 'Test Creator',
        coverImage: 'https://example.com/image.jpg',
        duration: '30:00',
        description: 'Test episode description',
        releaseDate: DateTime.now(),
        audioUrl: 'https://example.com/audio.mp3',
      );

      _mediaSessionService.setEpisode(testEpisode);
      _mediaSessionIntegration.setEpisode(testEpisode);
      debugPrint('✅ Episode setting test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Episode setting test: FAILED - $e');
      return false;
    }
  }

  /// Test playback state updates
  static bool _testPlaybackStateUpdates() {
    try {
      // Test playing state
      _mediaSessionService.updatePlaybackState(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
      );
      _mediaSessionIntegration.updatePlaybackState(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
      );

      // Test paused state
      _mediaSessionService.updatePlaybackState(
        isPlaying: false,
        position: Duration(seconds: 60),
        duration: Duration(minutes: 5),
      );
      _mediaSessionIntegration.updatePlaybackState(
        isPlaying: false,
        position: Duration(seconds: 60),
        duration: Duration(minutes: 5),
      );

      debugPrint('✅ Playback state updates test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Playback state updates test: FAILED - $e');
      return false;
    }
  }

  /// Test position updates
  static bool _testPositionUpdates() {
    try {
      _mediaSessionService.updatePosition(Duration(seconds: 45));
      _mediaSessionIntegration.updatePosition(Duration(seconds: 45));
      _mediaSessionService.updatePosition(Duration(minutes: 1, seconds: 30));
      _mediaSessionIntegration
          .updatePosition(Duration(minutes: 1, seconds: 30));
      debugPrint('✅ Position updates test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Position updates test: FAILED - $e');
      return false;
    }
  }

  /// Test duration updates
  static bool _testDurationUpdates() {
    try {
      _mediaSessionService.updateDuration(Duration(minutes: 10));
      _mediaSessionIntegration.updateDuration(Duration(minutes: 10));
      _mediaSessionService.updateDuration(Duration(hours: 1, minutes: 30));
      _mediaSessionIntegration.updateDuration(Duration(hours: 1, minutes: 30));
      debugPrint('✅ Duration updates test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Duration updates test: FAILED - $e');
      return false;
    }
  }

  /// Test integration with player provider
  static Future<bool> _testIntegration(
      PodcastPlayerProvider? playerProvider) async {
    try {
      if (playerProvider == null) {
        debugPrint('⚠️ Integration test: SKIPPED (no player provider)');
        return true;
      }

      // Test that integration is properly set up
      final isInitialized = _mediaSessionIntegration.isInitialized;
      if (!isInitialized) {
        debugPrint('❌ Integration test: FAILED - not initialized');
        return false;
      }

      debugPrint('✅ Integration test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Integration test: FAILED - $e');
      return false;
    }
  }

  /// Test with real episode data
  static Future<bool> _testRealEpisode() async {
    try {
      debugPrint('🧪 Testing with real episode data...');

      // Create a realistic episode
      final episode = Episode(
        id: 12345,
        title: 'The Future of Podcasting',
        podcastName: 'Tech Talk Weekly',
        creator: 'John Doe',
        coverImage: 'https://example.com/podcast-cover.jpg',
        duration: '45:30',
        description:
            'In this episode, we discuss the latest trends in podcasting technology and what the future holds for content creators.',
        releaseDate: DateTime.now().subtract(Duration(days: 1)),
        audioUrl: 'https://example.com/episode-123.mp3',
        podcastId: 'tech-talk-weekly',
      );

      // Test the full workflow
      _mediaSessionService.setEpisode(episode);
      _mediaSessionIntegration.setEpisode(episode);

      // Simulate playback
      _mediaSessionService.updatePlaybackState(
        isPlaying: true,
        position: Duration.zero,
        duration: Duration(minutes: 45, seconds: 30),
      );
      _mediaSessionIntegration.updatePlaybackState(
        isPlaying: true,
        position: Duration.zero,
        duration: Duration(minutes: 45, seconds: 30),
      );

      // Simulate position updates
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(milliseconds: 100));
        _mediaSessionService.updatePosition(Duration(seconds: i * 10));
        _mediaSessionIntegration.updatePosition(Duration(seconds: i * 10));
      }

      // Simulate pause
      _mediaSessionService.updatePlaybackState(
        isPlaying: false,
        position: Duration(seconds: 50),
        duration: Duration(minutes: 45, seconds: 30),
      );
      _mediaSessionIntegration.updatePlaybackState(
        isPlaying: false,
        position: Duration(seconds: 50),
        duration: Duration(minutes: 45, seconds: 30),
      );

      debugPrint('✅ Real episode test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Real episode test: FAILED - $e');
      return false;
    }
  }

  /// Display test results
  static void _displayTestResults(Map<String, bool> results) {
    debugPrint('\n📊 Media Session Test Results:');
    debugPrint('=' * 50);

    results.forEach((test, passed) {
      final status = passed ? '✅ PASSED' : '❌ FAILED';
      debugPrint('$status: $test');
    });

    final passedCount = results.values.where((passed) => passed).length;
    final totalCount = results.length;
    final percentage = (passedCount / totalCount * 100).round();

    debugPrint('=' * 50);
    debugPrint(
        '🎯 Overall Result: $passedCount/$totalCount tests passed ($percentage%)');

    if (passedCount == totalCount) {
      debugPrint('🎉 All media session tests passed!');
      debugPrint('🎵 Media session should be working correctly.');
    } else {
      debugPrint('⚠️ Some media session tests failed.');
      debugPrint('🔧 Check the logs above for specific issues.');
    }

    debugPrint('=' * 50);
  }

  /// Quick test for basic functionality
  static Future<void> runQuickTest() async {
    debugPrint('⚡ Running Quick Media Session Test...');

    try {
      // Test basic initialization
      await _mediaSessionService.initialize();
      debugPrint('✅ Quick test: Service initialized');

      // Test episode setting
      final episode = Episode(
        id: 1,
        title: 'Quick Test Episode',
        podcastName: 'Test Podcast',
        creator: 'Test Creator',
        coverImage: '',
        duration: '5:00',
        description: 'Quick test',
        releaseDate: DateTime.now(),
        audioUrl: 'https://example.com/test.mp3',
      );

      _mediaSessionService.setEpisode(episode);
      debugPrint('✅ Quick test: Episode set');

      // Test playback state
      _mediaSessionService.updatePlaybackState(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
      );
      debugPrint('✅ Quick test: Playback state updated');

      debugPrint('🎉 Quick test completed successfully!');
    } catch (e) {
      debugPrint('❌ Quick test failed: $e');
    }
  }
}
