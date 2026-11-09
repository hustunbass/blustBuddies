import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// The ad formats the app uses.
enum AdKind { banner, interstitial, rewarded }

/// AdMob identifiers. Debug and profile builds always use Google's official
/// **test** units (clicking your own live ads can get an AdMob account
/// suspended); release builds use the real ones.
///
/// Only the iOS app has live units so far. Android release builds show no ads
/// until [androidUnits] is filled in (and the app id in AndroidManifest.xml).
class AdConfig {
  AdConfig._();

  /// iOS AdMob application id (also in Info.plist as GADApplicationIdentifier).
  static const iosAppId = 'ca-app-pub-9207046302495275~6196109695';

  /// Live iOS ad units.
  static const Map<AdKind, String> iosUnits = {
    AdKind.banner: 'ca-app-pub-9207046302495275/4178440118',
    AdKind.interstitial: 'ca-app-pub-9207046302495275/8716275910',
    AdKind.rewarded: 'ca-app-pub-9207046302495275/1073589612',
  };

  /// Live Android ad units — fill in once the Android app exists in AdMob.
  static const Map<AdKind, String> androidUnits = {};

  static const _testIos = {
    AdKind.banner: 'ca-app-pub-3940256099942544/2934735716',
    AdKind.interstitial: 'ca-app-pub-3940256099942544/4411468910',
    AdKind.rewarded: 'ca-app-pub-3940256099942544/1712485313',
  };

  static const _testAndroid = {
    AdKind.banner: 'ca-app-pub-3940256099942544/6300978111',
    AdKind.interstitial: 'ca-app-pub-3940256099942544/1033173712',
    AdKind.rewarded: 'ca-app-pub-3940256099942544/5224354917',
  };

  /// Whether ads can run on this platform at all.
  static bool get supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Unit id for [kind] on this platform, or null if ads are off here
  /// (unsupported platform, or no live unit configured for a release build).
  static String? unit(AdKind kind) {
    if (!supported) return null;
    final ios = Platform.isIOS;
    if (kReleaseMode) return (ios ? iosUnits : androidUnits)[kind];
    return (ios ? _testIos : _testAndroid)[kind];
  }
}
