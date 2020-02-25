import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/Chord.dart';
import 'package:bsteeleMusicLib/songs/ChordAnticipationOrDelay.dart';
import 'package:bsteeleMusicLib/songs/ChordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/Measure.dart';
import 'package:bsteeleMusicLib/songs/Key.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import "package:test/test.dart";

import '../CustomMatchers.dart';

void main() {
  Logger.level = Level.warning;

  test("test equality", () {
    Measure m;
    Measure ref;
    int beats = 4;
    int beatsPerBar = 4;

    {
      m = Measure.parseString("B", beats);
      expect(m, isNotNull);
      Chord chord = Chord.byScaleChordAndBeats(
          ScaleChord(ScaleNote.get(ScaleNoteEnum.B), ChordDescriptor.major),
          beats,
          beatsPerBar);
      ref = Measure(beats, [chord]);
      logger.i("m:   " + m.toMarkup());
      logger.i("ref: " + ref.toMarkup());
      logger.i("m == ref: " + (m == ref).toString());
      expect(m, ref);
    }
  });

  test("testparseString", () {
    String s;
    Measure m;

    {
      s = "X.";

      m = Measure.parseString(s, 4);
      expect(m, isNotNull);

      //  explicit measure short of beats is left as specified
      expect(m.toMarkup(), s);
    }
    {
      s = "GD.C";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect("GD.C", m.toMarkup());
    }
    {
      s = "AX";

      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect("AX", m.toMarkup());
    }
    {
      s = "AX..";

      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect("AX..", m.toMarkup());
    }
    {
      s = "X";

      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect("X", m.toMarkup());
    }

    {
      s = "A.B.";

      m = Measure.parseString(s, 5);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect("A.B.", m.toMarkup());
    }
    {
      s = "A.B.";

      m = Measure.parseString(s, 5);
      expect(m, isNotNull);
      //  explicit measure short of beats is left as specified
      expect("A.B.", m.toMarkup());
    }
    {
      s = "AB";
      m = Measure.parseString(s, 5);
      expect(m, isNotNull);
      //  5/4 split across two chords, first one gets the extra beat
      expect("A..B.", m.toMarkup());
    }
    {
      s = "A.B.";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      //  default to simplest expression
      expect("AB", m.toMarkup());
    }
    {
      s = "A/GA/F♯";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(m.toMarkup(), "A/GA/F#");
    }
    {
      s = "A/G";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
      expect(m.beatCount, 4);
    }
    {
      s = "F.";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
      expect(m.beatCount, 2);
    }
    {
      s = "F.";
      m = Measure.parseString(s, 2);
      expect(m, isNotNull);
      expect("F", m.toMarkup());
      expect(m.beatCount, 2);
    }
    {
      s = "F..";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
      expect(m.beatCount, 3);
    }
    {
      s = "F...";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect("F", m.toMarkup());
      expect(m.beatCount, 4);
    }
    {
      s = "A..B";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
      expect(m.beatCount, 4);
    }
    {
      s = "AB..";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
    }
    {
      s = "ABC.";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
    }
    {
      s = "A.BC";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(s, m.toMarkup());
    }

    {
      s = "E♭F";
      m = Measure.parseString(s, 4);
      expect(m, isNotNull);
      expect(m.toMarkup(), "EbF");
    }
    {
      s = "E♭F";
      m = Measure.parseString(s, 3);
      expect(m, isNotNull);
      expect(m.toMarkup(), "Eb.F");
    }
    {
      //  test beat allocation
      m = Measure.parseString("EAB", 4);
      expect(3, m.chords.length);
      expect(2, m.chords[0].beats);
      expect(1, m.chords[1].beats);
      expect(1, m.chords[2].beats);

      m = Measure.parseString("EA", 4);
      expect(2, m.chords.length);
      expect(2, m.chords[0].beats);
      expect(2, m.chords[1].beats);
      m = Measure.parseString("E..A", 4);
      expect(2, m.chords.length);
      expect(3, m.chords[0].beats);
      expect(1, m.chords[1].beats);

      m = Measure.parseString("E.A", 4);
      expect(2, m.chords.length);
      expect(2, m.chords[0].beats);
      expect(2, m.chords[1].beats);
      m = Measure.parseString("E.A.", 4);
      expect(2, m.chords.length);
      expect(2, m.chords[0].beats);
      expect(2, m.chords[1].beats);
      m = Measure.parseString("EA.", 4);
      expect(2, m.chords.length);
      expect(2, m.chords[0].beats);
      expect(2, m.chords[1].beats);
      m = Measure.parseString("EA.", 6);
      expect(2, m.chords.length);
      expect(4, m.chords[0].beats);
      expect(2, m.chords[1].beats);

      //  too many specific beats
      m = Measure.parseString("E..A.", 4);
      expect(m, isNotNull); //  fixme: Measure.parseString() on errors

      //  too few specific beats
      m = Measure.parseString("E..A.", 6);
      expect(m, isNotNull); //  fixme: Measure.parseString() on errors
    }

    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString("A", beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(1, m.chords.length);
      Chord chord = m.chords[0];
      expect(
          chord,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.A),
              beatsPerBar,
              beatsPerBar)));
    }

    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString("BC", beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(2, m.chords.length);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat1 = beatsPerBar ~/ 2; //  smaller beat on 3 in 3 beats
      int beat0 = beatsPerBar - beat1;
      Chord refChord = Chord.byScaleChordAndBeats(
          ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.B), beat0, beatsPerBar);
      expect(chord0, CompareTo(refChord));
      expect(
          chord1,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.C),
              beat1,
              beatsPerBar)));
    }
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString("E#m7. ", beatsPerBar);
      expect(m, isNotNull);
      expect(2, m.beatCount);
      expect(1, m.chords.length);
      Chord chord0 = m.chords[0];
      expect(
          chord0,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(
                  ScaleNoteEnum.Es, ChordDescriptor.minor7),
              2,
              beatsPerBar)));
    }
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString("E#m7Gb7", beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(2, m.chords.length);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat1 = beatsPerBar ~/ 2;
      int beat0 = beatsPerBar - beat1;
      expect(
          chord0,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(
                  ScaleNoteEnum.Es, ChordDescriptor.minor7),
              beat0,
              beatsPerBar)));
      expect(
          chord1,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(
                  ScaleNoteEnum.Gb, ChordDescriptor.dominant7),
              beat1,
              beatsPerBar)));
    }
    for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString("F#m7.Asus4", beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(2, m.chords.length);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat0 = 2;
      int beat1 = beatsPerBar - beat0;
      expect(
          chord0,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(
                  ScaleNoteEnum.Fs, ChordDescriptor.minor7),
              beat0,
              beatsPerBar)));
      expect(
          chord1,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnumAndChordDescriptor(
                  ScaleNoteEnum.A, ChordDescriptor.suspended4),
              beat1,
              beatsPerBar)));
    }

    ChordAnticipationOrDelay delayNone =
        ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.none);
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString("A/G#", beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(1, m.chords.length);
      Chord chord = m.chords[0];
      expect(
          chord,
          CompareTo(Chord(
              ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.A),
              beatsPerBar,
              beatsPerBar,
              ScaleNote.get(ScaleNoteEnum.Gs),
              delayNone,
              true)));
    }
    for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
      m = Measure.parseString("C/F#.G", beatsPerBar);
      expect(beatsPerBar, m.beatCount);
      expect(2, m.chords.length);
      Chord chord0 = m.chords[0];
      Chord chord1 = m.chords[1];
      int beat0 = 2;
      int beat1 = beatsPerBar - beat0;
      expect(
          chord0,
          CompareTo(Chord(ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.C), beat0,
              beatsPerBar, ScaleNote.get(ScaleNoteEnum.Fs), delayNone, true)));
      expect(
          chord1,
          CompareTo(Chord.byScaleChordAndBeats(
              ScaleChord.fromScaleNoteEnum(ScaleNoteEnum.G),
              beat1,
              beatsPerBar)));
    }
    {
      for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
        Measure m0 = Measure.parseString("C", beatsPerBar);
        m = Measure.parse(MarkedString("-"), beatsPerBar, m0);
        expect(beatsPerBar, m.beatCount);
        expect(1, m.chords.length);
        expect(m0.chords, m.chords);
      }
    }
    {
      for (int beatsPerBar = 3; beatsPerBar <= 4; beatsPerBar++) {
        m = Measure.parseString("X", beatsPerBar);
        expect(beatsPerBar, m.beatCount);
        expect(1, m.chords.length);
      }
    }
    {
      m = Measure.parseString("E#m7. ", 3);
      expect(m, isNotNull);
      expect("E#m7.", m.toMarkup());
    }

    {
      //  too many beats or over specified, doesn't cover the beats per bar
      try {
        m = Measure.parseString("E#m7.. ", 2);
        fail("should be exception on too many beats in measure");
      } catch (e) {
        //  expected
      }
    }
    {
      int beatsPerBar = 4;
      try {
        m = Measure.parseString(" .G ", beatsPerBar);
        fail("should fail on stupid entry: .G");
      } catch (e) {
        //  expected
      }
    }
    {
      int beatsPerBar = 3;
      logger.d("beatsPerBar: " + beatsPerBar.toString());
      try {
        m = Measure.parseString(" .G ", beatsPerBar);
        fail("should fail on stupid entry: .G");
      } catch (e) {
        //  expected
      }
      try {
        m = Measure.parseString("E#m7... ", beatsPerBar);
        fail("should be exception on too many beats in measure");
      } catch (e) {
        //  expected
      }
    }
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      try {
        m = Measure.parseString("E#m7.. ", beatsPerBar);
        expect(3, m.beatCount);
        expect(1, m.chords.length);
        Chord chord0 = m.chords[0];
        expect(
            chord0,
            CompareTo(Chord.byScaleChordAndBeats(
                ScaleChord.fromScaleNoteEnumAndChordDescriptor(
                    ScaleNoteEnum.Es, ChordDescriptor.minor7),
                3,
                beatsPerBar)));
      } catch (e) {
        //  parseString failed
        if (beatsPerBar < 3) continue;
        fail(
            "too many beats or over specified, doesn't cover the beats per bar");
      }
    }
  });

  test("testTransposeToKey", () {
    Measure m;
    //  fixme: test multi chord measures
    for (Key key in Key.values) {
      logger.i("key: " + key.toString());
      for (ScaleNote scaleNote in ScaleNote.values) {
        if (scaleNote.isSilent) continue;
        logger.i("scaleNote: " + scaleNote.toString());
        for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
          logger.i("beatsPerBar: " + beatsPerBar.toString());
          m = Measure.parseString(scaleNote.toString(), beatsPerBar);
          m = m.transposeToKey(key) as Measure;
          for (Chord chord in m.chords) {
            ScaleNote sn = chord.scaleChord.scaleNote;

            logger.d("key: " + key.toString() + " sn: " + sn.toString());
            if (sn.isNatural) {
              expect(sn.isSharp, false);
              expect(sn.isFlat, false);
            } else {
              expect(sn.isSharp, key.isSharp);
              expect(!sn.isFlat, key.isSharp);
            }

            for (ScaleNote slash in ScaleNote.values) {
              if (slash.isSilent) continue;
              chord.slashScaleNote = slash;
              m = Measure.parseString(chord.toString(), beatsPerBar);
              m = m.transposeToKey(key) as Measure;
              slash = m.chords[0].slashScaleNote;

              logger.d("key: " +
                  key.toString() +
                  " m: " +
                  m.toString() +
                  " sn: " +
                  sn.toString() +
                  " slash: " +
                  slash.toString());
              if (sn.isNatural) {
                expect(sn.isSharp, false);
                expect(sn.isFlat, false);
              } else {
                expect(key.isSharp, sn.isSharp);
                expect(key.isSharp, !sn.isFlat);
              }
              if (slash.isNatural) {
                expect(slash.isSharp, false);
                expect(slash.isFlat, false);
              } else {
                expect(slash.isSharp, key.isSharp);
                logger.d("slash.isFlat: " +
                    slash.isFlat.toString() +
                    ", key.isSharp(): " +
                    key.isSharp.toString());
                expect(!slash.isFlat, key.isSharp);
              }
            }
          }
        }
      }
    }
  });
}
