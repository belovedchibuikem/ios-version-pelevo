import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/episode.dart';
import '../providers/podcast_player_provider.dart';
import '../core/services/media_session_test_runner.dart';

/// Widget for testing media session functionality
class MediaSessionTestWidget extends StatefulWidget {
  const MediaSessionTestWidget({Key? key}) : super(key: key);

  @override
  State<MediaSessionTestWidget> createState() => _MediaSessionTestWidgetState();
}

class _MediaSessionTestWidgetState extends State<MediaSessionTestWidget> {
  bool _isRunningTests = false;
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Session Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test buttons
            ElevatedButton(
              onPressed: _isRunningTests ? null : _runQuickTest,
              child: const Text('Run Quick Test'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunningTests ? null : _runComprehensiveTests,
              child: const Text('Run Comprehensive Tests'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunningTests ? null : _testWithRealEpisode,
              child: const Text('Test with Real Episode'),
            ),
            const SizedBox(height: 24),

            // Test results
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty
                        ? 'Test results will appear here...'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            if (_isRunningTests)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _runQuickTest() async {
    setState(() {
      _isRunningTests = true;
      _testResults = 'Running quick test...\n';
    });

    try {
      await MediaSessionTestRunner.runQuickTest();
      setState(() {
        _testResults += '\n✅ Quick test completed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Quick test failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _runComprehensiveTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = 'Running comprehensive tests...\n';
    });

    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      await MediaSessionTestRunner.runComprehensiveTests(
          playerProvider: playerProvider);
      setState(() {
        _testResults += '\n✅ Comprehensive tests completed!';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Comprehensive tests failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _testWithRealEpisode() async {
    setState(() {
      _isRunningTests = true;
      _testResults = 'Testing with real episode...\n';
    });

    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      // Create a test episode
      final testEpisode = Episode(
        id: 999,
        title: 'Media Session Test Episode',
        podcastName: 'Test Podcast',
        creator: 'Test Creator',
        coverImage: 'https://via.placeholder.com/300x300.png?text=Test+Episode',
        duration: '10:00',
        description: 'This is a test episode for media session functionality.',
        releaseDate: DateTime.now(),
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        podcastId: 'test-podcast',
      );

      // Play the test episode
      await playerProvider.playEpisode(testEpisode);

      setState(() {
        _testResults += '\n✅ Test episode loaded and playing!';
        _testResults += '\n🎵 Check your lock screen for media controls.';
        _testResults +=
            '\n📱 Check your notification panel for media controls.';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Test episode failed: $e';
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }
}
