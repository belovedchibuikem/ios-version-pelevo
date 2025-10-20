import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  bool _isInitialized = false;

  // Stream to listen to connection status changes
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // Current connection status
  bool get isConnected => _isConnected;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
      _connectionStatusController.add(_isConnected);

      // Listen to connectivity changes
      _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
        final wasConnected = _isConnected;
        _isConnected = result != ConnectivityResult.none;

        if (wasConnected != _isConnected) {
          debugPrint(
              '🌐 Network connectivity changed: ${_isConnected ? 'Connected' : 'Disconnected'}');
          _connectionStatusController.add(_isConnected);
        }
      });

      _isInitialized = true;
      debugPrint('✅ NetworkConnectivityService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NetworkConnectivityService: $e');
      rethrow;
    }
  }

  // Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final connected = result != ConnectivityResult.none;

      if (_isConnected != connected) {
        _isConnected = connected;
        _connectionStatusController.add(_isConnected);
      }

      return connected;
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      return false;
    }
  }

  // Wait for network to become available
  Future<bool> waitForConnection(
      {Duration timeout = const Duration(seconds: 30)}) async {
    if (_isConnected) return true;

    try {
      await _connectionStatusController.stream
          .firstWhere((connected) => connected)
          .timeout(timeout);
      return true;
    } catch (e) {
      debugPrint('⏰ Timeout waiting for network connection');
      return false;
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await _connectionStatusController.close();
      debugPrint('✅ NetworkConnectivityService disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing NetworkConnectivityService: $e');
    }
  }
}

