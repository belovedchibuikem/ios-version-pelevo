import 'package:flutter/material.dart';
import 'core/services/permission_service.dart';

/// Test screen for permission functionality
class TestPermissionScreen extends StatefulWidget {
  const TestPermissionScreen({super.key});

  @override
  State<TestPermissionScreen> createState() => _TestPermissionScreenState();
}

class _TestPermissionScreenState extends State<TestPermissionScreen> {
  Map<String, String> _permissionStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await PermissionService.getPermissionStatus();
      setState(() {
        _permissionStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _permissionStatus = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _requestStoragePermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await PermissionService.ensureStoragePermission(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted
              ? 'Storage permission granted!'
              : 'Storage permission denied'),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );

      // Refresh status
      await _checkPermissionStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugPermissionFlow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PermissionService.debugPermissionFlow(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Debug permission flow completed. Check console for details.'),
          backgroundColor: Colors.blue,
        ),
      );

      // Refresh status
      await _checkPermissionStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage Permission Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              const Text(
                'Current Permission Status:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _permissionStatus.entries.map((entry) {
                    final isGranted =
                        entry.value.toLowerCase().contains('granted');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isGranted ? Icons.check_circle : Icons.cancel,
                            color: isGranted ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('${entry.key}: ${entry.value}'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestStoragePermission,
                  child: const Text('Request Storage Permission'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _checkPermissionStatus,
                  child: const Text('Refresh Status'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _debugPermissionFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Debug Permission Flow'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Instructions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Click "Request Storage Permission" to test permission flow\n'
                '2. Check the status above to see current permissions\n'
                '3. If permission is denied, you can go to app settings\n'
                '4. This permission is required for downloading episodes',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
