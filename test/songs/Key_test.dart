import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/ChordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/MusicConstants.dart';
import 'package:bsteeleMusicLib/songs/Key.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

class _Help {
  static String majorScale(KeyEnum keyEnum) {
    StringBuffer sb = StringBuffer();
    for (int j = 0; j < 7; j++) {
      ScaleNote sn = Key.get(keyEnum).getMajorScaleByNote(j);
      String s = sn.toMarkup();
      sb.write(s);
      if (s.toString().length < 2) sb.write(' ');
      sb.write(' ');
    }
    return sb.toString().trim();
  }

  static String diatonicByDegree(KeyEnum keyEnum) {
    StringBuffer sb = StringBuffer();
    for (int j = 0; j < 7; j++) {
      ScaleChord sc = Key.get(keyEnum).getMajorDiatonicByDegree(j);
      String s = sc.toMarkup();
      sb.write(s);
      int i = s.length;
      while (i < 4) {
        i++;
        sb.write(' ');
      }
      sb.write(' ');
    }
    return sb.toString().trim();
  }
}

void main() {
  Logger.level = Level.info;

  test('testGetKeyByValue testing', () {
    //  the table of values
    for (int i = -6; i <= 6; i++) {
      Key key = Key.getKeyByValue(i);
      expect(i, key.getKeyValue());
      logger.v((i >= 0 ? ' ' : '') +
              i.toString() +
              ' ' +
              key.name
              //+ " toString: "
              +
              ' (' +
              key.toString() +
              ')\t'
          //+ " html: " + key.toHtml()
          );

      logger.i('\tscale: ');
      for (int j = 0; j < 7; j++) {
        ScaleNote sn = key.getMajorScaleByNote(j);
        String s = sn.toString();
        logger.i(s);
        if (s.toString().length < 2) logger.i(' ');
        logger.i(' ');
      }

      logger.i('\tdiatonics: ');
      for (int j = 0; j < 7; j++) {
        ScaleChord sc = key.getMajorDiatonicByDegree(j);
        String s = sc.toString();
        logger.i(s);
        int len = s.length;
        while (len < 4) {
          len++;
          logger.i(' ');
        }
        logger.i(' ');
      }

      logger.i('\tall notes: ');
      for (int j = 0; j < 12; j++) {
        ScaleNote sn = key.getScaleNoteByHalfStep(j);
        String s = sn.toString();
        logger.i(s);
        if (s.toString().length < 2) logger.i(' ');
        logger.i(' ');
      }
    }

    expect(_Help.majorScale(KeyEnum.Gb), 'Gb Ab Bb Cb Db Eb F');
    //  fixme: actual should be first on expect!
    expect(_Help.majorScale(KeyEnum.Db), 'Db Eb F  Gb Ab Bb C');
    expect(_Help.majorScale(KeyEnum.Ab), 'Ab Bb C  Db Eb F  G');
    expect(_Help.majorScale(KeyEnum.Eb), 'Eb F  G  Ab Bb C  D');
    expect(_Help.majorScale(KeyEnum.Bb), 'Bb C  D  Eb F  G  A');
    expect(_Help.majorScale(KeyEnum.F), 'F  G  A  Bb C  D  E');
    expect(_Help.majorScale(KeyEnum.C), 'C  D  E  F  G  A  B');
    expect(_Help.majorScale(KeyEnum.G), 'G  A  B  C  D  E  F#');
    expect(_Help.majorScale(KeyEnum.D), 'D  E  F# G  A  B  C#');
    expect(_Help.majorScale(KeyEnum.E), 'E  F# G# A  B  C# D#');
    expect(_Help.majorScale(KeyEnum.B), 'B  C# D# E  F# G# A#');
    expect(_Help.majorScale(KeyEnum.Fs), 'F# G# A# B  C# D# E#');

    expect(_Help.diatonicByDegree(KeyEnum.Gb), 'Gb   Abm  Bbm  Cb   Db7  Ebm  Fm7b5');
    expect('Db   Ebm  Fm   Gb   Ab7  Bbm  Cm7b5', _Help.diatonicByDegree(KeyEnum.Db));
    expect('Ab   Bbm  Cm   Db   Eb7  Fm   Gm7b5', _Help.diatonicByDegree(KeyEnum.Ab));
    expect('Eb   Fm   Gm   Ab   Bb7  Cm   Dm7b5', _Help.diatonicByDegree(KeyEnum.Eb));
    expect('Bb   Cm   Dm   Eb   F7   Gm   Am7b5', _Help.diatonicByDegree(KeyEnum.Bb));
    expect('F    Gm   Am   Bb   C7   Dm   Em7b5', _Help.diatonicByDegree(KeyEnum.F));
    expect('C    Dm   Em   F    G7   Am   Bm7b5', _Help.diatonicByDegree(KeyEnum.C));
    expect('G    Am   Bm   C    D7   Em   F#m7b5', _Help.diatonicByDegree(KeyEnum.G));
    expect('D    Em   F#m  G    A7   Bm   C#m7b5', _Help.diatonicByDegree(KeyEnum.D));
    expect('A    Bm   C#m  D    E7   F#m  G#m7b5', _Help.diatonicByDegree(KeyEnum.A));
    expect('E    F#m  G#m  A    B7   C#m  D#m7b5', _Help.diatonicByDegree(KeyEnum.E));
    expect('B    C#m  D#m  E    F#7  G#m  A#m7b5', _Help.diatonicByDegree(KeyEnum.B));
    expect('F#   G#m  A#m  B    C#7  D#m  E#m7b5', _Help.diatonicByDegree(KeyEnum.Fs));

//        -6 Gb toString: G♭ html: G&#9837;
//        G♭ A♭ B♭ C♭ D♭ E♭ F
//        G♭ D♭ A♭ E♭ B♭ F  C
//        G♭ G  A♭ A  B♭ C♭ C  D♭ D  E♭ E  F
//        -5 Db toString: D♭ html: D&#9837;
//        D♭ E♭ F  G♭ A♭ B♭ C
//        D♭ A♭ E♭ B♭ F  C  G
//        D♭ D  E♭ E  F  G♭ G  A♭ A  B♭ B  C
//        -4 Ab toString: A♭ html: A&#9837;
//        A♭ B♭ C  D♭ E♭ F  G
//        A♭ E♭ B♭ F  C  G  D
//        A♭ A  B♭ B  C  D♭ D  E♭ E  F  G♭ G
//                -3 Eb toString: E♭ html: E&#9837;
//        E♭ F  G  A♭ B♭ C  D
//        E♭ B♭ F  C  G  D  A
//        E♭ E  F  G♭ G  A♭ A  B♭ B  C  D♭ D
//                -2 Bb toString: B♭ html: B&#9837;
//        B♭ C  D  E♭ F  G  A
//        B♭ F  C  G  D  A  E
//        B♭ B  C  D♭ D  E♭ E  F  G♭ G  A♭ A
//                -1 F toString: F html: F
//        F  G  A  B♭ C  D  E
//        F  C  G  D  A  E  B
//        F  G♭ G  A♭ A  B♭ B  C  D♭ D  E♭ E
//        0 C toString: C html: C
//        C  D  E  F  G  A  B
//        C  G  D  A  E  B  F♯
//        C  C♯ D  D♯ E  F  F♯ G  G♯ A  A♯ B
//        1 G toString: G html: G
//        G  A  B  C  D  E  F♯
//        G  D  A  E  B  F♯ C♯
//        G  G♯ A  A♯ B  C  C♯ D  D♯ E  F  F♯
//        2 D toString: D html: D
//        D  E  F♯ G  A  B  C♯
//        D  A  E  B  F♯ C♯ G♯
//        D  D♯ E  F  F♯ G  G♯ A  A♯ B  C  C♯
//        3 A toString: A html: A
//        A  B  C♯ D  E  F♯ G♯
//        A  E  B  F♯ C♯ G♯ D♯
//        A  A♯ B  C  C♯ D  D♯ E  F  F♯ G  G♯
//        4 E toString: E html: E
//        E  F♯ G♯ A  B  C♯ D♯
//        E  B  F♯ C♯ G♯ D♯ A♯
//        E  F  F♯ G  G♯ A  A♯ B  C  C♯ D  D♯
//        5 B toString: B html: B
//        B  C♯ D♯ E  F♯ G♯ A♯
//        B  F♯ C♯ G♯ D♯ A♯ F
//        B  C  C♯ D  D♯ E  F  F♯ G  G♯ A  A♯
//        6 Fs toString: F♯ html: F&#9839;
//        F♯ G♯ A♯ B  C♯ D♯ E♯
//        F♯ C♯ G♯ D♯ A♯ E♯ C
//        F♯ G  G♯ A  A♯ B  C  C♯ D  D♯ E  E♯
  });

  test('testIsDiatonic testing', () {
    for (Key key in Key.values) {
      for (int j = 0; j < MusicConstants.notesPerScale; j++) {
        ScaleChord sc = key.getMajorDiatonicByDegree(j);
        expect(true, key.isDiatonic(sc));
        // fixme: add more tests
      }
    }
  });

  test('testMinorKey testing', () {
    expect(Key.get(KeyEnum.C).getMinorKey(), Key.get(KeyEnum.A));
    expect(Key.get(KeyEnum.F).getMinorKey(), Key.get(KeyEnum.D));
    expect(Key.get(KeyEnum.A).getMinorKey(), Key.get(KeyEnum.Gb));
    expect(Key.get(KeyEnum.Ab).getMinorKey(), Key.get(KeyEnum.F));
    expect(Key.get(KeyEnum.Eb).getMinorKey(), Key.get(KeyEnum.C));
  });

  test('testScaleNoteByHalfStep testing', () {
    for (Key key in Key.values) {
      logger.i('key ' + key.toString());
      if (key.isSharp) {
        for (int i = -18; i < 18; i++) {
          ScaleNote scaleNote = key.getScaleNoteByHalfStep(i);
          logger.i('\t' + i.toString() + ': ' + scaleNote.toString());
          expect(true, !scaleNote.toString().contains('♭'));
        }
      } else {
        for (int i = -18; i < 18; i++) {
          ScaleNote scaleNote = key.getScaleNoteByHalfStep(i);
          logger.i('\t' + i.toString() + ': ' + scaleNote.toString());
          expect(true, !scaleNote.toString().contains('♯'));
        }
      }
    }
  });

  test('testGuessKey testing', () {
    Key key;

    List<ScaleChord> scaleChords = [];
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Gb));
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Cb));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Db, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(key.getKeyScaleNote().getEnum(), ScaleNoteEnum.Gb);

    scaleChords.clear();

    scaleChords.add(ScaleChord.parseString('Gb'));
    scaleChords.add(ScaleChord.parseString('Cb'));
    scaleChords.add(ScaleChord.parseString('Db7'));
    key = Key.guessKey(scaleChords);
    expect(key.getKeyScaleNote().getEnum(), ScaleNoteEnum.Gb);

    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.C));
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.F));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.G, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.C, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Db));
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Gb));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Ab, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Db, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Cs));
    scaleChords.add(ScaleChord.parseString('F#'));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Gs, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Db, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Bb, ChordDescriptor.minor));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Db, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  A    Bm   C♯m  D    E7   F♯m  G♯m7b5
    //  B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5
    //  E    F♯m  G♯m  A    B7   C♯m  D♯m7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.A));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Fs, ChordDescriptor.minor));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.B, ChordDescriptor.minor));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.B, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.E, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.E, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.D, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.A, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    //  F    Gm   Am   B♭   C7   Dm   Em7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Ab));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.F, ChordDescriptor.minor));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.G, ChordDescriptor.minor));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Bb, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.F, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Eb, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Eb, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  C    Dm   Em   F    G7   Am   Bm7b5
    //  A    Bm   C♯m  D    E7   F♯m  G♯m7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.A, ChordDescriptor.minor));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.D, ChordDescriptor.minor));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.E, ChordDescriptor.minor));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.A, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.G, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.D, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5
    //  E    F♯m  G♯m  A    B7   C♯m  D♯m7b5
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Gs, ChordDescriptor.minor));
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Ds, ChordDescriptor.minor));
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.E));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Eb, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Fs, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.E, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Bb, ChordDescriptor.minor));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Bb, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Ab, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Ab, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Db, ChordDescriptor.dominant7));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Ab, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Bb, ChordDescriptor.minor));
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Db));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Db, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Ab));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.Ab, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  G    Am   Bm   C    D7   Em   F♯m7b5
    //  D    Em   F♯m  G    A7   Bm   C♯m7b5
    scaleChords.clear();
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.D));
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.A));
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.G));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.D, key.getKeyScaleNote().getEnum());
    scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.C));
    key = Key.guessKey(scaleChords);
    expect(ScaleNoteEnum.G, key.getKeyScaleNote().getEnum());
  });

  test('testTranspose testing', () {
    for (int k = -6; k <= 6; k++) {
      Key key = Key.getKeyByValue(k);
      logger.d(key.toString() + ':');

      for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
        ScaleNote fsn = ScaleNote.getFlatByHalfStep(i);
        ScaleNote ssn = ScaleNote.getSharpByHalfStep(i);
        expect(fsn.halfStep, ssn.halfStep);
//                logger.i(" " + i + ":");
//                if ( i < 10)
//                    logger.i(" ");
        for (int j = 0; j <= MusicConstants.halfStepsPerOctave; j++) {
          ScaleNote fTranSn = key.transpose(fsn, j);
          ScaleNote sTranSn = key.transpose(ssn, j);
          expect(fTranSn.halfStep, sTranSn.halfStep);
//                    logger.i(" ");
//                    ScaleNote sn =  key.getScaleNoteByHalfStep(fTranSn.getHalfStep());
//                    String s = sn.toString();
//                    logger.i(s);
//                    if ( s.length() < 2)
//                        logger.i(" ");

        }
      }
    }
  });

  test('testKeysByHalfStep testing', () {
    Key key = Key.get(KeyEnum.A);
    Key lastKey = key.previousKeyByHalfStep();
    Set<Key> set = {};
    for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
      Key nextKey = key.nextKeyByHalfStep();
      expect(false, key == lastKey);
      expect(false, key == nextKey);
      expect(key, lastKey.nextKeyByHalfStep());
      expect(key, nextKey.previousKeyByHalfStep());
      expect(false, set.contains(key));
      set.add(key);

      //  increment
      lastKey = key;
      key = nextKey;
    }
    expect(key, Key.get(KeyEnum.A));
    expect(MusicConstants.halfStepsPerOctave, set.length);
  });

  test('testKeyParse testing', () {
    expect(Key.parseString('B♭').keyEnum, KeyEnum.Bb);
    expect(Key.parseString('Bb').keyEnum, KeyEnum.Bb);
    expect(Key.parseString('F#').keyEnum, KeyEnum.Fs);
    expect(Key.parseString('F♯').keyEnum, KeyEnum.Fs);
    expect(Key.parseString('Fs').keyEnum, KeyEnum.Fs);
    expect(Key.parseString('F').keyEnum, KeyEnum.F);
    expect(Key.parseString('E♭').keyEnum, KeyEnum.Eb);
    expect(Key.parseString('Eb').keyEnum, KeyEnum.Eb);
  });

  test('test byHalfStep()', () {
    for (int off = -6; off <= 6; off++) {
      logger.i('$off');
      Key key = Key.getKeyByHalfStep(off);

      for (int i = -6; i <= 6; i++) {
        Key offsetKey = Key.getKeyByHalfStep(off + i);
        logger.i('\t+$i: ${offsetKey.toString()}   ${key.toString()}');
      }
    }
  });

  test('test getKeyByHalfStep()', () {
    Key key = Key.get(KeyEnum.E);
    List<Key> test = Key.keysByHalfStepFrom(key);
    int i = MusicConstants.halfStepsPerOctave ~/ 2;
    Key tk = test[i];
    expect(tk, isNotNull);
    expect(tk.keyEnum, KeyEnum.Bb);
    expect(test[0].keyEnum, KeyEnum.E);
    expect(test[12].keyEnum, KeyEnum.E);
  });
}
