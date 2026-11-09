import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';

/// The lessons of the tutorial, in order.
enum TutorialStep {
  /// Walk to the glowing spot.
  move,

  /// Drop a bomb next to the crate.
  bomb,

  /// Get away before it explodes.
  escape,

  /// Pick up what the crate hid.
  powerUp,

  /// Blow up a wandering enemy.
  enemy,

  /// All done.
  done,
}

/// A tiny arena and the rules that move the player from lesson to lesson.
///
/// Pure Dart (no widgets) so it can be tested by simply driving the world.
class TutorialFlow {
  /// Builds the arena and starts at [TutorialStep.move].
  TutorialFlow({Skin skin = const Skin()}) : world = _buildWorld(skin);

  /// The practice arena.
  final GameWorld world;

  /// Current lesson.
  TutorialStep step = TutorialStep.move;

  /// The last bomb missed the crate, so the lesson is repeated.
  bool tooFar = false;

  bool _exploded = false;

  /// Where the player starts.
  static const start = GridPos(1, 1);

  /// Step 1: the glowing spot to walk to.
  static const target = GridPos(5, 1);

  /// Step 2: the cell right next to the crate.
  static const stand = GridPos(6, 1);

  /// The crate that has to be blown up.
  static const crate = GridPos(7, 1);

  /// Where the practice enemy appears.
  static const enemyStart = GridPos(11, 1);

  /// Number of lessons before [TutorialStep.done].
  static int get lessons => TutorialStep.done.index;

  static GameWorld _buildWorld(Skin skin) {
    final grid = GridModel();
    for (var y = 0; y < GridModel.rows; y++) {
      for (var x = 0; x < GridModel.cols; x++) {
        if (GridModel.isFixedWall(x, y)) grid.setType(x, y, CellType.wall);
      }
    }
    // The lesson crate, plus a few more for the look of the arena. The
    // corridor from the start to the crate and to the enemy stays clear.
    for (final c in [crate, const GridPos(3, 3), const GridPos(7, 3), const GridPos(9, 3), const GridPos(1, 5), const GridPos(5, 5), const GridPos(9, 5), const GridPos(11, 5), const GridPos(3, 7), const GridPos(7, 7), const GridPos(11, 7), const GridPos(5, 9)]) {
      grid.setType(c.x, c.y, CellType.block);
    }
    return GameWorld.custom(
      grid: grid,
      players: [Player(id: 0, spawn: start, lives: 99)..skin = skin],
      timeLeft: 99999,
    );
  }

  /// The cell the pulsing ring should mark, if any.
  GridPos? get marker => switch (step) {
        TutorialStep.move => target,
        TutorialStep.bomb => stand,
        TutorialStep.powerUp => crate,
        _ => null,
      };

  /// Feed every simulation event here.
  void handle(GameEvent e) {
    switch (step) {
      case TutorialStep.bomb:
        if (e.type == GameEventType.bombPlaced && e.id == 0) {
          step = TutorialStep.escape;
          tooFar = false;
          _exploded = false;
        }
      case TutorialStep.escape:
        if (e.type == GameEventType.explosion) _exploded = true;
      case TutorialStep.powerUp:
        if (e.type == GameEventType.powerUp) {
          step = TutorialStep.enemy;
          world.enemies.add(Enemy(
            type: EnemyType.wanderer,
            cell: enemyStart,
            speed: GameWorld.baseEnemySpeed(EnemyType.wanderer) * .7,
          ));
        }
      case TutorialStep.enemy:
        if (e.type == GameEventType.enemyKilled) step = TutorialStep.done;
      case TutorialStep.move:
      case TutorialStep.done:
        break;
    }
  }

  bool get _crateGone => world.grid.typeAt(crate.x, crate.y) == CellType.empty;

  bool get _crateCellBurning => world.flameTime[crate.y * GridModel.cols + crate.x] > 0;

  /// Call every frame.
  void update() {
    switch (step) {
      case TutorialStep.move:
        if (world.players.first.cell == target) step = TutorialStep.bomb;
      case TutorialStep.escape:
        if (_exploded && world.bombs.isEmpty) {
          _exploded = false;
          if (_crateGone) {
            step = TutorialStep.powerUp;
          } else {
            // The bomb went off too far away: try again.
            step = TutorialStep.bomb;
            tooFar = true;
          }
        }
      case TutorialStep.powerUp:
        // The crate always hides a power-up here (the arena's random drops would
        // sometimes leave nothing to pick up). Wait for the flames to die down.
        if (!world.powerUps.containsKey(crate) && !_crateCellBurning) {
          world.powerUps[crate] = PowerUpType.range;
        }
      case TutorialStep.bomb:
      case TutorialStep.enemy:
      case TutorialStep.done:
        break;
    }
  }
}
