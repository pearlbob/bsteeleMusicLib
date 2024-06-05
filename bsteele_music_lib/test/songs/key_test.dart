import 'dart:collection';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord_descriptor.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:bsteele_music_lib/songs/pitch.dart';
import 'package:bsteele_music_lib/songs/scale_chord.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

List<ScaleChord> _scaleChords = [];

void _scaleChordAdd(ScaleChord? scaleChord) {
  if (scaleChord != null) {
    _scaleChords.add(scaleChord);
  }
}

class _Help {
  static String majorScale(Key key) {
    StringBuffer sb = StringBuffer();
    for (int j = 0; j < 7; j++) {
      ScaleNote sn = key.getMajorScaleByNote(j);
      String s = sn.toMarkup();
      sb.write(s);
      if (s.toString().length < 2) sb.write(' ');
      sb.write(' ');
    }
    return sb.toString().trim();
  }

  static String diatonicByDegree(Key key) {
    StringBuffer sb = StringBuffer();
    for (int j = 0; j < 7; j++) {
      ScaleChord sc = key.getMajorDiatonicByDegree(j);
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
    {
      //  let's start with a sane key
      var key = Key.C;
      expect(key.transpose(ScaleNote.Fs, 3), ScaleNote.A);
      expect(key.transpose(ScaleNote.Fs, 2), ScaleNote.Ab);
      expect(key.transpose(ScaleNote.Fs, 1), ScaleNote.G);
      expect(key.transpose(ScaleNote.Fs, 0), ScaleNote.Gb);
      expect(key.transpose(ScaleNote.Fs, -1), ScaleNote.F);
      expect(key.transpose(ScaleNote.Fs, -2), ScaleNote.E);

      //  E F Gb G Ab A
      expect(key.transpose(ScaleNote.A, -4), ScaleNote.F);
      expect(key.transpose(ScaleNote.A, -3), ScaleNote.Gb);
      expect(key.transpose(ScaleNote.A, -2), ScaleNote.G);
      expect(key.transpose(ScaleNote.A, -1), ScaleNote.Ab);
      expect(key.transpose(ScaleNote.A, 0), ScaleNote.A);
      expect(key.transpose(ScaleNote.A, 1), ScaleNote.Bb);
      expect(key.transpose(ScaleNote.A, 2), ScaleNote.B);
      expect(key.transpose(ScaleNote.A, 3), ScaleNote.C);
      expect(key.transpose(ScaleNote.A, 4), ScaleNote.Db);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Gb);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.F);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
    }
    {
      //  let's start with another sane key, even if it's flat
      var key = Key.F;
      expect(key.transpose(ScaleNote.Fs, 3), ScaleNote.A);
      expect(key.transpose(ScaleNote.Fs, 2), ScaleNote.Ab);
      expect(key.transpose(ScaleNote.Fs, 1), ScaleNote.G);
      expect(key.transpose(ScaleNote.Fs, 0), ScaleNote.Gb);
      expect(key.transpose(ScaleNote.Fs, -1), ScaleNote.F);
      expect(key.transpose(ScaleNote.Fs, -2), ScaleNote.E);

      expect(key.transpose(ScaleNote.A, -4), ScaleNote.F);
      expect(key.transpose(ScaleNote.A, -3), ScaleNote.Gb);
      expect(key.transpose(ScaleNote.A, -2), ScaleNote.G);
      expect(key.transpose(ScaleNote.A, -1), ScaleNote.Ab);
      expect(key.transpose(ScaleNote.A, 0), ScaleNote.A);
      expect(key.transpose(ScaleNote.A, 1), ScaleNote.Bb);
      expect(key.transpose(ScaleNote.A, 2), ScaleNote.B);
      expect(key.transpose(ScaleNote.A, 3), ScaleNote.C);
      expect(key.transpose(ScaleNote.A, 4), ScaleNote.Db);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Gb);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.F);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
    }
    {
      //  let's start with another sane key, even if it's sharp
      var key = Key.G;
      expect(key.transpose(ScaleNote.Fs, 3), ScaleNote.A);
      expect(key.transpose(ScaleNote.Fs, 2), ScaleNote.Gs);
      expect(key.transpose(ScaleNote.Fs, 1), ScaleNote.G);
      expect(key.transpose(ScaleNote.Fs, 0), ScaleNote.Fs);
      expect(key.transpose(ScaleNote.Fs, -1), ScaleNote.F);
      expect(key.transpose(ScaleNote.Fs, -2), ScaleNote.E);

      expect(key.transpose(ScaleNote.A, -4), ScaleNote.F);
      expect(key.transpose(ScaleNote.A, -3), ScaleNote.Fs);
      expect(key.transpose(ScaleNote.A, -2), ScaleNote.G);
      expect(key.transpose(ScaleNote.A, -1), ScaleNote.Gs);
      expect(key.transpose(ScaleNote.A, 0), ScaleNote.A);
      expect(key.transpose(ScaleNote.A, 1), ScaleNote.As);
      expect(key.transpose(ScaleNote.A, 2), ScaleNote.B);
      expect(key.transpose(ScaleNote.A, 3), ScaleNote.C);
      expect(key.transpose(ScaleNote.A, 4), ScaleNote.Cs);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Fs);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.F);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
      expect(key.getScaleNoteByHalfStep(-6), ScaleNote.Ds);
    }
    {
      var key = Key.Fs;
      expect(key.transpose(ScaleNote.Fs, 3), ScaleNote.A);
      expect(key.transpose(ScaleNote.Fs, 2), ScaleNote.Gs);
      expect(key.transpose(ScaleNote.Fs, 1), ScaleNote.G);
      expect(key.transpose(ScaleNote.Fs, 0), ScaleNote.Fs);
      expect(key.transpose(ScaleNote.Fs, -1), ScaleNote.Es);
      expect(key.transpose(ScaleNote.Fs, -2), ScaleNote.E);
      expect(key.transpose(ScaleNote.A, -3), ScaleNote.Fs);
      expect(key.transpose(ScaleNote.A, -4), ScaleNote.Es);
      expect(key.transpose(ScaleNote.A, 0), ScaleNote.A);
      expect(key.transpose(ScaleNote.A, 1), ScaleNote.As);
      expect(key.transpose(ScaleNote.A, 2), ScaleNote.B);
      expect(key.transpose(ScaleNote.A, 3), ScaleNote.C);
      expect(key.transpose(ScaleNote.A, 4), ScaleNote.Cs);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Fs);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.Es);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
    }
    {
      var key = Key.Gb;
      expect(key.transpose(ScaleNote.Fs, 3), ScaleNote.A);
      expect(key.transpose(ScaleNote.Fs, 2), ScaleNote.Ab);
      expect(key.transpose(ScaleNote.Fs, 1), ScaleNote.G);
      expect(key.transpose(ScaleNote.Fs, 0), ScaleNote.Gb);
      expect(key.transpose(ScaleNote.Fs, -1), ScaleNote.F);
      expect(key.transpose(ScaleNote.Fs, -2), ScaleNote.E);
      expect(key.transpose(ScaleNote.A, -3), ScaleNote.Gb);
      expect(key.transpose(ScaleNote.A, -4), ScaleNote.F);
      expect(key.transpose(ScaleNote.A, 0), ScaleNote.A);
      expect(key.transpose(ScaleNote.A, 1), ScaleNote.Bb);
      expect(key.transpose(ScaleNote.A, 2), ScaleNote.Cb);
      expect(key.transpose(ScaleNote.A, 3), ScaleNote.C);
      expect(key.transpose(ScaleNote.A, 4), ScaleNote.Db);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Gb);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.F);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
      expect(key.getScaleNoteByHalfStep(-6), ScaleNote.Eb);
    }

    //  the table of values
    for (int i = -6; i <= 6; i++) {
      Key key = Key.getKeyByValue(i);
      expect(i, key.getKeyValue());
      logger.t('${i >= 0 ? ' ' : ''}$i ${key.name} ($key)\t'
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

    expect(_Help.majorScale(Key.Gb), 'Gb Ab Bb Cb Db Eb F');
    //  fixme: actual should be first on expect!
    expect(_Help.majorScale(Key.Db), 'Db Eb F  Gb Ab Bb C');
    expect(_Help.majorScale(Key.Ab), 'Ab Bb C  Db Eb F  G');
    expect(_Help.majorScale(Key.Eb), 'Eb F  G  Ab Bb C  D');
    expect(_Help.majorScale(Key.Bb), 'Bb C  D  Eb F  G  A');
    expect(_Help.majorScale(Key.F), 'F  G  A  Bb C  D  E');
    expect(_Help.majorScale(Key.C), 'C  D  E  F  G  A  B');
    expect(_Help.majorScale(Key.G), 'G  A  B  C  D  E  F#');
    expect(_Help.majorScale(Key.D), 'D  E  F# G  A  B  C#');
    expect(_Help.majorScale(Key.E), 'E  F# G# A  B  C# D#');
    expect(_Help.majorScale(Key.B), 'B  C# D# E  F# G# A#');
    expect(_Help.majorScale(Key.Fs), 'F# G# A# B  C# D# E#');

    expect(_Help.diatonicByDegree(Key.Gb), 'Gb   Abm  Bbm  Cb   Db7  Ebm  Fm7b5');
    expect('Db   Ebm  Fm   Gb   Ab7  Bbm  Cm7b5', _Help.diatonicByDegree(Key.Db));
    expect('Ab   Bbm  Cm   Db   Eb7  Fm   Gm7b5', _Help.diatonicByDegree(Key.Ab));
    expect('Eb   Fm   Gm   Ab   Bb7  Cm   Dm7b5', _Help.diatonicByDegree(Key.Eb));
    expect('Bb   Cm   Dm   Eb   F7   Gm   Am7b5', _Help.diatonicByDegree(Key.Bb));
    expect('F    Gm   Am   Bb   C7   Dm   Em7b5', _Help.diatonicByDegree(Key.F));
    expect('C    Dm   Em   F    G7   Am   Bm7b5', _Help.diatonicByDegree(Key.C));
    expect('G    Am   Bm   C    D7   Em   F#m7b5', _Help.diatonicByDegree(Key.G));
    expect('D    Em   F#m  G    A7   Bm   C#m7b5', _Help.diatonicByDegree(Key.D));
    expect('A    Bm   C#m  D    E7   F#m  G#m7b5', _Help.diatonicByDegree(Key.A));
    expect('E    F#m  G#m  A    B7   C#m  D#m7b5', _Help.diatonicByDegree(Key.E));
    expect('B    C#m  D#m  E    F#7  G#m  A#m7b5', _Help.diatonicByDegree(Key.B));
    expect('F#   G#m  A#m  B    C#7  D#m  E#m7b5', _Help.diatonicByDegree(Key.Fs));

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
    expect(Key.C.getMinorKey(), Key.A);
    expect(Key.F.getMinorKey(), Key.D);
    expect(Key.A.getMinorKey(), Key.Gb);
    expect(Key.Ab.getMinorKey(), Key.F);
    expect(Key.Eb.getMinorKey(), Key.C);
  });

  test('testScaleNoteByHalfStep testing', () {
    for (Key key in Key.values) {
      logger.i('key $key');
      if (key.isSharp) {
        for (int i = -18; i < 18; i++) {
          var scaleNote = key.getScaleNoteByHalfStep(i);
          logger.i('\t$i: $scaleNote');
          expect(!scaleNote.toString().contains('♭'), true);
        }
      } else {
        for (int i = -18; i < 18; i++) {
          var scaleNote = key.getScaleNoteByHalfStep(i);
          logger.i('\t$i: $scaleNote');
          expect(!scaleNote.toString().contains('♯'), true);
        }
      }
    }
  });

  test('testGuessKey testing', () {
    Key key;

    _scaleChords = [];
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.Gb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.Cb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Db, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(key.getKeyScaleNote(), ScaleNote.Gb);

    _scaleChords.clear();

    _scaleChordAdd(ScaleChord.parseString('Gb'));
    _scaleChordAdd(ScaleChord.parseString('Cb'));
    _scaleChordAdd(ScaleChord.parseString('Db7'));
    key = Key.guessKey(_scaleChords);
    expect(key.getKeyScaleNote(), ScaleNote.Gb);

    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.C));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.F));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.G, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.C, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.Db));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.Gb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Ab, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Db, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.Cs));
    _scaleChordAdd(ScaleChord.parseString('F#'));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Gs, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Db, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Bb, ChordDescriptor.minor));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Db, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  A    Bm   C♯m  D    E7   F♯m  G♯m7b5
    //  B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5
    //  E    F♯m  G♯m  A    B7   C♯m  D♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.A));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Fs, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.B, ChordDescriptor.minor));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.B, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.E, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.E, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.D, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.A, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    //  F    Gm   Am   B♭   C7   Dm   Em7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.Ab));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.F, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.G, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Bb, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.F, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Eb, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Eb, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  C    Dm   Em   F    G7   Am   Bm7b5
    //  A    Bm   C♯m  D    E7   F♯m  G♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.A, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.D, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.E, ChordDescriptor.minor));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.A, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.G, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.D, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5
    //  E    F♯m  G♯m  A    B7   C♯m  D♯m7b5
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Gs, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Ds, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.E));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Eb, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Fs, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.E, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Bb, ChordDescriptor.minor));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Bb, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Ab, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Ab, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Db, ChordDescriptor.dominant7));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Ab, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Bb, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.Db));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Db, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.Ab));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.Ab, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  G    Am   Bm   C    D7   Em   F♯m7b5
    //  D    Em   F♯m  G    A7   Bm   C♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.D));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.A));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.G));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.D, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(ScaleNote.C));
    key = Key.guessKey(_scaleChords);
    expect(ScaleNote.G, key.getKeyScaleNote());
  });

  test('testTranspose testing', () {
    for (int k = -6; k <= 6; k++) {
      Key key = Key.getKeyByValue(k);
      logger.d('$key:');

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
//                    ScaleNoteEnum3 sn =  key.getScaleNoteByHalfStep(fTranSn.getHalfStep());
//                    String s = sn.toString();
//                    logger.i(s);
//                    if ( s.length() < 2)
//                        logger.i(" ");
        }
      }
    }
  });

  test('testKeysByHalfStep testing', () {
    Key key = Key.A;
    Key lastKey = key.previousKeyByHalfStep();
    Set<Key> set = {};
    for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
      logger.i('key: $key');
      Key nextKey = key.nextKeyByHalfStep();
      expect(false, key == lastKey);
      expect(false, key == nextKey);
      expect(key, lastKey.nextKeyByHalfStep());
      if (key == Key.Gb) {
        expect(key.halfStep, nextKey.previousKeyByHalfStep().halfStep);
      } else {
        expect(key, nextKey.previousKeyByHalfStep());
      }
      expect(false, set.contains(key));
      set.add(key);

      //  increment
      lastKey = key;
      key = nextKey;
    }
    expect(key, Key.A);
    expect(MusicConstants.halfStepsPerOctave, set.length);
  });

  test('testKeyParse testing', () {
    expect(Key.parseString('B♭'), Key.Bb);
    expect(Key.parseString('Bb'), Key.Bb);
    expect(Key.parseString('F#'), Key.Fs);
    expect(Key.parseString('F♯'), Key.Fs);
    expect(Key.parseString('Fs'), Key.Fs);
    expect(Key.parseString('F'), Key.F);
    expect(Key.parseString('E♭'), Key.Eb);
    expect(Key.parseString('Eb'), Key.Eb);
  });

  test('test byHalfStep()', () {
    for (int off = -6; off <= 6; off++) {
      logger.i('$off');
      Key key = Key.getKeyByHalfStep(off);

      for (int i = -6; i <= 6; i++) {
        Key offsetKey = Key.getKeyByHalfStep(off + i);
        logger.i('\t${i >= 0 ? '+' : ''}$i: ${offsetKey.toString()}   ${key.toString()}');
      }
    }

    expect(Key.getKeyByHalfStep(0), Key.A);
    expect(Key.getKeyByHalfStep(1), Key.Bb);
    expect(Key.getKeyByHalfStep(2), Key.B);
    expect(Key.getKeyByHalfStep(3), Key.C);
    expect(Key.getKeyByHalfStep(4), Key.Db);
    expect(Key.getKeyByHalfStep(5), Key.D);
    expect(Key.getKeyByHalfStep(6), Key.Eb);
    expect(Key.getKeyByHalfStep(7), Key.E);
    expect(Key.getKeyByHalfStep(8), Key.F);
    expect(Key.getKeyByHalfStep(9), Key.Gb);
    expect(Key.getKeyByHalfStep(10), Key.G);
    expect(Key.getKeyByHalfStep(11), Key.Ab);
    expect(Key.getKeyByHalfStep(12), Key.A);
  });

  test('test getKeyByHalfStep()', () {
    expect(Key.Fs.nextKeyByHalfSteps(-2), Key.E);
    expect(Key.Fs.nextKeyByHalfSteps(-1), Key.F);
    expect(Key.Fs.nextKeyByHalfSteps(0), Key.Fs);
    expect(Key.Fs.nextKeyByHalfSteps(1), Key.G);
    expect(Key.Fs.nextKeyByHalfSteps(2), Key.Ab);

    expect(Key.Ab.nextKeyByHalfSteps(-2), Key.Gb); //  note
    expect(Key.Ab.nextKeyByHalfSteps(-1), Key.G);
    expect(Key.Ab.nextKeyByHalfSteps(0), Key.Ab);
    expect(Key.Ab.nextKeyByHalfSteps(1), Key.A);
    expect(Key.Ab.nextKeyByHalfSteps(2), Key.Bb);

    expect(Key.G.nextKeyByHalfSteps(-2), Key.F);
    expect(Key.G.nextKeyByHalfSteps(-1), Key.Fs); //  note
    expect(Key.G.nextKeyByHalfSteps(0), Key.G);
    expect(Key.G.nextKeyByHalfSteps(1), Key.Ab);
    expect(Key.G.nextKeyByHalfSteps(2), Key.A);

    logger.i('F#: ${Key.Fs}');
    expect(Key.Fs.isSharp, isTrue);

    //  F# going up, Gb going down
    expect(Key.byHalfStep(offset: 9), Key.Fs);
    expect(Key.byHalfStep(offset: -3), Key.Gb);

    //  offset relative to A
    expect(Key.byHalfStep(), Key.A);
    expect(Key.byHalfStep(offset: 3), Key.C);
    expect(Key.byHalfStep(offset: -6), Key.Eb);

    //
    Key key = Key.E;
    List<Key> test = Key.keysByHalfStepFrom(key);
    int i = MusicConstants.halfStepsPerOctave ~/ 2;
    Key tk = test[i];
    expect(tk, isNotNull);
    expect(tk, Key.Bb);
    expect(test[0], Key.E);
    expect(test[12], Key.E);
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

    //  this bass clef algorithm is for piano!
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.C4)), -1);

    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.B3)), -0.5);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Bb3)), -0.5);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.A3)), 0);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.As3)), 0);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Gs3)), 1 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.G3)), 1 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.F3)), 2 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.E3)), 3 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.D3)), 4 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.C3)), 5 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.B2)), 6 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.A2)), 7 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Gs2)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.G2)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Gb2)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.F2)), 9 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Fb2)), 9 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.Es2)), 10 / 2);
    expect(Key.getStaffPosition(Clef.bass, Pitch.get(PitchEnum.E2)), 10 / 2);

    //  this bass clef algorithm is for bass!   not piano!
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.C3)), -1);

    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.B2)), -0.5);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.Bb2)), -0.5);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.A2)), 0);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.As2)), 0);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.Gs2)), 1 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.G2)), 1 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.F2)), 2 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.E2)), 3 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.D2)), 4 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.C2)), 5 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.B1)), 6 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.A1)), 7 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.Gs1)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.G1)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.Gb1)), 8 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.F1)), 9 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.Fb1)), 9 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.Es1)), 10 / 2);
    expect(Key.getStaffPosition(Clef.bass8vb, Pitch.get(PitchEnum.E1)), 10 / 2);

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
    for (final keyEnum in KeyEnum.values) {
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
    }
  });

  test('test key clef scale accidentals', () {
    for (final keyEnum in KeyEnum.values) {
      Key key = Key.get(keyEnum);

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
          logger.t('acc: "$accidental" ${accidental[0].codeUnitAt(0).toString()}'
              ', last: "${lastAccidental.toString()}"  ${lastAccidental[0].codeUnitAt(0).toString()}');

          //  same scale letter or the next one
          expect(
              accidental[0] == lastAccidental[0] ||
                  (accidental.codeUnitAt(0) == lastAccidental.codeUnitAt(0) + 1) ||
                  (accidental.codeUnitAt(0) == 'A'.codeUnitAt(0) && lastAccidental.codeUnitAt(0) == 'G'.codeUnitAt(0)),
              true);

          // {
          //     //  check that sharps are following   fixme: what is this testing?
          //     if (accidental.contains(MusicConstants.sharpChar)) {
          //       expect(lastAccidental.contains(MusicConstants.naturalChar), isFalse);
          //       expect(lastAccidental.contains(MusicConstants.flatChar), isFalse);
          //     }
          //
          //     //  check that flats are leading
          //     if (lastAccidental.contains(MusicConstants.flatChar) ) {
          //       logger.i('lastAccidental: $lastAccidental, accidental: $accidental');
          //       expect(accidental.contains(MusicConstants.naturalChar), isFalse);
          //       expect(accidental.contains(MusicConstants.sharpChar), isFalse);
          //     }
          //   }
        }

        lastAccidental = accidental;
      }
    }
  });

  test('test capo suggestions', () {
    for (KeyEnum keyEnum in KeyEnum.values) {
      Key key = Key.get(keyEnum);
      logger.i('key: ${key.toString().padRight(2)}: '
          '${key.halfStep.toString().padLeft(2)} '
          '=> ${key.capoKey} + capo at ${key.capoLocation}');
    }

    expect(Key.C.capoLocation, 0);
    expect(Key.Db.capoLocation, 1);
    expect(Key.D.capoLocation, 2);
    expect(Key.Eb.capoLocation, 3);
    expect(Key.E.capoLocation, 4);
    expect(Key.F.capoLocation, 5);
    expect(Key.Gb.capoLocation, 6);
    expect(Key.G.capoLocation, 0);
    expect(Key.Ab.capoLocation, 1);
    expect(Key.A.capoLocation, 2);
    expect(Key.Bb.capoLocation, 3);
    expect(Key.B.capoLocation, 4);

    expect(Key.C.capoKey, Key.C);
    expect(Key.Db.capoKey, Key.C);
    expect(Key.D.capoKey, Key.C);
    expect(Key.Eb.capoKey, Key.C);
    expect(Key.E.capoKey, Key.C);
    expect(Key.F.capoKey, Key.C);
    expect(Key.Gb.capoKey, Key.C);
    expect(Key.G.capoKey, Key.G);
    expect(Key.Ab.capoKey, Key.G);
    expect(Key.A.capoKey, Key.G);
    expect(Key.Bb.capoKey, Key.G);
    expect(Key.B.capoKey, Key.G);
  });

  test('test key.inKey()', () {
    {
      Key key = Key.Gb;
      logger.i('B in Gb: ${key.inKey(ScaleNote.B)}');
      logger.i('B tran in Gb: ${key.transpose(ScaleNote.B, 0)}');
    }

    for (final key in Key.values) {
      for (final scaleNote in ScaleNote.values) {
        logger.i('$key $scaleNote');
        final sn = key.inKey(scaleNote);
        expect(sn.halfStep, scaleNote.halfStep);
        if ((key != Key.Gb && scaleNote != ScaleNote.Cb) &&
            (key != Key.Db && scaleNote != ScaleNote.Fb) &&
            (key != Key.G && scaleNote != ScaleNote.Bs) &&
            (key != Key.D && scaleNote != ScaleNote.Es))
        //  fixme: why are these special?  isn't there a better way to mark these oddities?
        {
          expect(key.inKey(scaleNote.alias), sn);
        }
        expect(key.inKey(scaleNote), sn);
      }
    }
  });

  test('test Gb', () {
    expect(Key.values.length, KeyEnum.values.length);
    expect(Key.values.toList().length, KeyEnum.values.length);
    expect(Key.values.toList().reversed.length, KeyEnum.values.length);
    var map = Key.values.toList().reversed.map((Key value) {
      logger.i('Key value: $value');
      return value;
    });
    expect(map.length, KeyEnum.values.length);

    for (var key in Key.values) {
      logger.i('$key ${key.toMarkup()}');
    }
  });

  test('test getCircleOfFifthsAssociatedKey()', () {
    Map<KeyEnum, String> map = {
      KeyEnum.Gb: 'Eb',
      KeyEnum.Db: 'Bb',
      KeyEnum.Ab: 'F',
      KeyEnum.Eb: 'C',
      KeyEnum.Bb: 'G',
      KeyEnum.F: 'D',
      KeyEnum.C: 'A',
      KeyEnum.G: 'E',
      KeyEnum.D: 'B',
      KeyEnum.A: 'F#',
      KeyEnum.E: 'C#',
      KeyEnum.B: 'G#',
      KeyEnum.Fs: 'D#',
    };
    for (var keyEnum in map.keys) {
      var key = Key.get(keyEnum);
      logger.i('$key => minor: ${key.getKeyMinorScaleNote()}');
      expect(Key.get(keyEnum).getKeyMinorScaleNote().toMarkup(), map[keyEnum]);
    }
  });

  test('test getMajorScaleNumberByHalfStep()', () {
    for (var keyEnum in KeyEnum.values) {
      var key = Key.get(keyEnum);
      SplayTreeSet<int> majorScaleNoteHalfSteps = SplayTreeSet();
      for (var note = 0; note < MusicConstants.notesPerScale; note++) {
        var halfStepFromKey =
            (key.getMajorScaleByNote(note).halfStep - key.halfStep) % MusicConstants.halfStepsPerOctave;
        logger.d('$note: ${key.getMajorScaleByNote(note)}'
            '  $halfStepFromKey');
        majorScaleNoteHalfSteps.add(halfStepFromKey);
      }

      logger.i('major key $key:');
      for (var halfSteps = 0; halfSteps < MusicConstants.halfStepsPerOctave; halfSteps++) {
        logger.d(
            '$halfSteps: ${key.getKeyScaleNoteByHalfStep(halfSteps)} ${key.getMajorScaleNumberByHalfStep(halfSteps)}');
        logger.d('  majorScaleNoteHalfSteps: ${majorScaleNoteHalfSteps.contains(halfSteps).toString()} ');

        if (majorScaleNoteHalfSteps.contains(halfSteps)) {
          expect(key.getMajorScaleNumberByHalfStep(halfSteps), isNotNull);
        } else {
          expect(key.getMajorScaleNumberByHalfStep(halfSteps), isNull);
        }
      }
    }

    for (var keyEnum in KeyEnum.values) {
      var key = Key.get(keyEnum);
      SplayTreeSet<int> minorScaleNoteHalfSteps = SplayTreeSet();
      for (var note = 0; note < MusicConstants.notesPerScale; note++) {
        var halfStepFromKey =
            (key.getMinorScaleByNote(note).halfStep - key.halfStep) % MusicConstants.halfStepsPerOctave;
        logger.d('$note: ${key.getMinorScaleByNote(note)}'
            '  $halfStepFromKey');
        minorScaleNoteHalfSteps.add(halfStepFromKey);
      }

      logger.i('minor key $key:');
      for (var halfSteps = 0; halfSteps < MusicConstants.halfStepsPerOctave; halfSteps++) {
        logger.d(
            '$halfSteps: ${key.getKeyScaleNoteByHalfStep(halfSteps)} ${key.getMinorScaleNumberByHalfStep(halfSteps)}');
        logger.d('  minorScaleNoteHalfSteps: ${minorScaleNoteHalfSteps.contains(halfSteps).toString()} ');

        if (minorScaleNoteHalfSteps.contains(halfSteps)) {
          expect(key.getMinorScaleNumberByHalfStep(halfSteps), isNotNull);
        } else {
          expect(key.getMinorScaleNumberByHalfStep(halfSteps), isNull);
        }
      }
    }
  });

  test('test JSON', () {
    for (var keyEnum in KeyEnum.values) {
      var key = Key.get(keyEnum);
      var encoded = key.toJson();
      var decoded = Key.fromJson(key.toJson());
      logger.i('$key:  "$encoded" $decoded');
      expect(decoded, key);
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
