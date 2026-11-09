import 'dart:convert';
import 'dart:math';

import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Difficulty of a daily quest; decides its coin reward.
enum QuestTier {
  /// Quick.
  easy(15),

  /// A few rounds.
  medium(25),

  /// A real session.
  hard(40);

  const QuestTier(this.coins);

  /// Coins paid when claimed.
  final int coins;
}

/// A daily quest: raise [stat] by [goal] during the day.
class QuestDef {
  /// Creates a quest.
  const QuestDef(this.stat, this.goal, this.tier);

  /// Statistic counter it watches (see `StatsNotifier`).
  final String stat;

  /// Amount to gain today.
  final int goal;

  /// Difficulty.
  final QuestTier tier;

  /// Stable id within a day.
  String get id => '${stat}_$goal';

  /// Coins paid.
  int get reward => tier.coins;
}

const List<QuestDef> _easy = [
  QuestDef('blocks', 30, QuestTier.easy),
  QuestDef('bombs', 25, QuestTier.easy),
  QuestDef('games', 2, QuestTier.easy),
  QuestDef('powerups', 3, QuestTier.easy),
  QuestDef('kills', 5, QuestTier.easy),
];

const List<QuestDef> _medium = [
  QuestDef('kills', 15, QuestTier.medium),
  QuestDef('levels', 2, QuestTier.medium),
  QuestDef('blocks', 80, QuestTier.medium),
  QuestDef('bombs', 60, QuestTier.medium),
  QuestDef('powerups', 8, QuestTier.medium),
];

const List<QuestDef> _hard = [
  QuestDef('levels', 4, QuestTier.hard),
  QuestDef('kills', 30, QuestTier.hard),
  QuestDef('onlineGames', 2, QuestTier.hard),
  QuestDef('wins', 2, QuestTier.hard),
  QuestDef('bombs', 120, QuestTier.hard),
];

/// The three quests of [day] (days since 2020-01-01): one per tier, never two
/// on the same statistic. Everybody gets the same quests on the same day.
List<QuestDef> questsForDay(int day) {
  final picked = <QuestDef>[];
  void pick(List<QuestDef> pool, int salt) {
    // A seeded draw per day and tier (multiplying the day by the pool size
    // would pick the same quest every day).
    var i = Random(day * 10 + salt).nextInt(pool.length);
    while (picked.any((q) => q.stat == pool[i].stat)) {
      i = (i + 1) % pool.length;
    }
    picked.add(pool[i]);
  }

  pick(_easy, 1);
  pick(_medium, 2);
  pick(_hard, 3);
  return picked;
}

/// Today's progress and streak.
class DailyState {
  /// Creates the state.
  const DailyState({
    required this.day,
    required this.streak,
    required this.bestStreak,
    this.loginClaimed = false,
    this.base = const {},
    this.claimed = const {},
    this.bonusClaimed = false,
  });

  /// Day number of the last roll-over.
  final int day;

  /// Consecutive days played, counting today.
  final int streak;

  /// Longest streak ever (feeds the streak achievements).
  final int bestStreak;

  /// Today's login reward was collected.
  final bool loginClaimed;

  /// Counter values at the start of the day.
  final Map<String, int> base;

  /// Quest ids claimed today.
  final Set<String> claimed;

  /// The "all quests" bonus was collected today.
  final bool bonusClaimed;

  /// Copy with changes.
  DailyState copyWith({bool? loginClaimed, Set<String>? claimed, bool? bonusClaimed}) => DailyState(
        day: day,
        streak: streak,
        bestStreak: bestStreak,
        loginClaimed: loginClaimed ?? this.loginClaimed,
        base: base,
        claimed: claimed ?? this.claimed,
        bonusClaimed: bonusClaimed ?? this.bonusClaimed,
      );
}

/// The clock used for "today" (overridable in tests).
final dailyClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Daily login streak and quests, kept in shared preferences.
///
/// "Today" follows the device clock; setting the clock back never rewinds the
/// streak, but setting it forward can skip ahead (a server clock needs
/// accounts, which come later).
class DailyNotifier extends Notifier<DailyState> {
  /// Login reward per streak day; the cycle repeats every 7 days.
  static const loginRewards = [10, 15, 20, 25, 30, 40, 75];

  /// Bonus for claiming all three quests.
  static const allDoneBonus = 50;

  /// Day number of [t] (local date) since 2020-01-01.
  static int dayNumber(DateTime t) => DateTime.utc(t.year, t.month, t.day).difference(DateTime.utc(2020)).inDays;

  int _today() => dayNumber(ref.read(dailyClockProvider)());

  @override
  DailyState build() {
    ref.watch(dailyClockProvider);
    final p = ref.watch(prefsProvider);
    final stored = p.getInt('dailyDay');
    final saved = DailyState(
      day: stored ?? -1,
      streak: p.getInt('dailyStreak') ?? 0,
      bestStreak: p.getInt('dailyBest') ?? 0,
      loginClaimed: p.getBool('dailyLoginClaimed') ?? false,
      base: _decodeBase(p.getString('dailyBase')),
      claimed: (p.getStringList('dailyClaimed') ?? const []).toSet(),
      bonusClaimed: p.getBool('dailyBonus') ?? false,
    );
    return _rolled(saved, _today());
  }

  static Map<String, int> _decodeBase(String? s) {
    if (s == null || s.isEmpty) return const {};
    try {
      return (jsonDecode(s) as Map).map((k, v) => MapEntry(k as String, v as int));
    } on Object {
      return const {};
    }
  }

  DailyState _rolled(DailyState s, int today) {
    if (today <= s.day) return s; // same day (or the clock went back)
    final streak = s.day == today - 1 ? s.streak + 1 : 1;
    final stats = ref.read(statsProvider.notifier);
    final base = {
      for (final stat in {..._easy, ..._medium, ..._hard}.map((q) => q.stat)) stat: stats.value(stat),
    };
    final next = DailyState(
      day: today,
      streak: streak,
      bestStreak: max(s.bestStreak, streak),
      base: base,
    );
    _save(next);
    return next;
  }

  void _save(DailyState s) {
    final p = ref.read(prefsProvider);
    p
      ..setInt('dailyDay', s.day)
      ..setInt('dailyStreak', s.streak)
      ..setInt('dailyBest', s.bestStreak)
      ..setBool('dailyLoginClaimed', s.loginClaimed)
      ..setString('dailyBase', jsonEncode(s.base))
      ..setStringList('dailyClaimed', s.claimed.toList())
      ..setBool('dailyBonus', s.bonusClaimed);
  }

  /// Starts a new day if the date changed (call when the app comes back).
  void refresh() {
    final next = _rolled(state, _today());
    if (!identical(next, state)) state = next;
  }

  /// Today's quests.
  List<QuestDef> get quests => questsForDay(state.day);

  /// Progress of [q] today (0..goal).
  int progress(QuestDef q) {
    final now = ref.read(statsProvider.notifier).value(q.stat);
    return (now - (state.base[q.stat] ?? 0)).clamp(0, q.goal);
  }

  /// The quest is finished.
  bool isDone(QuestDef q) => progress(q) >= q.goal;

  /// Finished but not collected yet.
  bool canClaim(QuestDef q) => isDone(q) && !state.claimed.contains(q.id);

  /// Coins of today's login reward (day 1..7 of the cycle).
  int get loginReward => loginRewards[(max(state.streak, 1) - 1) % loginRewards.length];

  /// Position of today in the 7-day cycle (0..6).
  int get cycleDay => (max(state.streak, 1) - 1) % loginRewards.length;

  /// All three quests were collected.
  bool get allClaimed => quests.every((q) => state.claimed.contains(q.id));

  /// Something is waiting to be collected (drives the red dot).
  bool get attention =>
      !state.loginClaimed || quests.any(canClaim) || (allClaimed && !state.bonusClaimed);

  /// Collects the login reward; returns the coins (0 if already collected).
  Future<int> claimLogin() async {
    if (state.loginClaimed) return 0;
    final coins = loginReward;
    state = state.copyWith(loginClaimed: true);
    _save(state);
    await ref.read(walletProvider.notifier).earn(coins);
    return coins;
  }

  /// Collects quest [q]; returns the coins (0 if not finished or collected).
  Future<int> claimQuest(QuestDef q) async {
    if (!canClaim(q)) return 0;
    state = state.copyWith(claimed: {...state.claimed, q.id});
    _save(state);
    await ref.read(walletProvider.notifier).earn(q.reward);
    return q.reward;
  }

  /// Collects the all-quests bonus; returns the coins.
  Future<int> claimBonus() async {
    if (!allClaimed || state.bonusClaimed) return 0;
    state = state.copyWith(bonusClaimed: true);
    _save(state);
    await ref.read(walletProvider.notifier).earn(allDoneBonus);
    return allDoneBonus;
  }
}

/// Daily provider.
final dailyProvider = NotifierProvider<DailyNotifier, DailyState>(DailyNotifier.new);

/// True while the daily screen has something to collect.
final dailyAttentionProvider = Provider<bool>((ref) {
  ref.watch(dailyProvider);
  ref.watch(statsProvider); // quest progress changes with the counters
  return ref.read(dailyProvider.notifier).attention;
});
