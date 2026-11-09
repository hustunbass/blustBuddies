import 'package:blast_buddies/core/ads/ad_service.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/menu/achievement_toast.dart';
import 'package:blast_buddies/features/shop/shop_sheet.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reward for one "free Coin" ad.
const adCoinReward = 50;

/// The Coin icon: a gold coin stamped with a little bomb.
class CoinIcon extends StatelessWidget {
  /// Creates the icon of [size].
  const CoinIcon({super.key, this.size = 22});

  /// Edge length.
  final double size;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: SizedBox.square(dimension: size, child: CustomPaint(painter: _CoinPainter())));
}

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final rect = Rect.fromCircle(center: c, radius: r);
    // Rim, then the lit face.
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFD98200));
    canvas.drawCircle(
      c,
      r * .88,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE9A0), Color(0xFFFFC53D), Color(0xFFFFA000)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      r * .64,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .09
        ..color = const Color(0x66B26A00),
    );
    // The bomb: round body, short fuse with a spark.
    final body = c.translate(-r * .04, r * .1);
    canvas.drawCircle(body, r * .27, Paint()..color = const Color(0xFF7A4A00));
    canvas.drawCircle(body.translate(-r * .08, -r * .08), r * .07, Paint()..color = const Color(0x66FFFFFF));
    canvas.drawLine(
      body.translate(r * .15, -r * .2),
      body.translate(r * .3, -r * .38),
      Paint()
        ..color = const Color(0xFF7A4A00)
        ..strokeWidth = r * .09
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(body.translate(r * .33, -r * .42), r * .09, Paint()..color = const Color(0xFFFFF8E1));
  }

  @override
  bool shouldRepaint(_CoinPainter old) => false;
}

/// Pill showing the current Coin balance.
class CoinChip extends ConsumerWidget {
  /// Creates the chip.
  const CoinChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final n = ref.watch(walletProvider.select((w) => w.coin));
    return Semantics(
      label: l.coinAmount(n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoinIcon(),
              const SizedBox(width: 6),
              Text(
                '$n',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a rewarded ad and counts it for the "ads" achievements. Resolves to
/// true only if the reward was earned.
Future<bool> watchRewarded(BuildContext context, WidgetRef ref, AdPlacement placement) async {
  final l = AppLocalizations.of(context);
  final ok = await ref.read(adServiceProvider).showRewarded(placement);
  if (ok) {
    final fresh = await ref.read(statsProvider.notifier).add({'ads': 1});
    toastAchievements(l, fresh);
  }
  return ok;
}

/// Watches a rewarded ad and pays [adCoinReward]; shows the outcome.
Future<void> earnCoinWithAd(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final ok = await watchRewarded(context, ref, AdPlacement.earnCoin);
  if (ok) await ref.read(walletProvider.notifier).earn(adCoinReward);
  if (ok) {
    toastCoins(l, adCoinReward);
  } else {
    showToast(l.adNotReady, kind: ToastKind.info);
  }
}

/// Toast for coins that were just paid out, with the gold coin as its icon.
void toastCoins(AppLocalizations l, int coins) =>
    showToast(l.rewardGot(coins), kind: ToastKind.coins, leading: const CoinIcon(size: 28));

/// Home-screen header: balance, "free Coin" (ad) and shop buttons.
class EconomyBar extends ConsumerWidget {
  /// Creates the bar.
  const EconomyBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        const CoinChip(),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => earnCoinWithAd(context, ref),
            icon: const Icon(Icons.play_circle_fill, size: 20),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(l.earnCoin, maxLines: 1),
            ),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: l.shopTitle,
          child: IconButton.filled(
            tooltip: l.shopTitle,
            onPressed: () => showShopSheet(context),
            icon: const Icon(Icons.add_shopping_cart),
          ),
        ),
      ],
    );
  }
}
