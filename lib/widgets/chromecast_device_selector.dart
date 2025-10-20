import 'package:flutter/material.dart';
import '../services/chromecast_service.dart';

class ChromecastDeviceSelector extends StatefulWidget {
  final Function(CastDevice) onDeviceSelected;
  final VoidCallback? onCancel;

  const ChromecastDeviceSelector({
    super.key,
    required this.onDeviceSelected,
    this.onCancel,
  });

  @override
  State<ChromecastDeviceSelector> createState() =>
      _ChromecastDeviceSelectorState();
}

class _ChromecastDeviceSelectorState extends State<ChromecastDeviceSelector> {
  final ChromecastService _castService = ChromecastService();
  List<CastDevice> _devices = [];
  bool _isDiscovering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAndDiscover();
  }

  Future<void> _initializeAndDiscover() async {
    setState(() {
      _isDiscovering = true;
      _error = null;
    });

    try {
      // Initialize Chromecast service
      final initialized = await _castService.initialize();
      if (!initialized) {
        setState(() {
          _error = 'Failed to initialize Chromecast service';
          _isDiscovering = false;
        });
        return;
      }

      // Discover devices
      final devices = await _castService.discoverDevices();
      setState(() {
        _devices = devices;
        _isDiscovering = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error discovering devices: $e';
        _isDiscovering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cast, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Cast Device',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCancel?.call();
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isDiscovering ? null : _initializeAndDiscover,
                      icon: _isDiscovering
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label:
                          Text(_isDiscovering ? 'Discovering...' : 'Refresh'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCancel?.call();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isDiscovering) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Discovering Cast devices...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeAndDiscover,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cast_connected,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Cast devices found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Make sure your Chromecast device is on the same network',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _buildDeviceTile(device);
      },
    );
  }

  Widget _buildDeviceTile(CastDevice device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              device.isOnline ? Theme.of(context).primaryColor : Colors.grey,
          child: Icon(
            device.isOnline ? Icons.cast : Icons.cast_connected,
            color: Colors.white,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${device.type} • ${device.isOnline ? 'Online' : 'Offline'}',
          style: TextStyle(
            color: device.isOnline ? Colors.green[600] : Colors.red[600],
          ),
        ),
        trailing: device.isOnline
            ? IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDeviceSelected(device);
                },
                icon: const Icon(Icons.arrow_forward_ios),
              )
            : const Icon(Icons.offline_bolt, color: Colors.grey),
        onTap: device.isOnline
            ? () {
                Navigator.pop(context);
                widget.onDeviceSelected(device);
              }
            : null,
      ),
    );
  }
}



