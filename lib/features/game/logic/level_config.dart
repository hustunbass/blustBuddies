import 'dart:math';

import 'package:blast_buddies/features/game/logic/entities.dart';

/// Game mode.
enum GameMode {
  /// Single player campaign.
  story,

  /// Local multiplayer / bots.
  battle,
}

/// Difficulty parameters for one story level.
class LevelConfig {
  /// Creates a config.
  const LevelConfig({
    required this.level,
    required this.enemies,
    required this.blockDensity,
    required this.enemySpeedScale,
    this.timeLimit = 180,
    this.bossHp = 0,
  });

  /// Total number of story levels.
  static const int totalLevels = 100;

  /// Level number (1-based).
  final int level;

  /// Enemy counts per type.
  final Map<EnemyType, int> enemies;

  /// Block density 0..1.
  final double blockDensity;

  /// Multiplier on base enemy speed.
  final double enemySpeedScale;

  /// Time limit in seconds.
  final double timeLimit;

  /// Hits the boss takes (0 = no boss on this level).
  final int bossHp;

  /// Every 25th level ends with a boss fight.
  static bool isBossLevel(int level) => level % 25 == 0;

  /// Star rating for a cleared level.
  ///
  /// 1 star: cleared. 2 stars: at most one hit and enough time left.
  /// 3 stars: no hit at all and a lot of time left. The time requirements
  /// tighten with the level number and are relaxed on boss levels.
  int starsFor({required int hits, required double timeLeft}) {
    final frac = timeLeft / timeLimit;
    final boss = bossHp > 0;
    final three = 0.50 + 0.0013 * level - (boss ? 0.15 : 0);
    final two = 0.30 + 0.0015 * level - (boss ? 0.10 : 0);
    if (hits == 0 && frac >= three) return 3;
    if (hits <= 1 && frac >= two) return 2;
    return 1;
  }

  /// Total enemy count.
  int get enemyCount => enemies.values.fold(0, (a, b) => a + b);

  /// Builds the config for [level] (clamped to 1..[totalLevels]).
  ///
  /// Difficulty rises slowly and monotonically: a gentle start (two slow
  /// wanderers, open board), chasers from level 6, speedsters from level 16,
  /// and only by level 100 a crowd of 10 fast enemies on a dense board.
  factory LevelConfig.forLevel(int level) {
    final n = level.clamp(1, totalLevels);
    final total = 2 + (n * 0.08).floor();
    final chasers = n < 6 ? 0 : 1 + ((n - 6) * 3 ~/ 94);
    final fast = n < 16 ? 0 : 1 + ((n - 16) * 2 ~/ 84);
    final boss = isBossLevel(n);
    final wander = max(1, total - chasers - fast - (boss ? 1 : 0));
    return LevelConfig(
      level: n,
      enemies: {
        EnemyType.wanderer: wander,
        EnemyType.chaser: chasers,
        EnemyType.speedster: fast,
        if (boss) EnemyType.boss: 1,
      },
      blockDensity: 0.45 + 0.003 * n,
      enemySpeedScale: 0.9 + 0.0075 * n,
      timeLimit: 180.0 - (n ~/ 10) * 3 + (boss ? 60 : 0),
      bossHp: boss ? 2 + n ~/ 25 : 0,
    );
  }
}
