import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Singleton pattern
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Production Ad Unit IDs
  final String _androidBannerId = 'ca-app-pub-4851308752791320/5503246021';
  final String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716'; // iOS Test ID (Placeholder)

  final String _androidInterstitialId = 'ca-app-pub-4851308752791320/2395357647';
  final String _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  int _transactionCount = 0;
  final int _adFrequency = 4; // Show ad every 4 transactions

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _androidBannerId;
    } else if (Platform.isIOS) {
      return _iosBannerId;
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _androidInterstitialId;
    } else if (Platform.isIOS) {
      return _iosInterstitialId;
    }
    return '';
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error.');
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts < 3) {
            _loadInterstitial();
          }
        },
      ),
    );
  }

  // Call this method when a significant action is completed (e.g., transaction saved)
  // Returns true if ad was shown, false otherwise
  Future<bool> showInterstitialIfReady() async {
    _transactionCount++;
    
    // Only show if frequency cap is met
    if (_transactionCount % _adFrequency != 0) {
      return false;
    }

    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      _loadInterstitial(); // Try loading for next time
      return false;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _loadInterstitial(); // Load the next one
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _loadInterstitial();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null; // Clear reference
    return true;
  }
  
  // Widget helper for standard banner
  Widget getBannerWidget() {
    return const _BannerAdWidget();
  }
}

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = AdService().bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
