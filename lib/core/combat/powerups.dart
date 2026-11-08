import 'dart:math';

/// Collectable upgrade types.
enum PowerUpType {
  /// +1 simultaneous bomb.
  bomb,

  /// +1 blast range.
  range,

  /// Faster movement.
  speed,

  /// Temporary shield.
  shield,

  /// Lets the player kick bombs.
  kick,

  /// Remote detonation of own bombs.
  detonator,

  /// Walk through breakable crates for a while.
  ghost,
}

/// Relative drop weights, same order as [PowerUpType.values].
const List<int> _weights = [25, 25, 20, 15, 15, 8, 10];

/// Chance that a destroyed block drops a power-up.
const double powerUpDropChance = 0.30;

/// Rolls a drop for a destroyed block; returns null for "no drop".
PowerUpType? rollPowerUp(Random rng, {double chance = powerUpDropChance}) {
  if (rng.nextDouble() >= chance) return null;
  final total = _weights.reduce((a, b) => a + b);
  var r = rng.nextInt(total);
  for (var i = 0; i < _weights.length; i++) {
    r -= _weights[i];
    if (r < 0) return PowerUpType.values[i];
  }
  return PowerUpType.bomb;
}

/// Mutable upgrade state of a player.
class PlayerStats {
  /// Base values.
  PlayerStats();

  /// Max simultaneous bombs.
  int maxBombs = 1;

  /// Blast range in cells.
  int range = 2;

  /// Movement speed in cells per second.
  double speed = 3.6;

  /// Whether bombs can be kicked.
  bool canKick = false;

  /// Whether own bombs can be detonated on demand.
  bool canDetonate = false;

  /// Remaining ghost seconds (walk through crates).
  double ghost = 0;

  /// Remaining shield seconds.
  double shield = 0;

  /// Caps.
  static const int bombCap = 6;

  /// Range cap.
  static const int rangeCap = 8;

  /// Speed cap.
  static const double speedCap = 5.6;

  /// Speed gained per pickup.
  static const double speedStep = 0.5;

  /// Shield duration in seconds.
  static const double shieldDuration = 8;

  /// Ghost duration in seconds.
  static const double ghostDuration = 8;

  /// Applies a pick-up.
  void apply(PowerUpType t) {
    switch (t) {
      case PowerUpType.bomb:
        maxBombs = min(bombCap, maxBombs + 1);
      case PowerUpType.range:
        range = min(rangeCap, range + 1);
      case PowerUpType.speed:
        speed = min(speedCap, speed + speedStep);
      case PowerUpType.shield:
        shield = shieldDuration;
      case PowerUpType.kick:
        canKick = true;
      case PowerUpType.detonator:
        canDetonate = true;
      case PowerUpType.ghost:
        ghost = ghostDuration;
    }
  }
}
