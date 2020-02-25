import 'package:quiver/core.dart';

class GridCoordinate implements Comparable<GridCoordinate> {
  GridCoordinate(this._row, this._col);

  @override
  String toString() {
    return "(" + _row.toString() + "," + _col.toString() + ")";
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
    return other is GridCoordinate && _row == other._row && _col == other._col;
  }

  @override
  int get hashCode {
    int ret = hash2(_row, _col);
    return ret;
  }

  int get row => _row;
  final int _row;

  int get col => _col;
  final int _col;
}
