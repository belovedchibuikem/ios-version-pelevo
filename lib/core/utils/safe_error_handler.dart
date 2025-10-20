import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SafeErrorHandler {
  static final SafeErrorHandler _instance = SafeErrorHandler._internal();
  factory SafeErrorHandler() => _instance;
  SafeErrorHandler._internal();

  // Safe way to show SnackBar without crashing
  static void showSafeSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    try {
      // Check if context is mounted and has a Scaffold
      if (context.mounted && Scaffold.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(color: textColor),
            ),
            backgroundColor: backgroundColor,
            duration: duration,
            action: actionLabel != null && onActionPressed != null
                ? SnackBarAction(
                    label: actionLabel,
                    textColor: textColor,
                    onPressed: onActionPressed,
                  )
                : null,
          ),
        );
      } else {
        debugPrint(
            '⚠️ Cannot show SnackBar: Context not mounted or no Scaffold');
      }
    } catch (e) {
      debugPrint('❌ Error showing SnackBar: $e');
      // Fallback: just log the error
    }
  }

  // Safe way to show dialog without crashing
  static Future<T?> showSafeDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) async {
    try {
      if (context.mounted) {
        return await showDialog<T>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (context) => child,
        );
      }
    } catch (e) {
      debugPrint('❌ Error showing dialog: $e');
    }
    return null;
  }

  // Safe way to navigate without crashing
  static void safeNavigate(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    try {
      if (context.mounted) {
        Navigator.of(context).pushNamed(routeName, arguments: arguments);
      }
    } catch (e) {
      debugPrint('❌ Error navigating to $routeName: $e');
    }
  }

  // Safe way to pop without crashing
  static void safePop(BuildContext context, [Object? result]) {
    try {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      debugPrint('❌ Error popping navigation: $e');
    }
  }

  // Safe way to set state without crashing
  static void safeSetState(State state, VoidCallback fn) {
    try {
      if (state.mounted) {
        state.setState(fn);
      }
    } catch (e) {
      debugPrint('❌ Error setting state: $e');
    }
  }

  // Safe way to handle async operations
  static Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    String? operationName,
    T? fallbackValue,
    bool logErrors = true,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (logErrors) {
        debugPrint('❌ Error in ${operationName ?? 'async operation'}: $e');
      }
      return fallbackValue;
    }
  }

  // Safe way to handle errors in callbacks
  static void safeCallback(VoidCallback callback, {String? callbackName}) {
    try {
      callback();
    } catch (e) {
      debugPrint('❌ Error in ${callbackName ?? 'callback'}: $e');
    }
  }

  // Safe way to handle errors in async callbacks
  static Future<void> safeAsyncCallback(
    Future<void> Function() callback, {
    String? callbackName,
  }) async {
    try {
      await callback();
    } catch (e) {
      debugPrint('❌ Error in ${callbackName ?? 'async callback'}: $e');
    }
  }

  // Check if context is safe to use
  static bool isContextSafe(BuildContext context) {
    try {
      return context.mounted && Scaffold.of(context).mounted;
    } catch (e) {
      return false;
    }
  }

  // Safe way to get MediaQuery
  static MediaQueryData? getSafeMediaQuery(BuildContext context) {
    try {
      if (context.mounted) {
        return MediaQuery.of(context);
      }
    } catch (e) {
      debugPrint('❌ Error getting MediaQuery: $e');
    }
    return null;
  }

  // Safe way to get Theme
  static ThemeData? getSafeTheme(BuildContext context) {
    try {
      if (context.mounted) {
        return Theme.of(context);
      }
    } catch (e) {
      debugPrint('❌ Error getting Theme: $e');
    }
    return null;
  }
}

