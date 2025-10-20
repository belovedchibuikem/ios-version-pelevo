// lib/services/connectivity_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamController<ConnectivityResult> _connectionStatusController;
  late Stream<ConnectivityResult> connectionStatusStream;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _connectionStatusController =
        StreamController<ConnectivityResult>.broadcast();
    connectionStatusStream = _connectionStatusController.stream;

    // Get the initial connectivity status
    final initialResult = await _connectivity.checkConnectivity();
    _connectionStatusController.add(initialResult);

    // Listen for changes in connectivity
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _connectionStatusController.add(result);
    });

    _isInitialized = true;
  }

  Future<bool> isConnected() async {
    if (!_isInitialized) await initialize();

    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<ConnectivityResult> checkConnectivity() async {
    if (!_isInitialized) await initialize();

    return await _connectivity.checkConnectivity();
  }

  void dispose() {
    if (_isInitialized) {
      _connectionStatusController.close();
      _isInitialized = false;
    }
  }
}
