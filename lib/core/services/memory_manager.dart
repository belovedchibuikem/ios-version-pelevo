import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Memory manager for handling 16KB page size compatibility
class MemoryManager {
  static const MethodChannel _channel =
      MethodChannel('com.pelevo_podcast.app/memory');

  /// Get the system page size
  static Future<int> getPageSize() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS: use default 4KB and avoid MethodChannel to prevent MissingPluginException
        return 4096;
      }
      final int pageSize = await _channel.invokeMethod('getPageSize');
      return pageSize;
    } catch (e) {
      debugPrint('⚠️ Error getting page size: $e');
      return 4096; // Default to 4KB
    }
  }

  /// Optimize memory for 16KB page size
  static Future<bool> optimizeMemory() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return false;
      }
      final bool success = await _channel.invokeMethod('optimizeMemory');
      return success;
    } catch (e) {
      debugPrint('⚠️ Error optimizing memory: $e');
      return false;
    }
  }

  /// Check if 16KB page size is supported
  static Future<bool> is16KBPageSizeSupported() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return false;
      }
      final bool supported =
          await _channel.invokeMethod('is16KBPageSizeSupported');
      return supported;
    } catch (e) {
      debugPrint('⚠️ Error checking 16KB page support: $e');
      return false;
    }
  }

  /// Get memory information for debugging
  static Future<Map<String, dynamic>> getMemoryInfo() async {
    try {
      final pageSize = await getPageSize();
      final is16KBSupported = await is16KBPageSizeSupported();

      return {
        'pageSize': pageSize,
        'is16KBSupported': is16KBSupported,
        'pageSizeKB': (pageSize / 1024).round(),
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('⚠️ Error getting memory info: $e');
      return {
        'pageSize': 4096,
        'is16KBSupported': false,
        'pageSizeKB': 4,
        'platform': defaultTargetPlatform.name,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Log memory information for debugging
  static Future<void> logMemoryInfo() async {
    final info = await getMemoryInfo();
    debugPrint('🔍 Memory Info: $info');
  }

  /// Initialize memory optimization on app start
  static Future<void> initializeMemoryOptimization() async {
    try {
      await logMemoryInfo();

      final is16KBSupported = await is16KBPageSizeSupported();
      if (is16KBSupported) {
        debugPrint('✅ 16KB page size is supported - optimizing memory');
        await optimizeMemory();
      } else {
        debugPrint('📱 Using 4KB page size - standard memory management');
      }
    } catch (e) {
      debugPrint('⚠️ Error initializing memory optimization: $e');
    }
  }
}
