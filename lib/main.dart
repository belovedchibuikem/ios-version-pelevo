import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async'; // Add this import for TimeoutException
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'core/routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'core/services/in_app_purchase_service.dart';
import 'core/services/service_manager.dart';
import 'core/services/persistent_state_manager.dart';
import 'core/services/app_initialization_service.dart';
import 'core/navigation_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme_service.dart';
import 'providers/auth_provider.dart';
import 'providers/package_subscription_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/history_provider.dart';
import 'providers/podcast_player_provider.dart';
import 'providers/sync_status_provider.dart';
import 'providers/episode_progress_provider.dart';
import 'services/episode_progress_service.dart';
import 'core/error_handling/global_error_handler.dart';
import 'providers/home_provider.dart';
import 'providers/library_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/playlist_provider.dart';
import 'widgets/floating_mini_player_overlay.dart';
import 'core/services/memory_manager.dart';
import 'core/utils/debug_info.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://b1b17df59e8aefc70a2f801945b78d04@o4510040721457152.ingest.us.sentry.io/4510040723881984';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
    },
    appRunner: () => _runApp(),
  );
}

Future<void> _runApp() async {
  // Wrap everything in error handling to prevent crashes
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize global error handling
    GlobalErrorHandler.initialize();

    // Note: Mini-player position cache has been removed - always auto-detects
    debugPrint(
        '🎯 Mini-player positioning: Always auto-detects (cache removed)');

    // Log platform and debug mode for troubleshooting
    debugPrint('📱 Platform: ${Platform.operatingSystem}');
    debugPrint('🔧 Debug mode: $kDebugMode');
    debugPrint('🏗️ Release mode: $kReleaseMode');

    // Initialize memory optimization for 16KB page size support
    // Defer until after first frame to avoid blocking startup/splash
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await MemoryManager.initializeMemoryOptimization();
        await DebugInfo.log16KBPageCompliance();
      } catch (e) {
        debugPrint('⚠️ Warning: Memory optimization initialization failed: $e');
        debugPrint('App will continue without memory optimization');
      }
    });

    // Initialize Hive for local storage with retry logic
    // Do not block UI; start then proceed to runApp immediately.
    // Errors are handled internally and won't crash startup.
    unawaited(_initializeHiveWithRetry());

    // For in_app_purchase 3.x+, pending purchases are enabled by default on Android.
    // For iOS, you need to enable it explicitly.
    // await InAppPurchase.instance.enablePendingPurchases();

    runApp(SentryWidget(child: const MyApp()));
  } catch (e, stackTrace) {
    // If main function fails, still try to run the app
    debugPrint('🚨 Critical error in main function: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('🔄 Attempting to run app anyway...');

    try {
      // Force run the app even if initialization failed
      runApp(SentryWidget(child: const MyApp()));
    } catch (fallbackError) {
      debugPrint('🚨 Even fallback app launch failed: $fallbackError');
      // Last resort - show a simple error screen
      runApp(SentryWidget(
          child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('App initialization failed'),
                SizedBox(height: 8),
                Text('Please restart the app'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart
                    _runApp();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      )));
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NavigationService _navigationService = NavigationService();
  final ServiceManager _serviceManager = ServiceManager();
  final PersistentStateManager _persistentStateManager =
      PersistentStateManager();
  final AppUpdateService _appUpdateService = AppUpdateService();
  final NotificationService _notificationService = NotificationService();
  bool _servicesInitialized = false;
  bool _stateRestored = false;
  bool _hasError = false;
  String? _errorMessage;
  int _errorCount = 0;
  static const int _maxErrors = 3;

  // Deep link handling

  /// Handle critical errors and attempt recovery
  void _handleCriticalError(dynamic error, StackTrace? stackTrace,
      {String? context}) {
    _errorCount++;
    debugPrint('🚨 Critical error #$_errorCount: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }

    if (_errorCount >= _maxErrors) {
      debugPrint('🚨 Max error count reached, forcing app continuation');
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _servicesInitialized = true; // Force continuation
      });
      return;
    }

    // Set error state
    setState(() {
      _hasError = true;
      _errorMessage = '${context ?? 'Error'}: $error';
    });

    // Attempt automatic recovery after a delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted && _hasError) {
        debugPrint('🔄 Attempting automatic error recovery...');
        _attemptErrorRecovery();
      }
    });
  }

  /// Attempt to recover from errors
  void _attemptErrorRecovery() {
    try {
      debugPrint('🔄 Error recovery attempt...');

      // Clear error state
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });

      // Try to reinitialize services if they failed
      if (!_servicesInitialized) {
        _checkAndInitializeApp();
      }

      // Reset error count on successful recovery
      _errorCount = 0;

      debugPrint('✅ Error recovery completed');
    } catch (e) {
      debugPrint('❌ Error recovery failed: $e');
      // Continue anyway
    }
  }

  /// Reset error state and count
  void _resetErrorState() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _errorCount = 0;
    });
  }

  /// Initialize deep link handling
  void _initDeepLinks() {
    try {
      debugPrint('✅ Deep link handling initialized (simplified)');
    } catch (e) {
      debugPrint('❌ Error initializing deep links: $e');
    }
  }

  /// Initialize app update checking
  Future<void> _initAppUpdateChecking() async {
    try {
      debugPrint('🔄 Initializing app update checking...');

      // Initialize notification service
      await _notificationService.initialize();

      // Check for updates after a delay to let app fully load
      Future.delayed(const Duration(seconds: 10), () async {
        try {
          await _appUpdateService.checkForUpdates();
        } catch (e) {
          debugPrint('❌ Error checking for updates: $e');
        }
      });

      // Schedule periodic update checks
      _schedulePeriodicUpdateChecks();

      debugPrint('✅ App update checking initialized');
    } catch (e) {
      debugPrint('❌ Error initializing app update checking: $e');
    }
  }

  /// Schedule periodic update checks
  void _schedulePeriodicUpdateChecks() {
    // Check for updates every 6 hours when app is active
    Future.delayed(const Duration(hours: 6), () {
      if (mounted) {
        _appUpdateService.checkForUpdates();
        _schedulePeriodicUpdateChecks(); // Reschedule
      }
    });
  }

  /// Handle deep link navigation
  void _handleDeepLink(Uri uri) {
    try {
      debugPrint('🔗 Processing deep link: $uri');

      // Check if it's our custom scheme
      if (uri.scheme == 'pelevo') {
        final path = uri.path;

        // Handle different deep link paths
        switch (path) {
          case '/auth/login':
            debugPrint('🔗 Navigating to login screen');
            _navigateToLogin();
            break;
          case '/auth/register':
            debugPrint('🔗 Navigating to register screen');
            _navigateToRegister();
            break;
          default:
            debugPrint('🔗 Unknown deep link path: $path');
            // Default to login for unknown paths
            _navigateToLogin();
        }
      } else {
        debugPrint('🔗 Unknown deep link scheme: ${uri.scheme}');
      }
    } catch (e) {
      debugPrint('❌ Error handling deep link: $e');
    }
  }

  /// Navigate to login screen
  void _navigateToLogin() {
    try {
      // Wait for navigation service to be ready
      Future.delayed(Duration(milliseconds: 500), () {
        if (_navigationService.navigatorKey.currentContext != null) {
          _navigationService.navigateTo(AppRoutes.authenticationScreen);
          debugPrint('✅ Navigated to authentication screen');
        } else {
          debugPrint('⚠️ Navigation service not ready, retrying...');
          _navigateToLogin(); // Retry
        }
      });
    } catch (e) {
      debugPrint('❌ Error navigating to login: $e');
    }
  }

  /// Navigate to register screen
  void _navigateToRegister() {
    try {
      // Wait for navigation service to be ready
      Future.delayed(Duration(milliseconds: 500), () {
        if (_navigationService.navigatorKey.currentContext != null) {
          _navigationService.navigateTo(AppRoutes.authenticationScreen);
          debugPrint('✅ Navigated to authentication screen');
        } else {
          debugPrint('⚠️ Navigation service not ready, retrying...');
          _navigateToRegister(); // Retry
        }
      });
    } catch (e) {
      debugPrint('❌ Error navigating to register: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // Wrap initialization in error handling
    try {
      // Register for app lifecycle changes
      WidgetsBinding.instance.addObserver(this);

      // Initialize deep link handling
      _initDeepLinks();

      // Initialize app update checking
      _initAppUpdateChecking();

      // Initialize services after the app is fully loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndInitializeApp();
      });
    } catch (e, stackTrace) {
      debugPrint('🚨 Error in MyApp initState: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _hasError = true;
        _errorMessage = 'Initialization error: $e';
        _servicesInitialized = true; // Force continuation
      });
    }
  }

  @override
  void dispose() {
    // Unregister from app lifecycle changes
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App is going to background
        debugPrint(
            '🔄 App going to background, marking as properly closing...');
        _persistentStateManager.markAppProperlyClosing();
        break;
      case AppLifecycleState.resumed:
        // App is coming to foreground
        debugPrint('🔄 App coming to foreground');
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., receiving a phone call)
        debugPrint('🔄 App becoming inactive');
        break;
      case AppLifecycleState.detached:
        // App is detached (e.g., app is being terminated)
        debugPrint('🔄 App being detached');
        break;
      case AppLifecycleState.hidden:
        // App is hidden (e.g., app drawer is opened)
        debugPrint('🔄 App being hidden');
        break;
    }
  }

  Future<void> _checkAndInitializeApp() async {
    try {
      // Set overall timeout for app initialization
      await _checkAndInitializeAppWithTimeout().timeout(
        Duration(seconds: 60), // Overall timeout to prevent app from hanging
        onTimeout: () {
          debugPrint(
              '⏰ Overall app initialization timeout, forcing continuation');
          // Force services to be marked as initialized
          setState(() {
            _servicesInitialized = true;
          });
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error during app initialization: $e');
      debugPrint('Stack trace: $stackTrace');

      // Set error state but continue
      setState(() {
        _hasError = true;
        _errorMessage = 'Initialization error: $e';
        _servicesInitialized = true; // Force continuation
      });

      // Use critical error handler
      _handleCriticalError(e, stackTrace, context: 'App Initialization');

      // Fallback to full initialization
      try {
        await _initializeServices();
      } catch (fallbackError) {
        debugPrint('❌ Even fallback initialization failed: $fallbackError');
        // Continue anyway
      }
    }
  }

  Future<void> _checkAndInitializeAppWithTimeout() async {
    try {
      // Check if app was properly closed and can restore state
      final canRestoreState =
          await _persistentStateManager.wasAppProperlyClosed().timeout(
        Duration(seconds: 10), // Reduced from 20 to prevent hanging
        onTimeout: () {
          debugPrint(
              '⏰ State check timeout, proceeding with full initialization');
          return false;
        },
      );

      if (canRestoreState) {
        debugPrint(
            '🔄 App was properly closed, attempting state restoration...');
        await _restoreAppState();
      } else {
        debugPrint('🚀 App needs full initialization, starting services...');
        await _initializeServices();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error during app initialization: $e');
      debugPrint('Stack trace: $stackTrace');

      // Set error state but continue
      setState(() {
        _hasError = true;
        _errorMessage = 'State check error: $e';
      });

      // Use critical error handler
      _handleCriticalError(e, stackTrace, context: 'State Check');

      // Fallback to full initialization
      try {
        await _initializeServices();
      } catch (fallbackError) {
        debugPrint('❌ Even fallback initialization failed: $fallbackError');
        // Continue anyway
      }
    }
  }

  Future<void> _restoreAppState() async {
    try {
      debugPrint('🔄 Restoring app state...');

      // Initialize only essential services for state restoration with timeout
      await _serviceManager.initializeEssentialServicesOnly().timeout(
        Duration(seconds: 15), // Reduced from 30 to prevent hanging
        onTimeout: () {
          debugPrint(
              '⏰ Essential services initialization timeout, falling back to full initialization');
          throw TimeoutException('Essential services initialization timeout');
        },
      );

      // Mark services as initialized
      setState(() {
        _servicesInitialized = true;
        _stateRestored = true;
      });

      debugPrint('✅ App state restored successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ State restoration failed: $e');
      debugPrint('Stack trace: $stackTrace');

      // Set error state but continue
      setState(() {
        _hasError = true;
        _errorMessage = 'State restoration error: $e';
      });

      // Use critical error handler
      _handleCriticalError(e, stackTrace, context: 'State Restoration');

      // Fallback to full initialization
      try {
        await _initializeServices();
      } catch (fallbackError) {
        debugPrint('❌ Even fallback initialization failed: $fallbackError');
        // Continue anyway
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      debugPrint('🚀 Initializing background services...');

      // Skip complex service initialization on iOS simulator to prevent crashes
      if (Platform.isIOS && kDebugMode) {
        debugPrint(
            '📱 iOS Simulator detected - using minimal service initialization');
        await _serviceManager.initializeEssentialServicesOnly().timeout(
          Duration(seconds: 15),
          onTimeout: () {
            debugPrint(
                '⏰ Essential services timeout on iOS simulator, continuing...');
            throw TimeoutException('Essential services timeout');
          },
        );
        setState(() {
          _servicesInitialized = true;
        });
        return;
      }

      // Set timeout for service initialization with non-blocking fallback
      try {
        await _serviceManager.initialize().timeout(
          Duration(seconds: 45), // Reduced from 90 to prevent hanging
          onTimeout: () {
            debugPrint(
                '⏰ Service initialization timeout, continuing with limited functionality');
            throw TimeoutException('Service initialization timeout');
          },
        );

        debugPrint('✅ Background services initialized successfully');

        // Auth token is now automatically managed by services
        try {
          debugPrint(
              '🔐 Main: Auth token is now automatically managed by services');
          debugPrint(
              '🔐 Main: BackgroundSyncService will use global AuthService.getToken()');
        } catch (e) {
          debugPrint('⚠️ Main: Could not verify auth token setup: $e');
        }
      } on TimeoutException {
        debugPrint(
            '⏰ Service initialization timed out, forcing continuation...');
        // Don't rethrow - continue with minimal setup
      } catch (e) {
        debugPrint('❌ Service initialization error: $e');
        // Continue with minimal setup
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing background services: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('⚠️ App will continue without background services');

      // Set error state but continue
      setState(() {
        _hasError = true;
        _errorMessage = 'Service initialization error: $e';
      });

      // Use critical error handler
      _handleCriticalError(e, stackTrace, context: 'Service Initialization');
    } finally {
      // Always mark services as initialized to prevent app from hanging
      setState(() {
        _servicesInitialized = true;
      });

      // Try to initialize minimal services for basic functionality
      try {
        await _serviceManager.initializeEssentialServicesOnly().timeout(
          Duration(seconds: 15), // Reduced from 30 to prevent hanging
          onTimeout: () {
            debugPrint(
                '⏰ Essential services timeout, continuing with minimal setup');
          },
        );
        debugPrint('✅ Minimal services initialized');
      } catch (minimalError) {
        debugPrint('⚠️ Minimal services failed: $minimalError');
        // Continue anyway
      }

      // Log service status for debugging
      final status = _serviceManager.serviceStatus;
      debugPrint('📊 Service Status: $status');

      // Force app to continue even if services fail
      debugPrint('🚀 App initialization completed, proceeding to UI...');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check: if services take too long, force continuation
    if (!_servicesInitialized) {
      // Add a safety timeout to prevent infinite waiting
      Future.delayed(Duration(seconds: 5), () {
        if (mounted && !_servicesInitialized) {
          debugPrint(
              '⚠️ Safety timeout reached, forcing service initialization');
          setState(() {
            _servicesInitialized = true;
          });
        }
      });
    }

    // Show error screen if initialization failed
    if (_hasError) {
      return MaterialApp(
        home: SafeArea(
          child: Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 64, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'App encountered an issue',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Unknown error occurred',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _resetErrorState();
                        // Try to reinitialize
                        _checkAndInitializeApp();
                      },
                      child: Text('Retry'),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _resetErrorState();
                        _servicesInitialized = true; // Force continuation
                      },
                      child: Text('Continue Anyway'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionProvider>(
            create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider<PackageSubscriptionProvider>(
            create: (_) => PackageSubscriptionProvider()),
        ChangeNotifierProvider<HistoryProvider>(
            create: (_) => HistoryProvider()),
        ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider()),
        ChangeNotifierProvider<PlaylistProvider>(
            create: (_) => PlaylistProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<PodcastPlayerProvider>(create: (context) {
          final provider = PodcastPlayerProvider();

          // Connect services to the provider after services are initialized
          if (_servicesInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                if (_serviceManager.hasLocalStorage) {
                  provider.setLocalStorage(_serviceManager.localStorage!);
                }
                provider.setServiceManager(_serviceManager);

                // Connect to EpisodeProgressProvider for real-time updates
                final progressProvider = Provider.of<EpisodeProgressProvider>(
                    context,
                    listen: false);
                provider.setProgressProvider(progressProvider);

                // Connect to PlaybackPersistenceService for state persistence
                if (_serviceManager.hasPlaybackPersistence) {
                  provider.setPlaybackPersistenceService(
                      _serviceManager.playbackPersistence!);
                  debugPrint(
                      '✅ PlaybackPersistenceService connected to PodcastPlayerProvider');
                }

                // Initialize media session service with player provider using AppInitializationService
                // Skip on iOS simulator to prevent crashes
                if (!(Platform.isIOS && kDebugMode)) {
                  try {
                    final appInitService = AppInitializationService();
                    await appInitService.initialize(playerProvider: provider);
                    debugPrint(
                        '✅ Media session service connected to PodcastPlayerProvider via AppInitializationService');
                  } catch (e) {
                    debugPrint(
                        '⚠️ Warning: Media session initialization failed: $e');
                    debugPrint(
                        'App will continue without system media controls');
                  }
                } else {
                  debugPrint(
                      '📱 Skipping media session initialization on iOS simulator');
                }

                // Restore player state if we're restoring from persistence
                if (_stateRestored) {
                  provider.restoreFromPersistedState();
                }

                debugPrint(
                    '✅ PodcastPlayerProvider connected to services and progress provider');
              } catch (e) {
                debugPrint(
                    '⚠️ Warning: Could not connect PodcastPlayerProvider to services: $e');
                debugPrint('App will continue without service integration');
              }
            });
          }
          return provider;
        }),
        ChangeNotifierProvider<SyncStatusProvider>(
            create: (_) => SyncStatusProvider(_serviceManager)),
        ChangeNotifierProvider<EpisodeProgressProvider>(
            create: (_) => EpisodeProgressProvider()),
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
        ChangeNotifierProvider<LibraryProvider>(
            create: (_) => LibraryProvider()),
        ChangeNotifierProvider<ProfileProvider>(
            create: (_) => ProfileProvider()),
        Provider<NavigationService>(create: (_) => _navigationService),
        Provider<ServiceManager>(create: (_) => _serviceManager),
        Provider<PersistentStateManager>(
            create: (_) => _persistentStateManager),
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return ErrorBoundary(
                onError: (error, stackTrace) {
                  debugPrint('🚨 Error caught by ErrorBoundary: $error');
                  debugPrint('Stack trace: $stackTrace');

                  // Use critical error handler
                  _handleCriticalError(error, stackTrace,
                      context: 'Runtime Error');
                },
                errorBuilder: (error, stackTrace) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Something went wrong',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'The app encountered an unexpected error',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _hasError = false;
                                  _errorMessage = null;
                                });
                              },
                              child: Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: MaterialApp(
                  title: 'Pelevo',
                  debugShowCheckedModeBanner: false,
                  navigatorKey: _navigationService.navigatorKey,
                  initialRoute: AppRoutes.initial,
                  routes: AppRoutes.routes,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeService.themeMode,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Initialize Hive with retry logic to handle lock errors
Future<void> _initializeHiveWithRetry() async {
  const maxRetries = 3;
  const retryDelay = Duration(milliseconds: 1000);

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      debugPrint('🔄 Initializing Hive (attempt $attempt/$maxRetries)');

      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);

      debugPrint('✅ Hive initialized successfully');
      return; // Success, exit retry loop
    } catch (e) {
      debugPrint(
          '⚠️ Hive initialization failed (attempt $attempt/$maxRetries): $e');

      // Check if it's a lock error
      if (e.toString().contains('lock failed') ||
          e.toString().contains('errno = 11')) {
        debugPrint('🔒 Lock error detected, attempting cleanup...');

        // Try to clean up lock files
        await _cleanupHiveLockFiles();

        if (attempt < maxRetries) {
          debugPrint(
              '⏳ Waiting ${retryDelay.inMilliseconds}ms before retry...');
          await Future.delayed(retryDelay);
          continue;
        }
      }

      // If this is the last attempt, log the error but continue
      if (attempt == maxRetries) {
        debugPrint('❌ Hive initialization failed after $maxRetries attempts');
        debugPrint('📝 App will continue without local storage');
        return;
      }
    }
  }
}

/// Clean up Hive lock files
Future<void> _cleanupHiveLockFiles() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${appDir.path}/hive');

    if (await hiveDir.exists()) {
      // Find and delete lock files
      final lockFiles = await hiveDir
          .list()
          .where((entity) => entity.path.endsWith('.lock'))
          .toList();

      for (final lockFile in lockFiles) {
        try {
          await lockFile.delete();
          debugPrint('🗑️ Deleted lock file: ${lockFile.path}');
        } catch (e) {
          debugPrint('⚠️ Could not delete lock file ${lockFile.path}: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('⚠️ Error cleaning up Hive locks: $e');
  }
}
