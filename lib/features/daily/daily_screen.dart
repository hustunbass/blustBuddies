import 'package:blast_buddies/core/daily/daily.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/features/menu/achievement_toast.dart';
import 'package:blast_buddies/features/shop/economy_widgets.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/l10n/names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Daily reward with the 7-day streak, plus today's three quests.
class DailyScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  @override
  void initState() {
    super.initState();
    // The app may have been open since yesterday.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(dailyProvider.notifier).refresh();
    });
  }

  Future<void> _claim(Future<int> Function(DailyNotifier) action) async {
    final l = AppLocalizations.of(context);
    final coins = await action(ref.read(dailyProvider.notifier));
    if (coins <= 0) return;
    toastCoins(l, coins);
    // The streak counts for achievements.
    final fresh = await ref.read(statsProvider.notifier).check();
    toastAchievements(l, fresh);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(dailyProvider);
    ref.watch(statsProvider); // quest progress
    final daily = ref.read(dailyProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.daily),
        backgroundColor: Colors.transparent,
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: CoinChip())],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LoginCard(
              streak: state.streak,
              cycleDay: daily.cycleDay,
              claimed: state.loginClaimed,
              reward: daily.loginReward,
              onClaim: () => _claim((d) => d.claimLogin()),
            ),
            const SizedBox(height: 20),
            Text(l.dailyQuests, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final q in daily.quests)
              _QuestTile(
                text: Names.goalDesc(l, q.stat, q.goal),
                progress: daily.progress(q),
                goal: q.goal,
                reward: q.reward,
                claimed: state.claimed.contains(q.id),
                onClaim: () => _claim((d) => d.claimQuest(q)),
              ),
            _BonusTile(
              ready: daily.allClaimed && !state.bonusClaimed,
              claimed: state.bonusClaimed,
              onClaim: () => _claim((d) => d.claimBonus()),
            ),
            const SizedBox(height: 14),
            Center(child: Text(l.dailyReset, style: const TextStyle(color: Colors.white54, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.streak,
    required this.cycleDay,
    required this.claimed,
    required this.reward,
    required this.onClaim,
  });

  final int streak;
  final int cycleDay;
  final bool claimed;
  final int reward;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(l.dailyLoginTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          const Icon(Icons.local_fire_department, color: Colors.deepOrangeAccent),
          const SizedBox(width: 4),
          Text(l.streakDays(streak), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.deepOrangeAccent)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < DailyNotifier.loginRewards.length; i++)
            Expanded(
              child: _DayChip(
                day: i + 1,
                coins: DailyNotifier.loginRewards[i],
                done: i < cycleDay || (i == cycleDay && claimed),
                today: i == cycleDay,
              ),
            ),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: claimed ? null : onClaim,
          icon: claimed ? const Icon(Icons.check) : const CoinIcon(size: 18),
          label: Text(claimed ? l.dailyComeBack : '${l.achClaim} · $reward'),
        ),
      ]),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.coins, required this.done, required this.today});

  final int day;
  final int coins;
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: done ? Colors.green.withValues(alpha: .35) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: today ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(child: Text(l.dayN(day), style: const TextStyle(fontSize: 10, color: Colors.white70))),
          const SizedBox(height: 4),
          done ? const Icon(Icons.check_circle, size: 18, color: Colors.greenAccent) : const CoinIcon(size: 18),
          const SizedBox(height: 2),
          FittedBox(child: Text('$coins', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
        ]),
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.text,
    required this.progress,
    required this.goal,
    required this.reward,
    required this.claimed,
    required this.onClaim,
  });

  final String text;
  final int progress;
  final int goal;
  final int reward;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final done = progress >= goal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: (progress / goal).clamp(0, 1).toDouble(), minHeight: 6),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        if (claimed)
          const Icon(Icons.check_circle, color: Colors.greenAccent)
        else if (done)
          FilledButton(
            onPressed: onClaim,
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 16), Text(' $reward')]),
          )
        else
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$progress/$goal'),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const CoinIcon(size: 12),
              Text(' $reward', style: const TextStyle(fontSize: 11, color: Colors.amber)),
            ]),
          ]),
      ]),
    );
  }
}

class _BonusTile extends StatelessWidget {
  const _BonusTile({required this.ready, required this.claimed, required this.onClaim});

  final bool ready;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ready ? Colors.amber : Colors.white24),
      ),
      child: Row(children: [
        const Text('🏆', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Text(l.dailyAllDone(DailyNotifier.allDoneBonus), style: const TextStyle(fontWeight: FontWeight.w700))),
        if (claimed)
          const Icon(Icons.check_circle, color: Colors.greenAccent)
        else
          FilledButton(
            onPressed: ready ? onClaim : null,
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(l.achClaim),
          ),
      ]),
    );
  }
}
