import 'package:bsteele_music_lib/util/util.dart';
import 'package:test/test.dart';

void main() {
  test('test rolling average', () {
    RollingAverage ra = RollingAverage(windowSize: 4);

    expect(ra.average(1), 1);
    expect(ra.average(2), 1.5);
    expect(ra.average(3), 2);
    expect(ra.average(4), 10 / 4);
    expect(ra.average(5), 14 / 4);
    expect(ra.average(6), 18 / 4);
    ra.reset();
    expect(ra.average(7), 7);
    expect(ra.average(-8), -1 / 2);
    expect(ra.average(-9), -10 / 3);
    expect(ra.average(-10), -20 / 4);
    expect(ra.average(-11), -38 / 4);
    expect(ra.average(-12), -42 / 4);
    ra.reset();
    expect(ra.average(-12), -12);
  });
}
