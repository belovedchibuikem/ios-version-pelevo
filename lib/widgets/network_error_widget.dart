import 'package:flutter/material.dart';
import '../core/utils/network_error_handler.dart';

/// Professional network error widget with retry functionality
class NetworkErrorWidget extends StatelessWidget {
  final NetworkError error;
  final VoidCallback? onRetry;
  final String? title;
  final String? subtitle;
  final bool showRetryButton;
  final bool compact;

  const NetworkErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.subtitle,
    this.showRetryButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactError(context);
    }

    return _buildFullError(context);
  }

  Widget _buildCompactError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: error.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            error.icon,
            color: error.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.userMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: error.color,
                  ),
            ),
          ),
          if (showRetryButton && error.isRetryable && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildFullError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: error.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                error.icon,
                size: 48,
                color: error.color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? _getDefaultTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: error.color,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle ?? error.userMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && error.isRetryable && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: error.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
            if (error.statusCode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: error.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Error ${error.statusCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: error.color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDefaultTitle() {
    switch (error.type) {
      case NetworkErrorType.timeout:
        return 'Request Timeout';
      case NetworkErrorType.noConnection:
        return 'No Internet Connection';
      case NetworkErrorType.serverError:
        return 'Server Error';
      case NetworkErrorType.unauthorized:
        return 'Authentication Required';
      case NetworkErrorType.forbidden:
        return 'Access Denied';
      case NetworkErrorType.notFound:
        return 'Not Found';
      case NetworkErrorType.badRequest:
        return 'Invalid Request';
      case NetworkErrorType.unknown:
        return 'Something Went Wrong';
    }
  }
}

/// Network error dialog for modal presentations
class NetworkErrorDialog extends StatelessWidget {
  final NetworkError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const NetworkErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: error.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              error.icon,
              size: 32,
              color: error.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getDefaultTitle(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: error.color,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.userMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
        if (error.isRetryable && onRetry != null)
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: error.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
      ],
    );
  }

  String _getDefaultTitle() {
    switch (error.type) {
      case NetworkErrorType.timeout:
        return 'Request Timeout';
      case NetworkErrorType.noConnection:
        return 'No Internet Connection';
      case NetworkErrorType.serverError:
        return 'Server Error';
      case NetworkErrorType.unauthorized:
        return 'Authentication Required';
      case NetworkErrorType.forbidden:
        return 'Access Denied';
      case NetworkErrorType.notFound:
        return 'Not Found';
      case NetworkErrorType.badRequest:
        return 'Invalid Request';
      case NetworkErrorType.unknown:
        return 'Something Went Wrong';
    }
  }
}
