import 'dart:math';

import 'package:blast_buddies/core/ai/pathfinding.dart';
import 'package:blast_buddies/core/combat/blast.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';

/// How clever and fast battle bots are.
enum BotLevel {
  /// Slow, hesitant, sometimes walks into danger.
  easy(speed: 3.0, thinkEvery: 0.30, bombChance: 0.35, blunder: 0.25),

  /// The default.
  normal(speed: 3.6, thinkEvery: 0.12, bombChance: 0.7, blunder: 0),

  /// Quick, relentless, rarely wastes a bomb.
  hard(speed: 4.0, thinkEvery: 0.07, bombChance: 0.95, blunder: 0);

  const BotLevel({
    required this.speed,
    required this.thinkEvery,
    required this.bombChance,
    required this.blunder,
  });

  /// Movement speed (cells/s).
  final double speed;

  /// Seconds between decisions.
  final double thinkEvery;

  /// Chance to drop a bomb on a useful spot.
  final double bombChance;

  /// Chance per decision to ignore a nearby blast.
  final double blunder;
}

/// Simple battle-mode bot: flees danger, bombs blocks/opponents when it has
/// an escape route, otherwise walks towards a useful bombing spot.
class BotBrain {
  /// Creates a brain using [_rng] for tie breaking.
  BotBrain(this._rng, [this.level = BotLevel.normal]);

  /// Skill.
  final BotLevel level;

  final Random _rng;
  double _cooldown = 0;
  Dir _dir = Dir.none;

  /// Updates [p]'s movement request and bomb request.
  void update(GameWorld w, Player p, double dt) {
    _cooldown -= dt;
    if (_cooldown <= 0) {
      _cooldown = level.thinkEvery;
      _think(w, p);
    }
    p.moveDir = _aligned(p, _dir);
  }

  bool _useful(GameWorld w, Player p, GridPos c) {
    for (final d in Dir.cardinals) {
      for (var i = 1; i <= p.stats.range; i++) {
        final n = c.step(d, i);
        final t = w.grid.typeAt(n.x, n.y);
        if (t == CellType.wall) break;
        if (t == CellType.block) return true;
        if (w.players.any((o) => o.alive && o.teamId != p.teamId && o.cell == n)) {
          return true;
        }
      }
    }
    return false;
  }

  void _think(GameWorld w, Player p) {
    final danger = w.dangerMap();
    bool isDanger(GridPos c) =>
        w.grid.inBounds(c.x, c.y) && danger[c.y * GridModel.cols + c.x];
    final cell = p.cell;

    if (isDanger(cell) && !(level.blunder > 0 && _rng.nextDouble() < level.blunder)) {
      final path = bfsPath(cell, (c) => !isDanger(c), (c) => w.walkable(c.x, c.y),
          maxDepth: 8);
      _dir = path != null && path.isNotEmpty ? dirBetween(cell, path.first) : Dir.none;
      return;
    }

    final canPlace = p.activeBombs < p.stats.maxBombs && w.bombAt(cell.x, cell.y) == null;
    if (canPlace && _useful(w, p, cell) && _rng.nextDouble() < level.bombChance) {
      final escape = _escapeFrom(w, p, cell, isDanger);
      if (escape != null) {
        p.bombRequested = true;
        _dir = dirBetween(cell, escape.first);
        return;
      }
    }

    // Only target spots that can be bombed safely; a useful spot without an
    // escape route (e.g. a boxed-in spawn corner) would freeze the bot.
    final path = bfsPath(
      cell,
      (c) => _useful(w, p, c) && _escapeFrom(w, p, c, isDanger) != null,
      (c) => w.walkable(c.x, c.y) && !isDanger(c),
      maxDepth: 20,
    );
    if (path != null && path.isNotEmpty) {
      _dir = dirBetween(cell, path.first);
      return;
    }
    if (path != null && canPlace) {
      _dir = Dir.none; // waiting at a bombing spot
      return;
    }
    final free = Dir.cardinals.where((d) {
      final n = cell.step(d);
      return w.walkable(n.x, n.y) && !isDanger(n);
    }).toList();
    if (free.contains(_dir) && _rng.nextDouble() < 0.8) return;
    _dir = free.isEmpty ? Dir.none : free[_rng.nextInt(free.length)];
  }

  /// Escape path (non-empty) from a bomb placed at [c], or null if none.
  List<GridPos>? _escapeFrom(
    GameWorld w,
    Player p,
    GridPos c,
    bool Function(GridPos) isDanger,
  ) {
    final blast = computeBlast(w.grid, c, p.stats.range).cells.toSet();
    final escape = bfsPath(
      c,
      (e) => !blast.contains(e),
      (e) => w.walkable(e.x, e.y) && !isDanger(e),
      maxDepth: 6,
    );
    return escape == null || escape.isEmpty ? null : escape;
  }

  /// Centres the bot on its lane before turning, so corners are cleared.
  Dir _aligned(Player p, Dir d) {
    if (d == Dir.none) return d;
    final cx = p.cell.x + .5, cy = p.cell.y + .5;
    if (d.dx != 0) {
      final off = cy - p.y;
      if (off.abs() > 0.12) return off > 0 ? Dir.down : Dir.up;
    } else {
      final off = cx - p.x;
      if (off.abs() > 0.12) return off > 0 ? Dir.right : Dir.left;
    }
    return d;
  }
}
