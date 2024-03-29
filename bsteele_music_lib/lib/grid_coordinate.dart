///   Grid coordinate storage for row and column values.
///   Rows and columns both start counting from zero.
class GridCoordinate implements Comparable<GridCoordinate> {
  const GridCoordinate(this._row, this._col);

  @override
  String toString() {
    return '($_row, $_col)';
  }

  @override
  int compareTo(GridCoordinate o) {
    if (_row != o._row) {
      return _row < o._row ? -1 : 1;
    }

    if (_col != o._col) {
      return _col < o._col ? -1 : 1;
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType && other is GridCoordinate && _row == other._row && _col == other._col;
  }

  @override
  int get hashCode {
    int ret = Object.hash(_row, _col);
    return ret;
  }

  /// Row coordinate of the grid location.
  /// Starts counting from zero.
  int get row => _row;
  final int _row;

  /// Column coordinate of the grid location.
  /// Starts counting from zero.
  int get col => _col;
  final int _col;
}
