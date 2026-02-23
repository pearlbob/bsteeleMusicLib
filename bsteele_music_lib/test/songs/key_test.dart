import 'dart:collection';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord_component.dart';
import 'package:bsteele_music_lib/songs/chord_descriptor.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/mode.dart';
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
  static String majorScale(MajorKey key) {
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

  static String diatonicByDegree(MajorKey key) {
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
      var key = MajorKey.C;
      expect(key.transpose(.Fs, 3), ScaleNote.A);
      expect(key.transpose(.Fs, 2), ScaleNote.Ab);
      expect(key.transpose(.Fs, 1), ScaleNote.G);
      expect(key.transpose(.Fs, 0), ScaleNote.Gb);
      expect(key.transpose(.Fs, -1), ScaleNote.F);
      expect(key.transpose(.Fs, -2), ScaleNote.E);

      //  E F Gb G Ab A
      expect(key.transpose(.A, -4), ScaleNote.F);
      expect(key.transpose(.A, -3), ScaleNote.Gb);
      expect(key.transpose(.A, -2), ScaleNote.G);
      expect(key.transpose(.A, -1), ScaleNote.Ab);
      expect(key.transpose(.A, 0), ScaleNote.A);
      expect(key.transpose(.A, 1), ScaleNote.Bb);
      expect(key.transpose(.A, 2), ScaleNote.B);
      expect(key.transpose(.A, 3), ScaleNote.C);
      expect(key.transpose(.A, 4), ScaleNote.Db);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Gb);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.F);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
    }
    {
      //  let's start with another sane key, even if it's flat
      var key = MajorKey.F;
      expect(key.transpose(.Fs, 3), ScaleNote.A);
      expect(key.transpose(.Fs, 2), ScaleNote.Ab);
      expect(key.transpose(.Fs, 1), ScaleNote.G);
      expect(key.transpose(.Fs, 0), ScaleNote.Gb);
      expect(key.transpose(.Fs, -1), ScaleNote.F);
      expect(key.transpose(.Fs, -2), ScaleNote.E);

      expect(key.transpose(.A, -4), ScaleNote.F);
      expect(key.transpose(.A, -3), ScaleNote.Gb);
      expect(key.transpose(.A, -2), ScaleNote.G);
      expect(key.transpose(.A, -1), ScaleNote.Ab);
      expect(key.transpose(.A, 0), ScaleNote.A);
      expect(key.transpose(.A, 1), ScaleNote.Bb);
      expect(key.transpose(.A, 2), ScaleNote.B);
      expect(key.transpose(.A, 3), ScaleNote.C);
      expect(key.transpose(.A, 4), ScaleNote.Db);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Gb);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.F);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
    }
    {
      //  let's start with another sane key, even if it's sharp
      var key = MajorKey.G;
      expect(key.transpose(.Fs, 3), ScaleNote.A);
      expect(key.transpose(.Fs, 2), ScaleNote.Gs);
      expect(key.transpose(.Fs, 1), ScaleNote.G);
      expect(key.transpose(.Fs, 0), ScaleNote.Fs);
      expect(key.transpose(.Fs, -1), ScaleNote.F);
      expect(key.transpose(.Fs, -2), ScaleNote.E);

      expect(key.transpose(.A, -4), ScaleNote.F);
      expect(key.transpose(.A, -3), ScaleNote.Fs);
      expect(key.transpose(.A, -2), ScaleNote.G);
      expect(key.transpose(.A, -1), ScaleNote.Gs);
      expect(key.transpose(.A, 0), ScaleNote.A);
      expect(key.transpose(.A, 1), ScaleNote.As);
      expect(key.transpose(.A, 2), ScaleNote.B);
      expect(key.transpose(.A, 3), ScaleNote.C);
      expect(key.transpose(.A, 4), ScaleNote.Cs);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Fs);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.F);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
      expect(key.getScaleNoteByHalfStep(-6), ScaleNote.Ds);
    }
    {
      var key = MajorKey.Fs;
      expect(key.transpose(.Fs, 3), ScaleNote.A);
      expect(key.transpose(.Fs, 2), ScaleNote.Gs);
      expect(key.transpose(.Fs, 1), ScaleNote.G);
      expect(key.transpose(.Fs, 0), ScaleNote.Fs);
      expect(key.transpose(.Fs, -1), ScaleNote.Es);
      expect(key.transpose(.Fs, -2), ScaleNote.E);
      expect(key.transpose(.A, -3), ScaleNote.Fs);
      expect(key.transpose(.A, -4), ScaleNote.Es);
      expect(key.transpose(.A, 0), ScaleNote.A);
      expect(key.transpose(.A, 1), ScaleNote.As);
      expect(key.transpose(.A, 2), ScaleNote.B);
      expect(key.transpose(.A, 3), ScaleNote.C);
      expect(key.transpose(.A, 4), ScaleNote.Cs);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Fs);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.Es);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
    }
    {
      var key = MajorKey.Gb;
      expect(key.transpose(.Fs, 3), ScaleNote.A);
      expect(key.transpose(.Fs, 2), ScaleNote.Ab);
      expect(key.transpose(.Fs, 1), ScaleNote.G);
      expect(key.transpose(.Fs, 0), ScaleNote.Gb);
      expect(key.transpose(.Fs, -1), ScaleNote.F);
      expect(key.transpose(.Fs, -2), ScaleNote.E);
      expect(key.transpose(.A, -3), ScaleNote.Gb);
      expect(key.transpose(.A, -4), ScaleNote.F);
      expect(key.transpose(.A, 0), ScaleNote.A);
      expect(key.transpose(.A, 1), ScaleNote.Bb);
      expect(key.transpose(.A, 2), ScaleNote.Cb);
      expect(key.transpose(.A, 3), ScaleNote.C);
      expect(key.transpose(.A, 4), ScaleNote.Db);

      expect(key.getScaleNoteByHalfStep(-3), ScaleNote.Gb);
      expect(key.getScaleNoteByHalfStep(-4), ScaleNote.F);
      expect(key.getScaleNoteByHalfStep(-5), ScaleNote.E);
      expect(key.getScaleNoteByHalfStep(-6), ScaleNote.Eb);
    }

    //  the table of values
    for (int i = -6; i <= 6; i++) {
      MajorKey key = MajorKey.getKeyByValue(i);
      expect(i, key.getKeyValue());
      logger.t(
        '${i >= 0 ? ' ' : ''}$i ${key.name} ($key)\t',
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

    expect(_Help.majorScale(MajorKey.Gb), 'Gb Ab Bb Cb Db Eb F');
    //  fixme: actual should be first on expect!
    expect(_Help.majorScale(MajorKey.Db), 'Db Eb F  Gb Ab Bb C');
    expect(_Help.majorScale(MajorKey.Ab), 'Ab Bb C  Db Eb F  G');
    expect(_Help.majorScale(MajorKey.Eb), 'Eb F  G  Ab Bb C  D');
    expect(_Help.majorScale(MajorKey.Bb), 'Bb C  D  Eb F  G  A');
    expect(_Help.majorScale(MajorKey.F), 'F  G  A  Bb C  D  E');
    expect(_Help.majorScale(MajorKey.C), 'C  D  E  F  G  A  B');
    expect(_Help.majorScale(MajorKey.G), 'G  A  B  C  D  E  F#');
    expect(_Help.majorScale(MajorKey.D), 'D  E  F# G  A  B  C#');
    expect(_Help.majorScale(MajorKey.E), 'E  F# G# A  B  C# D#');
    expect(_Help.majorScale(MajorKey.B), 'B  C# D# E  F# G# A#');
    expect(_Help.majorScale(MajorKey.Fs), 'F# G# A# B  C# D# E#');

    expect(_Help.diatonicByDegree(MajorKey.Gb), 'Gb   Abm  Bbm  Cb   Db7  Ebm  Fm7b5');
    expect('Db   Ebm  Fm   Gb   Ab7  Bbm  Cm7b5', _Help.diatonicByDegree(MajorKey.Db));
    expect('Ab   Bbm  Cm   Db   Eb7  Fm   Gm7b5', _Help.diatonicByDegree(MajorKey.Ab));
    expect('Eb   Fm   Gm   Ab   Bb7  Cm   Dm7b5', _Help.diatonicByDegree(MajorKey.Eb));
    expect('Bb   Cm   Dm   Eb   F7   Gm   Am7b5', _Help.diatonicByDegree(MajorKey.Bb));
    expect('F    Gm   Am   Bb   C7   Dm   Em7b5', _Help.diatonicByDegree(MajorKey.F));
    expect('C    Dm   Em   F    G7   Am   Bm7b5', _Help.diatonicByDegree(MajorKey.C));
    expect('G    Am   Bm   C    D7   Em   F#m7b5', _Help.diatonicByDegree(MajorKey.G));
    expect('D    Em   F#m  G    A7   Bm   C#m7b5', _Help.diatonicByDegree(MajorKey.D));
    expect('A    Bm   C#m  D    E7   F#m  G#m7b5', _Help.diatonicByDegree(MajorKey.A));
    expect('E    F#m  G#m  A    B7   C#m  D#m7b5', _Help.diatonicByDegree(MajorKey.E));
    expect('B    C#m  D#m  E    F#7  G#m  A#m7b5', _Help.diatonicByDegree(MajorKey.B));
    expect('F#   G#m  A#m  B    C#7  D#m  E#m7b5', _Help.diatonicByDegree(MajorKey.Fs));

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
    for (MajorKey key in MajorKey.values) {
      for (int j = 0; j < MusicConstants.notesPerScale; j++) {
        ScaleChord sc = key.getMajorDiatonicByDegree(j);
        expect(true, key.isDiatonic(sc));
        // fixme: add more tests
      }
    }
  });

  test('testMinorKey testing', () {
    expect(MajorKey.C.getMinorKey(), MajorKey.A);
    expect(MajorKey.F.getMinorKey(), MajorKey.D);
    expect(MajorKey.A.getMinorKey(), MajorKey.Gb);
    expect(MajorKey.Ab.getMinorKey(), MajorKey.F);
    expect(MajorKey.Eb.getMinorKey(), MajorKey.C);
  });

  test('testScaleNoteByHalfStep testing', () {
    for (MajorKey key in MajorKey.values) {
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
    MajorKey key;

    _scaleChords = [];
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.Gb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.Cb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Db, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(key.getKeyScaleNote(), ScaleNote.Gb);

    _scaleChords.clear();

    _scaleChordAdd(ScaleChord.parseString('Gb'));
    _scaleChordAdd(ScaleChord.parseString('Cb'));
    _scaleChordAdd(ScaleChord.parseString('Db7'));
    key = MajorKey.guessKey(_scaleChords);
    expect(key.getKeyScaleNote(), ScaleNote.Gb);

    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.C));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.F));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.G, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.C, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.Db));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.Gb));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Ab, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Db, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.Cs));
    _scaleChordAdd(ScaleChord.parseString('F#'));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Gs, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Db, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Bb, ChordDescriptor.minor));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Db, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  A    Bm   C♯m  D    E7   F♯m  G♯m7b5
    //  B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5
    //  E    F♯m  G♯m  A    B7   C♯m  D♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.A));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Fs, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.B, ChordDescriptor.minor));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.B, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.E, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.E, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.D, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.A, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    //  F    Gm   Am   B♭   C7   Dm   Em7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.Ab));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.F, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.G, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Bb, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.F, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Eb, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Eb, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  C    Dm   Em   F    G7   Am   Bm7b5
    //  A    Bm   C♯m  D    E7   F♯m  G♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.A, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.D, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.E, ChordDescriptor.minor));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.A, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.G, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.D, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5
    //  E    F♯m  G♯m  A    B7   C♯m  D♯m7b5
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Gs, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Ds, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.E));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Eb, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Fs, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.E, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    //  E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Bb, ChordDescriptor.minor));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Bb, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Ab, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Ab, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Db, ChordDescriptor.dominant7));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Ab, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5
    //  D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.Bb, ChordDescriptor.minor));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.Db));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Db, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.Ab));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.Ab, key.getKeyScaleNote());

    //  1     2   3    4    5    6     7
    //  G    Am   Bm   C    D7   Em   F♯m7b5
    //  D    Em   F♯m  G    A7   Bm   C♯m7b5
    _scaleChords.clear();
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.D));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.A));
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.G));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.D, key.getKeyScaleNote());
    _scaleChords.add(ScaleChord.fromScaleNoteEnum(.C));
    key = MajorKey.guessKey(_scaleChords);
    expect(ScaleNote.G, key.getKeyScaleNote());
  });

  test('testTranspose testing', () {
    for (int k = -6; k <= 6; k++) {
      MajorKey key = MajorKey.getKeyByValue(k);
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
    MajorKey key = MajorKey.A;
    MajorKey lastKey = key.previousKeyByHalfStep();
    Set<MajorKey> set = {};
    for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
      logger.i('key: $key');
      MajorKey nextKey = key.nextKeyByHalfStep();
      expect(false, key == lastKey);
      expect(false, key == nextKey);
      expect(key, lastKey.nextKeyByHalfStep());
      if (key == MajorKey.Gb) {
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
    expect(key, MajorKey.A);
    expect(MusicConstants.halfStepsPerOctave, set.length);
  });

  test('testKeyParse testing', () {
    expect(MajorKey.parseString('B♭'), MajorKey.Bb);
    expect(MajorKey.parseString('Bb'), MajorKey.Bb);
    expect(MajorKey.parseString('F#'), MajorKey.Fs);
    expect(MajorKey.parseString('F♯'), MajorKey.Fs);
    expect(MajorKey.parseString('Fs'), MajorKey.Fs);
    expect(MajorKey.parseString('F'), MajorKey.F);
    expect(MajorKey.parseString('E♭'), MajorKey.Eb);
    expect(MajorKey.parseString('Eb'), MajorKey.Eb);
  });

  test('test byHalfStep()', () {
    for (int off = -6; off <= 6; off++) {
      logger.i('$off');
      MajorKey key = MajorKey.getKeyByHalfStep(off);

      for (int i = -6; i <= 6; i++) {
        MajorKey offsetKey = MajorKey.getKeyByHalfStep(off + i);
        logger.i('\t${i >= 0 ? '+' : ''}$i: ${offsetKey.toString()}   ${key.toString()}');
      }
    }

    expect(MajorKey.getKeyByHalfStep(0), MajorKey.A);
    expect(MajorKey.getKeyByHalfStep(1), MajorKey.Bb);
    expect(MajorKey.getKeyByHalfStep(2), MajorKey.B);
    expect(MajorKey.getKeyByHalfStep(3), MajorKey.C);
    expect(MajorKey.getKeyByHalfStep(4), MajorKey.Db);
    expect(MajorKey.getKeyByHalfStep(5), MajorKey.D);
    expect(MajorKey.getKeyByHalfStep(6), MajorKey.Eb);
    expect(MajorKey.getKeyByHalfStep(7), MajorKey.E);
    expect(MajorKey.getKeyByHalfStep(8), MajorKey.F);
    expect(MajorKey.getKeyByHalfStep(9), MajorKey.Gb);
    expect(MajorKey.getKeyByHalfStep(10), MajorKey.G);
    expect(MajorKey.getKeyByHalfStep(11), MajorKey.Ab);
    expect(MajorKey.getKeyByHalfStep(12), MajorKey.A);
  });

  test('test getKeyByHalfStep()', () {
    expect(MajorKey.Fs.nextKeyByHalfSteps(-2), MajorKey.E);
    expect(MajorKey.Fs.nextKeyByHalfSteps(-1), MajorKey.F);
    expect(MajorKey.Fs.nextKeyByHalfSteps(0), MajorKey.Fs);
    expect(MajorKey.Fs.nextKeyByHalfSteps(1), MajorKey.G);
    expect(MajorKey.Fs.nextKeyByHalfSteps(2), MajorKey.Ab);

    expect(MajorKey.Ab.nextKeyByHalfSteps(-2), MajorKey.Gb); //  note
    expect(MajorKey.Ab.nextKeyByHalfSteps(-1), MajorKey.G);
    expect(MajorKey.Ab.nextKeyByHalfSteps(0), MajorKey.Ab);
    expect(MajorKey.Ab.nextKeyByHalfSteps(1), MajorKey.A);
    expect(MajorKey.Ab.nextKeyByHalfSteps(2), MajorKey.Bb);

    expect(MajorKey.G.nextKeyByHalfSteps(-2), MajorKey.F);
    expect(MajorKey.G.nextKeyByHalfSteps(-1), MajorKey.Fs); //  note
    expect(MajorKey.G.nextKeyByHalfSteps(0), MajorKey.G);
    expect(MajorKey.G.nextKeyByHalfSteps(1), MajorKey.Ab);
    expect(MajorKey.G.nextKeyByHalfSteps(2), MajorKey.A);

    logger.i('F#: ${MajorKey.Fs}');
    expect(MajorKey.Fs.isSharp, isTrue);

    //  F# going up, Gb going down
    expect(MajorKey.byHalfStep(offset: 9), MajorKey.Fs);
    expect(MajorKey.byHalfStep(offset: -3), MajorKey.Gb);

    //  offset relative to A
    expect(MajorKey.byHalfStep(), MajorKey.A);
    expect(MajorKey.byHalfStep(offset: 3), MajorKey.C);
    expect(MajorKey.byHalfStep(offset: -6), MajorKey.Eb);

    //
    MajorKey key = MajorKey.E;
    List<MajorKey> test = MajorKey.keysByHalfStepFrom(key);
    int i = MusicConstants.halfStepsPerOctave ~/ 2;
    MajorKey tk = test[i];
    expect(tk, isNotNull);
    expect(tk, MajorKey.Bb);
    expect(test[0], MajorKey.E);
    expect(test[12], MajorKey.E);
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
    expect(MajorKey.getStaffPosition(Clef.treble, Pitch.get(.C4)), 5);

    expect(MajorKey.getStaffPosition(Clef.treble, Pitch.get(.G5)), -0.5);
    expect(MajorKey.getStaffPosition(Clef.treble, Pitch.get(.C5)), 1.5);
    expect(MajorKey.getStaffPosition(Clef.treble, Pitch.get(.G4)), 3);
    expect(MajorKey.getStaffPosition(Clef.treble, Pitch.get(.D4)), 4.5);
    expect(MajorKey.getStaffPosition(Clef.treble, Pitch.get(.Ds4)), 4.5);

    //  this bass clef algorithm is for piano!
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.C4)), -1);

    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.B3)), -0.5);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.Bb3)), -0.5);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.A3)), 0);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.As3)), 0);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.Gs3)), 1 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.G3)), 1 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.F3)), 2 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.E3)), 3 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.D3)), 4 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.C3)), 5 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.B2)), 6 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.A2)), 7 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.Gs2)), 8 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.G2)), 8 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.Gb2)), 8 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.F2)), 9 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.Fb2)), 9 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.Es2)), 10 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass, Pitch.get(.E2)), 10 / 2);

    //  this bass clef algorithm is for bass!   not piano!
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.C3)), -1);

    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.B2)), -0.5);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.Bb2)), -0.5);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.A2)), 0);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.As2)), 0);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.Gs2)), 1 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.G2)), 1 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.F2)), 2 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.E2)), 3 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.D2)), 4 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.C2)), 5 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.B1)), 6 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.A1)), 7 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.Gs1)), 8 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.G1)), 8 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.Gb1)), 8 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.F1)), 9 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.Fb1)), 9 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.Es1)), 10 / 2);
    expect(MajorKey.getStaffPosition(Clef.bass8vb, Pitch.get(.E1)), 10 / 2);

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
    for (MajorKeyEnum keyEnum in MajorKeyEnum.values) {
      MajorKey key = MajorKey.get(keyEnum);
      for (int i = 0; i < MusicConstants.notesPerScale; i++) {
        logger.d('${key.toString().padLeft(2)} ${key.getKeyValue()}: $i: ${key.getMajorScaleByNote(i)}');
      }
      for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
        Pitch pitch = Pitch
            .sharps[(i + MusicConstants.halfStepsFromAtoC + key.getKeyValue() * 7) % MusicConstants.halfStepsPerOctave];
        pitch = key.isSharp ? pitch.asSharp() : pitch.asFlat();
        ScaleNote keyScaleNote = key.getKeyScaleNoteFor(pitch.scaleNote);
        logger.d(
          '\t${key.toString().padLeft(2)} ${key.getKeyScaleNote()}: ${key.getKeyScaleNote().halfStep}:'
          ' ${pitch.scaleNote.toString().padLeft(2)} $i  $keyScaleNote  ${key.accidentalString(pitch)}'
          '  ${key.accidental(pitch)}',
        );
      }
    }

    logger.d('scale     1   2   3   4   5   6   7');
    for (MajorKeyEnum keyEnum in MajorKeyEnum.values) {
      MajorKey key = MajorKey.get(keyEnum);
      String s = '';
      for (int i = 0; i < MusicConstants.notesPerScale; i++) {
        s += '  ${key.getMajorScaleByNote(i).toString().padLeft(2)}';
      }
      logger.d('key ${key.toString().padLeft(2)}: $s');
    }
    logger.d('');
    logger.d('');

    for (MajorKeyEnum keyEnum in MajorKeyEnum.values) {
      MajorKey key = MajorKey.get(keyEnum);
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
    for (final keyEnum in MajorKeyEnum.values) {
      MajorKey key = MajorKey.get(keyEnum);

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
    for (final keyEnum in MajorKeyEnum.values) {
      MajorKey key = MajorKey.get(keyEnum);

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
          logger.t(
            'acc: "$accidental" ${accidental[0].codeUnitAt(0).toString()}'
            ', last: "${lastAccidental.toString()}"  ${lastAccidental[0].codeUnitAt(0).toString()}',
          );

          //  same scale letter or the next one
          expect(
            accidental[0] == lastAccidental[0] ||
                (accidental.codeUnitAt(0) == lastAccidental.codeUnitAt(0) + 1) ||
                (accidental.codeUnitAt(0) == 'A'.codeUnitAt(0) && lastAccidental.codeUnitAt(0) == 'G'.codeUnitAt(0)),
            true,
          );

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
    for (MajorKeyEnum keyEnum in MajorKeyEnum.values) {
      MajorKey key = MajorKey.get(keyEnum);
      logger.i(
        'key: ${key.toString().padRight(2)}: '
        '${key.halfStep.toString().padLeft(2)} '
        '=> ${key.capoKey} + capo at ${key.capoLocation}',
      );
    }

    expect(MajorKey.C.capoLocation, 0);
    expect(MajorKey.Db.capoLocation, 1);
    expect(MajorKey.D.capoLocation, 2);
    expect(MajorKey.Eb.capoLocation, 3);
    expect(MajorKey.E.capoLocation, 4);
    expect(MajorKey.F.capoLocation, 5);
    expect(MajorKey.Gb.capoLocation, 6);
    expect(MajorKey.G.capoLocation, 0);
    expect(MajorKey.Ab.capoLocation, 1);
    expect(MajorKey.A.capoLocation, 2);
    expect(MajorKey.Bb.capoLocation, 3);
    expect(MajorKey.B.capoLocation, 4);

    expect(MajorKey.C.capoKey, MajorKey.C);
    expect(MajorKey.Db.capoKey, MajorKey.C);
    expect(MajorKey.D.capoKey, MajorKey.C);
    expect(MajorKey.Eb.capoKey, MajorKey.C);
    expect(MajorKey.E.capoKey, MajorKey.C);
    expect(MajorKey.F.capoKey, MajorKey.C);
    expect(MajorKey.Gb.capoKey, MajorKey.C);
    expect(MajorKey.G.capoKey, MajorKey.G);
    expect(MajorKey.Ab.capoKey, MajorKey.G);
    expect(MajorKey.A.capoKey, MajorKey.G);
    expect(MajorKey.Bb.capoKey, MajorKey.G);
    expect(MajorKey.B.capoKey, MajorKey.G);
  });

  test('test key.inKey()', () {
    {
      MajorKey key = MajorKey.Gb;
      logger.i('B in Gb: ${key.inKey(.B)}');
      logger.i('B tran in Gb: ${key.transpose(.B, 0)}');
    }

    for (final key in MajorKey.values) {
      for (final scaleNote in ScaleNote.values) {
        logger.i('$key $scaleNote');
        final sn = key.inKey(scaleNote);
        expect(sn.halfStep, scaleNote.halfStep);
        if ((key != MajorKey.Gb && scaleNote != ScaleNote.Cb) &&
            (key != MajorKey.Db && scaleNote != ScaleNote.Fb) &&
            (key != MajorKey.G && scaleNote != ScaleNote.Bs) &&
            (key != MajorKey.D && scaleNote != ScaleNote.Es))
        //  fixme: why are these special?  isn't there a better way to mark these oddities?
        {
          expect(key.inKey(scaleNote.alias), sn);
        }
        expect(key.inKey(scaleNote), sn);
      }
    }
  });

  test('test Gb', () {
    expect(MajorKey.values.length, MajorKeyEnum.values.length);
    expect(MajorKey.values.toList().length, MajorKeyEnum.values.length);
    expect(MajorKey.values.toList().reversed.length, MajorKeyEnum.values.length);
    var map = MajorKey.values.toList().reversed.map((MajorKey value) {
      logger.i('Key value: $value');
      return value;
    });
    expect(map.length, MajorKeyEnum.values.length);

    for (var key in MajorKey.values) {
      logger.i('$key ${key.toMarkup()}');
    }
  });

  test('test getCircleOfFifthsAssociatedKey()', () {
    Map<MajorKeyEnum, String> map = {
      MajorKeyEnum.Gb: 'Eb',
      MajorKeyEnum.Db: 'Bb',
      MajorKeyEnum.Ab: 'F',
      MajorKeyEnum.Eb: 'C',
      MajorKeyEnum.Bb: 'G',
      MajorKeyEnum.F: 'D',
      MajorKeyEnum.C: 'A',
      MajorKeyEnum.G: 'E',
      MajorKeyEnum.D: 'B',
      MajorKeyEnum.A: 'F#',
      MajorKeyEnum.E: 'C#',
      MajorKeyEnum.B: 'G#',
      MajorKeyEnum.Fs: 'D#',
    };
    for (var keyEnum in map.keys) {
      var key = MajorKey.get(keyEnum);
      logger.i('$key => minor: ${key.getKeyMinorScaleNote()}');
      expect(MajorKey.get(keyEnum).getKeyMinorScaleNote().toMarkup(), map[keyEnum]);
    }
  });

  test('test getMajorScaleNumberByHalfStep()', () {
    for (var keyEnum in MajorKeyEnum.values) {
      var key = MajorKey.get(keyEnum);
      SplayTreeSet<int> majorScaleNoteHalfSteps = SplayTreeSet();
      for (var note = 0; note < MusicConstants.notesPerScale; note++) {
        var halfStepFromKey =
            (key.getMajorScaleByNote(note).halfStep - key.halfStep) % MusicConstants.halfStepsPerOctave;
        logger.d(
          '$note: ${key.getMajorScaleByNote(note)}'
          '  $halfStepFromKey',
        );
        majorScaleNoteHalfSteps.add(halfStepFromKey);
      }

      logger.i('major key $key:');
      for (var halfSteps = 0; halfSteps < MusicConstants.halfStepsPerOctave; halfSteps++) {
        logger.d(
          '$halfSteps: ${key.getKeyScaleNoteByHalfStep(halfSteps)} ${key.getMajorScaleNumberByHalfStep(halfSteps)}',
        );
        logger.d('  majorScaleNoteHalfSteps: ${majorScaleNoteHalfSteps.contains(halfSteps).toString()} ');

        if (majorScaleNoteHalfSteps.contains(halfSteps)) {
          expect(key.getMajorScaleNumberByHalfStep(halfSteps), isNotNull);
        } else {
          expect(key.getMajorScaleNumberByHalfStep(halfSteps), isNull);
        }
      }
    }

    for (var keyEnum in MajorKeyEnum.values) {
      var key = MajorKey.get(keyEnum);
      SplayTreeSet<int> minorScaleNoteHalfSteps = SplayTreeSet();
      for (var note = 0; note < MusicConstants.notesPerScale; note++) {
        var halfStepFromKey =
            (key.getMinorScaleByNote(note).halfStep - key.halfStep) % MusicConstants.halfStepsPerOctave;
        logger.d(
          '$note: ${key.getMinorScaleByNote(note)}'
          '  $halfStepFromKey',
        );
        minorScaleNoteHalfSteps.add(halfStepFromKey);
      }

      logger.i('minor key $key:');
      for (var halfSteps = 0; halfSteps < MusicConstants.halfStepsPerOctave; halfSteps++) {
        logger.d(
          '$halfSteps: ${key.getKeyScaleNoteByHalfStep(halfSteps)} ${key.getMinorScaleNumberByHalfStep(halfSteps)}',
        );
        logger.d('  minorScaleNoteHalfSteps: ${minorScaleNoteHalfSteps.contains(halfSteps).toString()} ');

        if (minorScaleNoteHalfSteps.contains(halfSteps)) {
          expect(key.getMinorScaleNumberByHalfStep(halfSteps), isNotNull);
        } else {
          expect(key.getMinorScaleNumberByHalfStep(halfSteps), isNull);
        }
      }
    }
  });

  test('test modes', () {
    //  for visual inspection:
    for (var mode in Mode.values) {
      print('${mode.name.toString().padLeft(10)}: ${mode.formula}');
    }
    print('');

    {
      for (var mode in [Mode.mixolydian]) {
        for (MajorKeyEnum keyEnum in MajorKeyEnum.values.reversed) {
          MajorKey key = MajorKey.get(keyEnum);

          final StringBuffer sb = StringBuffer('$key: ');
          for (int i = 0; i < MusicConstants.notesPerScale; i++) {
            var note = getModeScaleNote(key, mode, i);
            sb.write(' $note');
          }
          print(sb.toString());
        }
      }
      print('');
    }

    MajorKey parentMajorKey = MajorKey.D;
    for (var mode in Mode.values) {
      final List<ChordComponent> components = getModeChordComponents(mode);
      {
        final StringBuffer sb = StringBuffer();
        for (int i = 0; i < components.length; i++) {
          var component = components[i];
          sb.write(' $component');
        }
        print(sb.toString());
      }
      print('parentMajorKey: $parentMajorKey, mode: $mode');
      {
        final StringBuffer sb = StringBuffer();
        for (int i = 0; i < MusicConstants.notesPerScale; i++) {
          sb.write(' ${parentMajorKey.getKeyScaleNoteByHalfStep(components[i].halfSteps)}');
        }
        print(sb.toString());
      }
    }

    //  random sanity tests only
    //  note index starts on 0
    expect(getModeScaleNote(MajorKey.C, Mode.ionian, 3 - 1), ScaleNote.E);
    expect(getModeScaleNote(MajorKey.D, Mode.ionian, 3 - 1), ScaleNote.Fs);
    expect(getModeScaleNote(MajorKey.D, Mode.ionian, 6 - 1), ScaleNote.B);
    expect(getModeScaleNote(MajorKey.D, Mode.ionian, 7 - 1), ScaleNote.Cs);
    expect(getModeScaleNote(MajorKey.D, Mode.dorian, 2 - 1), ScaleNote.E);
    expect(getModeScaleNote(MajorKey.Ab, Mode.dorian, 3 - 1), ScaleNote.B);
    expect(getModeScaleNote(MajorKey.Ab, Mode.phrygian, 3 - 1), ScaleNote.B);
    expect(getModeScaleNote(MajorKey.Ab, Mode.phrygian, 4 - 1), ScaleNote.Db);
    expect(getModeScaleNote(MajorKey.Ab, Mode.phrygian, 6 - 1), ScaleNote.E);
    expect(getModeScaleNote(MajorKey.B, Mode.phrygian, 3 - 1), ScaleNote.D);
    expect(getModeScaleNote(MajorKey.Db, Mode.lydian, 2 - 1), ScaleNote.Eb);
    expect(getModeScaleNote(MajorKey.D, Mode.lydian, 5 - 1), ScaleNote.A);
    expect(getModeScaleNote(MajorKey.E, Mode.lydian, 7 - 1), ScaleNote.Ds);
    expect(getModeScaleNote(MajorKey.E, Mode.mixolydian, 6 - 1), ScaleNote.Cs);
    expect(getModeScaleNote(MajorKey.E, Mode.mixolydian, 2 - 1), ScaleNote.Fs);
    expect(getModeScaleNote(MajorKey.E, Mode.aeolian, 4 - 1), ScaleNote.A);
    expect(getModeScaleNote(MajorKey.A, Mode.locrian, 3 - 1), ScaleNote.C);
    expect(getModeScaleNote(MajorKey.A, Mode.locrian, 4 - 1), ScaleNote.D);
    expect(getModeScaleNote(MajorKey.Gb, Mode.locrian, 6 - 1), ScaleNote.D);
  });

  test('test mode chromatic scales', () {
    for (var keyEnum in MajorKeyEnum.values) {
      MajorKey parentMajorKey = MajorKey.get(keyEnum);
      for (var mode in Mode.values) {
        print('parentMajorkey: $parentMajorKey, mode: $mode');

        final List<ChordComponent> components = getModeChordComponents(mode);

        {
          final StringBuffer sb = StringBuffer();
          for (int i = 0; i < components.length; i++) {
            var component = components[i];
            sb.write(' ${component.toString().padRight(2)}');
          }
          print(sb.toString());
        }

        final componentHalfSteps = components.map((c) => c.halfSteps).toList(growable: false);
        {
          final StringBuffer sb = StringBuffer();
          for (int i = 0; i < components.length; i++) {
            sb.write(' ${componentHalfSteps[i].toString().padRight(2)}');
          }
          print(sb.toString());
        }

        {
          final StringBuffer sb = StringBuffer();
          for (int i = 0; i < MusicConstants.notesPerScale; i++) {
            sb.write(' ${parentMajorKey.getKeyScaleNoteByHalfStep(components[i].halfSteps).toString().padRight(2)}');
          }
          print(sb.toString());
        }
        int scaleNoteCount = 0;
        for (int i = 0; i < MusicConstants.halfStepsPerOctave; i++) {
          var chromaticNote = getModeChromaticNote(parentMajorKey, mode, i);
          ScaleNote? scaleNote;
          if (componentHalfSteps.contains(i)) {
            scaleNote = getModeScaleNote(parentMajorKey, mode, scaleNoteCount);
            scaleNoteCount++;
          }
          // print( '$i: $chromaticNote $scaleNote');
          if (scaleNote != null) {
            expect(chromaticNote, scaleNote);
          }
        }
      }
    }
  });

  test('test major minor keys', () {
    expect(MajorKey.Gb.minorKey, MinorKey.eb);
    expect(MajorKey.Db.minorKey, MinorKey.bb);
    expect(MajorKey.Ab.minorKey, MinorKey.f);
    expect(MajorKey.Eb.minorKey, MinorKey.c);
    expect(MajorKey.Bb.minorKey, MinorKey.g);
    expect(MajorKey.F.minorKey, MinorKey.d);
    expect(MajorKey.C.minorKey, MinorKey.a);
    expect(MajorKey.G.minorKey, MinorKey.e);
    expect(MajorKey.D.minorKey, MinorKey.b);
    expect(MajorKey.A.minorKey, MinorKey.fs);
    expect(MajorKey.E.minorKey, MinorKey.cs);
    expect(MajorKey.B.minorKey, MinorKey.gs);
    expect(MajorKey.Fs.minorKey, MinorKey.ds);

    expect(MinorKey.eb.majorKey, MajorKey.Gb);
    expect(MinorKey.bb.majorKey, MajorKey.Db);
    expect(MinorKey.f.majorKey, MajorKey.Ab);
    expect(MinorKey.c.majorKey, MajorKey.Eb);
    expect(MinorKey.g.majorKey, MajorKey.Bb);
    expect(MinorKey.d.majorKey, MajorKey.F);
    expect(MinorKey.a.majorKey, MajorKey.C);
    expect(MinorKey.e.majorKey, MajorKey.G);
    expect(MinorKey.b.majorKey, MajorKey.D);
    expect(MinorKey.fs.majorKey, MajorKey.A);
    expect(MinorKey.cs.majorKey, MajorKey.E);
    expect(MinorKey.gs.majorKey, MajorKey.B);
    expect(MinorKey.ds.majorKey, MajorKey.Fs);

    for (var keyEnum in MajorKeyEnum.values) {
      MajorKey majorKey = MajorKey.get(keyEnum);
      MinorKey minorKey = majorKey.minorKey;
      // print( 'expect(MajorKey.${majorKey.name}.minorKey, MinorKey.${minorKey.name});');
      // print('expect(MinorKey.${minorKey.name}.majorKey, MajorKey.${majorKey.name});');
      expect(minorKey.minorKey, minorKey);
      expect(majorKey.minorKey, minorKey);
      expect(minorKey.majorKey, majorKey);
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
