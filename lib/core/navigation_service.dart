// lib/core/navigation_service.dart
import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../core/services/unified_auth_service.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Callback function to switch tabs in the main navigation
  static Function(int)? _onTabSelectedCallback;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final List<String> _navigationStack = [];
  String? _initialRoute;
  String? _currentSourceRoute; // Track the source route for earning validation
  final UnifiedAuthService _auth = UnifiedAuthService();

  /// Set the initial route when the app starts
  void setInitialRoute(String route) {
    _initialRoute = route;
    if (!_navigationStack.contains(route)) {
      _navigationStack.add(route);
    }
  }

  /// Track navigation when pushing a new route
  void trackNavigation(String route) {
    if (_navigationStack.isEmpty && _initialRoute != null) {
      _navigationStack.add(_initialRoute!);
    }
    if (!_navigationStack.contains(route)) {
      _navigationStack.add(route);
    }
    _currentSourceRoute = route;
  }

  /// Navigate to a specific route and track it
  Future<T?> navigateTo<T extends Object?>(String routeName,
      {Object? arguments}) {
    // Guest restriction: allow only home-screen
    _auth.isGuestMode().then((isGuest) {
      if (isGuest && routeName != AppRoutes.homeScreen &&
          routeName != AppRoutes.podcastPlayer &&
          routeName != AppRoutes.podcastDetailScreen &&
          routeName != AppRoutes.categoryPodcasts &&
          routeName != AppRoutes.trendingPodcastsScreen &&
          routeName != AppRoutes.recommendationsScreen &&
          routeName != AppRoutes.categoriesListScreen) {
        navigatorKey.currentState?.pushReplacementNamed(AppRoutes.authenticationScreen);
        return null;
      }
    });
    if (routeName.isEmpty) {
      debugPrint('NavigationService: Route name is empty');
      return Future.value(null);
    }

    trackNavigation(routeName);
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
          'NavigationService: Navigator is null, cannot navigate to $routeName');
      return Future.value(null);
    }

    try {
      return navigator.pushNamed<T>(routeName, arguments: arguments);
    } catch (e) {
      debugPrint('NavigationService: Error navigating to $routeName: $e');
      return Future.value(null);
    }
  }

  /// Navigate to podcast player with source tracking for earning validation
  Future<T?> navigateToPlayerFromSource<T extends Object?>(String routeName,
      {Object? arguments, String? sourceRoute}) {
    final Map<String, dynamic> playerArguments = {
      'podcast': arguments,
      'sourceRoute': sourceRoute ?? _currentSourceRoute,
      'isEarningEnabled': isEarningEnabled(sourceRoute ?? _currentSourceRoute),
    };
    trackNavigation(routeName);
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
          'NavigationService: Navigator is null, cannot navigate to $routeName');
      return Future.value(null);
    }
    return navigator.pushNamed<T>(routeName, arguments: playerArguments);
  }

  /// Navigate and replace current route
  Future<T?> navigateAndReplace<T extends Object?, TO extends Object?>(
      String routeName,
      {Object? arguments}) {
    _auth.isGuestMode().then((isGuest) {
      if (isGuest && routeName != AppRoutes.homeScreen &&
          routeName != AppRoutes.podcastPlayer &&
          routeName != AppRoutes.podcastDetailScreen &&
          routeName != AppRoutes.categoryPodcasts &&
          routeName != AppRoutes.trendingPodcastsScreen &&
          routeName != AppRoutes.recommendationsScreen &&
          routeName != AppRoutes.categoriesListScreen) {
        navigatorKey.currentState?.pushReplacementNamed(AppRoutes.authenticationScreen);
        return null;
      }
    });
    trackNavigation(routeName);
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
          'NavigationService: Navigator is null, cannot navigate to $routeName');
      return Future.value(null);
    }
    return navigator.pushReplacementNamed<T, TO>(routeName,
        arguments: arguments);
  }

  /// Navigate and clear all previous routes
  Future<T?> navigateAndClearStack<T extends Object?>(String routeName,
      {Object? arguments}) {
    _navigationStack.clear();
    trackNavigation(routeName);
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
          'NavigationService: Navigator is null, cannot navigate to $routeName');
      return Future.value(null);
    }
    return navigator.pushNamedAndRemoveUntil<T>(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  /// Go back to the previous screen
  void goBack<T extends Object?>([T? result]) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('NavigationService: Navigator is null, cannot go back');
      return;
    }
    if (navigator.canPop()) {
      if (_navigationStack.isNotEmpty) {
        _navigationStack.removeLast();
      }
      navigator.pop<T>(result);
    }
  }

  /// Go back to the starting point (first screen in navigation stack)
  void goBackToStart() {
    if (_navigationStack.isNotEmpty) {
      final startRoute = _navigationStack.first;
      navigateAndClearStack(startRoute);
    }
  }

  /// Get the starting route
  String? getStartRoute() {
    return _navigationStack.isNotEmpty ? _navigationStack.first : _initialRoute;
  }

  /// Get current navigation stack
  List<String> getNavigationStack() {
    return List.unmodifiable(_navigationStack);
  }

  /// Check if we can go back to start
  bool canGoBackToStart() {
    return _navigationStack.length > 1;
  }

  /// Clear navigation history
  void clearNavigationHistory() {
    _navigationStack.clear();
  }

  /// Remove specific route from stack
  void removeFromStack(String route) {
    _navigationStack.remove(route);
  }

  /// Get current source route for earning validation
  String? getCurrentSourceRoute() {
    return _currentSourceRoute;
  }

  /// Check if earning features should be enabled based on source route
  bool isEarningEnabled(String? sourceRoute) {
    if (sourceRoute == null) return false;

    // Check for exact route match
    return sourceRoute == AppRoutes.earnScreen;
  }

  /// Validate if current context allows earning features
  bool validateEarningContext() {
    final currentSource = getCurrentSourceRoute();
    return isEarningEnabled(currentSource);
  }

  /// Reset earning validation state
  void resetEarningValidation() {
    _currentSourceRoute = null;
  }

  /// Register the tab selection callback for the main navigation
  static void registerTabSelectionCallback(Function(int) callback) {
    _onTabSelectedCallback = callback;
    debugPrint('NavigationService: Tab selection callback registered');
  }

  /// Unregister the tab selection callback
  static void unregisterTabSelectionCallback() {
    _onTabSelectedCallback = null;
    debugPrint('NavigationService: Tab selection callback unregistered');
  }

  /// Navigate to home tab within existing navigation (preserves data)
  Future<void> navigateToHomeTab() {
    // If we have a registered callback, use it to switch tabs
    if (_onTabSelectedCallback != null) {
      debugPrint(
          'NavigationService: Switching to home tab via registered callback');
      _onTabSelectedCallback!(0);
      return Future.value();
    }

    // Fallback to regular navigation
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
          'NavigationService: Navigator is null, cannot navigate to home tab');
      return Future.value();
    }

    // Check if we're already in the main navigation
    final currentRoute = ModalRoute.of(navigator.context);
    if (currentRoute?.settings.name == AppRoutes.homeScreen ||
        currentRoute?.settings.name == AppRoutes.earnScreen ||
        currentRoute?.settings.name == AppRoutes.libraryScreen ||
        currentRoute?.settings.name == AppRoutes.walletScreen ||
        currentRoute?.settings.name == AppRoutes.profileScreen) {
      // We're already in main navigation, just switch to home tab
      debugPrint(
          'NavigationService: Already in main navigation, switching to home tab');
      // The EnhancedMainNavigation will handle tab switching automatically
      return Future.value();
    } else {
      // We're not in main navigation, navigate to home screen
      debugPrint(
          'NavigationService: Not in main navigation, navigating to home screen');
      return navigator.pushReplacementNamed(AppRoutes.homeScreen);
    }
  }

  /// Navigate to specific tab within existing navigation (preserves data)
  Future<void> navigateToTab(int tabIndex) {
    _auth.isGuestMode().then((isGuest) {
      if (isGuest && tabIndex != 0) {
        navigatorKey.currentState?.pushReplacementNamed(AppRoutes.authenticationScreen);
        return;
      }
    });
    // If we have a registered callback, use it to switch tabs
    if (_onTabSelectedCallback != null) {
      debugPrint(
          'NavigationService: Switching to tab $tabIndex via registered callback');
      _onTabSelectedCallback!(tabIndex);
      return Future.value();
    }

    // Fallback to regular navigation
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint(
          'NavigationService: Navigator is null, cannot navigate to tab $tabIndex');
      return Future.value();
    }

    // Check if we're already in the main navigation
    final currentRoute = ModalRoute.of(navigator.context);
    if (currentRoute?.settings.name == AppRoutes.homeScreen ||
        currentRoute?.settings.name == AppRoutes.earnScreen ||
        currentRoute?.settings.name == AppRoutes.libraryScreen ||
        currentRoute?.settings.name == AppRoutes.walletScreen ||
        currentRoute?.settings.name == AppRoutes.profileScreen) {
      // We're already in main navigation, just switch to the specified tab
      debugPrint(
          'NavigationService: Already in main navigation, switching to tab $tabIndex');
      // The EnhancedMainNavigation will handle tab switching automatically
      return Future.value();
    } else {
      // We're not in main navigation, navigate to the appropriate screen
      String targetRoute;
      switch (tabIndex) {
        case 0:
          targetRoute = AppRoutes.homeScreen;
          break;
        case 1:
          targetRoute = AppRoutes.earnScreen;
          break;
        case 2:
          targetRoute = AppRoutes.libraryScreen;
          break;
        case 3:
          targetRoute = AppRoutes.walletScreen;
          break;
        case 4:
          targetRoute = AppRoutes.profileScreen;
          break;
        default:
          targetRoute = AppRoutes.homeScreen;
      }
      debugPrint(
          'NavigationService: Not in main navigation, navigating to $targetRoute');
      return navigator.pushReplacementNamed(targetRoute);
    }
  }
}
