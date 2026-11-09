import 'package:blast_buddies/core/daily/daily.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Difficulty tier of an achievement; decides its coin reward.
enum AchTier {
  /// Quick wins.
  easy(5),

  /// Takes a few sessions.
  medium(15),

  /// Takes real effort.
  hard(40),

  /// For dedicated players.
  expert(100),

  /// The long haul.
  legend(250);

  const AchTier(this.coins);

  /// Coins paid when the reward is claimed.
  final int coins;
}

/// One achievement: reach [goal] in the statistic [stat]. Achievements of one
/// statistic form a series with ascending [rank] (shown as I, II, III ...).
class Achievement {
  /// Creates an achievement.
  const Achievement(this.stat, this.goal, this.tier, this.rank);

  /// Statistic it tracks.
  final String stat;

  /// Value needed.
  final int goal;

  /// Difficulty tier.
  final AchTier tier;

  /// Position within its series (1-based).
  final int rank;

  /// Stable id, e.g. `kills_100`.
  String get id => '${stat}_$goal';

  /// Coins paid for this achievement.
  int get reward => tier.coins;
}

List<Achievement> _series(String stat, List<(int, AchTier)> steps) => [
      for (var i = 0; i < steps.length; i++) Achievement(stat, steps[i].$1, steps[i].$2, i + 1),
    ];

/// Turn on together with the friend-invite feature (needs accounts).
const bool invitesEnabled = false;

const _e = AchTier.easy, _m = AchTier.medium, _h = AchTier.hard, _x = AchTier.expert, _l = AchTier.legend;

/// All achievements (113, or 118 with invites), grouped by series, easiest first within a series.
final List<Achievement> achievements = [
  ..._series('kills', [(1, _e), (10, _e), (50, _m), (100, _m), (250, _h), (500, _h), (1000, _x), (2500, _x), (5000, _l)]),
  ..._series('blocks', [(10, _e), (50, _e), (100, _m), (250, _m), (500, _h), (1000, _h), (2500, _x), (5000, _l)]),
  ..._series('bombs', [(10, _e), (50, _e), (100, _m), (300, _m), (500, _h), (1000, _h), (2500, _x), (5000, _x), (10000, _l)]),
  ..._series('powerups', [(5, _e), (25, _e), (50, _m), (100, _m), (250, _h), (500, _x), (1000, _l)]),
  ..._series('levels', [(1, _e), (5, _e), (10, _m), (25, _m), (50, _h), (75, _x), (100, _l)]),
  ..._series('stars', [(3, _e), (10, _e), (30, _m), (60, _m), (100, _h), (150, _h), (200, _x), (250, _x), (300, _l)]),
  ..._series('perfect', [(1, _e), (5, _m), (10, _m), (25, _h), (50, _h), (75, _x), (100, _l)]),
  ..._series('bosses', [(1, _m), (2, _h), (3, _x), (4, _l)]),
  ..._series('wins', [(1, _e), (5, _e), (10, _m), (25, _m), (50, _h), (100, _x), (250, _l)]),
  ..._series('onlineWins', [(1, _m), (5, _m), (10, _h), (25, _h), (50, _x), (100, _x), (250, _l), (500, _l)]),
  ..._series('onlineGames', [(1, _e), (5, _e), (10, _m), (25, _m), (50, _h), (100, _h), (250, _x)]),
  ..._series('games', [(1, _e), (10, _e), (25, _m), (50, _m), (100, _h), (250, _h), (500, _x), (1000, _l)]),
  ..._series('emotes', [(1, _e), (10, _e), (50, _m), (100, _h), (250, _x)]),
  ..._series('ads', [(1, _e), (5, _e), (10, _m), (25, _m), (50, _h), (100, _x)]),
  ..._series('owned', [(1, _e), (3, _m), (5, _m), (10, _h), (15, _x), (20, _l)]),
  // Hidden until the friend-invite system exists: nobody can earn these yet.
  if (invitesEnabled) ..._series('invites', [(1, _m), (3, _m), (5, _h), (10, _x), (25, _l)]),
  ..._series('streak', [(3, _e), (7, _m), (14, _h), (30, _x), (60, _l), (100, _l)]),
];

/// Lifetime counters and unlocked achievements.
class PlayerStatsData {
  /// Creates data.
  const PlayerStatsData({
    this.counters = const {},
    this.unlocked = const {},
    this.claimed = const {},
  });

  /// Raw counters (kills, blocks, bombs, wins, ...).
  final Map<String, int> counters;

  /// Unlocked achievement ids.
  final Set<String> unlocked;

  /// Achievement ids whose coin reward was collected.
  final Set<String> claimed;

  /// Counter value (0 if unset).
  int operator [](String key) => counters[key] ?? 0;
}

/// Persists [PlayerStatsData] in shared preferences.
class StatsNotifier extends Notifier<PlayerStatsData> {
  static const _keys = [
    'kills', 'blocks', 'bombs', 'wins', 'onlineWins', 'onlineGames', 'games', 'levels', 'bosses', 'powerups', //
    'emotes', 'ads', 'invites', 'streak',
  ];

  @override
  PlayerStatsData build() {
    final p = ref.watch(prefsProvider);
    return PlayerStatsData(
      counters: {for (final k in _keys) k: p.getInt('stat_$k') ?? 0},
      unlocked: (p.getStringList('ach') ?? const []).toSet(),
      claimed: (p.getStringList('achClaimed') ?? const []).toSet(),
    );
  }

  static bool _isPaidCosmetic(String key) {
    final parts = key.split(':');
    return parts.length == 2 && const {'hat', 'face', 'color'}.contains(parts[0]) && parts[1] != '0';
  }

  /// Current value of [stat] including values derived from story progress.
  int value(String stat) {
    final pr = ref.read(progressProvider);
    return switch (stat) {
      'stars' => pr.totalStars,
      'perfect' => pr.perfectLevels,
      'owned' => ref.read(walletProvider).owned.where(_isPaidCosmetic).length,
      'streak' => ref.read(dailyProvider).bestStreak,
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
    state = PlayerStatsData(counters: next, unlocked: state.unlocked, claimed: state.claimed);
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
    state = PlayerStatsData(counters: state.counters, unlocked: all, claimed: state.claimed);
    await ref.read(prefsProvider).setStringList('ach', all.toList());
    return fresh;
  }

  /// Achievements that are unlocked but whose reward is still uncollected.
  List<Achievement> get claimable =>
      [for (final a in achievements) if (state.unlocked.contains(a.id) && !state.claimed.contains(a.id)) a];

  /// Pays the reward of [a] (once); returns the coins granted.
  Future<int> claim(Achievement a) async {
    if (!state.unlocked.contains(a.id) || state.claimed.contains(a.id)) return 0;
    final claimed = {...state.claimed, a.id};
    state = PlayerStatsData(counters: state.counters, unlocked: state.unlocked, claimed: claimed);
    await ref.read(prefsProvider).setStringList('achClaimed', claimed.toList());
    await ref.read(walletProvider.notifier).earn(a.reward);
    return a.reward;
  }

  /// Collects every pending reward; returns the total coins granted.
  Future<int> claimAll() async {
    var total = 0;
    for (final a in claimable) {
      total += await claim(a);
    }
    return total;
  }
}

/// Stats provider.
final statsProvider = NotifierProvider<StatsNotifier, PlayerStatsData>(StatsNotifier.new);
