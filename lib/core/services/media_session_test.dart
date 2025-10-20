import 'package:flutter/foundation.dart';
import '../../data/models/episode.dart';
import 'media_session_manager.dart';

/// Test class to verify media session functionality
class MediaSessionTest {
  static final MediaSessionManager _mediaSessionManager = MediaSessionManager();

  /// Test media session initialization
  static Future<bool> testInitialization() async {
    try {
      await _mediaSessionManager.initialize();
      debugPrint('✅ Media session initialization test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Media session initialization test: FAILED - $e');
      return false;
    }
  }

  /// Test episode setting
  static bool testSetEpisode() {
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

      _mediaSessionManager.setEpisode(testEpisode);
      debugPrint('✅ Media session set episode test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Media session set episode test: FAILED - $e');
      return false;
    }
  }

  /// Test playback state updates
  static bool testPlaybackStateUpdate() {
    try {
      _mediaSessionManager.updatePlaybackState(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
      );

      _mediaSessionManager.updatePlaybackState(
        isPlaying: false,
        position: Duration(seconds: 60),
        duration: Duration(minutes: 5),
      );

      debugPrint('✅ Media session playback state test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Media session playback state test: FAILED - $e');
      return false;
    }
  }

  /// Test position updates
  static bool testPositionUpdate() {
    try {
      _mediaSessionManager.updatePosition(Duration(seconds: 45));
      _mediaSessionManager.updatePosition(Duration(minutes: 1, seconds: 30));
      debugPrint('✅ Media session position update test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Media session position update test: FAILED - $e');
      return false;
    }
  }

  /// Test duration updates
  static bool testDurationUpdate() {
    try {
      _mediaSessionManager.updateDuration(Duration(minutes: 10));
      _mediaSessionManager.updateDuration(Duration(hours: 1, minutes: 30));
      debugPrint('✅ Media session duration update test: PASSED');
      return true;
    } catch (e) {
      debugPrint('❌ Media session duration update test: FAILED - $e');
      return false;
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    debugPrint('🧪 Starting Media Session Tests...');

    final results = <String, bool>{};

    results['Initialization'] = await testInitialization();
    results['Set Episode'] = testSetEpisode();
    results['Playback State'] = testPlaybackStateUpdate();
    results['Position Update'] = testPositionUpdate();
    results['Duration Update'] = testDurationUpdate();

    debugPrint('\n📊 Media Session Test Results:');
    results.forEach((test, passed) {
      debugPrint(
          '${passed ? '✅' : '❌'} $test: ${passed ? 'PASSED' : 'FAILED'}');
    });

    final passedCount = results.values.where((passed) => passed).length;
    final totalCount = results.length;

    debugPrint('\n🎯 Overall Result: $passedCount/$totalCount tests passed');

    if (passedCount == totalCount) {
      debugPrint('🎉 All media session tests passed!');
    } else {
      debugPrint('⚠️ Some media session tests failed. Check the logs above.');
    }
  }

  /// Test with real episode data
  static Future<void> testWithRealEpisode() async {
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
      await _mediaSessionManager.initialize();
      _mediaSessionManager.setEpisode(episode);

      // Simulate playback
      _mediaSessionManager.updatePlaybackState(
        isPlaying: true,
        position: Duration.zero,
        duration: Duration(minutes: 45, seconds: 30),
      );

      // Simulate position updates
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(milliseconds: 100));
        _mediaSessionManager.updatePosition(Duration(seconds: i * 10));
      }

      // Simulate pause
      _mediaSessionManager.updatePlaybackState(
        isPlaying: false,
        position: Duration(seconds: 50),
        duration: Duration(minutes: 45, seconds: 30),
      );

      debugPrint('✅ Real episode test: PASSED');
    } catch (e) {
      debugPrint('❌ Real episode test: FAILED - $e');
    }
  }
}
