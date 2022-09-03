import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/grid.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test('test set', () {
    Grid<int> grid = Grid<int>();

    expect(grid.toString(), 'Grid{\n}');
    grid.clear();
    expect(grid.toString(), 'Grid{\n}');

    grid.set(0, 0, 1);
    expect(grid.toString(), 'Grid{\n\t1\n}');
    grid.set(0, 0, 1);
    expect(grid.toString(), 'Grid{\n\t1\n}');
    grid.set(0, 1, 2);
    expect(grid.toString(), 'Grid{\n\t1       2\n}');
    grid.set(0, 3, 4);
    expect(grid.toString(), 'Grid{\n\t1       2       (0,2)   4\n}');
    grid.set(2, 3, 4);
    expect(
        grid.toString(),
        'Grid{\n'
        '\t1       2       (0,2)   4\n'
        '\t(1,0)\n'
        '\t(2,0)   (2,1)   (2,2)   4\n'
        '}');
    grid.set(-2, 3, 444);
    expect(
        grid.toString(),
        'Grid{\n'
        '\t1       2       (0,2)   444\n'
        '\t(1,0)\n'
        '\t(2,0)   (2,1)   (2,2)   4\n'
        '}');
    grid.set(-2, -3, 555);
    expect(
        grid.toString(),
        'Grid{\n'
        '\t555     2       (0,2)   444\n'
        '\t(1,0)\n'
        '\t(2,0)   (2,1)   (2,2)   4\n'
        '}');

    grid.clear();
    expect(
        grid.toString(),
        'Grid{\n'
        '}');
    grid.set(4, 0, 1);
    expect(
        grid.toString(),
        'Grid{\n'
        '\t(0,0)\n'
        '\t(1,0)\n'
        '\t(2,0)\n'
        '\t(3,0)\n'
        '\t1\n'
        '}');
    grid.clear();
    expect(
        grid.toString(),
        'Grid{\n'
        '}');
    grid.set(0, 4, 1);
    expect(
        grid.toString(),
        'Grid{\n'
        '\t(0,0)   (0,1)   (0,2)   (0,3)   1\n'
        '}');

    grid.clear();
    expect(
        grid.toString(),
        'Grid{\n'
        '}');
  });

  test('test get', () {
    Grid<int> grid = Grid<int>();

    expect(
        grid.toString(),
        'Grid{\n'
        '}');
    expect(grid.get(0, 0), isNull);
    expect(grid.get(1000, 0), isNull);
    expect(grid.get(1000, 2345678), isNull);
    expect(grid.get(-1, -12), isNull);

    grid.set(0, 0, 1);
    grid.set(0, 1, 5);
    grid.set(0, 3, 9);
    grid.set(3, 3, 12);
    logger.d(grid.toString());
    expect(
        grid.toString(),
        'Grid{\n'
        '\t1       5       (0,2)   9\n'
        '\t(1,0)\n'
        '\t(2,0)\n'
        '\t(3,0)   (3,1)   (3,2)   12\n'
        '}');
    expect(1, grid.get(0, 0));
    expect(grid.get(3, 0), isNull);
    expect(5, grid.get(0, 1));
    expect(grid.get(1, 1), isNull);

    expect(9, grid.get(0, 3));
    expect(grid.get(1, 3), isNull);
    expect(grid.get(2, 3), isNull);
    expect(12, grid.get(3, 3));
    expect(grid.get(4, 3), isNull);
  });
}
