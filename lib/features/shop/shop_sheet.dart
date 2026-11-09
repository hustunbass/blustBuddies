import 'package:blast_buddies/core/ads/ads_removed.dart';
import 'package:blast_buddies/core/economy/packages.dart';
import 'package:blast_buddies/core/store/store.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/shop/economy_widgets.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Coin shop as a bottom sheet.
Future<void> showShopSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ShopSheet(),
    );

/// Starter offer, coin packs, remove-ads and restore.
class ShopSheet extends ConsumerWidget {
  /// Creates the sheet.
  const ShopSheet({super.key});

  static String _name(AppLocalizations l, int i) => [l.pkgSpark, l.pkgFuse, l.pkgDynamite, l.pkgDepot][i];

  static String _timeLeft(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes.clamp(1, 59)}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final store = ref.watch(storeProvider);
    final notifier = ref.read(storeProvider.notifier);
    final adsRemoved = ref.watch(adsRemovedProvider);
    String price(String id, String fallback) => store.prices[id] ?? fallback;
    final busy = store.busyId != null;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Row(children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [BuddyColors.gold.withValues(alpha: .35), Colors.transparent]),
                ),
                child: const CoinIcon(size: 34),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.shopTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const CoinChip(),
              const SizedBox(width: 2),
              // An obvious way out: the sheet covers most of the screen.
              IconButton(
                tooltip: l.close,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ]),
            const SizedBox(height: 8),
            Text(l.shopHint, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.35)),
            const SizedBox(height: 16),
            if (notifier.starterActive) ...[
              _StarterCard(
                price: price(starterPackProductId, starterPackFallbackPrice),
                endsIn: _timeLeft(store.starterEndsAt!.difference(notifier.now())),
                busy: store.busyId == starterPackProductId,
                enabled: !busy,
                onBuy: () => notifier.buy(starterPackProductId),
              ),
              const SizedBox(height: 18),
            ],
            _SectionLabel(l.shopPacks),
            if (notifier.bonusFor(coinPackages.first) > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Row(children: [
                  const Icon(Icons.redeem_rounded, size: 16, color: Color(0xFF81C784)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l.firstBuyNote,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF81C784))),
                  ),
                ]),
              ),
            for (var i = 0; i < coinPackages.length; i++)
              _PackageTile(
                tier: i + 1,
                title: _name(l, i),
                pkg: coinPackages[i],
                price: price(coinPackages[i].id, coinPackages[i].fallbackPrice),
                bonus: notifier.bonusFor(coinPackages[i]),
                busy: store.busyId == coinPackages[i].id,
                enabled: !busy,
                onBuy: () => notifier.buy(coinPackages[i].id),
              ),
            const SizedBox(height: 6),
            _RemoveAdsTile(
              owned: adsRemoved,
              price: price(removeAdsProductId, '₺99,99'),
              busy: store.busyId == removeAdsProductId,
              enabled: !busy,
              onBuy: () => notifier.buy(removeAdsProductId),
            ),
            const SizedBox(height: 6),
            Center(child: TextButton(onPressed: notifier.restore, child: Text(l.restorePurchases))),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: BuddyColors.gold),
        ),
      );
}

/// The price button: the theme's own filled button, or a spinner while the
/// payment sheet is open.
class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.price, required this.busy, required this.enabled, required this.onBuy, this.style});

  final String price;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: enabled ? onBuy : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 46),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ).merge(style),
        child: busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4)) : Text(price),
      );
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({
    required this.price,
    required this.endsIn,
    required this.busy,
    required this.enabled,
    required this.onBuy,
  });

  final String price;
  final String endsIn;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7043), Color(0xFFFFA726)],
        ),
        boxShadow: [BoxShadow(color: BuddyColors.accent.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE65100), size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.starterTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text(l.starterBody(starterPackCoins), style: const TextStyle(fontSize: 13.5, height: 1.25, color: Colors.white)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(l.starterEnds(endsIn),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        _BuyButton(
          price: price,
          busy: busy,
          enabled: enabled,
          onBuy: onBuy,
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFBF360C)),
        ),
      ]),
    );
  }
}

/// A little pile of coins, taller for bigger packs.
class _CoinStack extends StatelessWidget {
  const _CoinStack(this.tier);

  final int tier;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 62,
        height: 56,
        child: Stack(children: [
          for (var k = 0; k < tier; k++)
            Positioned(left: k * 7.0, top: 22.0 - k * 5, child: const CoinIcon(size: 34)),
        ]),
      );
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.tier,
    required this.title,
    required this.pkg,
    required this.price,
    required this.bonus,
    required this.busy,
    required this.enabled,
    required this.onBuy,
  });

  final int tier;
  final String title;
  final CoinPackage pkg;
  final String price;
  final int bonus;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final badge = pkg.popular ? l.mostPopular : (pkg.bestValue ? l.bestValue : null);
    final highlighted = badge != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(clipBehavior: Clip.none, children: [
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BuddyColors.panelLight, BuddyColors.panel],
              ),
              border: Border.all(color: highlighted ? BuddyColors.gold : Colors.white12, width: highlighted ? 1.8 : 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: enabled ? onBuy : null,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, highlighted ? 20 : 14, 14, 14),
                child: LayoutBuilder(builder: (context, c) {
                  // Not enough width (small phone or big system text): the price
                  // button moves under the pack instead of overflowing.
                  final stacked = c.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(16) > 19;
                  final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white54)),
                    const SizedBox(height: 2),
                    Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${pkg.amount}',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: BuddyColors.gold)),
                            const SizedBox(width: 5),
                            Text(l.coin, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white70)),
                          ],
                        ),
                      ),
                      if (pkg.bonusPercent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF66BB6A).withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+${pkg.bonusPercent}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF81C784))),
                        ),
                    ]),
                    if (bonus > 0) ...[
                      const SizedBox(height: 4),
                      Text(l.firstBuyChip(bonus),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF81C784))),
                    ],
                  ]);
                  final button = _BuyButton(price: price, busy: busy, enabled: enabled, onBuy: onBuy);
                  if (stacked) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [_CoinStack(tier), const SizedBox(width: 10), Expanded(child: info)]),
                      const SizedBox(height: 12),
                      button,
                    ]);
                  }
                  return Row(children: [
                    _CoinStack(tier),
                    const SizedBox(width: 10),
                    Expanded(child: info),
                    const SizedBox(width: 8),
                    button,
                  ]);
                }),
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -9,
            left: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: BuddyColors.gold, borderRadius: BorderRadius.circular(10)),
              child: Text(badge,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: .8, color: Color(0xFF3E2A00))),
            ),
          ),
      ]),
    );
  }
}

class _RemoveAdsTile extends StatelessWidget {
  const _RemoveAdsTile({
    required this.owned,
    required this.price,
    required this.busy,
    required this.enabled,
    required this.onBuy,
  });

  final bool owned;
  final String price;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BuddyColors.panelLight.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(color: BuddyColors.panel, shape: BoxShape.circle),
          child: const Icon(Icons.block_rounded, color: BuddyColors.accent, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.removeAds, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(l.removeAdsDesc, style: const TextStyle(fontSize: 12.5, height: 1.25, color: Colors.white60)),
          ]),
        ),
        const SizedBox(width: 8),
        if (owned)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF66BB6A)),
            const SizedBox(width: 4),
            Text(l.purchased, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF81C784))),
          ])
        else
          _BuyButton(price: price, busy: busy, enabled: enabled, onBuy: onBuy),
      ]),
    );
  }
}
