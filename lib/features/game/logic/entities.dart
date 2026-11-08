import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';

/// Cosmetic look of a buddy (hat, face, optional body colour as ARGB).
class Skin {
  /// Creates a skin; the default is the plain buddy in its slot colour.
  const Skin({this.hat = 0, this.face = 0, this.color});

  /// Hat index (0 = none), see `Cosmetics.hats`.
  final int hat;

  /// Face index, see `Cosmetics.faces`.
  final int face;

  /// Body colour override (ARGB), null = slot colour.
  final int? color;

  @override
  bool operator ==(Object other) =>
      other is Skin && other.hat == hat && other.face == face && other.color == color;

  @override
  int get hashCode => Object.hash(hat, face, color);
}

/// A player-controlled or bot-controlled buddy.
class Player {
  /// Creates a player at the centre of [spawn].
  Player({
    required this.id,
    required this.spawn,
    this.isBot = false,
    this.lives = 3,
    int? teamId,
  })  : teamId = teamId ?? id,
        x = spawn.x + 0.5,
        y = spawn.y + 0.5;

  /// Index (0..3).
  final int id;

  /// Team; players sharing a team win together. Defaults to [id] (free-for-all).
  final int teamId;

  /// Respawn cell.
  final GridPos spawn;

  /// Bot controlled.
  final bool isBot;

  /// Centre X in cell units (cell c spans [c, c+1)).
  double x;

  /// Centre Y in cell units.
  double y;

  /// Remaining lives.
  int lives;

  /// Score.
  int score = 0;

  /// False once out of lives.
  bool alive = true;

  /// Upgrade state.
  final PlayerStats stats = PlayerStats();

  /// Seconds of post-hit invulnerability left.
  double invuln = 0;

  /// Bombs currently on the field.
  int activeBombs = 0;

  /// Requested movement (set by input or bot).
  Dir moveDir = Dir.none;

  /// Last non-none movement direction (for drawing).
  Dir facing = Dir.down;

  /// Set by input; consumed by the world.
  bool bombRequested = false;

  /// Set by input: detonate own bombs (needs the detonator power-up).
  bool detonateRequested = false;

  /// Cosmetics.
  Skin skin = const Skin();

  /// Cell holding the player's centre.
  GridPos get cell => GridPos(x.floor(), y.floor());

  /// Whether damage is currently ignored.
  bool get protectedNow => stats.shield > 0 || invuln > 0;
}

/// A placed bomb.
class Bomb {
  /// Creates a bomb.
  Bomb({
    required this.col,
    required this.row,
    required this.range,
    required this.ownerId,
    required this.passIds,
    this.fuse = bombFuse,
  });

  /// Seconds until detonation.
  static const double bombFuse = 3;

  /// Cell column (destination cell while sliding).
  int col;

  /// Cell row.
  int row;

  /// Blast range.
  final int range;

  /// Owning player.
  final int ownerId;

  /// Actors that may still walk through this bomb (they stood on it).
  final Set<int> passIds;

  /// Remaining fuse.
  double fuse;

  /// Slide direction after a kick.
  Dir slideDir = Dir.none;

  /// Slide progress 0..1 towards ([col],[row]).
  double slideProgress = 0;

  /// Render X (cell units, top-left).
  double get drawX => slideDir == Dir.none ? col.toDouble() : col - slideDir.dx * (1 - slideProgress);

  /// Render Y.
  double get drawY => slideDir == Dir.none ? row.toDouble() : row - slideDir.dy * (1 - slideProgress);

  /// Occupied cell.
  GridPos get cell => GridPos(col, row);
}

/// Enemy behaviour types.
enum EnemyType {
  /// Wanders randomly.
  wanderer,

  /// Chases the nearest player using BFS.
  chaser,

  /// Wanders quickly.
  speedster,

  /// Big chaser that takes several hits (every 25th story level).
  boss,
}

/// A hostile roaming robot.
class Enemy {
  /// Creates an enemy at the centre of [cell].
  Enemy({required this.type, required GridPos cell, required this.speed, this.hp = 1})
      : maxHp = hp,
        x = cell.x + 0.5,
        y = cell.y + 0.5,
        tx = cell.x,
        ty = cell.y,
        fromX = cell.x,
        fromY = cell.y;

  /// Behaviour.
  final EnemyType type;

  /// Cells per second.
  final double speed;

  /// Centre X.
  double x;

  /// Centre Y.
  double y;

  /// Target cell.
  int tx;

  /// Target cell row.
  int ty;

  /// Cell last departed from.
  int fromX;

  /// Row last departed from.
  int fromY;

  /// Heading used to prefer straight walking.
  Dir dir = Dir.none;

  /// Hits left before dying.
  int hp;

  /// Hits at spawn.
  final int maxHp;

  /// Seconds during which flames don't hurt it again (bosses).
  double hitCooldown = 0;

  /// Alive flag.
  bool alive = true;

  /// Score awarded when killed.
  int get points => switch (type) {
        EnemyType.wanderer => 100,
        EnemyType.chaser => 200,
        EnemyType.speedster => 150,
        EnemyType.boss => 1000,
      };
}
