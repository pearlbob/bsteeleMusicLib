import 'dart:collection';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chord.dart';
import 'package:bsteeleMusicLib/songs/chordAnticipationOrDelay.dart';
import 'package:bsteeleMusicLib/songs/chordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/pitch.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../customMatchers.dart';

void testChordTranspose(Key key) {
  int count = 0;
  for (ScaleNote sn in ScaleNote.values) {
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      for (int halfSteps = -15; halfSteps < 15; halfSteps++) {
        for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
          ScaleNote snHalfSteps = sn.transpose(key, halfSteps);

          logger.d(sn.toString() +
              chordDescriptor.shortName +
              ' ' +
              halfSteps.toString() +
              ' in key ' +
              key.toString() +
              ' ' +
              beatsPerBar.toString() +
              ' beats');
          expect(
              Chord.parseString(snHalfSteps.toString() + chordDescriptor.shortName, beatsPerBar),
              CompareTo(Chord.parseString(sn.toString() + chordDescriptor.shortName, beatsPerBar)
                  ?.transpose(key, halfSteps)));
          count++;
        }
      }
    }
  }
  logger.d('transpose count: ' + count.toString());

  count = 0;
  for (ScaleNote sn in ScaleNote.values) {
    for (ScaleNote slashSn in ScaleNote.values) {
      for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
        for (int halfSteps = -15; halfSteps < 15; halfSteps++) {
          for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
            ScaleNote snHalfSteps = sn.transpose(key, halfSteps);
            ScaleNote slashSnHalfSteps = slashSn.transpose(key, halfSteps);

            logger.d(sn.toString() +
                chordDescriptor.shortName +
                '/' +
                slashSn.toString() +
                ' ' +
                halfSteps.toString() +
                ' in key ' +
                key.toString() +
                ' ' +
                beatsPerBar.toString() +
                ' beats');
            expect(
                Chord.parseString(
                    snHalfSteps.toString() + chordDescriptor.shortName + '/' + slashSnHalfSteps.toString(),
                    beatsPerBar),
                CompareTo(
                    Chord.parseString(sn.toString() + chordDescriptor.shortName + '/' + slashSn.toString(), beatsPerBar)
                        ?.transpose(key, halfSteps)));
            count++;
          }
        }
      }
    }
  }
  logger.d('transpose slash count: ' + count.toString());
}

void main() {
  Logger.level = Level.warning;

  group('chords ', () {
    test('testSetScaleChord testing', () {
      SplayTreeSet<ScaleChord> slashScaleChords = SplayTreeSet();
      for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
        for (ChordAnticipationOrDelay anticipationOrDelay in ChordAnticipationOrDelay.values) {
          logger.d('anticipationOrDelay: ' + anticipationOrDelay.toString());
          for (ScaleNote scaleNote in ScaleNote.values) {
            if (scaleNote.getEnum() == ScaleNoteEnum.X) {
              continue;
            }
            for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
              for (int beats = 2; beats <= 4; beats++) {
                ScaleChord scaleChord = ScaleChord(scaleNote, chordDescriptor);
                if (chordDescriptor == ChordDescriptor.minor) {
                  slashScaleChords.add(scaleChord);
                }
                Chord chord = Chord(scaleChord, beats, beatsPerBar, null, anticipationOrDelay, true);
                logger.d(chord.toString());
                Chord? pChord = Chord.parseString(chord.toString(), beatsPerBar);

                if (pChord != null && beats != beatsPerBar) {
                  //  the beats will default to beats per bar if unspecified
                  expect(pChord.scaleChord, CompareTo(chord.scaleChord));
                  expect(pChord.slashScaleNote, chord.slashScaleNote);
                } else {
                  expect(pChord, CompareTo(chord));
                }
              }
            }
          }
        }
      }
    });

    test('testChordParse testing', () {
      Chord? chord;
      int beatsPerBar = 4;
      chord = Chord.byScaleChord(
          ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.D, ChordDescriptor.diminished));
      chord.slashScaleNote = ScaleNote.get(ScaleNoteEnum.G);

      logger.i('\"' + Chord.parseString('Ddim/G', beatsPerBar).toString() + '\"');
      logger.i('compare: ' + (Chord.parseString('Ddim/G', beatsPerBar)?.compareTo(chord)).toString());
      logger.i('==: ' + (Chord.parseString('Ddim/G', beatsPerBar) == chord ? 'true' : 'false'));
      Chord? pChord = Chord.parseString('Ddim/G', beatsPerBar);
      expect(pChord, CompareTo(chord));

      chord =
          Chord.byScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.X, ChordDescriptor.major));
      chord.slashScaleNote = ScaleNote.get(ScaleNoteEnum.G);
      expect(Chord.parseString('X/G', beatsPerBar), CompareTo(chord));

      chord = Chord.byScaleChord(
          ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.A, ChordDescriptor.diminished));
      chord.slashScaleNote = ScaleNote.get(ScaleNoteEnum.G);
      expect(Chord.parseString('Adim/G', beatsPerBar), CompareTo(chord));
      chord = Chord.byScaleChord(
          ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.G, ChordDescriptor.suspendedSecond));
      chord.slashScaleNote = ScaleNote.get(ScaleNoteEnum.A);
      expect(Chord.parseString('G2/A', beatsPerBar), CompareTo(chord));
      chord = Chord.byScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNoteEnum.G, ChordDescriptor.add9));
      expect(Chord.parseString('Gadd9A', beatsPerBar), CompareTo(chord));

      chord = Chord.parseString('G.1', beatsPerBar);
      expect(chord.toString(), 'G.1');
      chord = Chord.parseString('G.2', beatsPerBar);
      expect(chord.toString(), 'G.');
      chord = Chord.parseString('G.3', beatsPerBar);
      expect(chord.toString(), 'G..');
      chord = Chord.parseString('G.4', beatsPerBar);
      expect(chord.toString(), 'G');
    });

    test('testSimpleChordTranspose testing', () {
      int count = 0;
      for (Key key in <Key>[Key.get(KeyEnum.C), Key.get(KeyEnum.G)]) {
        for (ScaleNote sn in ScaleNote.values) {
          for (int halfSteps = 0; halfSteps < 12; halfSteps++) {
            ScaleNote snHalfSteps = sn.transpose(key, halfSteps);

            logger.d(sn.toString() +
                ' ' +
                halfSteps.toString() +
                ' in key ' +
                key.toString() +
                ' +> ' +
                snHalfSteps.toString());
//                                assertEquals(Chord.parse(snHalfSteps + chordDescriptor.getShortName(), beatsPerBar),
//                                        Chord.parse(sn + chordDescriptor.getShortName(), beatsPerBar)
//                                                .transpose(key, halfSteps));
            count++;
          }
        }
      }
      logger.d('transpose count: ' + count.toString());
    });

    test('testChordTranspose testing', () {
      //  generate the code
      for (KeyEnum key in KeyEnum.values) {
        logger.v('''
  KeyEnum keyEnum = KeyEnum.$key;

  test('testChordTranspose \$keyEnum', () {
    testChordTranspose(Key.get(keyEnum));
  });
      ''');
      }
    });

    test('test piano pitches ', () {
      int beats = 4;
      int beatsPerBar = 4;
      ChordDescriptor chordDescriptor = ChordDescriptor.major;

      Logger.level = Level.info;

      if (Logger.level.index <= Level.debug.index) {
        for (ScaleNote sn in ScaleNote.values) {
          if (sn.isSilent) {
            continue;
          }
          logger.i('$sn:');
          for (var chordDescriptor in ChordDescriptor.values) {
            ScaleChord scaleChord = ScaleChord(sn, chordDescriptor);
            Chord chord = Chord(scaleChord, beats, beatsPerBar, null, ChordAnticipationOrDelay.defaultValue, true);
            logger.i('  $chord: ${chordDescriptor.chordComponents}: ${chord.pianoChordPitches()}');
          }
        }
      }
      expect(
          Chord(ScaleChord(ScaleNote.get(ScaleNoteEnum.C), ChordDescriptor.major), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.defaultValue, true)
              .pianoChordPitches(),
          [Pitch.get(PitchEnum.C4), Pitch.get(PitchEnum.E4), Pitch.get(PitchEnum.G4)]);
      expect(
          Chord(ScaleChord(ScaleNote.get(ScaleNoteEnum.C), ChordDescriptor.minor), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
              .pianoChordPitches(),
          [Pitch.get(PitchEnum.C4), Pitch.get(PitchEnum.Eb4), Pitch.get(PitchEnum.G4)]);
      expect(
          Chord(ScaleChord(ScaleNote.get(ScaleNoteEnum.C), ChordDescriptor.dominant7), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
              .pianoChordPitches(),
          [Pitch.get(PitchEnum.C4), Pitch.get(PitchEnum.E4), Pitch.get(PitchEnum.G4), Pitch.get(PitchEnum.Bb4)]);
      expect(
          Chord(
                  ScaleChord(ScaleNote.get(ScaleNoteEnum.C), ChordDescriptor.dominant7),
                  beats,
                  beatsPerBar,
                  ScaleNote.get(ScaleNoteEnum.G),
                  ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th),
                  true)
              .pianoChordPitches(),
          [
            Pitch.get(PitchEnum.G1),
            Pitch.get(PitchEnum.C4),
            Pitch.get(PitchEnum.E4),
            Pitch.get(PitchEnum.G4),
            Pitch.get(PitchEnum.Bb4)
          ]);

      //  G♯maj9: {R, 3, 5, 7, 9}: [G♯4, C5, D♯5, G5, C6]
      expect(
          Chord(ScaleChord(ScaleNote.get(ScaleNoteEnum.Gs), ChordDescriptor.major9), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.defaultValue, true)
              .pianoChordPitches(),
          [
            Pitch.get(PitchEnum.Gs4),
            Pitch.get(PitchEnum.C5),
            Pitch.get(PitchEnum.Ds5),
            Pitch.get(PitchEnum.G5),
            Pitch.get(PitchEnum.C6)
          ]);
    });
  });
}
