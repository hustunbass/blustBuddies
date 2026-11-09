import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a rewarded ad is shown from (for analytics and frequency caps).
enum AdPlacement { earnCoin, extraLife, startBombs, doubleReward }

/// Abstraction over the ad SDK so screens never touch AdMob directly.
abstract class AdService {
  /// Whether a rewarded ad can be shown right now.
  bool get rewardedReady;

  /// Shows a rewarded ad; resolves to true only if the reward was earned.
  Future<bool> showRewarded(AdPlacement placement);

  /// Shows a pop-up ad at a natural break if the frequency rules allow it
  /// (never for players who removed ads). Call at result screens only.
  Future<void> maybeShowInterstitial();

  /// A banner of [width] logical pixels, or an empty box when none is shown.
  Widget buildBanner(BuildContext context, double width);
}

/// Used in tests and when ads are unavailable: grants rewards in debug builds
/// only (so flows can be tried), never shows banners or pop-ups.
class DebugAdService implements AdService {
  @override
  bool get rewardedReady => kDebugMode;

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    if (!kDebugMode) return false;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return true;
  }

  @override
  Future<void> maybeShowInterstitial() async {}

  @override
  Widget buildBanner(BuildContext context, double width) => const SizedBox.shrink();
}

/// Ad service provider (overridden with the AdMob implementation at startup).
final adServiceProvider = Provider<AdService>((ref) => DebugAdService());
