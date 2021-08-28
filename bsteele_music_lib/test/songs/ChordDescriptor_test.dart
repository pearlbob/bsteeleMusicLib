import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/musicConstants.dart';
import 'package:test/test.dart';

void main() {
  test('ChordDescriptor testing', () {
    expect(ChordDescriptor.major, ChordDescriptor.major);
    expect(ChordDescriptor.parseString('' + MusicConstants.greekCapitalDelta), ChordDescriptor.major7);
    expect(ChordDescriptor.diminished, ChordDescriptor.parseString('' + MusicConstants.diminishedCircle));
    expect(ChordDescriptor.major, ChordDescriptor.parseString(''));
    expect(ChordDescriptor.minor, ChordDescriptor.parseString('m'));
    expect(ChordDescriptor.dominant7, ChordDescriptor.parseString('7'));
    expect(ChordDescriptor.major7, ChordDescriptor.parseString('maj7'));
    expect(ChordDescriptor.minor7, ChordDescriptor.parseString('m7'));
    expect(ChordDescriptor.augmented5, ChordDescriptor.parseString('aug5'));
    expect(ChordDescriptor.diminished, ChordDescriptor.parseString('dim'));
    expect(ChordDescriptor.suspended4, ChordDescriptor.parseString('sus4'));
    expect(ChordDescriptor.nineSus4, ChordDescriptor.parseString('9sus4'));
    expect(ChordDescriptor.power5, ChordDescriptor.parseString('5'));
    expect(ChordDescriptor.dominant9, ChordDescriptor.parseString('9'));
    expect(ChordDescriptor.dominant13, ChordDescriptor.parseString('13'));
    expect(ChordDescriptor.dominant11, ChordDescriptor.parseString('11'));
    expect(ChordDescriptor.minor7b5, ChordDescriptor.parseString('m7b5'));
    expect(ChordDescriptor.add9, ChordDescriptor.parseString('add9'));
    expect(ChordDescriptor.madd9, ChordDescriptor.parseString('madd9'));
    expect(ChordDescriptor.jazz7b9, ChordDescriptor.parseString('jazz7b9'));
    expect(ChordDescriptor.sevenSharp5, ChordDescriptor.parseString('7#5'));
    expect(ChordDescriptor.sevenFlat5, ChordDescriptor.parseString('7b5'));
    expect(ChordDescriptor.sevenSharp9, ChordDescriptor.parseString('7#9'));
    expect(ChordDescriptor.sevenFlat9, ChordDescriptor.parseString('7b9'));
    expect(ChordDescriptor.major6, ChordDescriptor.parseString('6'));
    expect(ChordDescriptor.six9, ChordDescriptor.parseString('69'));
    expect(ChordDescriptor.power5, ChordDescriptor.parseString('5'));
    expect(ChordDescriptor.diminished7, ChordDescriptor.parseString('dim7'));
    expect(ChordDescriptor.augmented, ChordDescriptor.parseString('aug'));
    expect(ChordDescriptor.augmented5, ChordDescriptor.parseString('aug5'));
    expect(ChordDescriptor.augmented7, ChordDescriptor.parseString('aug7'));
    expect(ChordDescriptor.suspended7, ChordDescriptor.parseString('sus7'));
    expect(ChordDescriptor.suspended2, ChordDescriptor.parseString('sus2'));
    expect(ChordDescriptor.suspended, ChordDescriptor.parseString('sus'));
    expect(ChordDescriptor.minor11, ChordDescriptor.parseString('m11'));
    expect(ChordDescriptor.minor13, ChordDescriptor.parseString('m13'));

    for (ChordDescriptor cd in ChordDescriptor.values) {
      logger.i(cd.toString() + ':\t' + cd.chordComponentsToString());
    }
    {
      ChordDescriptor cd1 = ChordDescriptor.dominant7;
      for (ChordDescriptor cd2 in ChordDescriptor.values) {
        int compareValue = cd2.compareTo(cd1);
        compareValue = (compareValue < 0 ? -1 : (compareValue > 0 ? 1 : 0));

        logger.i(cd2.toString() + ':\tcompare:\t' + compareValue.toString());
        if (cd1 == cd2) {
          expect(compareValue, 0);
        } else {
          expect(compareValue, cd2.name.compareTo(cd1.name));
        }
      }
    }
  });

  test('ChordDescriptor all values', () {
    expect(ChordDescriptor.completenessTest(), 0);
    ChordDescriptor chordDescriptor = ChordDescriptor.capMajor;
    logger.i('$chordDescriptor');
    for (ChordDescriptor cd in ChordDescriptor.values) {
      logger.d('$cd');
    }
    logger.d('length: ${ChordDescriptor.values.length}');
    expect(ChordDescriptor.values.length, 53); // expect this to change when a ChordDescriptor is added!
  });

  test('ChordDescriptor is minor', () {
    expect(ChordDescriptor.major.isMinor(), false);
    expect(ChordDescriptor.major.isMajor(), true);
    expect(ChordDescriptor.minor.isMinor(), true);
    expect(ChordDescriptor.minor.isMajor(), false);

    expect(ChordDescriptor.major7.isMajor(), true);
    expect(ChordDescriptor.dominant7.isMajor(), true);
    expect(ChordDescriptor.dominant9.isMajor(), true);
    expect(ChordDescriptor.add9.isMajor(), true);
    expect(ChordDescriptor.madd9.isMajor(), false);
    expect(ChordDescriptor.augmented.isMajor(), true);
    expect(ChordDescriptor.suspended.isMajor(), true);

    expect(ChordDescriptor.minor7.isMinor(), true);
    expect(ChordDescriptor.diminished.isMinor(), true);
    expect(ChordDescriptor.minor7b5.isMinor(), true);
    expect(ChordDescriptor.madd9.isMinor(), true);
    expect(ChordDescriptor.msus4.isMinor(), true);
    expect(ChordDescriptor.dimMasculineOrdinalIndicator.isMinor(), true);

    expect(ChordDescriptor.nineSus4.isMinor(), false);
    expect(ChordDescriptor.suspended4.isMinor(), false);
    expect(ChordDescriptor.sevenSus4.isMinor(), false);
  });
}
