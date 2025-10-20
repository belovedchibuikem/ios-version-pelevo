import 'package:flutter/material.dart';
import '../core/utils/network_error_handler.dart';
import 'network_error_widget.dart';

/// Example widget showing how to use network error handling
class NetworkErrorExample extends StatefulWidget {
  const NetworkErrorExample({super.key});

  @override
  State<NetworkErrorExample> createState() => _NetworkErrorExampleState();
}

class _NetworkErrorExampleState extends State<NetworkErrorExample> {
  bool _isLoading = false;
  NetworkError? _error;
  String? _data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Error Handling Example'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return NetworkErrorWidget(
        error: _error!,
        onRetry: _loadData,
        title: 'Failed to Load Data',
        subtitle: 'We encountered an issue while loading your data.',
      );
    }

    if (_data != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Data Loaded Successfully!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_data!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reload Data'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_download,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Load Data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Tap the button below to load data'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Load Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate API call that might fail
      await _simulateApiCall();

      setState(() {
        _data = 'Data loaded at ${DateTime.now()}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is NetworkError
            ? e
            : NetworkError(
                type: NetworkErrorType.unknown,
                message: e.toString(),
                userMessage: 'An unexpected error occurred. Please try again.',
                isRetryable: true,
                color: Colors.grey,
                icon: Icons.help_outline,
              );
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateApiCall() async {
    // Simulate different types of errors
    await Future.delayed(const Duration(seconds: 2));

    // Randomly throw different types of errors for demonstration
    final random = DateTime.now().millisecond % 4;

    switch (random) {
      case 0:
        // Simulate timeout error
        throw NetworkError(
          type: NetworkErrorType.timeout,
          message: 'Request timeout after 30 seconds',
          userMessage:
              'Request timed out. Please check your connection and try again.',
          isRetryable: true,
          color: Colors.orange,
          icon: Icons.timer_off,
        );
      case 1:
        // Simulate no connection error
        throw NetworkError(
          type: NetworkErrorType.noConnection,
          message: 'No internet connection',
          userMessage:
              'No internet connection. Please check your network settings.',
          isRetryable: true,
          color: Colors.orange,
          icon: Icons.wifi_off,
        );
      case 2:
        // Simulate server error
        throw NetworkError(
          type: NetworkErrorType.serverError,
          message: 'Internal server error',
          userMessage:
              'Server is temporarily unavailable. Please try again later.',
          statusCode: 500,
          isRetryable: true,
          color: Colors.red,
          icon: Icons.error_outline,
        );
      case 3:
        // Success case
        return;
    }
  }
}

/// Example of showing network error in a dialog
class NetworkErrorDialogExample extends StatelessWidget {
  const NetworkErrorDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Error Dialog Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showTimeoutError(context),
              child: const Text('Show Timeout Error'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showConnectionError(context),
              child: const Text('Show Connection Error'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showServerError(context),
              child: const Text('Show Server Error'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeoutError(BuildContext context) {
    final error = NetworkError(
      type: NetworkErrorType.timeout,
      message: 'Request timeout after 30 seconds',
      userMessage:
          'Request timed out. Please check your connection and try again.',
      isRetryable: true,
      color: Colors.orange,
      icon: Icons.timer_off,
    );

    showDialog(
      context: context,
      builder: (context) => NetworkErrorDialog(
        error: error,
        onRetry: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retrying...')),
          );
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _showConnectionError(BuildContext context) {
    final error = NetworkError(
      type: NetworkErrorType.noConnection,
      message: 'No internet connection',
      userMessage:
          'No internet connection. Please check your network settings.',
      isRetryable: true,
      color: Colors.orange,
      icon: Icons.wifi_off,
    );

    showDialog(
      context: context,
      builder: (context) => NetworkErrorDialog(
        error: error,
        onRetry: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retrying...')),
          );
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _showServerError(BuildContext context) {
    final error = NetworkError(
      type: NetworkErrorType.serverError,
      message: 'Internal server error',
      userMessage: 'Server is temporarily unavailable. Please try again later.',
      statusCode: 500,
      isRetryable: true,
      color: Colors.red,
      icon: Icons.error_outline,
    );

    showDialog(
      context: context,
      builder: (context) => NetworkErrorDialog(
        error: error,
        onRetry: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retrying...')),
          );
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}
