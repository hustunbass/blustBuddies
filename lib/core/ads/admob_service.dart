import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:blast_buddies/core/ads/ad_config.dart';
import 'package:blast_buddies/core/ads/ad_service.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob implementation of [AdService].
///
/// * **Rewarded** powers every "watch an ad" button; the player always opts in
///   by tapping that button.
/// * **Interstitial** is shown at result screens only: every third break, never
///   in the first [minSessionAge], and at least [minGap] after any other
///   full-screen ad. Players who removed ads never see it.
/// * **Banner** is anchored-adaptive and only placed on menu screens.
class AdMobService implements AdService {
  /// Creates the service; [adsRemoved] tells whether to suppress pop-ups.
  AdMobService({required this.adsRemoved, DateTime Function()? now}) : now = now ?? DateTime.now {
    _started = this.now();
  }

  /// Whether the player bought "Remove ads".
  final bool Function() adsRemoved;

  /// Clock (overridable in tests).
  final DateTime Function() now;

  /// No pop-up ads this early in a session.
  static const minSessionAge = Duration(minutes: 5);

  /// Minimum time between two full-screen ads.
  static const minGap = Duration(minutes: 2);

  /// A pop-up ad is considered every this many result screens.
  static const breaksPerInterstitial = 3;

  late final DateTime _started;
  DateTime? _lastFullScreen;
  int _breaks = 0;

  /// True once consent was handled and the SDK is initialised.
  final ValueNotifier<bool> ready = ValueNotifier(false);

  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  int _rewardedFails = 0;
  int _interstitialFails = 0;

  /// Asks for consent (GDPR / US states via Google UMP) and tracking
  /// permission (iOS ATT), then starts the SDK and preloads ads. Never throws.
  Future<void> init() async {
    if (!AdConfig.supported) return;
    try {
      await _gatherConsent();
      if (Platform.isIOS) await _requestTracking();
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.updateRequestConfiguration(
        // 13+ game: keep ads at teen level or below.
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.t),
      );
      await MobileAds.instance.initialize();
      ready.value = true;
      _loadRewarded();
      _loadInterstitial();
    } on Object catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => unawaited(ConsentForm.loadAndShowConsentFormIfRequired((_) => finish())),
      (_) => finish(),
    );
    return done.future.timeout(const Duration(seconds: 30), onTimeout: () {});
  }

  Future<void> _requestTracking() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      // The system prompt only appears while the app is active.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  Duration _backoff(int fails) => Duration(seconds: (15 * (1 << fails.clamp(0, 5))).clamp(15, 300));

  void _loadRewarded() {
    final unit = AdConfig.unit(AdKind.rewarded);
    if (!ready.value || unit == null || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedFails = 0;
          _rewarded = ad;
        },
        onAdFailedToLoad: (e) {
          debugPrint('Rewarded failed: $e');
          Future<void>.delayed(_backoff(_rewardedFails++), _loadRewarded);
        },
      ),
    );
  }

  void _loadInterstitial() {
    final unit = AdConfig.unit(AdKind.interstitial);
    if (!ready.value || unit == null || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialFails = 0;
          _interstitial = ad;
        },
        onAdFailedToLoad: (e) {
          debugPrint('Interstitial failed: $e');
          Future<void>.delayed(_backoff(_interstitialFails++), _loadInterstitial);
        },
      ),
    );
  }

  @override
  bool get rewardedReady => ready.value && _rewarded != null;

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    if (!ready.value) return false;
    if (_rewarded == null) {
      // Give a slow load a few seconds before telling the player "no ad".
      _loadRewarded();
      for (var i = 0; i < 20 && _rewarded == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _lastFullScreen = now();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        debugPrint('Rewarded failed to show: $e');
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }

  @override
  Future<void> maybeShowInterstitial() async {
    if (!ready.value || adsRemoved()) return;
    if (++_breaks % breaksPerInterstitial != 0) return;
    if (now().difference(_started) < minSessionAge) return;
    final last = _lastFullScreen;
    if (last != null && now().difference(last) < minGap) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _lastFullScreen = now();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show();
    await done.future;
  }

  @override
  Widget buildBanner(BuildContext context, double width) {
    if (AdConfig.unit(AdKind.banner) == null) return const SizedBox.shrink();
    return _BannerView(service: this, width: width);
  }
}

class _BannerView extends StatefulWidget {
  const _BannerView({required this.service, required this.width});

  final AdMobService service;
  final double width;

  @override
  State<_BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<_BannerView> {
  BannerAd? _ad;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    widget.service.ready.addListener(_load);
    _load();
  }

  Future<void> _load() async {
    final unit = AdConfig.unit(AdKind.banner);
    if (_loading || _ad != null || unit == null || !widget.service.ready.value) return;
    _loading = true;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(widget.width.truncate());
    if (!mounted || size == null) {
      _loading = false;
      return;
    }
    unawaited(BannerAd(
      adUnitId: unit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _loading = false;
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _ad = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, e) {
          debugPrint('Banner failed: $e');
          ad.dispose();
          _loading = false;
        },
      ),
    ).load());
  }

  @override
  void dispose() {
    widget.service.ready.removeListener(_load);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad));
  }
}
