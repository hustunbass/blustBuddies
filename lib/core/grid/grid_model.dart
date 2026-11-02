/// Terrain type of a grid cell.
enum CellType {
  /// Walkable floor.
  empty,

  /// Indestructible block.
  wall,

  /// Destructible block.
  block,
}

/// Fixed-size terrain grid (13 columns x 11 rows). Pure Dart, no Flame.
class GridModel {
  /// Creates a grid filled with [CellType.empty].
  GridModel() : _cells = List.filled(cols * rows, CellType.empty);

  GridModel._(this._cells);

  /// Number of columns.
  static const int cols = 13;

  /// Number of rows.
  static const int rows = 11;

  final List<CellType> _cells;

  /// Whether ([x],[y]) is inside the grid.
  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < cols && y < rows;

  /// Terrain at ([x],[y]); out-of-bounds counts as [CellType.wall].
  CellType typeAt(int x, int y) =>
      inBounds(x, y) ? _cells[y * cols + x] : CellType.wall;

  /// Sets terrain at ([x],[y]).
  void setType(int x, int y, CellType t) {
    if (inBounds(x, y)) _cells[y * cols + x] = t;
  }

  /// Whether the cell blocks movement and blasts partially (wall or block).
  bool isSolid(int x, int y) => typeAt(x, y) != CellType.empty;

  /// Number of destructible blocks left.
  int get blockCount => _cells.where((c) => c == CellType.block).length;

  /// Deep copy.
  GridModel clone() => GridModel._(List.of(_cells));

  /// True for the fixed layout of indestructible walls (border + even/even).
  static bool isFixedWall(int x, int y) =>
      x == 0 || y == 0 || x == cols - 1 || y == rows - 1 || (x.isEven && y.isEven);
}
