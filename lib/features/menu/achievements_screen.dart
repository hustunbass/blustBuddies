import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/features/shop/economy_widgets.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/l10n/names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lifetime statistics and achievements with claimable coin rewards.
class AchievementsScreen extends ConsumerWidget {
  /// Creates the screen.
  const AchievementsScreen({super.key});

  static const _summary = ['kills', 'blocks', 'bombs', 'wins', 'onlineWins', 'levels', 'bosses', 'stars'];

  static Color tierColor(AchTier t) => switch (t) {
        AchTier.easy => const Color(0xFFA1887F),
        AchTier.medium => const Color(0xFFB0BEC5),
        AchTier.hard => const Color(0xFFFFC107),
        AchTier.expert => const Color(0xFF40C4FF),
        AchTier.legend => const Color(0xFFE040FB),
      };

  Future<void> _claim(BuildContext context, WidgetRef ref, Achievement? a) async {
    final l = AppLocalizations.of(context);
    final stats = ref.read(statsProvider.notifier);
    final coins = a == null ? await stats.claimAll() : await stats.claim(a);
    if (coins <= 0) return;
    toastCoins(l, coins);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(statsProvider);
    final notifier = ref.read(statsProvider.notifier);

    // Ready to claim first, then in progress (closest first), completed last.
    double progress(Achievement a) => (notifier.value(a.stat) / a.goal).clamp(0, 1).toDouble();
    final ready = [for (final a in achievements) if (data.unlocked.contains(a.id) && !data.claimed.contains(a.id)) a];
    final open = [for (final a in achievements) if (!data.unlocked.contains(a.id)) a]
      // Closest first; ties keep the catalogue order (Dart's sort is not stable).
      ..sort((a, b) {
        final byProgress = progress(b).compareTo(progress(a));
        return byProgress != 0 ? byProgress : achievements.indexOf(a).compareTo(achievements.indexOf(b));
      });
    final done = [for (final a in achievements) if (data.claimed.contains(a.id)) a];
    final rows = <Object>[
      if (ready.isNotEmpty) ...[(l.achReady, ready.fold<int>(0, (s, a) => s + a.reward)), ...ready],
      if (open.isNotEmpty) ...[l.achInProgress, ...open],
      if (done.isNotEmpty) ...[l.achDone, ...done],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.achievements),
        backgroundColor: Colors.transparent,
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: CoinChip())],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _Summary(summary: _summary, notifier: notifier, total: achievements.length, unlocked: data.unlocked.length);
            final row = rows[i - 1];
            if (row is Achievement) {
              return _Tile(
                title: Names.achievement(l, row),
                description: Names.achievementDesc(l, row),
                value: notifier.value(row.stat),
                goal: row.goal,
                done: data.unlocked.contains(row.id),
                claimed: data.claimed.contains(row.id),
                color: tierColor(row.tier),
                reward: row.reward,
                onClaim: () => _claim(context, ref, row),
              );
            }
            if (row is (String, int)) {
              return _Header(
                row.$1,
                action: FilledButton.icon(
                  onPressed: () => _claim(context, ref, null),
                  icon: const CoinIcon(size: 16),
                  label: Text('${l.achClaimAll} · ${row.$2}'),
                ),
              );
            }
            return _Header(row as String);
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary, required this.notifier, required this.total, required this.unlocked});

  final List<String> summary;
  final StatsNotifier notifier;
  final int total;
  final int unlocked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.statsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final k in summary)
            Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${notifier.value(k)}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.amber)),
                Text(Names.stat(l, k), style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
              ]),
            ),
        ],
      ),
      const SizedBox(height: 22),
      Text('${l.achievements} · $unlocked/$total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 4),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white70))),
          if (action != null) action!,
        ]),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.description,
    required this.value,
    required this.goal,
    required this.done,
    required this.claimed,
    required this.color,
    required this.reward,
    required this.onClaim,
  });

  final String title;
  final String description;
  final int value;
  final int goal;
  final bool done;
  final bool claimed;
  final Color color;
  final int reward;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: done ? color : Colors.white12,
          child: Icon(done ? Icons.emoji_events : Icons.lock_outline, color: done ? Colors.black : Colors.white38),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(description, style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
            if (!done) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: (value / goal).clamp(0, 1).toDouble(), minHeight: 6, color: color),
              ),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        if (done && !claimed)
          FilledButton(
            onPressed: onClaim,
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 16), Text(' $reward')]),
          )
        else if (claimed)
          const Icon(Icons.check_circle, color: Colors.greenAccent)
        else
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${value.clamp(0, goal)}/$goal'),
            Text(l.achReward(reward), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          ]),
      ]),
    );
  }
}
