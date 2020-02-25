import 'package:bsteeleMusicLib/Grid.dart';
import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test("test set", () {
    Grid<int> grid = Grid<int>();

    expect(grid.toString(), "Grid{[[null]]}");
    grid.clear();
    expect(grid.toString(), "Grid{[[null]]}" );


    grid.set(0,0, 1);
    expect(grid.toString(),"Grid{[[1]]}");
    grid.set(0,0, 1);
    expect(grid.toString(),"Grid{[[1]]}", );
    grid.set(0,1, 2);
    expect(grid.toString(),"Grid{[[1, 2]]}");
    grid.set(0,3, 4);
    expect( grid.toString(),"Grid{[[1, 2, null, 4]]}");
    grid.set(2,3, 4);
    expect( grid.toString(),"Grid{[[1, 2, null, 4], [null], [null, null, null, 4]]}");
    grid.set(-2,3, 444);
    expect(grid.toString(),"Grid{[[1, 2, null, 444], [null], [null, null, null, 4]]}");
    grid.set(-2,-3, 555);
    expect(grid.toString(),"Grid{[[555, 2, null, 444], [null], [null, null, null, 4]]}");

    grid.clear();
    expect(grid.toString(),"Grid{[[null]]}");
    grid.set(4,0, 1);
    expect(grid.toString(),"Grid{[[null], [null], [null], [null], [1]]}");
    grid.clear();
    expect(grid.toString(),"Grid{[[null]]}");
    grid.set(0,4, 1);
    expect(grid.toString(),"Grid{[[null, null, null, null, 1]]}");

    grid.clear();
    expect(grid.toString(),"Grid{[[null]]}");
  });

  test("test get", () {
    Grid<int> grid = new Grid<int>();

    expect(grid.toString(),"Grid{[[null]]}");
    expect(grid.get(0, 0),isNull);
    expect(grid.get(1000, 0),isNull);
    expect(grid.get(1000, 2345678),isNull);
    expect(grid.get(-1, -12),isNull);

    grid.set(0,0, 1);
    grid.set(0,1, 5);
    grid.set(0,3, 9);
    grid.set(3,3, 12);
    logger.d(grid.toString());
    expect(grid.toString(), "Grid{[[1, 5, null, 9], [null], [null], [null, null, null, 12]]}" );
    expect( 1,grid.get(0,0));
    expect(grid.get(3,0),isNull);
    expect( 5,grid.get(0,1));
    expect(grid.get(1,1),isNull);

    expect( 9,grid.get(0,3));
    expect(grid.get(1,3),isNull);
    expect(grid.get(2,3),isNull);
    expect(12,grid.get(3,3));
    expect(grid.get(4,3),isNull);
  });
}