import 'package:flutter/material.dart';
import '../../core/utils/safe_area_utils.dart';

class WithdrawalSetupScreen extends StatelessWidget {
  const WithdrawalSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeAreaUtils.wrapWithSafeArea(
      const Scaffold(
        body: Center(child: Text('Withdrawal Setup Screen')),
      ),
    );
  }
}
