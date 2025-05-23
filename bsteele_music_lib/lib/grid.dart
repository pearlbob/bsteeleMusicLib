import 'dart:math';

import 'grid_coordinate.dart';

typedef GridCallback<T> = void Function(int r, int c, T value);

/// A generic grid used to store data presentations to the user.
/// Grid locations are logically assigned without the details of the UI mapping.
class Grid<T> {
  /// Deep copy, not as a constructor
  Grid<T> deepCopy(Grid<T>? other) {
    if (other == null) {
      return Grid<T>();
    }
    int rLimit = other.getRowCount();
    for (int r = 0; r < rLimit; r++) {
      List<T?>? row = other.getRow(r);
      int colLimit = row?.length ?? 0;
      for (int c = 0; c < colLimit; c++) {
        set(c, r, row?[c]);
      }
    }
    return this;
  }

  void add(Grid<T> otherGrid) {
    for (var row in otherGrid.gridList) {
      gridList.add(row);
    }
  }

  bool get isEmpty => gridList.isEmpty;

  bool get isNotEmpty => gridList.isNotEmpty;

  /// Copy a list to a given row
  /// Watch for mutations after the fact
  void setRow(int r, int c, List<T?>? tList) {
    if (tList == null || tList.isEmpty) return;

    //  copy the list to the row
    for (int tc = 0; tc < tList.length; tc++) {
      set(r, c + tc, tList[tc]);
    }
  }

  void set(int r, int c, T? t) {
    if (r < 0) {
      r = 0;
    }
    if (c < 0) {
      c = 0;
    }

    //  add new rows to the grid if required
    while (r >= gridList.length) {
      gridList.add(
        List.generate(1, (a) {
          return null;
        }),
      );
    }

    //  add new columns to the grid if required
    List<T?>? row = gridList[r];
    if (c == row?.length) {
      //  add at the given column
      row?.add(t);
    } else {
      while (c > (row?.length ?? 0) - 1) {
        row?.add(null);
      }
      //  set at the given column
      row?[c] = t;
    }
  }

  void setAt(GridCoordinate gc, T? t) {
    set(gc.row, gc.col, t);
  }

  /// process each non-null grid position by the given function
  void foreach(GridCallback<T> action) {
    for (int r = 0; r < getRowCount(); r++) {
      List<T?>? row = getRow(r);
      int colLimit = row?.length ?? 0;
      for (int c = 0; c < colLimit; c++) {
        var value = get(r, c);
        if (value != null) {
          action(r, c, value);
        }
      }
    }
  }

  @override
  String toString() {
    return 'Grid{\n${_debugString()}}';
  }

  String toMultiLineString() {
    StringBuffer sb = StringBuffer('Grid{\n');

    int rLimit = getRowCount();
    for (int r = 0; r < rLimit; r++) {
      List<T?>? row = getRow(r);
      int colLimit = row?.length ?? 0;
      sb.write('\t[');
      for (int c = 0; c < colLimit; c++) {
        sb.write('\t${row?[c].toString() ?? ''},');
      }
      sb.write('\t]\n');
    }
    sb.write('}');
    return sb.toString();
  }

  //  map the grid to a debug string
  String _debugString() {
    var sb = StringBuffer();
    for (var r = 0; r < getRowCount(); r++) {
      var row = getRow(r);
      var s = '\t';
      for (var c = 0; c < (row?.length ?? 0); c++) {
        var cell = get(r, c);
        if (cell == null) {
          s += '($r,$c)'.padRight(8);
        } else {
          s += cell.toString().replaceAll('\n', '\\n').padRight(8);
        }
      }
      sb.write('${s.trimRight()}\n');
    }
    return sb.toString();
  }

  T? at(GridCoordinate gc) {
    return get(gc.row, gc.col);
  }

  T? get(int r, int c) {
    try {
      List<T?>? row = gridList[r];
      if (row == null) {
        return null;
      }
      return row[c];
    } catch (ex) {
      return null;
    }
  }

  int getRowCount() {
    return gridList.length;
  }

  int get maxColumnCount {
    int ret = 0;
    for (int r = 0; r < getRowCount(); r++) {
      ret = max(ret, rowLength(r));
    }
    return ret;
  }

  List<T?>? getRow(int r) {
    try {
      return gridList[r];
    } catch (ex) {
      return null;
    }
  }

  int rowLength(int r) {
    try {
      return gridList[r]?.length ?? 0;
    } catch (ex) {
      return 0;
    }
  }

  void clear() {
    gridList.clear();
  }

  final List<List<T?>?> gridList = [];
}
