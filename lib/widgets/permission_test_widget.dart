import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Test widget to verify storage permissions
class PermissionTestWidget extends StatefulWidget {
  const PermissionTestWidget({super.key});

  @override
  State<PermissionTestWidget> createState() => _PermissionTestWidgetState();
}

class _PermissionTestWidgetState extends State<PermissionTestWidget> {
  String _status = 'Checking permissions...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking permissions...';
    });

    try {
      // Check storage permission
      final storageStatus = await Permission.storage.status;
      final externalStorageStatus =
          await Permission.manageExternalStorage.status;

      // Check if we can write to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final testDir = Directory('${appDir.path}/test');
      final testFile = File('${testDir.path}/test.txt');

      bool canWrite = false;
      try {
        if (!await testDir.exists()) {
          await testDir.create(recursive: true);
        }
        await testFile.writeAsString('test');
        await testFile.delete();
        canWrite = true;
      } catch (e) {
        canWrite = false;
      }

      setState(() {
        _status = '''
Permission Status:
- Storage Permission: $storageStatus
- External Storage Permission: $externalStorageStatus
- Can Write to App Directory: $canWrite
- App Directory: ${appDir.path}
        ''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking permissions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting permissions...';
    });

    try {
      final storageStatus = await Permission.storage.request();
      final externalStorageStatus =
          await Permission.manageExternalStorage.request();

      setState(() {
        _status = '''
Permission Request Results:
- Storage Permission: $storageStatus
- External Storage Permission: $externalStorageStatus
        ''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error requesting permissions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permission Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkPermissions,
              child: const Text('Check Permissions'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _requestPermissions,
              child: const Text('Request Permissions'),
            ),
          ],
        ),
      ),
    );
  }
}
