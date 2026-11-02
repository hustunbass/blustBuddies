import 'dart:math';

import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';

/// Result of [MapGenerator.generate].
class GeneratedMap {
  /// Creates a result.
  const GeneratedMap({
    required this.grid,
    required this.spawns,
    required this.exit,
    required this.enemySpawns,
  });

  /// Terrain.
  final GridModel grid;

  /// Player start cells (corner order: TL, BR, TR, BL).
  final List<GridPos> spawns;

  /// Hidden exit cell (always under a breakable block), or null.
  final GridPos? exit;

  /// Enemy start cells.
  final List<GridPos> enemySpawns;
}

/// Procedural level layout generator.
class MapGenerator {
  MapGenerator._();

  /// Player start corners.
  static const List<GridPos> corners = [
    GridPos(1, 1),
    GridPos(GridModel.cols - 2, GridModel.rows - 2),
    GridPos(GridModel.cols - 2, 1),
    GridPos(1, GridModel.rows - 2),
  ];

  /// Cells that must stay empty near [corner] (the corner and 2 neighbours).
  static List<GridPos> safeZone(GridPos corner) {
    final sx = corner.x == 1 ? 1 : -1;
    final sy = corner.y == 1 ? 1 : -1;
    return [corner, GridPos(corner.x + sx, corner.y), GridPos(corner.x, corner.y + sy)];
  }

  /// Builds a map. [density] is the chance a free cell gets a breakable block.
  static GeneratedMap generate({
    required Random rng,
    double density = 0.6,
    bool withExit = true,
    int enemyCount = 0,
  }) {
    final grid = GridModel();
    final safe = <GridPos>{for (final c in corners) ...safeZone(c)};
    for (var y = 0; y < GridModel.rows; y++) {
      for (var x = 0; x < GridModel.cols; x++) {
        if (GridModel.isFixedWall(x, y)) {
          grid.setType(x, y, CellType.wall);
        } else if (!safe.contains(GridPos(x, y)) && rng.nextDouble() < density) {
          grid.setType(x, y, CellType.block);
        }
      }
    }

    final enemySpawns = pickEnemySpawns(grid, rng, enemyCount, corners.first);
    GridPos? exit;
    if (withExit) {
      final blocks = <GridPos>[
        for (var y = 0; y < GridModel.rows; y++)
          for (var x = 0; x < GridModel.cols; x++)
            if (grid.typeAt(x, y) == CellType.block &&
                GridPos(x, y).manhattan(corners.first) > 6)
              GridPos(x, y),
      ];
      if (blocks.isEmpty) {
        // Guarantee a block exists far from the start.
        exit = const GridPos(GridModel.cols - 2, GridModel.rows - 3);
        grid.setType(exit.x, exit.y, CellType.block);
      } else {
        exit = blocks[rng.nextInt(blocks.length)];
      }
    }

    return GeneratedMap(
      grid: grid,
      spawns: corners,
      exit: exit,
      enemySpawns: enemySpawns,
    );
  }

  /// Picks [count] empty cells at least 6 steps (Manhattan) from [avoid].
  /// Cells are cleared of blocks so enemies always start on free floor.
  static List<GridPos> pickEnemySpawns(
    GridModel grid,
    Random rng,
    int count,
    GridPos avoid,
  ) {
    final candidates = <GridPos>[
      for (var y = 1; y < GridModel.rows - 1; y++)
        for (var x = 1; x < GridModel.cols - 1; x++)
          if (grid.typeAt(x, y) != CellType.wall &&
              GridPos(x, y).manhattan(avoid) >= 6 &&
              !corners.any((c) => safeZone(c).contains(GridPos(x, y))))
            GridPos(x, y),
    ]..shuffle(rng);
    final picked = candidates.take(count).toList();
    for (final p in picked) {
      grid.setType(p.x, p.y, CellType.empty);
    }
    return picked;
  }
}
