import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';

/// Cells affected by one bomb explosion.
class BlastResult {
  /// Creates a result.
  const BlastResult(this.cells, this.destroyedBlocks);

  /// All burning cells including the origin.
  final List<GridPos> cells;

  /// Subset of [cells] that held a breakable block.
  final List<GridPos> destroyedBlocks;
}

/// Computes a plus-shaped blast from [origin] with [range] cells per arm.
///
/// Arms stop before indestructible walls and at (including) the first
/// breakable block, which is destroyed.
BlastResult computeBlast(GridModel grid, GridPos origin, int range) {
  final cells = <GridPos>[origin];
  final destroyed = <GridPos>[];
  for (final d in Dir.cardinals) {
    for (var i = 1; i <= range; i++) {
      final p = origin.step(d, i);
      final t = grid.typeAt(p.x, p.y);
      if (t == CellType.wall) break;
      cells.add(p);
      if (t == CellType.block) {
        destroyed.add(p);
        break;
      }
    }
  }
  return BlastResult(cells, destroyed);
}
