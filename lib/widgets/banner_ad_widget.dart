// lib/widgets/banner_ad_widget.dart
/*import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sizer/sizer.dart';

import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final String screenName;
  final bool isBottom;

  const BannerAdWidget({
    super.key,
    required this.screenName,
    this.isBottom = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    await _adService.loadBannerAd(widget.screenName);

    setState(() {
      _bannerAd = _adService.getBannerAd(widget.screenName);
      _isAdLoaded = _bannerAd != null;
    });
  }

  @override
  void dispose() {
    _adService.disposeBannerAd(widget.screenName);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return SizedBox(height: 8.h); // Placeholder height when ad is loading
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: widget.isBottom
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withAlpha(26),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withAlpha(26),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}*/
