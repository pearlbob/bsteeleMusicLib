/// A generic grid used to store data presentations to the user.
/// Grid locations are logically assigned without the details of the UI mapping.
class Grid<T> {
  /// Deep copy, not as a constructor
  Grid<T> deepCopy(Grid<T> other) {
    if (other == null) return null;
    int rLimit = other.getRowCount();
    for (int r = 0; r < rLimit; r++) {
      List<T> row = other.getRow(r);
      int colLimit = row.length;
      for (int c = 0; c < colLimit; c++) {
        set(c, r, row[c]);
      }
    }
    return this;
  }

  bool get isEmpty => grid.isEmpty;
  bool get isNotEmpty => grid.isNotEmpty;

  void set(int x, int y, T t) {
    if (x < 0) x = 0;
    if (y < 0) y = 0;

    while (x >= grid.length) {
      //  addTo a new row to the grid
      grid.add(List.generate(1, (a) {
        return null;
      }));
    }

    List<T> row = grid[x];
    if (y == row.length)
      row.add(t);
    else {
      while (y > row.length - 1) row.add(null);
      row[y] = t;
    }
  }

  @override
  String toString() {
    return "Grid{" + grid.toString() + '}';
  }

  T get(int x, int y) {
    try {
      List<T> row = grid[x];
      if (row == null) {
        return null;
      }
      return row[y];
    } catch (ex) {
      return null;
    }
  }

  int getRowCount() {
    return grid.length;
  }

  List<T> getRow(int r) {
    try {
      return grid[r];
    } catch (ex) {
      return null;
    }
  }

  int rowLength(int r ){
    try {
      return grid[r].length;
    } catch (ex) {
      return null;
    }
  }

  void clear() {
    grid.clear();
    grid.add(List.generate(1, (a) {
      return null;
    }));
  }

  final List<List<T>> grid =
  //  fixme: is this required for a dart bug?
  List.generate(1, (a) {
    return List.generate(1, (a) {
      return null;
    });
  });
}
