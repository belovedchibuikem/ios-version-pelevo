// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import '../../presentation/splash_screen/splash_screen.dart';
import '../../widgets/enhanced_main_navigation.dart';
import '../../presentation/onboarding_flow/onboarding_flow.dart';
import '../../presentation/authentication_screen/authentication_screen.dart';
import '../../presentation/podcast_player/podcast_player.dart';
import '../../presentation/category_podcasts_screen/category_podcasts_screen.dart';
import '../../presentation/edit_profile_screen/edit_profile_screen.dart';
import '../../presentation/podcast_detail_screen/podcast_detail_screen.dart';
import '../../presentation/categories_list_screen/categories_list_screen.dart';
import '../../presentation/trending_podcasts_screen/trending_podcasts_screen.dart';
import '../../presentation/recommendations_screen/recommendations_screen.dart';
import '../../presentation/package_subscription_screen/package_subscription_screen.dart';
import '../../presentation/withdrawal_setup_screen/withdrawal_setup_screen.dart';
import '../../presentation/withdrawal_confirmation_screen/withdrawal_confirmation_screen.dart';
import '../../presentation/withdrawal_history_screen/withdrawal_history_screen.dart';
import '../../presentation/subscription_management_screen/subscription_management_screen.dart';
import '../../presentation/downloaded_episodes_screen/downloaded_episodes_screen.dart';
import '../../presentation/listening_statistics_screen/listening_statistics_screen.dart';
import '../../presentation/forgot_password_screen/forgot_password_screen.dart';
import '../../presentation/reset_password_screen/reset_password_screen.dart';
import '../../presentation/home_screen/featured_podcasts_screen.dart';
import '../../presentation/home_screen/crime_archives_screen.dart';
import '../../presentation/home_screen/podcast_for_health_screen.dart';
import '../../presentation/playlist_detail_screen/playlist_detail_screen.dart';
import '../../presentation/add_episodes_to_playlist_screen/add_episodes_to_playlist_screen.dart';
import '../../presentation/listening_history_screen/listening_history_screen.dart';
import '../../presentation/help_center_screen/help_center_screen.dart';
import '../../presentation/feedback_screen/feedback_screen.dart';
import '../../presentation/privacy_policy_screen/privacy_policy_screen.dart';
import '../../presentation/terms_screen/terms_screen.dart';
import '../../presentation/progress_tracking_screen/progress_tracking_screen.dart';
import '../../presentation/archive_screen/archive_screen.dart';
import '../../models/playlist.dart';
import '../../presentation/debug_screen/debug_screen.dart';
import '../../presentation/performance_dashboard_screen/performance_dashboard_screen.dart';
import '../../presentation/email_confirmation_screen/email_confirmation_screen.dart';
import '../../test_subscription_screen.dart';
import '../../test_in_app_purchase.dart';
import '../../test_permission_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String authenticationScreen = '/authentication-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String homeScreen = '/home-screen';
  static const String earnScreen = '/earn-screen';
  static const String podcastPlayer = '/podcast-player';
  static const String categoryPodcasts = '/category-podcasts';
  static const String libraryScreen = '/library-screen';
  static const String walletScreen = '/wallet-screen';
  static const String profileScreen = '/profile-screen';
  static const String editProfileScreen = '/edit-profile-screen';
  static const String podcastDetailScreen = '/podcast-detail-screen';
  static const String categoriesListScreen = '/categories-list-screen';
  static const String trendingPodcastsScreen = '/trending-podcasts-screen';
  static const String newEpisodesScreen = '/new-episodes-screen';
  static const String recommendationsScreen = '/recommendations-screen';
  static const String packageSubscriptionScreen =
      '/package-subscription-screen';
  static const String withdrawalSetupScreen = '/withdrawal-setup-screen';
  static const String withdrawalConfirmationScreen =
      '/withdrawal-confirmation-screen';
  static const String withdrawalHistoryScreen = '/withdrawal-history-screen';
  static const String subscriptionManagementScreen =
      '/subscription-management-screen';
  static const String downloadedEpisodesScreen = '/downloaded-episodes-screen';
  static const String listeningStatisticsScreen =
      '/listening-statistics-screen';
  static const String listeningHistoryScreen = '/listening-history-screen';
  static const String forgotPasswordScreen = '/forgot-password';
  static const String resetPasswordScreen = '/reset-password';
  static const String featuredPodcastsScreen = '/featured-podcasts-screen';
  static const String crimeArchivesScreen = '/crime-archives-screen';
  static const String podcastForHealthScreen = '/podcast-for-health-screen';
  static const String playlistDetailScreen = '/playlist-detail';
  static const String addEpisodesToPlaylistScreen = '/add-episodes-to-playlist';
  static const String helpCenter = '/help-center';
  static const String feedbackScreen = '/feedback';
  static const String privacyPolicyScreen = '/privacy-policy';
  static const String termsScreen = '/terms';
  static const String progressTrackingScreen = '/progress-tracking-screen';
  static const String archiveScreen = '/archive-screen';
  static const String debugScreen = '/debug-screen';
  static const String performanceDashboardScreen =
      '/performance-dashboard-screen';
  static const String testSubscriptionScreen = '/test-subscription-screen';
  static const String testInAppPurchaseScreen = '/test-in-app-purchase-screen';
  static const String testPermissionScreen = '/test-permission-screen';
  static const String emailConfirmationScreen = '/email-confirmation-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    homeScreen: (context) => const EnhancedMainNavigation(),
    authenticationScreen: (context) => const AuthenticationScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    earnScreen: (context) => const EnhancedMainNavigation(),
    podcastPlayer: (context) => const PodcastPlayer(),
    categoryPodcasts: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        debugPrint(
            'AppRoutes: Navigating to CategoryPodcasts with id=${args['id']}, name=${args['name']}');
        return CategoryPodcastsScreen(category: args);
      } else {
        debugPrint('AppRoutes: Invalid arguments for CategoryPodcasts: $args');
        return const Scaffold(
            body: Center(child: Text('Invalid category arguments')));
      }
    },
    libraryScreen: (context) => const EnhancedMainNavigation(),
    walletScreen: (context) => const EnhancedMainNavigation(),
    profileScreen: (context) => const EnhancedMainNavigation(),
    editProfileScreen: (context) => const EditProfileScreen(),
    podcastDetailScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        return PodcastDetailScreen(podcast: args);
      } else {
        debugPrint(
            'AppRoutes: Invalid arguments for PodcastDetailScreen: $args');
        return const Scaffold(
          body: Center(
            child: Text('Invalid podcast arguments. Please try again.'),
          ),
        );
      }
    },
    categoriesListScreen: (context) => const CategoriesListScreen(),
    trendingPodcastsScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return TrendingPodcastsScreen(podcasts: args?['podcasts'] ?? []);
    },
    recommendationsScreen: (context) => const RecommendationsScreen(),
    packageSubscriptionScreen: (context) => const PackageSubscriptionScreen(),
    withdrawalSetupScreen: (context) => const WithdrawalSetupScreen(),
    withdrawalConfirmationScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return WithdrawalConfirmationScreen(withdrawalData: args ?? {});
    },
    withdrawalHistoryScreen: (context) => const WithdrawalHistoryScreen(),
    subscriptionManagementScreen: (context) =>
        const SubscriptionManagementScreen(),
    downloadedEpisodesScreen: (context) => const DownloadedEpisodesScreen(),
    listeningStatisticsScreen: (context) => const ListeningStatisticsScreen(),
    listeningHistoryScreen: (context) => const ListeningHistoryScreen(),
    forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
    resetPasswordScreen: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, String>;
      return ResetPasswordScreen(
        token: args['token']!,
        email: args['email']!,
      );
    },
    featuredPodcastsScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return FeaturedPodcastsScreen(podcasts: args?['podcasts'] ?? []);
    },
    crimeArchivesScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return CrimeArchivesScreen(podcasts: args?['podcasts'] ?? []);
    },
    podcastForHealthScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PodcastForHealthScreen(podcasts: args?['podcasts'] ?? []);
    },
    playlistDetailScreen: (context) {
      final playlistData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final playlist =
          playlistData != null ? Playlist.fromJson(playlistData) : null;
      return PlaylistDetailScreen(playlist: playlist!);
    },
    addEpisodesToPlaylistScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final playlist = args?['playlist'] as Playlist?;
      final onEpisodesAdded = args?['onEpisodesAdded'] as VoidCallback?;
      return AddEpisodesToPlaylistScreen(
        playlist: playlist!,
        onEpisodesAdded: onEpisodesAdded,
      );
    },
    helpCenter: (context) => const HelpCenterScreen(),
    feedbackScreen: (context) => const FeedbackScreen(),
    privacyPolicyScreen: (context) => const PrivacyPolicyScreen(),
    termsScreen: (context) => const TermsScreen(),
    progressTrackingScreen: (context) => const ProgressTrackingScreen(),
    archiveScreen: (context) => const ArchiveScreen(),
    debugScreen: (context) => const DebugScreen(),
    performanceDashboardScreen: (context) => const PerformanceDashboardScreen(),
    testSubscriptionScreen: (context) => const TestSubscriptionScreen(),
    testInAppPurchaseScreen: (context) => const TestInAppPurchaseScreen(),
    testPermissionScreen: (context) => const TestPermissionScreen(),
    emailConfirmationScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return EmailConfirmationScreen(
        userEmail: args?['email'],
      );
    },
  };
}
