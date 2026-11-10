import 'dart:math';

import 'package:blast_buddies/core/ai/pathfinding.dart';
import 'package:blast_buddies/core/combat/blast.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';

/// How clever and fast battle bots are. The three levels differ in speed,
/// reaction time, aggression and how well they plan, so each one feels
/// clearly different (none of them kills itself on purpose).
enum BotLevel {
  /// Slow, hesitant and passive: it blasts crates, wanders, stands still now
  /// and then, and never hunts the player. Easy to outrun and outplay.
  easy(
    speed: 2.7,
    thinkEvery: 0.45,
    bombChance: 0.30,
    hunt: 0.25,
    idleChance: 0.30,
    escapeSlack: 0.55,
    pickups: 0,
  ),

  /// A fair opponent: decent speed, goes for crates and for the player when
  /// the chance is there, grabs nearby power-ups.
  normal(
    speed: 3.5,
    thinkEvery: 0.16,
    bombChance: 0.75,
    hunt: 0.5,
    idleChance: 0.04,
    escapeSlack: 0.75,
    pickups: 5,
  ),

  /// Fast and relentless: hunts the player, traps them in corridors, plans
  /// escape routes with a safety margin and chases power-ups.
  hard(
    speed: 4.0,
    thinkEvery: 0.07,
    bombChance: 1.0,
    hunt: 1.0,
    idleChance: 0.0,
    escapeSlack: 0.95,
    pickups: 9,
  );

  const BotLevel({
    required this.speed,
    required this.thinkEvery,
    required this.bombChance,
    required this.hunt,
    required this.idleChance,
    required this.escapeSlack,
    required this.pickups,
  });

  /// Movement speed (cells/s).
  final double speed;

  /// Seconds between decisions.
  final double thinkEvery;

  /// Chance to drop a bomb on a useful spot.
  final double bombChance;

  /// 0..1: how much it prefers going after players over blasting crates.
  final double hunt;

  /// Chance per decision to just stand still for a moment.
  final double idleChance;

  /// 0..1: how much of the fuse the escape route may use (low = it needs a
  /// short, obvious way out, high = it dares tight escapes).
  final double escapeSlack;

  /// How many steps away it notices power-ups (0 = ignores them).
  final int pickups;
}

/// When each cell is deadly: flames that burn now and the blasts of every
/// bomb on the board (a bomb inside another blast goes off earlier, chain
/// reaction). Optionally includes a bomb that is about to be placed.
class _Hazard {
  _Hazard(GameWorld w, {GridPos? bombAt, int range = 0}) {
    for (var i = 0; i < w.flameTime.length; i++) {
      if (w.flameTime[i] > 0) _add(i, 0, w.flameTime[i]);
    }
    final bombs = <(GridPos, int, double)>[
      for (final b in w.bombs) (b.cell, b.range, b.fuse),
      if (bombAt != null) (bombAt, range, Bomb.bombFuse),
    ];
    final blasts = [for (final b in bombs) computeBlast(w.grid, b.$1, b.$2).cells];
    // Effective fuse: a bomb caught in an earlier blast explodes with it.
    final fuse = [for (final b in bombs) b.$3];
    for (var round = 0; round < bombs.length; round++) {
      var changed = false;
      for (var i = 0; i < bombs.length; i++) {
        for (var j = 0; j < bombs.length; j++) {
          if (i != j && fuse[i] < fuse[j] && blasts[i].contains(bombs[j].$1)) {
            fuse[j] = fuse[i];
            changed = true;
          }
        }
      }
      if (!changed) break;
    }
    for (var i = 0; i < bombs.length; i++) {
      for (final c in blasts[i]) {
        _add(c.y * GridModel.cols + c.x, fuse[i], fuse[i] + GameWorld.flameDuration);
      }
    }
  }

  final List<double> _start = List.filled(GridModel.cols * GridModel.rows, double.infinity);
  final List<double> _end = List.filled(GridModel.cols * GridModel.rows, 0);

  void _add(int i, double s, double e) {
    if (s < _start[i]) _start[i] = s;
    if (e > _end[i]) _end[i] = e;
  }

  int _i(GridPos c) => c.y * GridModel.cols + c.x;

  /// Whether the cell is touched by any blast or flame at some point.
  bool any(GridPos c) => _inBounds(c) && _start[_i(c)] < double.infinity;

  /// Seconds until [c] first burns (0 = burning now, infinity = never).
  double firstDanger(GridPos c) => _inBounds(c) ? _start[_i(c)] : 0;

  /// Whether standing in [c] at any moment between [from] and [to] seconds
  /// from now would burn (with a small safety margin around the window). A
  /// player is hurt as soon as their centre is in a burning cell, so the bot
  /// occupies a cell from when it crosses its border until it leaves again.
  bool deadlyBetween(GridPos c, double from, double to) {
    if (!_inBounds(c)) return true;
    final i = _i(c);
    return to >= _start[i] - 0.15 && from <= _end[i] + 0.1;
  }

  static bool _inBounds(GridPos c) => c.x >= 0 && c.y >= 0 && c.x < GridModel.cols && c.y < GridModel.rows;
}

/// Battle-mode bot: flees danger (including chain reactions), bombs crates
/// and opponents only when a safe, reachable escape exists, collects
/// power-ups and hunts opponents according to its [BotLevel].
class BotBrain {
  /// Creates a brain using [_rng] for tie breaking.
  BotBrain(this._rng, [this.level = BotLevel.normal]) {
    // Bots do not all act on the very first frame: dropping bombs at the same
    // instant would trap neighbours in each other's blasts before anyone has
    // seen the others' bombs.
    _cooldown = 0.15 + _rng.nextDouble() * (0.3 + level.thinkEvery * 3);
  }

  /// Skill.
  final BotLevel level;

  final Random _rng;
  double _cooldown = 0;
  Dir _dir = Dir.none;

  /// The adjacent cell the bot is walking to. It stops in the middle of it and
  /// decides again, so it never coasts into a cell it has not checked.
  GridPos? _target;

  /// How long the current step has taken (a blocked bot gives up and re-plans).
  double _stepAge = 0;

  /// A bomb wanted at the next centred moment.
  bool _wantBomb = false;

  /// Updates [p]'s movement request and bomb request.
  void update(GameWorld w, Player p, double dt) {
    _cooldown -= dt;
    _stepAge += dt;
    if (_target != null && _stepAge > 0.9) _target = null;
    final target = _target;
    if (target != null && _arrived(p, target)) {
      _target = null;
      _dir = Dir.none;
      // A short hesitation at every cell centre: none for hard bots, a clear
      // beat for easy ones.
      if (_cooldown > level.thinkEvery * 0.35) _cooldown = level.thinkEvery * 0.35;
    }
    if (_cooldown <= 0) {
      _cooldown = level.thinkEvery;
      _think(w, p);
    }
    // Bombs go down only while standing in the middle of a cell: the world
    // places a bomb in the cell the player occupies after this tick's move,
    // so a bot that is drifting across a boundary would drop it somewhere
    // other than where it checked the escape route.
    if (_wantBomb && p.activeBombs < p.stats.maxBombs) {
      if (_centred(p)) {
        p.bombRequested = true;
        _wantBomb = false;
        _cooldown = 0; // run for it next tick
        p.moveDir = Dir.none;
      } else {
        p.moveDir = _towardCentre(p);
      }
      return;
    }
    p.moveDir = _aligned(p, _dir);
  }

  /// Direction that brings [p] to the middle of its cell.
  Dir _towardCentre(Player p) {
    final dx = p.cell.x + .5 - p.x, dy = p.cell.y + .5 - p.y;
    if (dx.abs() >= dy.abs()) return dx > 0 ? Dir.right : Dir.left;
    return dy > 0 ? Dir.down : Dir.up;
  }

  /// Whether [p] has reached (or passed) the middle of [target] while walking
  /// in [_dir].
  bool _arrived(Player p, GridPos target) {
    final tx = target.x + .5, ty = target.y + .5;
    if (_dir.dx != 0) return (p.x - tx) * _dir.dx >= -0.05;
    if (_dir.dy != 0) return (p.y - ty) * _dir.dy >= -0.05;
    return true;
  }

  /// Walks to the adjacent cell [next] (or stands still when it is [Dir.none]).
  void _step(GridPos from, GridPos next) {
    _dir = dirBetween(from, next);
    _target = _dir == Dir.none ? null : next;
    _stepAge = 0;
  }

  bool _centred(Player p) => (p.x - (p.cell.x + .5)).abs() < 0.14 && (p.y - (p.cell.y + .5)).abs() < 0.14;

  bool _opponentAt(GameWorld w, Player p, GridPos c) =>
      w.players.any((o) => o.alive && o.teamId != p.teamId && o.cell == c);

  /// Whether a bomb at [c] would hit a crate (and, if [opponents], a player).
  bool _useful(GameWorld w, Player p, GridPos c, {required bool crates, required bool opponents}) {
    for (final d in Dir.cardinals) {
      for (var i = 1; i <= p.stats.range; i++) {
        final n = c.step(d, i);
        final t = w.grid.typeAt(n.x, n.y);
        if (t == CellType.wall) break;
        if (t == CellType.block) {
          if (crates) return true;
          break;
        }
        if (opponents && _opponentAt(w, p, n)) return true;
      }
    }
    return false;
  }

  void _think(GameWorld w, Player p) {
    _wantBomb = false;
    final hz = _Hazard(w);
    bool isDanger(GridPos c) => hz.any(c);
    final cell = p.cell;

    // Finish the step that is under way unless it has become deadly: changing
    // one's mind in the middle of a cell is how bots dithered into flames.
    final under = _target;
    if (under != null && w.walkable(under.x, under.y)) {
      final dist = (_dir.dx != 0 ? (p.x - (under.x + .5)).abs() : (p.y - (under.y + .5)).abs());
      final v = 1 / p.stats.speed;
      if (!hz.deadlyBetween(under, max(0.0, dist - 0.5) * v, (dist + 0.5) * v)) return;
    }

    // 1. Get out of any blast zone first, along a route that is not on fire
    //    by the time the bot gets there.
    if (isDanger(cell)) {
      var path = _route(w, p, cell, (c) => !hz.any(c), (c, a, b) => !hz.deadlyBetween(c, a, b), maxDepth: 10);
      if (path == null) {
        // No clean route right now (flames in the way). If the blast is still
        // some time off, wait for the flames to die down instead of running
        // through them; otherwise take any way out.
        if (hz.firstDanger(cell) > 0.9) {
          _dir = Dir.none;
          _target = null;
          return;
        }
        path = bfsPath(cell, (c) => !hz.any(c), (c) => w.walkable(c.x, c.y), maxDepth: 10);
      }
      if (path != null && path.isNotEmpty) {
        _step(cell, path.first);
      } else {
        _dir = Dir.none;
        _target = null;
      }
      return;
    }

    // Easy bots hesitate: they stand around for a moment now and then.
    if (level.idleChance > 0 && _rng.nextDouble() < level.idleChance) {
      _dir = Dir.none;
      _target = null;
      return;
    }

    final canPlace = p.activeBombs < p.stats.maxBombs && w.bombAt(cell.x, cell.y) == null;
    final huntOpponents = level.hunt > 0;

    // 2. Drop a bomb here if it hurts something and there is a safe way out.
    if (canPlace && _rng.nextDouble() < level.bombChance) {
      // Aggressive bots also put pressure on a player who is close, even when
      // the blast would not reach them yet: it cuts off their escape routes.
      final pressure = huntOpponents &&
          _rng.nextDouble() < level.hunt * 0.55 &&
          w.players.any((o) => o.alive && o.teamId != p.teamId && (o.cell.x - cell.x).abs() + (o.cell.y - cell.y).abs() <= 3);
      final hitsOpponent = pressure || (huntOpponents && _useful(w, p, cell, crates: false, opponents: true));
      final hitsCrate = _useful(w, p, cell, crates: true, opponents: false);
      if ((hitsOpponent || hitsCrate) && _escapeFrom(w, p, cell) != null) {
        // Stand still on the cell; the bomb goes down once centred, then the
        // flee logic above takes over.
        _wantBomb = true;
        _dir = Dir.none;
        _target = null;
        return;
      }
    }

    // 3. Power-ups close by.
    if (level.pickups > 0 && w.powerUps.isNotEmpty) {
      final path = bfsPath(
        cell,
        (c) => w.powerUps.containsKey(c),
        (c) => w.walkable(c.x, c.y) && !isDanger(c),
        maxDepth: level.pickups,
      );
      if (path != null && path.isNotEmpty) {
        _step(cell, path.first);
        return;
      }
    }

    // 4. Head for a spot that can be bombed safely: players first for
    //    aggressive bots, crates otherwise.
    final preferHunt = huntOpponents && _rng.nextDouble() < level.hunt;
    List<GridPos>? path;
    if (preferHunt) path = _pathToSpot(w, p, isDanger, crates: false, opponents: true);
    path ??= _pathToSpot(w, p, isDanger, crates: true, opponents: false);
    if (path == null && huntOpponents && !preferHunt) {
      path = _pathToSpot(w, p, isDanger, crates: false, opponents: true);
    }
    if (path != null && path.isNotEmpty) {
      _step(cell, path.first);
      return;
    }
    if (path != null && canPlace) {
      _dir = Dir.none; // standing on a bombing spot, waiting for the dice
      _target = null;
      return;
    }

    // 5. Chase the nearest opponent when there is nothing to blast.
    if (huntOpponents) {
      final chase = bfsPath(
        cell,
        (c) => _opponentAt(w, p, c),
        (c) => w.walkable(c.x, c.y) && !isDanger(c),
        maxDepth: 24,
      );
      if (chase != null && chase.length > 1) {
        _step(cell, chase.first);
        return;
      }
    }

    final free = Dir.cardinals.where((d) {
      final n = cell.step(d);
      return w.walkable(n.x, n.y) && !isDanger(n);
    }).toList();
    final pick = free.contains(_dir) && _rng.nextDouble() < 0.8 ? _dir : (free.isEmpty ? Dir.none : free[_rng.nextInt(free.length)]);
    if (pick == Dir.none) {
      _dir = Dir.none;
      _target = null;
    } else {
      _step(cell, cell.step(pick));
    }
  }

  List<GridPos>? _pathToSpot(
    GameWorld w,
    Player p,
    bool Function(GridPos) isDanger, {
    required bool crates,
    required bool opponents,
  }) =>
      bfsPath(
        p.cell,
        (c) => _useful(w, p, c, crates: crates, opponents: opponents) && _escapeFrom(w, p, c) != null,
        (c) => w.walkable(c.x, c.y) && !isDanger(c),
        maxDepth: 20,
      );

  /// A way out (non-empty path) from a bomb placed at [c]: every step is off
  /// the blasts and flames by the time the bot gets there, it ends outside all
  /// of them and fits the level's idea of a comfortable escape; null if there
  /// is none.
  List<GridPos>? _escapeFrom(GameWorld w, Player p, GridPos c) {
    final hz = _Hazard(w, bombAt: c, range: p.stats.range);
    final escape = _route(w, p, c, (e) => !hz.any(e), (e, a, b) => !hz.deadlyBetween(e, a, b), maxDepth: 8);
    if (escape == null || escape.isEmpty) return null;
    final seconds = (escape.length + 0.5) * (1 / p.stats.speed + level.thinkEvery * 0.35);
    if (seconds > Bomb.bombFuse * level.escapeSlack) return null;
    return escape;
  }

  /// Breadth-first route from [start] (exclusive) to the nearest goal cell.
  /// A step into cell [n] is allowed when [ok] holds for the time the bot
  /// would reach it (steps / speed) and the cell is walkable.
  List<GridPos>? _route(
    GameWorld w,
    Player p,
    GridPos start,
    bool Function(GridPos) isGoal,
    bool Function(GridPos, double, double) ok, {
    int maxDepth = 10,
  }) {
    if (isGoal(start)) return const [];
    // Seconds to cross one cell, and the short pause at every cell centre
    // (slow-reacting bots lose time there).
    final v = 1 / p.stats.speed;
    final h = level.thinkEvery * 0.35;
    final prev = <GridPos, GridPos>{};
    final depth = <GridPos, int>{start: 0};
    final queue = <GridPos>[start];
    for (var head = 0; head < queue.length; head++) {
      final cur = queue[head];
      final d = depth[cur]!;
      if (d >= maxDepth) continue;
      for (final dir in Dir.cardinals) {
        final n = cur.step(dir);
        if (depth.containsKey(n) || !w.walkable(n.x, n.y)) continue;
        final k = d + 1;
        // In the cell from crossing its border (half a cell before the centre)
        // until the centre has crossed the far border.
        final enter = (k - 0.5) * v + (k - 1) * h;
        final leave = (k + 0.5) * v + k * h;
        if (!ok(n, enter, leave)) continue;
        depth[n] = d + 1;
        prev[n] = cur;
        if (isGoal(n)) {
          final path = <GridPos>[n];
          var c = n;
          while (prev[c] != start) {
            c = prev[c]!;
            path.add(c);
          }
          return path.reversed.toList();
        }
        queue.add(n);
      }
    }
    return null;
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
