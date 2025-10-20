import 'package:flutter/material.dart';

/// Example widget demonstrating proper async setState handling
class MountedCheckTest extends StatefulWidget {
  const MountedCheckTest({super.key});

  @override
  State<MountedCheckTest> createState() => _MountedCheckTestState();
}

class _MountedCheckTestState extends State<MountedCheckTest> {
  bool _isLoading = false;
  String _data = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate async operation
    await Future.delayed(const Duration(seconds: 2));

    // ✅ CORRECT: Check if widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _isLoading = false;
        _data = 'Data loaded successfully!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mounted Check Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(_data.isEmpty ? 'No data' : _data),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reload Data'),
            ),
          ],
        ),
      ),
    );
  }
}
