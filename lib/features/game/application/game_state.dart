import 'package:blast_buddies/features/game/logic/bot_brain.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';
import 'package:flutter/foundation.dart';

/// Arguments for the game route.
class GameArgs {
  /// Story game starting at [level], optionally carrying a previous player.
  const GameArgs.story({required this.level, this.carry, this.seed})
      : mode = GameMode.story,
        humans = 1,
        bots = 0,
        teams = false,
        botLevel = BotLevel.normal,
        daily = false;

  /// Battle game; [teams] plays 2v2 when there are 4 players.
  const GameArgs.battle({
    required this.humans,
    required this.bots,
    this.seed,
    this.teams = false,
    this.botLevel = BotLevel.normal,
    this.daily = false,
  })
      : mode = GameMode.battle,
        level = 0,
        carry = null;

  /// Mode.
  final GameMode mode;

  /// Story level.
  final int level;

  /// Human players.
  final int humans;

  /// Bot players.
  final int bots;

  /// 2v2 battle.
  final bool teams;

  /// Bot skill (battle).
  final BotLevel botLevel;

  /// Battle on today's shared arena (same layout, colours and crates for
  /// everybody on the same date).
  final bool daily;

  /// Seed of the daily arena for [now] (local date).
  static int dailySeed([DateTime? now]) {
    final d = now ?? DateTime.now();
    final days = DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;
    return (days * 2654435761) & 0x7fffffff;
  }

  /// Player carried over from the previous level.
  final Player? carry;

  /// Optional fixed seed (tests).
  final int? seed;

  /// Builds a fresh world.
  GameWorld buildWorld({Skin skin = const Skin()}) {
    final s = seed ?? (daily ? dailySeed() : DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    return mode == GameMode.story
        ? GameWorld.story(level: level, seed: s, carry: carry, skin: skin)
        : GameWorld.battle(
            humans: humans,
            bots: bots,
            seed: s,
            teams: teams,
            botLevel: botLevel,
            skins: [skin],
          );
  }

  /// Whether another story level exists after this one.
  bool get hasNextLevel => mode == GameMode.story && level < LevelConfig.totalLevels;
}

/// Immutable snapshot of what the HUD shows. Only changes trigger rebuilds.
@immutable
class HudState {
  /// Creates a snapshot.
  const HudState({
    this.lives = 3,
    this.score = 0,
    this.seconds = 180,
    this.level = 1,
    this.maxBombs = 1,
    this.range = 2,
    this.speed = 3.6,
    this.kick = false,
    this.detonate = false,
    this.ghost = 0,
    this.shield = 0,
    this.enemies = 0,
    this.alive = const [],
  });

  /// Lives of player 1.
  final int lives;

  /// Score of player 1.
  final int score;

  /// Whole seconds left.
  final int seconds;

  /// Story level.
  final int level;

  /// Bomb capacity.
  final int maxBombs;

  /// Blast range.
  final int range;

  /// Speed.
  final double speed;

  /// Kick unlocked.
  final bool kick;

  /// Detonator unlocked.
  final bool detonate;

  /// Ghost seconds left (rounded up).
  final int ghost;

  /// Shield seconds left (rounded up).
  final int shield;

  /// Enemies still alive.
  final int enemies;

  /// Alive flags per player (battle).
  final List<bool> alive;

  /// Reads a snapshot from [w]; [me] is the local player's slot (online).
  factory HudState.from(GameWorld w, [int me = 0]) {
    final p = w.players[me < w.players.length ? me : 0];
    return HudState(
      lives: p.lives,
      score: p.score,
      seconds: w.timeLeft.ceil().clamp(0, 9999),
      level: w.level,
      maxBombs: p.stats.maxBombs,
      range: p.stats.range,
      speed: (p.stats.speed * 10).round() / 10,
      kick: p.stats.canKick,
      detonate: p.stats.canDetonate,
      ghost: p.stats.ghost.ceil(),
      shield: p.stats.shield.ceil(),
      enemies: w.enemies.where((e) => e.alive).length,
      alive: [for (final q in w.players) q.alive],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HudState &&
      other.lives == lives &&
      other.score == score &&
      other.seconds == seconds &&
      other.level == level &&
      other.maxBombs == maxBombs &&
      other.range == range &&
      other.speed == speed &&
      other.kick == kick &&
      other.detonate == detonate &&
      other.ghost == ghost &&
      other.shield == shield &&
      other.enemies == enemies &&
      listEquals(other.alive, alive);

  @override
  int get hashCode => Object.hash(lives, score, seconds, level, maxBombs, range,
      speed, kick, detonate, ghost, shield, enemies, Object.hashAll(alive));
}
