import 'package:blast_buddies/core/ads/ad_service.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/shop/economy_widgets.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Watch an ad, start your next match with 2 bombs". Turns into a badge once
/// the ad was watched; the advantage is used up when a match begins.
class BoostButton extends ConsumerWidget {
  /// Creates the button for [client].
  const BoostButton({super.key, required this.client});

  /// Connection that receives the advantage.
  final OnlineClient client;

  Future<void> _watch(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await watchRewarded(context, ref, AdPlacement.startBombs);
    if (ok) {
      client.setBoost(true);
    } else {
      showToast(l.adNotReady);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (client.boosted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber),
        ),
        child: Row(children: [
          const Icon(Icons.bolt, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(child: Text(l.boostReady(boostedStartBombs), style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () => _watch(context, ref),
      icon: const Icon(Icons.play_circle_fill),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(l.boostWatchAd(boostedStartBombs), maxLines: 1)),
    );
  }
}
