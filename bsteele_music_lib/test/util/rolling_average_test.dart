import 'package:bsteeleMusicLib/util/rolling_average.dart';
import 'package:test/test.dart';

void main() {
  test('test rolling average', () {
    RollingAverage ra = RollingAverage(4);

    expect(ra.roll(1), 1);
    expect(ra.roll(2), 1.5);
    expect(ra.roll(3), 2);
    expect(ra.roll(4), 10/4);
    expect(ra.roll(5), 14/4);
    expect(ra.roll(6), 18/4);
    ra.reset();
    expect(ra.roll(7), 7);
    expect(ra.roll(-8), -1/2);
    expect(ra.roll(-9), -10/3);
    expect(ra.roll(-10), -20/4);
    expect(ra.roll(-11), -38/4);
    expect(ra.roll(-12), -42/4);
    ra.reset();
    expect(ra.roll(-12), -12);
  });
}
