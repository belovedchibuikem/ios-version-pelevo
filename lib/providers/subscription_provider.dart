import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';
import '../services/library_api_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final Set<String> _subscribedPodcastIds = {};
  bool isLoading = true;
  String? errorMessage;
  bool _disposed = false;

  Set<String> get subscribedPodcastIds => _subscribedPodcastIds;

  bool isSubscribed(String podcastId) =>
      _subscribedPodcastIds.contains(podcastId);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get mounted => !_disposed;

  void setSubscriptions(Set<String> ids) {
    if (_disposed) return;
    _subscribedPodcastIds
      ..clear()
      ..addAll(ids);
    debugPrint('Subscribed podcast IDs:  [32m$_subscribedPodcastIds [0m');
    _safeNotifyListeners();
  }

  void addSubscription(String podcastId) {
    if (_disposed) return;
    _subscribedPodcastIds.add(podcastId);
    _safeNotifyListeners();
  }

  void removeSubscription(String podcastId) {
    if (_disposed) return;
    _subscribedPodcastIds.remove(podcastId);
    _safeNotifyListeners();
  }

  /// Safe method to notify listeners without causing setState during build errors
  void _safeNotifyListeners() {
    if (!_disposed) {
      // Use Future.microtask to defer the notification until after the current build
      Future.microtask(() {
        if (!_disposed) {
          notifyListeners();
        }
      });
    }
  }

  /// Fetch subscriptions from backend and update state
  Future<void> fetchAndSetSubscriptionsFromBackend() async {
    if (_disposed) return;

    // Don't call notifyListeners() here to avoid setState during build errors
    // Only update the loading state internally
    isLoading = true;
    errorMessage = null;

    try {
      final apiService = LibraryApiService();
      final response = await apiService.getSubscribedPodcastIds();

      if (_disposed) return;

      if (response['success'] == true) {
        final List data = response['data'] ?? [];
        final ids = data.map((e) => e['podcast_id'].toString()).toSet();
        setSubscriptions(ids);
        errorMessage = null;
      } else {
        errorMessage = 'Failed to load subscriptions.';
      }
    } catch (e) {
      if (_disposed) return;
      debugPrint('Error fetching subscriptions: $e');
      errorMessage = 'Failed to load subscriptions.';
    } finally {
      if (_disposed) return;
      isLoading = false;
      // Use safe notification method
      _safeNotifyListeners();
    }
  }
}
