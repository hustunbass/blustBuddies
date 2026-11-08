import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/net/protocol.dart';

int _c(double v) => (v * 100).round();
double _d(Object? v) => (v as num) / 100;

/// [serverTime] (seconds of simulated match time) lets clients interpolate
/// smoothly even when packets arrive unevenly.
///
/// Encodes everything a client needs to draw [w] plus the [events] produced
/// since the previous snapshot. Fixed-point (x100) ints keep frames small.
Map<String, dynamic> encodeSnapshot(GameWorld w, List<GameEvent> events, {double? serverTime}) {
  final grid = StringBuffer();
  for (var y = 0; y < GridModel.rows; y++) {
    for (var x = 0; x < GridModel.cols; x++) {
      grid.write(w.grid.typeAt(x, y).index);
    }
  }
  return {
    't': Msg.snapshot,
    if (serverTime != null) 'n': (serverTime * 1000).round(),
    'tl': _c(w.timeLeft),
    'st': w.status.index,
    if (w.winnerId != null) 'w': w.winnerId,
    if (w.winnerTeam != null) 'wt': w.winnerTeam,
    'g': grid.toString(),
    'f': [
      for (var i = 0; i < w.flameTime.length; i++)
        if (w.flameTime[i] > 0) [i, _c(w.flameTime[i])],
    ],
    'b': [
      for (final b in w.bombs)
        [b.col, b.row, _c(b.fuse), b.slideDir.index, _c(b.slideProgress), b.ownerId, b.range],
    ],
    'u': [
      for (final e in w.powerUps.entries) [e.key.x, e.key.y, e.value.index],
    ],
    'p': [
      for (final p in w.players)
        [
          _c(p.x),
          _c(p.y),
          p.moveDir.index,
          p.facing.index,
          if (p.alive) 1 else 0,
          p.lives,
          _c(p.invuln),
          _c(p.stats.shield),
          p.stats.maxBombs,
          p.stats.range,
          _c(p.stats.speed),
          if (p.stats.canKick) 1 else 0,
        ],
    ],
    'e': [
      for (final e in events) [e.type.index, _c(e.x), _c(e.y), e.id],
    ],
  };
}

/// Copies snapshot [m] into [w] (built from the same seed/shape) and queues
/// its events, so the normal renderer/audio code can be reused.
void applySnapshot(GameWorld w, Map<String, dynamic> m) {
  w
    ..timeLeft = _d(m['tl'])
    ..status = WorldStatus.values[m['st'] as int]
    ..winnerId = m['w'] as int?
    ..winnerTeam = m['wt'] as int?;

  final g = m['g'] as String;
  for (var i = 0; i < g.length && i < GridModel.cols * GridModel.rows; i++) {
    w.grid.setType(i % GridModel.cols, i ~/ GridModel.cols, CellType.values[g.codeUnitAt(i) - 48]);
  }

  w.flameTime.fillRange(0, w.flameTime.length, 0);
  for (final f in m['f'] as List) {
    final l = f as List;
    w.flameTime[l[0] as int] = _d(l[1]);
  }

  w.bombs
    ..clear()
    ..addAll([
      for (final b in m['b'] as List)
        Bomb(
          col: (b as List)[0] as int,
          row: b[1] as int,
          fuse: _d(b[2]),
          ownerId: b[5] as int,
          range: b[6] as int,
          passIds: {},
        )
          ..slideDir = Dir.values[b[3] as int]
          ..slideProgress = _d(b[4]),
    ]);

  w.powerUps
    ..clear()
    ..addAll({
      for (final u in m['u'] as List)
        GridPos((u as List)[0] as int, u[1] as int): PowerUpType.values[u[2] as int],
    });

  final ps = m['p'] as List;
  for (var i = 0; i < ps.length && i < w.players.length; i++) {
    final l = ps[i] as List;
    final p = w.players[i]
      ..x = _d(l[0])
      ..y = _d(l[1])
      ..moveDir = Dir.values[l[2] as int]
      ..facing = Dir.values[l[3] as int]
      ..alive = l[4] == 1
      ..lives = l[5] as int
      ..invuln = _d(l[6]);
    p.stats
      ..shield = _d(l[7])
      ..maxBombs = l[8] as int
      ..range = l[9] as int
      ..speed = _d(l[10])
      ..canKick = l[11] == 1;
  }

  for (final e in m['e'] as List) {
    final l = e as List;
    w.emit(GameEvent(GameEventType.values[l[0] as int], _d(l[1]), _d(l[2]), l[3] as int));
  }
}
