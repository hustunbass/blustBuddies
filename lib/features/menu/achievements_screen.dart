import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/l10n/names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lifetime statistics and achievements.
class AchievementsScreen extends ConsumerWidget {
  /// Creates the screen.
  const AchievementsScreen({super.key});

  static const _summary = ['kills', 'blocks', 'bombs', 'wins', 'onlineWins', 'levels', 'bosses', 'stars'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(statsProvider);
    final notifier = ref.read(statsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.achievements), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.statsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final k in _summary)
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
            Text('${l.achievements} · ${data.unlocked.length}/${achievements.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final a in achievements)
              _Tile(
                title: Names.achievement(l, a.id),
                description: Names.achievementDesc(l, a.id, a.goal),
                value: notifier.value(a.stat),
                goal: a.goal,
                done: data.unlocked.contains(a.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.description,
    required this.value,
    required this.goal,
    required this.done,
  });

  final String title;
  final String description;
  final int value;
  final int goal;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: done ? Colors.amber : Colors.white12,
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
                  child: LinearProgressIndicator(value: (value / goal).clamp(0, 1).toDouble(), minHeight: 6),
                ),
              ],
            ]),
          ),
          if (!done) Padding(padding: const EdgeInsets.only(left: 10), child: Text('${value.clamp(0, goal)}/$goal')),
        ]),
      );
}
