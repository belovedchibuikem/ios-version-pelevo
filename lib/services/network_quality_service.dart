import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/buffering_models.dart';

/// Service to monitor network quality and provide adaptive buffering recommendations
class NetworkQualityService {
  static final NetworkQualityService _instance =
      NetworkQualityService._internal();
  factory NetworkQualityService() => _instance;
  NetworkQualityService._internal();

  final Connectivity _connectivity = Connectivity();
  NetworkQuality _currentQuality = NetworkQuality.unknown;
  double _lastSpeedTest = 0.0;
  DateTime? _lastSpeedTestTime;

  // Stream controllers
  final StreamController<NetworkQuality> _qualityController =
      StreamController<NetworkQuality>.broadcast();
  final StreamController<double> _speedController =
      StreamController<double>.broadcast();

  // Getters
  NetworkQuality get currentQuality => _currentQuality;
  double get lastSpeedTest => _lastSpeedTest;
  Stream<NetworkQuality> get qualityStream => _qualityController.stream;
  Stream<double> get speedStream => _speedController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Get initial connectivity result
      final connectivityResult = await _connectivity.checkConnectivity();
      await _updateNetworkQuality(connectivityResult);

      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
        _updateNetworkQuality(result);
      });

      // Perform initial speed test
      await _performSpeedTest();

      debugPrint('NetworkQualityService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NetworkQualityService: $e');
    }
  }

  /// Update network quality based on connectivity result
  Future<void> _updateNetworkQuality(ConnectivityResult result) async {
    NetworkQuality newQuality;

    switch (result) {
      case ConnectivityResult.wifi:
        // WiFi usually means good to excellent quality
        newQuality = NetworkQuality.good;
        break;
      case ConnectivityResult.mobile:
        // Mobile can vary, will be updated by speed test
        newQuality = NetworkQuality.poor;
        break;
      case ConnectivityResult.ethernet:
        // Ethernet usually means excellent quality
        newQuality = NetworkQuality.excellent;
        break;
      case ConnectivityResult.none:
        newQuality = NetworkQuality.poor;
        break;
      default:
        newQuality = NetworkQuality.unknown;
    }

    if (_currentQuality != newQuality) {
      _currentQuality = newQuality;
      _qualityController.add(_currentQuality);
      debugPrint('NetworkQualityService: Quality changed to $_currentQuality');
    }
  }

  /// Perform a speed test to determine actual network quality
  Future<void> _performSpeedTest() async {
    try {
      // Simple speed test using a small file download
      final stopwatch = Stopwatch()..start();

      // Test with a small file (1KB) to measure speed
      final testUrl = 'https://httpbin.org/bytes/1024';
      final response = await _makeTestRequest(testUrl);

      stopwatch.stop();

      if (response != null) {
        final durationMs = stopwatch.elapsedMilliseconds;
        final bytesPerSecond = 1024 / (durationMs / 1000);
        final mbps = (bytesPerSecond * 8) / (1024 * 1024); // Convert to Mbps

        _lastSpeedTest = mbps;
        _lastSpeedTestTime = DateTime.now();
        _speedController.add(mbps);

        // Update quality based on speed
        final newQuality = _determineQualityFromSpeed(mbps);
        if (_currentQuality != newQuality) {
          _currentQuality = newQuality;
          _qualityController.add(_currentQuality);
        }

        debugPrint(
            'NetworkQualityService: Speed test - ${mbps.toStringAsFixed(2)} Mbps, Quality: $_currentQuality');
      }
    } catch (e) {
      debugPrint('NetworkQualityService: Speed test failed: $e');
      _currentQuality = NetworkQuality.poor;
      _qualityController.add(_currentQuality);
    }
  }

  /// Make a test request to measure network speed
  Future<dynamic> _makeTestRequest(String url) async {
    try {
      // Using dart:io HttpClient for speed test
      final client = HttpClient();

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        // Read the response to complete the request
        await response.transform(utf8.decoder).drain();
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('NetworkQualityService: Test request failed: $e');
      return null;
    }
  }

  /// Determine network quality based on speed in Mbps
  NetworkQuality _determineQualityFromSpeed(double mbps) {
    if (mbps >= 10.0) {
      return NetworkQuality.excellent;
    } else if (mbps >= 2.0) {
      return NetworkQuality.good;
    } else {
      return NetworkQuality.poor;
    }
  }

  /// Get recommended buffer size based on network quality
  int getRecommendedBufferSize() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return 30; // 30 seconds for excellent connection
      case NetworkQuality.good:
        return 20; // 20 seconds for good connection
      case NetworkQuality.poor:
        return 10; // 10 seconds for poor connection
      case NetworkQuality.unknown:
        return 15; // 15 seconds default
    }
  }

  /// Get recommended audio quality based on network quality
  AudioQuality getRecommendedAudioQuality() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return AudioQuality.original;
      case NetworkQuality.good:
        return AudioQuality.high;
      case NetworkQuality.poor:
        return AudioQuality.medium;
      case NetworkQuality.unknown:
        return AudioQuality.medium;
    }
  }

  /// Check if speed test is needed (older than 5 minutes)
  bool get needsSpeedTest {
    if (_lastSpeedTestTime == null) return true;
    final difference = DateTime.now().difference(_lastSpeedTestTime!);
    return difference.inMinutes >= 5;
  }

  /// Perform a speed test if needed
  Future<void> performSpeedTestIfNeeded() async {
    if (needsSpeedTest) {
      await _performSpeedTest();
    }
  }

  /// Force a speed test
  Future<void> forceSpeedTest() async {
    await _performSpeedTest();
  }

  /// Get network quality description
  String get qualityDescription {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return 'Excellent';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.poor:
        return 'Poor';
      case NetworkQuality.unknown:
        return 'Unknown';
    }
  }

  /// Get speed description
  String get speedDescription {
    if (_lastSpeedTest == 0.0) return 'Unknown';
    return '${_lastSpeedTest.toStringAsFixed(1)} Mbps';
  }

  /// Dispose resources
  void dispose() {
    _qualityController.close();
    _speedController.close();
  }
}
