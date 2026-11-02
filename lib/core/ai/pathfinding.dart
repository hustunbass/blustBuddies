import 'dart:collection';

import 'package:blast_buddies/core/grid/grid_pos.dart';

/// Breadth-first search on the grid.
///
/// Returns the path from [start] (exclusive) to the nearest cell satisfying
/// [isGoal] (inclusive), moving only through cells where [passable] is true.
/// Returns an empty list if [start] is already a goal, `null` if unreachable
/// within [maxDepth] steps.
List<GridPos>? bfsPath(
  GridPos start,
  bool Function(GridPos) isGoal,
  bool Function(GridPos) passable, {
  int maxDepth = 1 << 20,
}) {
  if (isGoal(start)) return const [];
  final prev = <GridPos, GridPos>{};
  final depth = <GridPos, int>{start: 0};
  final queue = Queue<GridPos>()..add(start);
  while (queue.isNotEmpty) {
    final cur = queue.removeFirst();
    final dcur = depth[cur]!;
    if (dcur >= maxDepth) continue;
    for (final d in Dir.cardinals) {
      final n = cur.step(d);
      if (depth.containsKey(n) || !passable(n)) continue;
      depth[n] = dcur + 1;
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

/// Direction from [from] to adjacent [to] ([Dir.none] if not adjacent).
Dir dirBetween(GridPos from, GridPos to) {
  for (final d in Dir.cardinals) {
    if (from.step(d) == to) return d;
  }
  return Dir.none;
}
