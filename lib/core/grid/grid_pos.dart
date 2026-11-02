/// Integer cell coordinate on the game grid.
class GridPos {
  /// Creates a cell coordinate ([x] = column, [y] = row).
  const GridPos(this.x, this.y);

  /// Column index.
  final int x;

  /// Row index.
  final int y;

  /// Returns the neighbouring cell in direction [d].
  GridPos step(Dir d, [int n = 1]) => GridPos(x + d.dx * n, y + d.dy * n);

  /// Manhattan distance to [o].
  int manhattan(GridPos o) => (x - o.x).abs() + (y - o.y).abs();

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.x == x && other.y == y;

  @override
  int get hashCode => x * 1000 + y;

  @override
  String toString() => 'GridPos($x, $y)';
}

/// Movement direction on the grid.
enum Dir {
  /// Towards row 0.
  up(0, -1),

  /// Towards the last row.
  down(0, 1),

  /// Towards column 0.
  left(-1, 0),

  /// Towards the last column.
  right(1, 0),

  /// No movement.
  none(0, 0);

  const Dir(this.dx, this.dy);

  /// Horizontal unit component.
  final int dx;

  /// Vertical unit component.
  final int dy;

  /// The four real directions.
  static const List<Dir> cardinals = [Dir.up, Dir.down, Dir.left, Dir.right];

  /// Opposite direction.
  Dir get opposite => switch (this) {
        Dir.up => Dir.down,
        Dir.down => Dir.up,
        Dir.left => Dir.right,
        Dir.right => Dir.left,
        Dir.none => Dir.none,
      };
}
