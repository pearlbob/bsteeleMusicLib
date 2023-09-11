import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord.dart';
import 'package:bsteele_music_lib/songs/chord_anticipation_or_delay.dart';
import 'package:bsteele_music_lib/songs/chord_descriptor.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/measure.dart';
import 'package:bsteele_music_lib/songs/scale_chord.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';
import 'package:bsteele_music_lib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../custom_matchers.dart';

void main() {
  Logger.level = Level.warning;

  test('test equality', () {
    Measure? m;
    Measure ref;
    int beats = 4;
    int beatsPerBar = 4;

    {
      m = Measure.parseString('B', beats);
      expect(m, isNotNull);
      Chord chord = Chord.byScaleChordAndBeats(ScaleChord(ScaleNote.B, ChordDescriptor.major), beats, beatsPerBar);
      ref = Measure(beats, [chord]);
      logger.i('m:   ${m.toMarkup()}');
      logger.i('ref: ${ref.toMarkup()}');
      logger.i('m == ref: ${m == ref}');
      expect(m, ref);
    }
  });

  test('testparseString', () {
    String s;
    Measure? m;

    {
      s = 'X.';

      m = Measure.parseString(s, 4);
      expect(m, isNotNull);

      //  explicit measure short of beats is left as specified
      expect(m.toMarkup(), s);
    }
    {
      s = 'GD.C';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect('GD.C', m.toMarkup());
    }
    {
      s = 'AX';

      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect('AX', m.toMarkup());
    }
    {
      s = 'AX..';

      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect('AX..', m.toMarkup());
    }
    {
      s = 'X';

      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect('X', m.toMarkup());
    }

    {
      s = 'A.B.';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(m.toMarkup(), 'AB');
    }

    {
      s = 'A.B.';

      m = Measure.parseString(s, 6);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect(m.toMarkup(), '4A.B.');
    }
    {
      s = 'A.B.';

      m = Measure.parseString(s, 6);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect(m.toMarkup(), '4A.B.');
    }
    {
      s = 'AB';
      m = Measure.parseString(s, 6);
      expect(m, isNotNull);
      //  5/4 split across two chords, first one gets the extra beat
      expect(m.toMarkup(), 'AB');
    }
    {
      s = 'A.B.';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  default to simplest expression
      expect('AB', m.toMarkup());
    }
    {
      s = 'A/GA/F♯';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(m.toMarkup(), 'A/GA/F#');
    }
    {
      s = 'A/G';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
      expect(m.beatCount, 4);
    }
    {
      s = 'F.';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
      expect(m.beatCount, 2);
    }
    {
      s = 'F.';
      m = Measure.parseString(s, 2);
      expect(m, isNotNull);
      expect('F', m.toMarkup());
      expect(m.beatCount, 2);
    }
    {
      s = 'F..';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
      expect(m.beatCount, 3);
    }
    {
      s = 'F...';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect('F', m.toMarkup());
      expect(m.beatCount, 4);
    }
    {
      s = 'A..B';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
      expect(m.beatCount, 4);
    }
    {
      s = 'AB..';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
    }
    {
      s = 'ABC.';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
    }
    {
      s = 'A.BC';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
    }

    {
      s = 'E♭F';
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(m.toMarkup(), 'EbF');
    }
    {
      s = 'E♭.F';
      m = Measure.parseString(s, 3);
      expect(m, isNotNull);
      expect(m.toMarkup(), 'Eb.F');
    }
    {
      //  test beat allocation
      m = Measure.parseString('EAB', 4);
      expect(m.chords.length, 3);
      expect(m.chords[0].beats, 1);
      expect(m.chords[1].beats, 1);
      expect(m.chords[2].beats, 1);

      m = Measure.parseString('EA', 4);

      expect(2, m.chords.length);
      expect(2, m.chords[0].beats);
      expect(2, m.chords[1].beats);
      m = Measure.parseString('E..A', 4);
      expect(2, m.chords.length);
      expect(3, m.chords[0].beats);
      expect(1, m.chords[1].beats);

      m = Measure.parseString('E.A', 4);
      expect(m.chords.length, 2);
      expect(m.chords[0].beats, 2);
      expect(m.chords[1].beats, 1);
      m = Measure.parseString('E.A.', 4);
      expect(2, m.chords.length);
      expect(2, m.chords[0].beats);
      expect(2, m.chords[1].beats);
      m = Measure.parseString('EA.', 4);
      expect(m.chords.length, 2);
      expect(m.chords[0].beats, 1);
      expect(m.chords[1].beats, 2);
      m = Measure.parseString('EA.', 6);
      expect(m.chords.length, 2);
      expect(m.chords[0].beats, 1);
      expect(m.chords[1].beats, 2);

      //  too many specific beats
      m = Measure.parseString('E..A.', 4);
      expect(m, isNotNull); //  fixme: Measure.parseString() on errors

      //  too few specific beats
      m = Measure.parseString('E..A.', 6);
      expect(m, isNotNull); //  fixme: Measure.parseString() on errors
    }

    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString('A', beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(1, m.chords.length);
      Chord chord = m.chords[0];
      expect(chord,
          CompareTo(Chord.byScaleChordAndBeats(ScaleChord.fromScaleNoteEnum(ScaleNote.A), beatsPerBar, beatsPerBar)));
    }

    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString('BC', beatsPerBar);
      expect(2 * beatsPerBar ~/ 2, beatsPerBar);
      expect(m.chords.length, 2);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat = beatsPerBar ~/ 2;
      Chord refChord = Chord.byScaleChordAndBeats(ScaleChord.fromScaleNoteEnum(ScaleNote.B), beat, beatsPerBar);
      expect(chord0, CompareTo(refChord));
      expect(
          chord1, CompareTo(Chord.byScaleChordAndBeats(ScaleChord.fromScaleNoteEnum(ScaleNote.C), beat, beatsPerBar)));
    }
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString('E#m7. ', beatsPerBar);
      expect(m, isNotNull);
      expect(2, m.beatCount);
      expect(1, m.chords.length);
      Chord chord0 = m.chords[0];
      expect(
          chord0,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Es, ChordDescriptor.minor7), 2, beatsPerBar)));
    }
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar += 2) {
      m = Measure.parseString('E#m7Gb7', beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(2, m.chords.length);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat1 = beatsPerBar ~/ 2;
      int beat0 = beatsPerBar - beat1;
      expect(
          chord0,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Es, ChordDescriptor.minor7),
              beat0,
              beatsPerBar)));
      expect(
          chord1,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Gb, ChordDescriptor.dominant7),
              beat1,
              beatsPerBar)));
    }
    for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString('F#m7.Asus4', beatsPerBar);
      expect(m.beatCount, 3);
      expect(2, m.chords.length);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat0 = 2;
      int beat1 = 1;
      expect(
          chord0,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Fs, ChordDescriptor.minor7),
              beat0,
              beatsPerBar)));
      expect(
          chord1,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.A, ChordDescriptor.suspended4),
              beat1,
              beatsPerBar)));
    }
    for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString('F#m7.A9sus4', beatsPerBar);
      expect(m.beatCount, 3);
      expect(2, m.chords.length);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat0 = 2;
      int beat1 = 1;
      expect(
          chord0,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Fs, ChordDescriptor.minor7),
              beat0,
              beatsPerBar)));
      expect(
          chord1,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.A, ChordDescriptor.nineSus4),
              beat1,
              beatsPerBar)));
    }

    ChordAnticipationOrDelay delayNone = ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.none);
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString('A/G#', beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(1, m.chords.length);
      Chord chord = m.chords[0];
      expect(
          chord,
          CompareTo(Chord(
              ScaleChord.fromScaleNoteEnum(ScaleNote.A), beatsPerBar, beatsPerBar, ScaleNote.Gs, delayNone, true)));
    }
    for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString('C/F#.G', beatsPerBar);
      expect(
        m.beatCount,
        3,
      );
      expect(2, m.chords.length);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat0 = 2;
      int beat1 = 1;
      expect(
          chord0,
          CompareTo(
              Chord(ScaleChord.fromScaleNoteEnum(ScaleNote.C), beat0, beatsPerBar, ScaleNote.Fs, delayNone, true)));
      expect(
          chord1, CompareTo(Chord.byScaleChordAndBeats(ScaleChord.fromScaleNoteEnum(ScaleNote.G), beat1, beatsPerBar)));
    }
    {
      for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
        Measure? m0 = Measure.parseString('C', beatsPerBar);
        m = Measure.parse(MarkedString('-'), beatsPerBar, m0);
        expect(beatsPerBar, m.beatCount);
        expect(1, m.chords.length);
        expect(m0.chords, m.chords);
      }
    }
    {
      for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
        m = Measure.parseString('X', beatsPerBar);
        expect(beatsPerBar, m.beatCount);
        expect(1, m.chords.length);
      }
    }
    {
      m = Measure.parseString('E#m7. ', 3);
      expect(m, isNotNull);
      expect('E#m7.', m.toMarkup());
    }

    {
      //  too many beats or over specified, doesn't cover the beats per bar
      try {
        m = Measure.parseString('E#m7.. ', 2);
        fail('should be exception on too many beats in measure');
      } catch (e) {
        //  expected
      }
    }
    {
      int beatsPerBar = 4;
      try {
        m = Measure.parseString(' .G ', beatsPerBar);
        fail('should fail on stupid entry: .G');
      } catch (e) {
        //  expected
      }
    }
    {
      int beatsPerBar = 3;
      logger.d('beatsPerBar: $beatsPerBar');
      try {
        m = Measure.parseString(' .G ', beatsPerBar);
        fail('should fail on stupid entry: .G');
      } catch (e) {
        //  expected
      }
      try {
        m = Measure.parseString('E#m7... ', beatsPerBar);
        fail('should be exception on too many beats in measure');
      } catch (e) {
        //  expected
      }
    }
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      try {
        m = Measure.parseString('E#m7.. ', beatsPerBar);
        expect(3, m.beatCount);
        expect(1, m.chords.length);
        Chord chord0 = m.chords[0];
        expect(
            chord0,
            CompareTo(Chord.byScaleChordAndBeats(
                ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.Es, ChordDescriptor.minor7), 3, beatsPerBar)));
      } catch (e) {
        //  parseString failed
        if (beatsPerBar < 3) continue;
        fail("too many beats or over specified, doesn't cover the beats per bar");
      }
    }
  });

  test('testTransposeToKey', () {
    Measure? m;
    //  fixme: test multi chord measures
    for (Key key in Key.values) {
      logger.i('key: $key');
      for (final scaleNote in ScaleNote.values) {
        if (scaleNote.isSilent) continue;
        logger.i('scaleNote: $scaleNote');
        for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
          logger.i('beatsPerBar: $beatsPerBar');
          m = Measure.parseString(scaleNote.toString(), beatsPerBar);
          m = m.transposeToKey(key) as Measure;
          for (Chord chord in m.chords) {
            var sn = chord.scaleChord.scaleNote;

            logger.d('key: $key sn: $sn');
            if (sn.isNatural) {
              expect(sn.isSharp, false);
              expect(sn.isFlat, false);
            } else {
              expect(sn.isSharp, key.isSharp);
              expect(!sn.isFlat, key.isSharp);
            }

            for (final sourceSlash in ScaleNote.values) {
              if (sourceSlash.isSilent) continue;
              chord.slashScaleNote = sourceSlash;
              m = Measure.parseString(chord.toString(), beatsPerBar);
              m = m.transposeToKey(key) as Measure;
              if (m.chords.isEmpty) throw TestFailure('transposeToKey result is empty');
              ScaleNote? slashScaleNote = m.chords[0].slashScaleNote;
              if (slashScaleNote == null) throw TestFailure('transposeToKey result is null');

              logger.d('key: $key m: $m sn: $sn slash: $slashScaleNote');
              if (sn.isNatural) {
                expect(sn.isSharp, false);
                expect(sn.isFlat, false);
              } else {
                expect(key.isSharp, sn.isSharp);
                expect(key.isSharp, !sn.isFlat);
              }
              if (slashScaleNote.isNatural) {
                expect(slashScaleNote.isSharp, false);
                expect(slashScaleNote.isFlat, false);
              } else {
                expect(slashScaleNote.isSharp, key.isSharp);
                logger.d('slash.isFlat: ${slashScaleNote.isFlat}, key.isSharp(): ${key.isSharp}');
                expect(!slashScaleNote.isFlat, key.isSharp);
              }
            }
          }
        }
      }
    }
  });

  test('test short measures', () {
    int beatsPerBar;
    Measure measure;
    Chord expected;

    beatsPerBar = 2;
    measure = Measure.parseString('1A', beatsPerBar);
    expect(measure.beatCount, 1);
    expected = Chord.byScaleChordAndBeats(ScaleChord.fromScaleNote(ScaleNote.A), 1, beatsPerBar);
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.toMarkup(), '1A');
    expect(measure.beatCount, 1);
    expect(measure.getChordAtBeat(2), null);

    measure = Measure.parseString('A', beatsPerBar);
    expect(measure.beatCount, 2);
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.beatCount, 2);
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.toMarkup(), 'A');

    measure = Measure.parseString('AB', beatsPerBar);
    expect(measure.beatCount, 2);
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.toMarkup(), 'AB');

    beatsPerBar = 3;
    measure = Measure.parseString('1A', beatsPerBar);
    expect(measure.beatCount, 1);
    expect(measure.toMarkup(), '1A');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('2A', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.beatsPerBar, 3);
    expect(measure.toMarkup(), 'A.');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expected.implicitBeats = false;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);

    measure = Measure.parseString('2AB', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.toMarkup(), '2AB');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(1), expected);

    measure = Measure.parseString('A.', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.toMarkup(), 'A.');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);

    measure = Measure.parseString('A..', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), 'A');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 3;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);

    measure = Measure.parseString('A', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), 'A');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 3;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);

    measure = Measure.parseString('A.B', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), 'A.B');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);

    measure = Measure.parseString('AB.', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), 'AB.');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);

    measure = Measure.parseString('ABC', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), 'ABC');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(1), expected);
    expected = Chord.parseString('C', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);

    beatsPerBar = 4;
    measure = Measure.parseString('1A', beatsPerBar);
    expect(measure.beatCount, 1);
    expect(measure.toMarkup(), '1A');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('2A', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.toMarkup(), 'A.');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('A.', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.toMarkup(), 'A.');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('2AB', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.toMarkup(), '2AB');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('A..', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), 'A..');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 3;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    //  deprecated form
    measure = Measure.parseString('A...', beatsPerBar);
    expect(measure.beatCount, 4);
    expect(measure.toMarkup(), 'A');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 4;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), expected);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('A', beatsPerBar);
    expect(measure.beatCount, 4);
    expect(measure.toMarkup(), 'A');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 4;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), expected);
    expect(measure.getChordAtBeat(4), null);

    beatsPerBar = 4;
    measure = Measure.parseString('AB', beatsPerBar);
    expect(measure.beatCount, 4);
    expect(measure.toMarkup(), 'AB');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), expected);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('A.B', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), '3A.B');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('AB.', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), '3AB.');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('ABC', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), '3ABC'); //  promoted without a beat count
    expected = Chord.parseString('A', beatsPerBar)!;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expect(measure.getChordAtBeat(1), expected);
    expected = Chord.parseString('C', beatsPerBar)!;
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('A.BC', beatsPerBar);
    expect(measure.beatCount, 4);
    expect(measure.toMarkup(), 'A.BC'); //  promoted without a beat count
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expect(measure.getChordAtBeat(2), expected);
    expected = Chord.parseString('C', beatsPerBar)!;
    expect(measure.getChordAtBeat(3), expected);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('ABC.', beatsPerBar);
    expect(measure.beatCount, 4);
    expect(measure.toMarkup(), 'ABC.'); //  promoted without a beat count
    expected = Chord.parseString('A', beatsPerBar)!;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expect(measure.getChordAtBeat(1), expected);
    expected = Chord.parseString('C', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), expected);
    expect(measure.getChordAtBeat(4), null);

/*
    beats  bpb    forms, in order of preference
    1       4     1A
    2       4     A. 2A 2AB
    3       4     A.. 3A 3A.B 3AB. 3ABC                   not: ABC
    4       4     A A..B AB A.BC AB.C ABC.              not: ABC   A...
    1       6     1A
    2       6     A. 2A 2AB
    3       6     A.. 3A 3A.B 3AB.                      not: ABC
    4       6     A... 4A 4A..B 4A.B. 4A.BC 4AB.C 4ABC.
    5       6     A.... 5A 5A...B 5A..B. 5A.BC. 5A.B.C 5AB..C 5ABC..
    6       6     A AB A..B.C AB...C ABC...   A.B.C.  not:  ABC  A.....
    */
    beatsPerBar = 6;
    measure = Measure.parseString('1A', beatsPerBar);
    expect(measure.beatCount, 1);
    expect(measure.toMarkup(), '1A');

    measure = Measure.parseString('2A', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.toMarkup(), 'A.');
    expected = Chord(ScaleChord(ScaleNote.A, ChordDescriptor.major), 2, beatsPerBar, null,
        ChordAnticipationOrDelay.defaultValue, true);
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    measure = Measure.parseString('A.', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);

    measure = Measure.parseString('2AB', beatsPerBar);
    expect(measure.beatCount, 2);
    expect(measure.toMarkup(), '2AB');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(0), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(1), expected);
    expect(measure.getChordAtBeat(2), null);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('3A.B', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), '3A.B');
    expected = Chord.parseString('A', beatsPerBar)!;
    expected.beats = 2;
    expect(measure.getChordAtBeat(0), expected);
    expect(measure.getChordAtBeat(1), expected);
    expected = Chord.parseString('B', beatsPerBar)!;
    expected.beats = 1;
    expect(measure.getChordAtBeat(2), expected);
    expect(measure.getChordAtBeat(3), null);
    expect(measure.getChordAtBeat(4), null);

    measure = Measure.parseString('A..', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), 'A..');

    measure = Measure.parseString('3A..', beatsPerBar);
    expect(measure.beatCount, 3);
    expect(measure.toMarkup(), 'A..');

    measure = Measure.parseString('4Asus2...', beatsPerBar);
    expect(measure.beatCount, 4);
    expect(measure.toMarkup(), 'Asus2...');

    measure = Measure.parseString('5A', 6);
    expect(measure.beatCount, 5);
    expect(measure.toMarkup(), 'A....');

    measure = Measure.parseString('6A', 6);
    expect(measure.beatCount, 6);
    expect(measure.toMarkup(), 'A');
  });
}
