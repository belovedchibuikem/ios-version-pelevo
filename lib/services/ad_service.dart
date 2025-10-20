/*// lib/services/ad_service.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  // Test Ad Unit IDs for Development
  // These are Google's test ad IDs that always return test ads
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Production Ad Unit IDs - Replace these with your actual AdMob IDs when ready for production
  static const String _bannerAdUnitId = _testBannerAdUnitId;
  static const String _interstitialAdUnitId = _testInterstitialAdUnitId;
  static const String _rewardedAdUnitId = _testRewardedAdUnitId;

  // Map to store ads by screen to avoid creating multiple instances
  final Map<String, BannerAd> _bannerAds = {};
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Initialize the Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  // Create a banner ad
  BannerAd createBannerAd(String screenName) {
    if (_bannerAds.containsKey(screenName)) {
      return _bannerAds[screenName]!;
    }

    final BannerAd bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded for $screenName');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load for $screenName: $error');
          ad.dispose();
          _bannerAds.remove(screenName);
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened from $screenName');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed from $screenName');
        },
      ),
    );

    _bannerAds[screenName] = bannerAd;
    return bannerAd;
  }

  // Load a banner ad
  Future<void> loadBannerAd(String screenName) async {
    if (!_isInitialized) await initialize();

    final bannerAd = createBannerAd(screenName);
    return bannerAd.load();
  }

  // Get a previously created banner ad
  BannerAd? getBannerAd(String screenName) {
    return _bannerAds[screenName];
  }

  // Dispose a banner ad
  void disposeBannerAd(String screenName) {
    if (_bannerAds.containsKey(screenName)) {
      _bannerAds[screenName]!.dispose();
      _bannerAds.remove(screenName);
    }
  }

  // Load an interstitial ad
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized) await initialize();

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  // Show the interstitial ad if it's loaded
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not loaded yet');
      return false;
    }

    // Set up a callback for when the ad is closed
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        // Preload the next interstitial ad
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
      },
    );

    await _interstitialAd!.show();
    return true;
  }

  // Load a rewarded ad
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) await initialize();

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  // Show the rewarded ad if it's loaded
  Future<bool> showRewardedAd(
      OnUserEarnedRewardCallback onUserEarnedReward) async {
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not loaded yet');
      return false;
    }

    // Set up callbacks
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        // Preload the next rewarded ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
    return true;
  }

  // Dispose all ads
  void disposeAds() {
    _bannerAds.forEach((_, ad) => ad.dispose());
    _bannerAds.clear();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}*/
