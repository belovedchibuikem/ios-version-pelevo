import 'package:flutter/foundation.dart';
import '../services/memory_manager.dart';

/// Debug information utility for system compatibility
class DebugInfo {
  /// Get comprehensive system information
  static Future<Map<String, dynamic>> getSystemInfo() async {
    final memoryInfo = await MemoryManager.getMemoryInfo();

    return {
      ...memoryInfo,
      'isDebugMode': kDebugMode,
      'isProfileMode': kProfileMode,
      'isReleaseMode': kReleaseMode,
      'flutterVersion': '3.6.0', // Update this based on your Flutter version
      'dartVersion': '3.6.0', // Update this based on your Dart version
    };
  }

  /// Log comprehensive system information
  static Future<void> logSystemInfo() async {
    final info = await getSystemInfo();
    debugPrint('🔍 System Info: $info');
  }

  /// Get Google Play 16KB page size compliance status
  static Future<Map<String, dynamic>> get16KBPageCompliance() async {
    final memoryInfo = await MemoryManager.getMemoryInfo();
    final pageSize = memoryInfo['pageSize'] as int;
    final is16KBSupported = memoryInfo['is16KBSupported'] as bool;

    return {
      'isCompliant': is16KBSupported,
      'pageSize': pageSize,
      'pageSizeKB': (pageSize / 1024).round(),
      'complianceStatus': is16KBSupported ? 'COMPLIANT' : 'NON_COMPLIANT',
      'deadline': '2025-11-01', // Google Play deadline
      'extendedDeadline': '2026-05-31', // Extended deadline
      'recommendation': is16KBSupported
          ? 'App is ready for Google Play 16KB page size requirements'
          : 'App needs updates to support 16KB page size requirements',
    };
  }

  /// Log 16KB page size compliance status
  static Future<void> log16KBPageCompliance() async {
    final compliance = await get16KBPageCompliance();
    debugPrint('📋 16KB Page Size Compliance: $compliance');
  }

  /// Check if app is ready for Google Play requirements
  static Future<bool> isReadyForGooglePlayRequirements() async {
    final compliance = await get16KBPageCompliance();
    return compliance['isCompliant'] as bool;
  }
}
