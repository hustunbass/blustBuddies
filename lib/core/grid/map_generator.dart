import 'dart:math';

import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';

/// Arena floor plan. Every layout keeps all floor cells connected and the
/// four corner start areas free.
enum MapLayout {
  /// The classic pillar grid.
  classic,

  /// Every other pillar removed: wide open fights.
  open,

  /// A plus-shaped obstacle in the middle.
  cross,

  /// Walled-off inner courtyard with gates.
  fortress,

  /// Two broken horizontal walls.
  lanes,
}

/// Result of [MapGenerator.generate].
class GeneratedMap {
  /// Creates a result.
  const GeneratedMap({
    required this.grid,
    required this.spawns,
    required this.exit,
    required this.enemySpawns,
    this.layout = MapLayout.classic,
    this.theme = 0,
  });

  /// Floor plan used.
  final MapLayout layout;

  /// Index into `MapTheme.all`.
  final int theme;

  /// Terrain.
  final GridModel grid;

  /// Player start cells (corner order: TL, BR, TR, BL, then top-middle,
  /// bottom-middle, centre).
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

  /// Largest match: 4 corners plus top-middle, bottom-middle and centre.
  static const int maxPlayers = 7;

  /// Start cells of players 5..7 (see [spawnPoints]).
  static const List<GridPos> extraSpawns = [
    GridPos(GridModel.cols ~/ 2, 1),
    GridPos(GridModel.cols ~/ 2, GridModel.rows - 2),
    GridPos(GridModel.cols ~/ 2, GridModel.rows ~/ 2),
  ];

  /// Every start cell in player order: the four corners first (so 2..4 player
  /// matches look exactly as before), then [extraSpawns].
  static const List<GridPos> spawnPoints = [...corners, ...extraSpawns];

  /// Cells that must stay empty around start cell [p]: the L-shaped corner
  /// area, or the cell and its two horizontal neighbours for the others.
  static List<GridPos> safeZoneOf(GridPos p) =>
      corners.contains(p) ? safeZone(p) : [p, GridPos(p.x - 1, p.y), GridPos(p.x + 1, p.y)];

  /// Cells that must stay empty near [corner] (the corner and 2 neighbours).
  static List<GridPos> safeZone(GridPos corner) {
    final sx = corner.x == 1 ? 1 : -1;
    final sy = corner.y == 1 ? 1 : -1;
    return [corner, GridPos(corner.x + sx, corner.y), GridPos(corner.x, corner.y + sy)];
  }

  /// Number of arena colour themes.
  static const int themeCount = 7;

  /// Deterministic (layout, theme) for a match [seed], independent of the
  /// generator's own random stream. Used by battles and online rooms.
  static (MapLayout, int) styleFor(int seed) {
    final r = Random(seed ^ 0x5bd1e995);
    return (MapLayout.values[r.nextInt(MapLayout.values.length)], r.nextInt(themeCount));
  }

  static const _extraWalls = <MapLayout, List<GridPos>>{
    MapLayout.cross: [GridPos(6, 5), GridPos(5, 5), GridPos(7, 5)],
    // Courtyard around the centre with a single gate on the west side.
    MapLayout.fortress: [
      GridPos(5, 4), GridPos(7, 4), GridPos(5, 6), GridPos(7, 6), GridPos(8, 5),
    ],
    // Two broken walls with a gap in the middle.
    MapLayout.lanes: [
      GridPos(2, 3), GridPos(4, 3), GridPos(8, 3), GridPos(10, 3),
      GridPos(2, 7), GridPos(4, 7), GridPos(8, 7), GridPos(10, 7),
    ],
  };

  static bool _isWall(MapLayout layout, int x, int y) {
    if (!GridModel.isFixedWall(x, y)) return false;
    final interior = x > 0 && y > 0 && x < GridModel.cols - 1 && y < GridModel.rows - 1;
    return !(layout == MapLayout.open && interior && (x + y) % 4 == 0);
  }

  /// Whether every non-wall cell is reachable from the first corner.
  static bool _connected(GridModel g) {
    final seen = <GridPos>{corners.first};
    final todo = [corners.first];
    while (todo.isNotEmpty) {
      final c = todo.removeLast();
      for (final n in [GridPos(c.x + 1, c.y), GridPos(c.x - 1, c.y), GridPos(c.x, c.y + 1), GridPos(c.x, c.y - 1)]) {
        if (g.typeAt(n.x, n.y) != CellType.wall && seen.add(n)) todo.add(n);
      }
    }
    var floor = 0;
    for (var y = 0; y < GridModel.rows; y++) {
      for (var x = 0; x < GridModel.cols; x++) {
        if (g.typeAt(x, y) != CellType.wall) floor++;
      }
    }
    return floor == seen.length;
  }

  /// Builds a map. [density] is the chance a free cell gets a breakable block.
  static GeneratedMap generate({
    required Random rng,
    double density = 0.6,
    bool withExit = true,
    int enemyCount = 0,
    MapLayout layout = MapLayout.classic,
    int theme = 0,
    int players = 4,
  }) {
    // Start cells in use: always the four corners, more for 5..7 players.
    final starts = spawnPoints.take(players.clamp(4, maxPlayers)).toList();
    final safe = <GridPos>{for (final c in starts) ...safeZoneOf(c)};
    var extra = {
      for (final c in _extraWalls[layout] ?? const <GridPos>[])
        if (!safe.contains(c)) c,
    };
    GridModel walls(Set<GridPos> extra) {
      final g = GridModel();
      for (var y = 0; y < GridModel.rows; y++) {
        for (var x = 0; x < GridModel.cols; x++) {
          if (_isWall(layout, x, y) || extra.contains(GridPos(x, y))) {
            g.setType(x, y, CellType.wall);
          }
        }
      }
      return g;
    }

    var grid = walls(extra);
    if (!_connected(grid)) {
      // A layout must never seal off part of the floor.
      extra = {};
      grid = walls(extra);
    }
    for (var y = 0; y < GridModel.rows; y++) {
      for (var x = 0; x < GridModel.cols; x++) {
        if (grid.typeAt(x, y) == CellType.wall || safe.contains(GridPos(x, y))) continue;
        if (rng.nextDouble() < density) grid.setType(x, y, CellType.block);
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
      spawns: starts,
      exit: exit,
      enemySpawns: enemySpawns,
      layout: layout,
      theme: theme,
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
