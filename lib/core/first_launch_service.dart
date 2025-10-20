// lib/core/first_launch_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class FirstLaunchService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keySkippedOnboarding = 'skipped_onboarding';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  static Future<void> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
    await setFirstLaunchCompleted();
  }

  static Future<bool> isOnboardingSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySkippedOnboarding) ?? false;
  }

  static Future<void> setOnboardingSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySkippedOnboarding, true);
    await setFirstLaunchCompleted();
  }

  static Future<void> resetFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstLaunch);
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keySkippedOnboarding);
  }

  /// Reset only onboarding state (for testing)
  static Future<void> resetOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keySkippedOnboarding);
  }

  /// Force first launch state (for testing)
  static Future<void> forceFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, true);
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keySkippedOnboarding);
  }
}
