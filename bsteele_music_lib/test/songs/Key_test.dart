import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/musicConstants.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/pitch.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

List<ScaleChord> _scaleChords = [];

void _scaleChordAdd(ScaleChord? scaleChord) {
  if (scaleChord != null) {
    _scaleChords.add(scaleChord);
  }
}

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
          expect(!scaleNote.toString().contains('♭'), true);
        }
      } else {
        for (int i = -18; i < 18; i++) {
          ScaleNote scaleNote = key.getScaleNoteByHalfStep(i);
          logger.i('\t' + i.toString() + ': ' + scaleNote.toString());
          expect(!scaleNote.toString().contains('♯'), true);
        }
      }
    }
  });

  test('testGuessKey testing', () {
    Key key;

    _scaleChords = [];
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Gb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Cb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Db, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(key.getKeyScaleNote().getEnum(), ScaleNoteEnum.Gb);

    _scaleChords.clear();

    _scaleChordAdd(ScaleChord.parseString('Gb'));
    _scaleChordAdd(ScaleChord.parseString('Cb'));
    _scaleChordAdd(ScaleChord.parseString('Db7'));
    key = Key.guessKey(_scaleChords);
    expect(key.getKeyScaleNote().getEnum(), ScaleNoteEnum.Gb);

    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.C));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.F));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.G, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.C, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Db));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Gb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Ab, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Db, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Cs));
    _scaleChordAdd(ScaleChord.parseString('F#'));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Gs, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Db, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Bb, ChordDescriptor.minor));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Db, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  A    Bm   C♯m  D    E7   F♯m  G♯m7b5
    //  B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5
    //  E    F♯m  G♯m  A    B7   C♯m  D♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.A));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Fs, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.B, ChordDescriptor.minor));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.B, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.E, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.E, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.D, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.A, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    //  F    Gm   Am   B♭   C7   Dm   Em7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Ab));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.F, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.G, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Bb, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.F, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Eb, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Eb, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  C    Dm   Em   F    G7   Am   Bm7b5
    //  A    Bm   C♯m  D    E7   F♯m  G♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.A, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.D, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.E, ChordDescriptor.minor));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.A, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.G, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.D, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5
    //  E    F♯m  G♯m  A    B7   C♯m  D♯m7b5
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Gs, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Ds, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.E));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Eb, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Fs, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.E, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Bb, ChordDescriptor.minor));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Bb, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Ab, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Ab, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Db, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Ab, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.Bb, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Db));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Db, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.Ab));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.Ab, key.getKeyScaleNote().getEnum());

    //  1     2   3    4    5    6     7
    //  G    Am   Bm   C    D7   Em   F♯m7b5
    //  D    Em   F♯m  G    A7   Bm   C♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.D));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.A));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.G));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNoteEnum.D, key.getKeyScaleNote().getEnum());
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.C));
    key = Key.guessKey(_scaleChords);
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
    expect(Key.parseString('B♭')?.keyEnum, KeyEnum.Bb);
    expect(Key.parseString('Bb')?.keyEnum, KeyEnum.Bb);
    expect(Key.parseString('F#')?.keyEnum, KeyEnum.Fs);
    expect(Key.parseString('F♯')?.keyEnum, KeyEnum.Fs);
    expect(Key.parseString('Fs')?.keyEnum, KeyEnum.Fs);
    expect(Key.parseString('F')?.keyEnum, KeyEnum.F);
    expect(Key.parseString('E♭')?.keyEnum, KeyEnum.Eb);
    expect(Key.parseString('Eb')?.keyEnum, KeyEnum.Eb);
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

  test('test clef stuff', () {
    // for (Pitch pitch in Pitch.sharps) {
    //   logger.d(
    //       '$pitch: ${pitch.number}, scale: ${pitch.scaleNumber}, octave: ${pitch.octaveNumber}'
    //           ', treble: ${Key.getStaffPosition(Clef.treble, pitch)}'
    //           ', bass:  ${Key.getStaffPosition(Clef.bass, pitch)}');
    // }
    // for (Pitch pitch in Pitch.flats) {
    //   logger.d(
    //       '$pitch: ${pitch.number}, label: ${pitch.octaveNumber}'
    //           ', treble: ${Key.getStaffPosition(Clef.treble, pitch)}'
    //           ', bass:  ${Key.getStaffPosition(Clef.bass, pitch)}');
    // }

    //  middle c is at the first lower stave of the treble clef staff
    expect(Key.getStaffPosition(Clef.treble, Pitch.get(PitchEnum.C4)), 5);

    expect(Key.getStaffPosition(Clef.treble, Pitch.get(PitchEnum.G5)), -0.5);
    expect(Key.getStaffPosition(Clef.treble, Pitch.get(PitchEnum.C5)), 1.5);
    expect(Key.getStaffPosition(Clef.treble, Pitch.get(PitchEnum.G4)), 3);
    expect(Key.getStaffPosition(Clef.treble, Pitch.get(PitchEnum.D4)), 4.5);
    expect(Key.getStaffPosition(Clef.treble, Pitch.get(PitchEnum.Ds4)), 4.5);

    //  bass clef algorithm is for bass!   not piano!
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.C3)), -1);

    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.B2)), -0.5);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Bb2)), -0.5);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.A2)), 0);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.As2)), 0);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Gs2)), 1 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.G2)), 1 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.F2)), 2 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.E2)), 3 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.D2)), 4 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.C2)), 5 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.B1)), 6 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.A1)), 7 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Gs1)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.G1)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Gb1)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.F1)), 9 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Fb1)), 9 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Es1)), 10 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.E1)), 10 / 2);

    int i = 0;
    for (Pitch pitch in Pitch.flats) {
      Pitch sharp = pitch.asSharp();
      expect(sharp.isFlat, false);
      if (pitch.isNatural) {
        expect(sharp.isNatural, true);
      } else {
        expect(sharp.isSharp, true);
      }
      expect(sharp.number, pitch.number);
      expect(pitch.number, i++);
    }
    i = 0;
    for (Pitch pitch in Pitch.sharps) {
      Pitch flat = pitch.asFlat();
      expect(flat.isSharp, false);
      if (pitch.isNatural) {
        expect(flat.isNatural, true);
      } else {
        expect(flat.isFlat, true);
      }
      expect(flat.number, pitch.number);
      expect(pitch.number, i++);
    }
  });

  test('test key clef scale notes', () {
    for (KeyEnum keyEnum in KeyEnum.values) {
      Key key = Key.get(keyEnum);
      for (int i = 0; i < MusicConstants.notesPerScale; i++) {
        logger.d('${key.toString().padLeft(2)} ${key.getKeyValue()}: $i: ${key.getMajorScaleByNote(i)}');
      }
      for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
        Pitch pitch = Pitch
            .sharps[(i + MusicConstants.halfStepsFromAtoC + key.getKeyValue() * 7) % MusicConstants.halfStepsPerOctave];
        pitch = key.isSharp ? pitch.asSharp() : pitch.asFlat();
        ScaleNote keyScaleNote = key.getKeyScaleNoteFor(pitch.scaleNote);
        logger.d('\t${key.toString().padLeft(2)} ${key.getKeyScaleNote()}: ${key.getKeyScaleNote().halfStep}:'
            ' ${pitch.scaleNote.toString().padLeft(2)} $i  $keyScaleNote  ${key.accidentalString(pitch)}'
            '  ${key.accidental(pitch)}');
      }
    }

    logger.d('scale     1   2   3   4   5   6   7');
    for (KeyEnum keyEnum in KeyEnum.values) {
      Key key = Key.get(keyEnum);
      String s = '';
      for (int i = 0; i < MusicConstants.notesPerScale; i++) {
        s += '  ${key.getMajorScaleByNote(i).toString().padLeft(2)}';
      }
      logger.d('key ${key.toString().padLeft(2)}: $s');
    }
    logger.d('');
    logger.d('');

    for (KeyEnum keyEnum in KeyEnum.values) {
      Key key = Key.get(keyEnum);
      logger.i('');
      logger.i('key ${key.toString().padLeft(2)}:     1   2   3   4   5   6   7   8   9  10  11  12');

      String s = '';
      // key.getKeyScaleNoteByHalfStep(i).toString().padLeft(2)
      for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
        Pitch pitch = key.isSharp ? Pitch.sharps[i + key.halfStep] : Pitch.flats[i + key.halfStep];
        s += '  ${pitch.scaleNote.toString().padLeft(2)}';
      }

      logger.i('pitches: $s');

      s = '';
      for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
        Pitch pitch = Pitch.sharps[i + key.halfStep];
        s += '  ${key.accidentalString(pitch).padLeft(2)}';
      }
      logger.i('shown as:$s');
    }

    for (KeyEnum keyEnum in KeyEnum.values) {
      Key key = Key.get(keyEnum);

      Pitch pitch;
      ScaleNote? scaleNote;
      for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
        pitch = key.isSharp ? Pitch.sharps[i + key.halfStep] : Pitch.flats[i + key.halfStep];
        if (scaleNote != null) {
          expect((pitch.scaleNote.halfStep - scaleNote.halfStep) % MusicConstants.halfStepsPerOctave, 1);
        }
        scaleNote = pitch.scaleNote;
      }
      //  around the loop
      expect((key.halfStep - (scaleNote?.halfStep ?? -1)) % MusicConstants.halfStepsPerOctave, 1);

      String? lastAccidental;
      for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
        Pitch pitch = Pitch.sharps[i + key.halfStep];
        String accidental = key.accidentalString(pitch);
        if (key.isSharp) {
          expect(accidental.contains(MusicConstants.flatChar), false);
        } else {
          expect(accidental.contains(MusicConstants.sharpChar), false);
        }
        if (lastAccidental != null) {
          logger.v('acc: "$accidental" ${accidental[0].codeUnitAt(0).toString()}'
              ', last: "${lastAccidental.toString()}"  ${lastAccidental[0].codeUnitAt(0).toString()}');

          //  same scale letter or the next one
          expect(
              accidental[0] == lastAccidental[0] ||
                  (accidental.codeUnitAt(0) == lastAccidental.codeUnitAt(0) + 1) ||
                  (accidental.codeUnitAt(0) == 'A'.codeUnitAt(0) && lastAccidental.codeUnitAt(0) == 'G'.codeUnitAt(0)),
              true);
        }

        //  check that sharps are following
        if (accidental.contains(MusicConstants.sharpChar)) {
          expect(lastAccidental?.contains(MusicConstants.naturalChar), isFalse);
          expect(lastAccidental?.contains(MusicConstants.flatChar), isFalse);
        }

        //  check that flats are leading
        if (lastAccidental?.contains(MusicConstants.flatChar) ?? false) {
          expect(accidental.contains(MusicConstants.naturalChar), isFalse);
          expect(accidental.contains(MusicConstants.sharpChar), isFalse);
        }

        lastAccidental = accidental;
      }
    }
  });
}
/*
Bodhi approved:

 key G♭:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:   G♭   G  A♭   A  B♭   B   C  D♭   D  E♭   E   F
shown as:   G  G♮   A  A♮   B   C  C♮   D  D♮   E  E♮   F

key D♭:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:   D♭   D  E♭   E   F  G♭   G  A♭   A  B♭   B   C
shown as:   D  D♮   E  E♮   F   G  G♮   A  A♮   B  B♮   C

key A♭:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:   A♭   A  B♭   B   C  D♭   D  E♭   E   F  G♭   G
shown as:   A  A♮   B  B♮   C   D  D♮   E  E♮   F  G♭   G

key E♭:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:   E♭   E   F  G♭   G  A♭   A  B♭   B   C  D♭   D
shown as:   E  E♮   F  G♭   G   A  A♮   B  B♮   C  D♭   D

key B♭:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:   B♭   B   C  D♭   D  E♭   E   F  G♭   G  A♭   A
shown as:   B  B♮   C  D♭   D   E  E♮   F  G♭   G  A♭   A

key  F:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:    F  G♭   G  A♭   A  B♭   B   C  D♭   D  E♭   E
shown as:   F  G♭   G  A♭   A   B  B♮   C  D♭   D  E♭   E

key  C:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:    C  D♭   D  E♭   E   F  G♭   G  A♭   A  B♭   B
shown as:   C  D♭   D  E♭   E   F  G♭   G  A♭   A  B♭   B

key  G:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:    G  G♯   A  A♯   B   C  C♯   D  D♯   E   F  F♯
shown as:   G  G♯   A  A♯   B   C  C♯   D  D♯   E  F♮   F

key  D:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:    D  D♯   E   F  F♯   G  G♯   A  A♯   B   C  C♯
shown as:   D  D♯   E  F♮   F   G  G♯   A  A♯   B  C♮   C

key  A:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:    A  A♯   B   C  C♯   D  D♯   E   F  F♯   G  G♯
shown as:   A  A♯   B  C♮   C   D  D♯   E  F♮   F  G♮   G

key  E:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:    E   F  F♯   G  G♯   A  A♯   B   C  C♯   D  D♯
shown as:   E  F♮   F  G♮   G   A  A♯   B  C♮   C  D♮   D

key  B:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:    B   C  C♯   D  D♯   E   F  F♯   G  G♯   A  A♯
shown as:   B  C♮   C  D♮   D   E  F♮   F  G♮   G  A♮   A

key F♯:     1   2   3   4   5   6   7   8   9  10  11  12
pitches:   F♯   G  G♯   A  A♯   B   C  C♯   D  D♯   E   F
shown as:   F  G♮   G  A♮   A   B  C♮   C  D♮   D  E♮   E

 */
