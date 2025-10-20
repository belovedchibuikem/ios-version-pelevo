import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'library_api_service.dart';
import '../core/config/api_config.dart';
import '../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import 'subscriber_count_service.dart';

/// Standardized handler for subscribe/unsubscribe actions.
///
/// [context] - BuildContext for showing snackbars
/// [podcastId] - The podcast's unique ID (string)
/// [isCurrentlySubscribed] - Current subscription state
/// [onStateChanged] - Callback to update UI state (pass true for subscribed, false for unsubscribed)
Future<void> handleSubscribeAction({
  required BuildContext context,
  required String podcastId,
  required bool isCurrentlySubscribed,
  required Function(bool) onStateChanged,
}) async {
  final apiService = LibraryApiService();
  final subscriptionProvider =
      Provider.of<SubscriptionProvider>(context, listen: false);
  final subscriberCountService = SubscriberCountService();

  try {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isCurrentlySubscribed ? 'Unsubscribing...' : 'Subscribing...'),
        duration: const Duration(seconds: 1),
      ),
    );

    if (isCurrentlySubscribed) {
      await apiService.unsubscribeFromPodcast(
        podcastId,
        context: context,
        onRetry: () => handleSubscribeAction(
          context: context,
          podcastId: podcastId,
          isCurrentlySubscribed: isCurrentlySubscribed,
          onStateChanged: onStateChanged,
        ),
      );
      subscriptionProvider.removeSubscription(podcastId);

      // Update subscriber count locally (decrease by 1)
      final currentCount = subscriberCountService.getSubscriberCount(podcastId);
      subscriberCountService.updateSubscriberCount(podcastId, currentCount - 1);

      onStateChanged(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unsubscribed from podcast'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      await apiService.subscribeToPodcast(
        podcastId,
        context: context,
        onRetry: () => handleSubscribeAction(
          context: context,
          podcastId: podcastId,
          isCurrentlySubscribed: isCurrentlySubscribed,
          onStateChanged: onStateChanged,
        ),
      );
      subscriptionProvider.addSubscription(podcastId);

      // Update subscriber count locally (increase by 1)
      final currentCount = subscriberCountService.getSubscriberCount(podcastId);
      subscriberCountService.updateSubscriberCount(podcastId, currentCount + 1);

      onStateChanged(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscribed to podcast'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    String errorMsg = 'Failed to update subscription.';
    if (e is DioException && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        errorMsg = data['message'].toString();
      } else if (data is String) {
        errorMsg = data;
      } else {
        errorMsg = data.toString();
      }
    } else if (e is Exception) {
      errorMsg = e.toString();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<Set<String>> fetchSubscribedPodcastIdsFromBackend() async {
  try {
    final apiService = LibraryApiService();
    final response = await apiService.getSubscribedPodcastIds();

    if (response['success'] == true && response['data'] != null) {
      Set<String> ids = {};
      if (response['data'] is List) {
        ids = (response['data'] as List)
            .map((e) => e['podcast_id'].toString())
            .toSet();
      }
      return ids;
    }
    throw Exception('Failed to fetch subscription IDs');
  } catch (e) {
    debugPrint('Error fetching subscription IDs: $e');
    throw Exception('Failed to fetch subscription IDs: $e');
  }
}
