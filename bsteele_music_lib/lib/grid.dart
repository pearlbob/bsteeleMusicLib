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
    for (var row in otherGrid.grid) {
      grid.add(row);
    }
  }

  bool get isEmpty => grid.isEmpty;

  bool get isNotEmpty => grid.isNotEmpty;

  void set(int r, int c, T? t) {
    if (r < 0) {
      r = 0;
    }
    if (c < 0) {
      c = 0;
    }

    while (r >= grid.length) {
      //  addTo a new row to the grid
      grid.add(List.generate(1, (a) {
        return null;
      }));
    }

    List<T?>? row = grid[r];
    if (c == row?.length) {
      row?.add(t);
    } else {
      while (c > (row?.length ?? 0) - 1) {
        row?.add(null);
      }
      row?[c] = t;
    }
  }

  @override
  String toString() {
    return 'Grid{' + grid.toString() + '}';
  }

  String toMultiLineString() {
    StringBuffer sb = StringBuffer('Grid{\n');

    int rLimit = getRowCount();
    for (int r = 0; r < rLimit; r++) {
      List<T?>? row = getRow(r);
      int colLimit = row?.length ?? 0;
      sb.write('\t[');
      for (int c = 0; c < colLimit; c++) {
        sb.write('\t' + (row?[c].toString() ?? '') + ',');
      }
      sb.write('\t]\n');
    }
    sb.write('}');
    return sb.toString();
  }

  T? get(int r, int c) {
    try {
      List<T?>? row = grid[r];
      if (row == null) {
        return null;
      }
      return row[c];
    } catch (ex) {
      return null;
    }
  }

  int getRowCount() {
    return grid.length;
  }

  List<T?>? getRow(int r) {
    try {
      return grid[r];
    } catch (ex) {
      return null;
    }
  }

  int rowLength(int r) {
    try {
      return grid[r]?.length ?? 0;
    } catch (ex) {
      return 0;
    }
  }

  void clear() {
    grid.clear();
  }

  final List<List<T?>?> grid = [];
}
