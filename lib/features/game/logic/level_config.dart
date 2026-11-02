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
  });

  /// Total number of story levels.
  static const int totalLevels = 12;

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

  /// Total enemy count.
  int get enemyCount => enemies.values.fold(0, (a, b) => a + b);

  /// Builds the config for [level] (clamped to 1..[totalLevels]); difficulty
  /// rises monotonically.
  factory LevelConfig.forLevel(int level) {
    final n = level.clamp(1, totalLevels);
    final wander = (5 - n ~/ 3).clamp(2, 5);
    final chasers = n < 3 ? 0 : ((n - 1) ~/ 2).clamp(1, 4);
    final fast = n < 4 ? 0 : ((n - 1) ~/ 3).clamp(1, 3);
    return LevelConfig(
      level: n,
      enemies: {
        EnemyType.wanderer: wander,
        EnemyType.chaser: chasers,
        EnemyType.speedster: fast,
      },
      blockDensity: 0.5 + 0.02 * n,
      enemySpeedScale: 1 + 0.04 * n,
    );
  }
}
