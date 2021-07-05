import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chordComponent.dart';
import 'package:test/test.dart';

void main() {
  test('ChordComponent testing', () {
    List<ChordComponent> list = [];
    list.addAll(ChordComponent.parse('r'));
    expect(ChordComponent.root, list[0]);
    list.clear();
    list.addAll(ChordComponent.parse('1'));
    expect(ChordComponent.root, list[0]);
    list.clear();
    list.addAll(ChordComponent.parse('R m2  m3 3 4 b5   5 #5 6 m7 7'));

    expect(ChordComponent.root, list[0]);
    expect(ChordComponent.minorSecond, list[1]);
    expect(ChordComponent.minorThird, list[2]);
    expect(ChordComponent.third, list[3]);
    expect(ChordComponent.fourth, list[4]);
    expect(ChordComponent.flatFifth, list[5]);
    expect(ChordComponent.fifth, list[6]);
    expect(ChordComponent.sharpFifth, list[7]);
    expect(ChordComponent.sixth, list[8]);
    expect(ChordComponent.minorSeventh, list[9]);
    expect(ChordComponent.seventh, list[10]);
    list.clear();

    Set<ChordComponent> set = ChordComponent.parse('R 3 5 7');
    expect(true, set.contains(ChordComponent.root));
    expect(true, set.contains(ChordComponent.third));
    expect(true, set.contains(ChordComponent.fifth));
    expect(true, set.contains(ChordComponent.seventh));
    expect(false, set.contains(ChordComponent.minorThird));
    expect(false, set.contains(ChordComponent.fourth));
    expect(false, set.contains(ChordComponent.sixth));
    expect(false, set.contains(ChordComponent.minorSeventh));
  });

  test('ChordComponent values', () {
    logger.d(ChordComponent.values.toString());
    expect(ChordComponent.values.toString(), '[R, m2, 2, m3, 3, 4, b5, 5, #5, 6, m7, 7]');
  });
}
