import 'dart:math';

import 'package:blast_buddies/core/ai/pathfinding.dart';
import 'package:blast_buddies/core/combat/blast.dart';
import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/core/grid/map_generator.dart';
import 'package:blast_buddies/features/game/logic/bot_brain.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';

/// Things the presentation layer reacts to (audio, haptics, particles).
enum GameEventType {
  /// A bomb was placed.
  bombPlaced,

  /// A bomb exploded.
  explosion,

  /// A breakable block was destroyed.
  blockDestroyed,

  /// A power-up was collected.
  powerUp,

  /// A player lost a life (or died).
  playerHit,

  /// An enemy died.
  enemyKilled,

  /// A bomb was kicked.
  bombKicked,

  /// The exit door opened.
  exitOpened,

  /// Story level cleared.
  levelComplete,

  /// Story lost or battle over.
  gameOver,
}

/// One emitted event.
class GameEvent {
  /// Creates an event at cell-space position ([x],[y]).
  const GameEvent(this.type, this.x, this.y, [this.id = -1]);

  /// Kind.
  final GameEventType type;

  /// X in cell units.
  final double x;

  /// Y in cell units.
  final double y;

  /// Related player id or power-up index.
  final int id;
}

/// Overall state of the simulation.
enum WorldStatus {
  /// Running.
  playing,

  /// Story: exit reached.
  levelComplete,

  /// Story: out of lives or time.
  gameOver,

  /// Battle finished (see [GameWorld.winnerId]).
  battleOver,
}

/// Deterministic, Flame-independent game simulation.
///
/// Cell `c` covers `[c, c+1)`; entity positions are cell-space centres.
class GameWorld {
  GameWorld._({
    required this.mode,
    required this.rng,
    required this.level,
    required this.timeLeft,
    required GeneratedMap map,
    required this.players,
    required this.enemies,
    this.teams = false,
  })  : grid = map.grid,
        exit = map.exit,
        themeId = map.theme,
        layout = map.layout {
    for (final p in players.where((p) => p.isBot)) {
      _brains[p.id] = BotBrain(Random(rng.nextInt(1 << 30)));
    }
  }

  /// Index into `MapTheme.all` used to colour this arena.
  final int themeId;

  /// Floor plan of this arena.
  final MapLayout layout;

  /// Creates a story-mode world. [carry] transfers lives/score/upgrades.
  factory GameWorld.story({required int level, int seed = 0, Player? carry}) {
    final rng = Random(seed);
    final cfg = LevelConfig.forLevel(level);
    final map = MapGenerator.generate(
      rng: rng,
      density: cfg.blockDensity,
      enemyCount: cfg.enemyCount,
      // A new colour world every 10 levels; every 5th level a new floor plan.
      theme: ((cfg.level - 1) ~/ 10) % MapGenerator.themeCount,
      layout: cfg.level % 5 == 0
          ? MapLayout.values[(cfg.level ~/ 5) % MapLayout.values.length]
          : MapLayout.classic,
    );
    final player = Player(id: 0, spawn: map.spawns.first);
    if (carry != null) {
      player.lives = carry.lives;
      player.score = carry.score;
      player.stats
        ..maxBombs = carry.stats.maxBombs
        ..range = carry.stats.range
        ..speed = carry.stats.speed
        ..canKick = carry.stats.canKick;
    }
    final types = <EnemyType>[
      for (final e in cfg.enemies.entries)
        for (var i = 0; i < e.value; i++) e.key,
    ];
    final enemies = <Enemy>[
      for (var i = 0; i < map.enemySpawns.length; i++)
        Enemy(
          type: types[i],
          cell: map.enemySpawns[i],
          speed: baseEnemySpeed(types[i]) * cfg.enemySpeedScale,
        ),
    ];
    return GameWorld._(
      mode: GameMode.story,
      rng: rng,
      level: cfg.level,
      timeLeft: cfg.timeLimit,
      map: map,
      players: [player],
      enemies: enemies,
    );
  }

  /// Creates a battle world with [humans] + [bots] players (2..4 total).
  ///
  /// With [teams] and 4 players, ids 0+2 (top corners) face 1+3 (bottom
  /// corners); see [teamOf].
  factory GameWorld.battle({
    required int humans,
    required int bots,
    int seed = 0,
    bool teams = false,
  }) {
    final total = (humans + bots).clamp(2, 4);
    final teamed = teams && total == 4;
    final rng = Random(seed);
    final style = MapGenerator.styleFor(seed);
    final map = MapGenerator.generate(
      rng: rng,
      density: 0.6,
      withExit: false,
      layout: style.$1,
      theme: style.$2,
    );
    final players = [
      for (var i = 0; i < total; i++)
        Player(
          id: i,
          spawn: map.spawns[i],
          isBot: i >= humans,
          lives: 1,
          teamId: teamed ? teamOf(i) : i,
        ),
    ];
    return GameWorld._(
      mode: GameMode.battle,
      rng: rng,
      level: 0,
      timeLeft: 180,
      map: map,
      players: players,
      enemies: [],
      teams: teamed,
    );
  }

  /// Team of player slot [id] in a 2v2 match.
  static int teamOf(int id) => id % 2;

  /// Creates a world from explicit parts (tests and custom scenarios).
  factory GameWorld.custom({
    required GridModel grid,
    required List<Player> players,
    List<Enemy> enemies = const [],
    GridPos? exit,
    GameMode mode = GameMode.story,
    int seed = 0,
    double timeLeft = 180,
    bool teams = false,
  }) {
    return GameWorld._(
      teams: teams,
      mode: mode,
      rng: Random(seed),
      level: 1,
      timeLeft: timeLeft,
      map: GeneratedMap(
        grid: grid,
        spawns: [for (final p in players) p.spawn],
        exit: exit,
        enemySpawns: const [],
      ),
      players: players,
      enemies: List.of(enemies),
    );
  }

  /// Enemy base speed in cells/second.
  static double baseEnemySpeed(EnemyType t) => switch (t) {
        EnemyType.wanderer => 1.6,
        EnemyType.chaser => 2.0,
        EnemyType.speedster => 3.2,
      };

  /// Half size of an actor's collision box.
  static const double half = 0.4;

  /// Seconds a flame stays.
  static const double flameDuration = 0.6;

  /// Bomb slide speed in cells/second.
  static const double slideSpeed = 8;

  /// Mode.
  final GameMode mode;

  /// Random source.
  final Random rng;

  /// Story level number (0 in battle).
  final int level;

  /// Battle is played in teams (2v2).
  final bool teams;

  /// Terrain.
  final GridModel grid;

  /// Players.
  final List<Player> players;

  /// Enemies.
  final List<Enemy> enemies;

  /// Live bombs.
  final List<Bomb> bombs = [];

  /// Visible power-ups.
  final Map<GridPos, PowerUpType> powerUps = {};

  /// Exit cell (story).
  final GridPos? exit;

  /// True once the exit block was destroyed.
  bool exitRevealed = false;

  /// True once all enemies are dead.
  bool exitOpen = false;

  /// Remaining seconds.
  double timeLeft;

  /// Seconds elapsed (for animation).
  double elapsed = 0;

  /// Simulation state.
  WorldStatus status = WorldStatus.playing;

  /// Battle winner id (null = draw). In team battles: a surviving member.
  int? winnerId;

  /// Battle winning team (null = draw). Equals [winnerId] in free-for-all.
  int? winnerTeam;

  /// Remaining flame time per cell (row-major).
  final List<double> flameTime = List.filled(GridModel.cols * GridModel.rows, 0);

  final List<int> _flameOwner = List.filled(GridModel.cols * GridModel.rows, 0);
  final List<GameEvent> _events = [];
  final Map<int, BotBrain> _brains = {};

  /// Queues [e] as if the simulation produced it (network clients).
  void emit(GameEvent e) => _events.add(e);

  /// Returns and clears pending events.
  List<GameEvent> drainEvents() {
    if (_events.isEmpty) return const [];
    final out = List<GameEvent>.of(_events);
    _events.clear();
    return out;
  }

  /// True if ([x],[y]) is burning.
  bool isBurning(int x, int y) =>
      grid.inBounds(x, y) && flameTime[y * GridModel.cols + x] > 0;

  /// Bomb occupying a cell, if any.
  Bomb? bombAt(int x, int y) {
    for (final b in bombs) {
      if (b.col == x && b.row == y) return b;
    }
    return null;
  }

  /// Sets the movement request of player [id].
  void setMove(int id, Dir d) {
    if (id < players.length) players[id].moveDir = d;
  }

  /// Requests a bomb placement for player [id].
  void requestBomb(int id) {
    if (id < players.length) players[id].bombRequested = true;
  }

  /// Advances the simulation by [dtRaw] seconds.
  void tick(double dtRaw) {
    if (status != WorldStatus.playing) return;
    final dt = min(dtRaw, 0.05);
    elapsed += dt;
    timeLeft -= dt;

    for (final p in players) {
      if (!p.alive) continue;
      if (p.isBot) _brains[p.id]!.update(this, p, dt);
      if (p.invuln > 0) p.invuln = max(0, p.invuln - dt);
      if (p.stats.shield > 0) p.stats.shield = max(0, p.stats.shield - dt);
      _movePlayer(p, dt);
      if (p.bombRequested) {
        p.bombRequested = false;
        _placeBomb(p);
      }
    }

    _updateBombs(dt);
    _updateFlames(dt);
    for (final e in enemies) {
      if (e.alive) _updateEnemy(e, dt);
    }
    _checkContacts();
    _checkEnd();
  }

  // ---------------------------------------------------------------- movement

  bool _solidOrBomb(int x, int y, int? passId) {
    if (grid.isSolid(x, y)) return true;
    final b = bombAt(x, y);
    return b != null && !(passId != null && b.passIds.contains(passId));
  }

  bool _boxBlocked(double x, double y, int id) {
    final x0 = (x - half).floor(), x1 = (x + half).floor();
    final y0 = (y - half).floor(), y1 = (y + half).floor();
    for (var cy = y0; cy <= y1; cy++) {
      for (var cx = x0; cx <= x1; cx++) {
        if (_solidOrBomb(cx, cy, id)) return true;
      }
    }
    return false;
  }

  /// Moves player [id] by its current `moveDir` for [dt] seconds without any
  /// side effects on other objects (no bomb kicks). Used by online clients to
  /// predict their own movement before the server confirms it.
  void predictMove(int id, double dt) {
    if (id >= players.length || !players[id].alive) return;
    _movePlayer(players[id], min(dt, 0.05), kick: false);
  }

  void _movePlayer(Player p, double dt, {bool kick = true}) {
    final d = p.moveDir;
    if (d == Dir.none) return;
    p.facing = d;
    final dist = p.stats.speed * dt;
    final nx = p.x + d.dx * dist, ny = p.y + d.dy * dist;
    if (!_boxBlocked(nx, ny, p.id)) {
      p.x = nx;
      p.y = ny;
      return;
    }
    // Move flush against the obstacle.
    var fx = p.x, fy = p.y;
    if (d.dx > 0) fx = (nx + half).floor() - half - 1e-4;
    if (d.dx < 0) fx = (nx - half).floor() + 1 + half + 1e-4;
    if (d.dy > 0) fy = (ny + half).floor() - half - 1e-4;
    if (d.dy < 0) fy = (ny - half).floor() + 1 + half + 1e-4;
    if ((fx - p.x) * d.dx >= 0 &&
        (fy - p.y) * d.dy >= 0 &&
        !_boxBlocked(fx, fy, p.id)) {
      p.x = fx;
      p.y = fy;
    }
    if (kick && p.stats.canKick) _tryKick(p, d);
    _slide(p, d, dist);
  }

  /// Corner assist: nudge towards a free lane perpendicular to [d].
  void _slide(Player p, Dir d, double dist) {
    final horizontal = d.dx != 0;
    final pos = horizontal ? p.y : p.x;
    final cx = p.x.floor(), cy = p.y.floor();
    final lanes = <int>{
      (pos - half).floor(),
      (pos + half).floor(),
      horizontal ? cy : cx,
    }.toList()
      ..sort((a, b) => (a + .5 - pos).abs().compareTo((b + .5 - pos).abs()));
    for (final lane in lanes) {
      final ax = horizontal ? cx : lane;
      final ay = horizontal ? lane : cy;
      if (_solidOrBomb(ax, ay, p.id) || _solidOrBomb(ax + d.dx, ay + d.dy, p.id)) {
        continue;
      }
      final diff = lane + 0.5 - pos;
      if (diff.abs() < 1e-6) return;
      final step = diff.sign * min(diff.abs(), dist);
      final tx = horizontal ? p.x : p.x + step;
      final ty = horizontal ? p.y + step : p.y;
      if (!_boxBlocked(tx, ty, p.id)) {
        p.x = tx;
        p.y = ty;
      }
      return;
    }
  }

  void _tryKick(Player p, Dir d) {
    final c = GridPos(p.x.floor() + d.dx, p.y.floor() + d.dy);
    final b = bombAt(c.x, c.y);
    if (b == null || b.slideDir != Dir.none || b.passIds.contains(p.id)) return;
    final off = d.dx != 0 ? p.y - (c.y + .5) : p.x - (c.x + .5);
    if (off.abs() > 0.3) return;
    final n = c.step(d);
    if (!_cellFreeForBomb(n)) return;
    b
      ..col = n.x
      ..row = n.y
      ..slideDir = d
      ..slideProgress = 0;
    _events.add(GameEvent(GameEventType.bombKicked, c.x + .5, c.y + .5));
  }

  bool _cellFreeForBomb(GridPos c) {
    if (grid.isSolid(c.x, c.y) || bombAt(c.x, c.y) != null) return false;
    if (players.any((p) => p.alive && p.cell == c)) return false;
    return !enemies.any((e) => e.alive && e.x.floor() == c.x && e.y.floor() == c.y);
  }

  // ------------------------------------------------------------------ bombs

  void _placeBomb(Player p) {
    final c = p.cell;
    if (p.activeBombs >= p.stats.maxBombs || bombAt(c.x, c.y) != null) return;
    if (grid.typeAt(c.x, c.y) != CellType.empty) return;
    final pass = <int>{
      for (final o in players)
        if (o.alive && _overlapsCell(o, c.x, c.y)) o.id,
    };
    bombs.add(Bomb(
      col: c.x,
      row: c.y,
      range: p.stats.range,
      ownerId: p.id,
      passIds: pass,
    ));
    p.activeBombs++;
    _events.add(GameEvent(GameEventType.bombPlaced, c.x + .5, c.y + .5, p.id));
  }

  bool _overlapsCell(Player p, int cx, int cy) =>
      (p.x - (cx + .5)).abs() < .5 + half && (p.y - (cy + .5)).abs() < .5 + half;

  void _updateBombs(double dt) {
    for (final b in bombs) {
      b.fuse -= dt;
      if (b.slideDir != Dir.none) {
        b.slideProgress += slideSpeed * dt;
        while (b.slideDir != Dir.none && b.slideProgress >= 1) {
          final n = b.cell.step(b.slideDir);
          if (_cellFreeForBomb(n)) {
            b
              ..col = n.x
              ..row = n.y
              ..slideProgress -= 1;
          } else {
            b
              ..slideDir = Dir.none
              ..slideProgress = 0;
          }
        }
      }
      b.passIds.removeWhere((id) => !_overlapsCell(players[id], b.col, b.row));
    }
    while (true) {
      final due = bombs.where((b) => b.fuse <= 0).toList();
      if (due.isEmpty) break;
      for (final b in due) {
        if (bombs.contains(b)) _explode(b);
      }
    }
  }

  void _explode(Bomb b) {
    bombs.remove(b);
    players[b.ownerId].activeBombs = max(0, players[b.ownerId].activeBombs - 1);
    final blast = computeBlast(grid, b.cell, b.range);
    for (final c in blast.cells) {
      final i = c.y * GridModel.cols + c.x;
      flameTime[i] = flameDuration;
      _flameOwner[i] = b.ownerId;
      powerUps.remove(c);
      final other = bombAt(c.x, c.y);
      if (other != null) other.fuse = 0;
    }
    for (final c in blast.destroyedBlocks) {
      grid.setType(c.x, c.y, CellType.empty);
      if (mode == GameMode.story) players[b.ownerId].score += 10;
      _events.add(GameEvent(GameEventType.blockDestroyed, c.x + .5, c.y + .5));
      if (c == exit) {
        exitRevealed = true;
      } else {
        final t = rollPowerUp(rng);
        if (t != null) powerUps[c] = t;
      }
    }
    _events.add(GameEvent(GameEventType.explosion, b.col + .5, b.row + .5));
  }

  void _updateFlames(double dt) {
    for (var i = 0; i < flameTime.length; i++) {
      if (flameTime[i] > 0) flameTime[i] = max(0, flameTime[i] - dt);
    }
    for (final p in players) {
      if (p.alive && isBurning(p.cell.x, p.cell.y)) _hurt(p);
    }
    for (final e in enemies) {
      if (!e.alive) continue;
      final cx = e.x.floor(), cy = e.y.floor();
      if (isBurning(cx, cy)) {
        e.alive = false;
        if (mode == GameMode.story) {
          players[_flameOwner[cy * GridModel.cols + cx]].score += e.points;
        }
        _events.add(GameEvent(GameEventType.enemyKilled, e.x, e.y));
      }
    }
  }

  void _hurt(Player p) {
    if (p.protectedNow) return;
    p.lives--;
    _events.add(GameEvent(GameEventType.playerHit, p.x, p.y, p.id));
    if (p.lives <= 0) {
      p.alive = false;
      return;
    }
    p
      ..x = p.spawn.x + .5
      ..y = p.spawn.y + .5
      ..invuln = 2.5;
    for (final b in bombs) {
      if (_overlapsCell(p, b.col, b.row)) b.passIds.add(p.id);
    }
  }

  // ---------------------------------------------------------------- enemies

  bool _enemyPassable(int x, int y) => !grid.isSolid(x, y) && bombAt(x, y) == null;

  void _updateEnemy(Enemy e, double dt) {
    final curX = e.x.floor(), curY = e.y.floor();
    if ((e.tx != curX || e.ty != curY) && !_enemyPassable(e.tx, e.ty)) {
      e
        ..tx = e.fromX
        ..ty = e.fromY;
    }
    var move = e.speed * dt;
    for (var guard = 0; move > 1e-9 && guard < 4; guard++) {
      final cx = e.tx + .5, cy = e.ty + .5;
      final dx = cx - e.x, dy = cy - e.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist <= move) {
        e
          ..x = cx
          ..y = cy;
        move -= dist;
        final before = GridPos(e.tx, e.ty);
        _enemyChoose(e);
        if (e.tx == before.x && e.ty == before.y) break;
      } else {
        e
          ..x += dx / dist * move
          ..y += dy / dist * move;
        move = 0;
      }
    }
  }

  void _enemyChoose(Enemy e) {
    final cur = GridPos(e.tx, e.ty);
    GridPos? next;
    if (e.type == EnemyType.chaser) {
      final targets = players.where((p) => p.alive).map((p) => p.cell).toSet();
      if (targets.isNotEmpty) {
        final path = bfsPath(
          cur,
          targets.contains,
          (c) => _enemyPassable(c.x, c.y),
          maxDepth: 14,
        );
        if (path != null && path.isNotEmpty) next = path.first;
      }
    }
    next ??= _wanderStep(e, cur);
    if (next == null) return;
    e
      ..fromX = cur.x
      ..fromY = cur.y
      ..tx = next.x
      ..ty = next.y
      ..dir = dirBetween(cur, next);
  }

  GridPos? _wanderStep(Enemy e, GridPos cur) {
    final free = [
      for (final d in Dir.cardinals)
        if (_enemyPassable(cur.x + d.dx, cur.y + d.dy)) d,
    ];
    if (free.isEmpty) return null;
    if (free.contains(e.dir) && rng.nextDouble() < 0.7) return cur.step(e.dir);
    final noBack = free.where((d) => d != e.dir.opposite).toList();
    final pool = noBack.isEmpty ? free : noBack;
    return cur.step(pool[rng.nextInt(pool.length)]);
  }

  // -------------------------------------------------------- contacts and end

  void _checkContacts() {
    for (final p in players) {
      if (!p.alive) continue;
      for (final e in enemies) {
        if (e.alive && (e.x - p.x).abs() < .65 && (e.y - p.y).abs() < .65) {
          _hurt(p);
          if (!p.alive) break;
        }
      }
      if (!p.alive) continue;
      final pu = powerUps.remove(p.cell);
      if (pu != null) {
        p.stats.apply(pu);
        if (mode == GameMode.story) p.score += 50;
        _events.add(GameEvent(GameEventType.powerUp, p.x, p.y, pu.index));
      }
    }
  }

  void _checkEnd() {
    if (mode == GameMode.story) {
      final p = players.first;
      if (!exitOpen && enemies.every((e) => !e.alive)) {
        exitOpen = true;
        _events.add(const GameEvent(GameEventType.exitOpened, 0, 0));
      }
      if (!p.alive || timeLeft <= 0) {
        status = WorldStatus.gameOver;
        _events.add(const GameEvent(GameEventType.gameOver, 0, 0));
      } else if (exitOpen && exit != null && exitRevealed && p.cell == exit) {
        p.score += timeLeft.floor() * 5;
        status = WorldStatus.levelComplete;
        _events.add(const GameEvent(GameEventType.levelComplete, 0, 0));
      }
      return;
    }
    final alive = players.where((p) => p.alive).toList();
    final aliveTeams = {for (final p in alive) p.teamId};
    if (aliveTeams.length <= 1 || timeLeft <= 0) {
      status = WorldStatus.battleOver;
      final won = aliveTeams.length == 1;
      winnerId = won ? alive.first.id : null;
      winnerTeam = won ? alive.first.teamId : null;
      _events.add(const GameEvent(GameEventType.gameOver, 0, 0));
    }
  }

  // ---------------------------------------------------------------- AI help

  /// Cells currently burning or about to be hit by any bomb.
  List<bool> dangerMap() {
    final danger = List<bool>.filled(GridModel.cols * GridModel.rows, false);
    for (var i = 0; i < danger.length; i++) {
      danger[i] = flameTime[i] > 0;
    }
    for (final b in bombs) {
      for (final c in computeBlast(grid, b.cell, b.range).cells) {
        danger[c.y * GridModel.cols + c.x] = true;
      }
    }
    return danger;
  }

  /// Whether a bot/enemy may step on ([x],[y]) (no wall/block/bomb).
  bool walkable(int x, int y) => !_solidOrBomb(x, y, null);
}
