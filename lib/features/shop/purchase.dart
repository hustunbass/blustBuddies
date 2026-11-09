import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/menu/achievement_toast.dart';
import 'package:blast_buddies/features/shop/shop_sheet.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks to unlock item [key] for [price] coins and buys it on confirmation.
/// Offers the shop when the wallet is too empty. Returns true if the item is
/// owned afterwards.
Future<bool> purchaseWithCoins(BuildContext context, WidgetRef ref, String key, int price) async {
  final wallet = ref.read(walletProvider);
  if (price == 0 || wallet.has(key)) return true;
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.unlockFor(price)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.buy)),
      ],
    ),
  );
  if (ok != true) return false;
  if (await ref.read(walletProvider.notifier).buy(key, price)) {
    final fresh = await ref.read(statsProvider.notifier).check();
    toastAchievements(l, fresh);
    return true;
  }
  showToast(
    l.notEnoughCoin,
    kind: ToastKind.error,
    actionLabel: l.shopTitle,
    onAction: () {
      if (context.mounted) showShopSheet(context);
    },
  );
  return false;
}
