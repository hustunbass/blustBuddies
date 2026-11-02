import 'dart:math';

import 'package:blast_buddies/core/ai/pathfinding.dart';
import 'package:blast_buddies/core/combat/blast.dart';
import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:flutter_test/flutter_test.dart';

/// Open arena: fixed walls only.
GridModel arena() {
  final g = GridModel();
  for (var y = 0; y < GridModel.rows; y++) {
    for (var x = 0; x < GridModel.cols; x++) {
      if (GridModel.isFixedWall(x, y)) g.setType(x, y, CellType.wall);
    }
  }
  return g;
}

void main() {
  group('computeBlast', () {
    test('extends range in a plus shape', () {
      final r = computeBlast(arena(), const GridPos(5, 5), 2);
      expect(r.cells.length, 9);
      expect(r.cells, contains(const GridPos(5, 3)));
      expect(r.cells, contains(const GridPos(7, 5)));
      expect(r.cells, isNot(contains(const GridPos(6, 6))));
    });

    test('stops at walls without including them', () {
      final r = computeBlast(arena(), const GridPos(1, 1), 5);
      expect(r.cells, isNot(contains(const GridPos(0, 1))));
      expect(r.cells, isNot(contains(const GridPos(1, 0))));
    });

    test('stops at and destroys the first block', () {
      final g = arena()..setType(4, 5, CellType.block);
      final r = computeBlast(g, const GridPos(5, 5), 3);
      expect(r.destroyedBlocks, [const GridPos(4, 5)]);
      expect(r.cells, contains(const GridPos(4, 5)));
      expect(r.cells, isNot(contains(const GridPos(3, 5))));
    });

    test('indestructible wall blocks the arm', () {
      final r = computeBlast(arena(), const GridPos(1, 2), 4);
      // Row 2 has walls at even x: arm right stops at (2,2).
      expect(r.cells, isNot(contains(const GridPos(2, 2))));
    });
  });

  group('bfsPath', () {
    test('finds shortest path around walls', () {
      final g = arena();
      final p = bfsPath(
        const GridPos(1, 1),
        (c) => c == const GridPos(3, 1),
        (c) => !g.isSolid(c.x, c.y),
      );
      expect(p, [const GridPos(2, 1), const GridPos(3, 1)]);
    });

    test('returns empty when already at goal and null when unreachable', () {
      final g = arena();
      expect(bfsPath(const GridPos(1, 1), (c) => true, (c) => true), isEmpty);
      g.setType(2, 1, CellType.block);
      g.setType(1, 2, CellType.block);
      expect(
        bfsPath(const GridPos(1, 1), (c) => c == const GridPos(5, 5),
            (c) => !g.isSolid(c.x, c.y)),
        isNull,
      );
    });

    test('respects maxDepth', () {
      final g = arena();
      expect(
        bfsPath(const GridPos(1, 1), (c) => c == const GridPos(11, 1),
            (c) => !g.isSolid(c.x, c.y), maxDepth: 3),
        isNull,
      );
    });
  });

  group('powerups', () {
    test('drop rate is about 30%', () {
      final rng = Random(3);
      var drops = 0;
      const n = 10000;
      for (var i = 0; i < n; i++) {
        if (rollPowerUp(rng) != null) drops++;
      }
      expect(drops / n, closeTo(0.30, 0.03));
    });

    test('all types can drop', () {
      final rng = Random(5);
      final seen = {
        for (var i = 0; i < 2000; i++) rollPowerUp(rng, chance: 1),
      };
      expect(seen, containsAll(PowerUpType.values));
    });

    test('apply updates and caps stats', () {
      final s = PlayerStats();
      for (var i = 0; i < 20; i++) {
        s
          ..apply(PowerUpType.bomb)
          ..apply(PowerUpType.range)
          ..apply(PowerUpType.speed);
      }
      s
        ..apply(PowerUpType.kick)
        ..apply(PowerUpType.shield);
      expect(s.maxBombs, PlayerStats.bombCap);
      expect(s.range, PlayerStats.rangeCap);
      expect(s.speed, PlayerStats.speedCap);
      expect(s.canKick, isTrue);
      expect(s.shield, PlayerStats.shieldDuration);
    });
  });
}
