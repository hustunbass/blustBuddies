import 'package:blast_buddies/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One achievement: reach [goal] in the statistic [stat].
class Achievement {
  /// Creates an achievement.
  const Achievement(this.id, this.stat, this.goal);

  /// Stable id (also the localisation key suffix).
  final String id;

  /// Statistic it tracks.
  final String stat;

  /// Value needed.
  final int goal;
}

/// All achievements, easiest first.
const List<Achievement> achievements = [
  Achievement('firstBlood', 'kills', 1),
  Achievement('firstWin', 'wins', 1),
  Achievement('bomber', 'bombs', 300),
  Achievement('demolition', 'blocks', 200),
  Achievement('collector', 'powerups', 50),
  Achievement('chapter', 'levels', 10),
  Achievement('stars30', 'stars', 30),
  Achievement('exterminator', 'kills', 100),
  Achievement('champion', 'wins', 20),
  Achievement('online1', 'onlineWins', 1),
  Achievement('boss1', 'bosses', 1),
  Achievement('perfectionist', 'perfect', 10),
  Achievement('explorer', 'levels', 50),
  Achievement('online10', 'onlineWins', 10),
  Achievement('bosses4', 'bosses', 4),
  Achievement('legend', 'levels', 100),
];

/// Lifetime counters and unlocked achievements.
class PlayerStatsData {
  /// Creates data.
  const PlayerStatsData({this.counters = const {}, this.unlocked = const {}});

  /// Raw counters (kills, blocks, bombs, wins, ...).
  final Map<String, int> counters;

  /// Unlocked achievement ids.
  final Set<String> unlocked;

  /// Counter value (0 if unset).
  int operator [](String key) => counters[key] ?? 0;
}

/// Persists [PlayerStatsData] in shared preferences.
class StatsNotifier extends Notifier<PlayerStatsData> {
  static const _keys = ['kills', 'blocks', 'bombs', 'wins', 'onlineWins', 'onlineGames', 'games', 'levels', 'bosses', 'powerups'];

  @override
  PlayerStatsData build() {
    final p = ref.watch(prefsProvider);
    return PlayerStatsData(
      counters: {for (final k in _keys) k: p.getInt('stat_$k') ?? 0},
      unlocked: (p.getStringList('ach') ?? const []).toSet(),
    );
  }

  /// Current value of [stat] including values derived from story progress.
  int value(String stat) {
    final pr = ref.read(progressProvider);
    return switch (stat) {
      'stars' => pr.totalStars,
      'perfect' => pr.perfectLevels,
      _ => state[stat],
    };
  }

  /// Adds [delta] to counters and returns achievements that just unlocked.
  Future<List<Achievement>> add(Map<String, int> delta) async {
    final p = ref.read(prefsProvider);
    final next = {...state.counters};
    delta.forEach((k, v) {
      if (v != 0) next[k] = (next[k] ?? 0) + v;
    });
    state = PlayerStatsData(counters: next, unlocked: state.unlocked);
    for (final e in delta.entries) {
      if (e.value != 0) await p.setInt('stat_${e.key}', next[e.key]!);
    }
    return check();
  }

  /// Unlocks achievements whose goal is reached (also after star changes).
  Future<List<Achievement>> check() async {
    final fresh = [
      for (final a in achievements)
        if (!state.unlocked.contains(a.id) && value(a.stat) >= a.goal) a,
    ];
    if (fresh.isEmpty) return fresh;
    final all = {...state.unlocked, ...fresh.map((a) => a.id)};
    state = PlayerStatsData(counters: state.counters, unlocked: all);
    await ref.read(prefsProvider).setStringList('ach', all.toList());
    return fresh;
  }
}

/// Stats provider.
final statsProvider = NotifierProvider<StatsNotifier, PlayerStatsData>(StatsNotifier.new);
