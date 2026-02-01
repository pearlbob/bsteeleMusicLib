import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord_component.dart';
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
    logger.i(ChordComponent.values.toString());
    expect(ChordComponent.root.halfSteps, 0);
    expect(ChordComponent.minorSecond.halfSteps, 1);
    expect(ChordComponent.second.halfSteps, 2);
    expect(ChordComponent.minorThird.halfSteps, 3);
    expect(ChordComponent.third.halfSteps, 4);
    expect(ChordComponent.fourth.halfSteps, 5);
    expect(ChordComponent.flatFifth.halfSteps, 6);
    expect(ChordComponent.fifth.halfSteps, 7);
    expect(ChordComponent.minorSixth.halfSteps, 8);
    expect(ChordComponent.sixth.halfSteps, 9);
    expect(ChordComponent.minorSeventh.halfSteps, 10);
    expect(ChordComponent.seventh.halfSteps, 11);

    expect(ChordComponent.octave.halfSteps, 12);

    expect(ChordComponent.minorNinth.halfSteps, 13);
    expect(ChordComponent.ninth.halfSteps, 14);
    expect(ChordComponent.eleventh.halfSteps, 17);
    expect(ChordComponent.thirteenth.halfSteps, 21);
  });
}
