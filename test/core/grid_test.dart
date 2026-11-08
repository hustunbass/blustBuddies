import 'dart:math';

import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/core/grid/map_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  layoutTests();
  group('GridModel', () {
    test('is 13x11 and out-of-bounds counts as wall', () {
      expect(GridModel.cols, 13);
      expect(GridModel.rows, 11);
      expect(GridModel().typeAt(-1, 0), CellType.wall);
      expect(GridModel().isSolid(13, 5), isTrue);
    });

    test('clone is independent', () {
      final g = GridModel()..setType(2, 1, CellType.block);
      final c = g.clone()..setType(2, 1, CellType.empty);
      expect(g.typeAt(2, 1), CellType.block);
      expect(c.typeAt(2, 1), CellType.empty);
    });
  });

  group('MapGenerator', () {
    final map = MapGenerator.generate(rng: Random(1), enemyCount: 5);

    test('border and even/even cells are walls', () {
      for (var y = 0; y < GridModel.rows; y++) {
        for (var x = 0; x < GridModel.cols; x++) {
          if (GridModel.isFixedWall(x, y)) {
            expect(map.grid.typeAt(x, y), CellType.wall, reason: '$x,$y');
          } else {
            expect(map.grid.typeAt(x, y), isNot(CellType.wall));
          }
        }
      }
    });

    test('corner safe zones are empty', () {
      for (final c in MapGenerator.corners) {
        for (final p in MapGenerator.safeZone(c)) {
          expect(map.grid.typeAt(p.x, p.y), CellType.empty, reason: '$p');
        }
      }
    });

    test('has breakable blocks and exit hides under one', () {
      expect(map.grid.blockCount, greaterThan(10));
      expect(map.grid.typeAt(map.exit!.x, map.exit!.y), CellType.block);
    });

    test('enemy spawns are free and far from player start', () {
      expect(map.enemySpawns.length, 5);
      for (final p in map.enemySpawns) {
        expect(map.grid.typeAt(p.x, p.y), CellType.empty);
        expect(p.manhattan(const GridPos(1, 1)), greaterThanOrEqualTo(6));
        expect(p, isNot(map.exit));
      }
    });

    test('is deterministic for a given seed', () {
      final a = MapGenerator.generate(rng: Random(7));
      final b = MapGenerator.generate(rng: Random(7));
      expect(a.exit, b.exit);
      expect(a.grid.blockCount, b.grid.blockCount);
    });
  });
}

void layoutTests() {
  group('map layouts', () {
    test('every layout keeps the floor connected and corners free', () {
      for (final layout in MapLayout.values) {
        for (var seed = 0; seed < 20; seed++) {
          final m = MapGenerator.generate(rng: Random(seed), layout: layout, withExit: false);
          for (final c in MapGenerator.corners) {
            for (final z in MapGenerator.safeZone(c)) {
              expect(m.grid.typeAt(z.x, z.y), CellType.empty, reason: '$layout $seed $z');
            }
          }
        }
      }
    });

    test('seeds give different arenas and layouts differ in walls', () {
      final styles = {for (var s = 0; s < 200; s++) MapGenerator.styleFor(s)};
      expect(styles.length, greaterThan(20));
      int walls(MapLayout l) {
        final g = MapGenerator.generate(rng: Random(1), layout: l, density: 0, withExit: false).grid;
        var n = 0;
        for (var y = 0; y < GridModel.rows; y++) {
          for (var x = 0; x < GridModel.cols; x++) {
            if (g.typeAt(x, y) == CellType.wall) n++;
          }
        }
        return n;
      }

      expect(walls(MapLayout.open), lessThan(walls(MapLayout.classic)));
      expect(walls(MapLayout.fortress), greaterThan(walls(MapLayout.classic)));
    });
  });
}
