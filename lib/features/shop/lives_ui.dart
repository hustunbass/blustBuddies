import 'dart:async';

import 'package:blast_buddies/core/ads/ad_service.dart';
import 'package:blast_buddies/core/economy/lives.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/shop/economy_widgets.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _mmss(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Hearts counter with a live countdown to the next life.
class LivesChip extends ConsumerStatefulWidget {
  /// Creates the chip.
  const LivesChip({super.key});

  @override
  ConsumerState<LivesChip> createState() => _LivesChipState();
}

class _LivesChipState extends ConsumerState<LivesChip> {
  Timer? _timer;

  void _syncTimer(bool needed) {
    if (needed && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        ref.read(livesProvider.notifier).refresh();
        if (mounted) setState(() {});
      });
    } else if (!needed) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(livesProvider);
    // Only tick while a life is regenerating (keeps idle screens timer-free).
    _syncTimer(!d.full);
    final left = d.untilNext(ref.read(livesProvider.notifier).now());
    return Semantics(
      label: l.livesChipLabel(d.lives, LivesNotifier.maxLives),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
              const SizedBox(width: 4),
              Text(
                '${d.lives}/${LivesNotifier.maxLives}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (left != null) ...[
                const SizedBox(width: 6),
                Text(
                  _mmss(left),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Spends a life to start a story attempt. If none is left, offers to refill
/// (ad / coins) first. Returns whether the attempt may start.
Future<bool> startStoryAttempt(BuildContext context, WidgetRef ref) async {
  final lives = ref.read(livesProvider.notifier)..refresh();
  if (ref.read(livesProvider).lives <= 0) {
    final refilled = await showDialog<bool>(
      context: context,
      builder: (_) => const _OutOfLivesDialog(),
    );
    if (refilled != true) return false;
  }
  return lives.consume();
}

class _OutOfLivesDialog extends ConsumerStatefulWidget {
  const _OutOfLivesDialog();

  @override
  ConsumerState<_OutOfLivesDialog> createState() => _OutOfLivesDialogState();
}

class _OutOfLivesDialogState extends ConsumerState<_OutOfLivesDialog> {
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(livesProvider.notifier).refresh();
      // A life regenerated while the dialog was open: let the player in.
      if (ref.read(livesProvider).lives > 0 && mounted)
        Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _ad() async {
    setState(() => _busy = true);
    final ok = await watchRewarded(context, ref, AdPlacement.extraLife);
    if (!mounted) return;
    if (ok) {
      await ref.read(livesProvider.notifier).add();
      if (mounted) Navigator.pop(context, true);
      return;
    }
    setState(() => _busy = false);
    showToast(AppLocalizations.of(context).adNotReady);
  }

  Future<void> _coins() async {
    if (await ref
        .read(walletProvider.notifier)
        .spend(LivesNotifier.coinPrice)) {
      await ref.read(livesProvider.notifier).add();
      if (mounted) Navigator.pop(context, true);
    } else if (mounted) {
      showToast(AppLocalizations.of(context).notEnoughCoin, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(livesProvider);
    final left =
        d.untilNext(ref.read(livesProvider.notifier).now()) ?? Duration.zero;
    final coins = ref.watch(walletProvider.select((w) => w.coin));
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.heart_broken, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(l.livesOutTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.livesOutBody(_mmss(left))),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _ad,
            icon: const Icon(Icons.play_circle_fill),
            label: Text(l.livesRefillAd),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _busy || coins < LivesNotifier.coinPrice ? null : _coins,
            icon: const CoinIcon(size: 18),
            label: Text(l.livesRefillCoins(LivesNotifier.coinPrice)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.livesWait),
        ),
      ],
    );
  }
}
