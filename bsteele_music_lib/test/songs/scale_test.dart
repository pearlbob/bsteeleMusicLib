import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/scale.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test('Scale tests', () {
    expect(Scale.major.halfSteps[0], 0);
    expect(Scale.major.intervals[0], 2);
    expect(Scale.major.halfSteps[1], 2);
    expect(Scale.major.intervals[1], 2);
    expect(Scale.major.halfSteps[2], 4);
    expect(Scale.major.intervals[2], 1);
    expect(Scale.major.halfSteps[3], 5);
    expect(Scale.major.intervals[3], 2);
    expect(Scale.major.halfSteps[4], 7);
    expect(Scale.major.intervals[4], 2);
    expect(Scale.major.halfSteps[5], 9);
    expect(Scale.major.intervals[5], 2);
    expect(Scale.major.halfSteps[6], 11);
    expect(Scale.major.intervals[6], 1);
    expect(Scale.major.halfSteps[7], 12);

    expect(Scale.minor.halfSteps[0], 0);
    expect(Scale.minor.intervals[0], 2);
    expect(Scale.minor.halfSteps[1], 2);
    expect(Scale.minor.intervals[1], 1);
    expect(Scale.minor.halfSteps[2], 3);
    expect(Scale.minor.intervals[2], 2);
    expect(Scale.minor.halfSteps[3], 5);
    expect(Scale.minor.intervals[3], 2);
    expect(Scale.minor.halfSteps[4], 7);
    expect(Scale.minor.intervals[4], 1);
    expect(Scale.minor.halfSteps[5], 8);
    expect(Scale.minor.intervals[5], 2);
    expect(Scale.minor.halfSteps[6], 10);
    expect(Scale.minor.intervals[6], 2);
    expect(Scale.minor.halfSteps[7], 12);

    expect(Scale.major.inKey(Key.get(KeyEnum.C)).toString(), '[C, D, E, F, G, A, B, C]');
    expect(Scale.ionian.inKey(Key.get(KeyEnum.C)).toString(), '[C, D, E, F, G, A, B, C]');
    expect(Scale.dorian.inKey(Key.get(KeyEnum.D)).toString(), '[D, E, F, G, A, B, C, D]');
    expect(Scale.phrygian.inKey(Key.get(KeyEnum.E)).toString(), '[E, F, G, A, B, C, D, E]');
    expect(Scale.lydian.inKey(Key.get(KeyEnum.F)).toString(), '[F, G, A, B, C, D, E, F]');
    expect(Scale.mixolydian.inKey(Key.get(KeyEnum.G)).toString(), '[G, A, B, C, D, E, F, G]');
    expect(Scale.aeolian.inKey(Key.get(KeyEnum.A)).toString(), '[A, B, C, D, E, F, G, A]');
    expect(Scale.minor.inKey(Key.get(KeyEnum.A)).toString(), '[A, B, C, D, E, F, G, A]');
    expect(Scale.locrian.inKey(Key.get(KeyEnum.B)).toString(), '[B, C, D, E, F, G, A, B]');
    /*
     Mode	Also known as	Starting note relative
     to major scale	Interval sequence	Example
     Ionian	Major scale	I	T,T,S,T,T,T,S	C,D,E,F,G,A,B,C
     Dorian		II	T,S,T,T,T,S,T	D,E,F,G,A,B,C,D
     Phrygian		III	S,T,T,T,S,T,T	E,F,G,A,B,C,D,E
     Lydian		IV	T,T,T,S,T,T,S	F,G,A,B,C,D,E,F
     Mixolydian		V	T,T,S,T,T,S,T	G,A,B,C,D,E,F,G
     Aeolian	Natural minor scale	VI	T,S,T,T,S,T,T	A,B,C,D,E,F,G,A
     Locrian		VII	S,T,T,S,T,T,T	B,C,D,E,F,G,A,B
     */

    expect(Scale.majorPentatonic.inKey(Key.get(KeyEnum.C)).toString(), '[C, D, E, G, A, C]');
    expect(Scale.minorPentatonic.inKey(Key.get(KeyEnum.A)).toString(), '[A, C, D, E, G, A]');
    expect(Scale.minorPentatonic.inKey(Key.get(KeyEnum.C)).toString(), '[C, E♭, F, G, B♭, C]');
  });
}
