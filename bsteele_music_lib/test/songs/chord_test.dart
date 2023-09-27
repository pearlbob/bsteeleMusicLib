import 'dart:collection';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord.dart';
import 'package:bsteele_music_lib/songs/chord_anticipation_or_delay.dart';
import 'package:bsteele_music_lib/songs/chord_descriptor.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/pitch.dart';
import 'package:bsteele_music_lib/songs/scale_chord.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../custom_matchers.dart';

Chord chordByScaleChord(final ScaleChord scaleChord) {
  return Chord(scaleChord, 4, 4, null, ChordAnticipationOrDelay.defaultValue, false);
}

void testChordTranspose(Key key) {
  int count = 0;
  for (final sn in ScaleNote.values) {
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
      for (int halfSteps = -15; halfSteps < 15; halfSteps++) {
        for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
          ScaleNote snHalfSteps = sn.transpose(key, halfSteps);

          logger.d('$sn${chordDescriptor.shortName} $halfSteps in key $key $beatsPerBar beats');
          expect(
              Chord.parseString(snHalfSteps.toString() + chordDescriptor.shortName, beatsPerBar),
              CompareTo(Chord.parseString(sn.toString() + chordDescriptor.shortName, beatsPerBar)
                  ?.transpose(key, halfSteps)));
          count++;
        }
      }
    }
  }
  logger.d('transpose count: $count');

  count = 0;
  for (final sn in ScaleNote.values) {
    for (final slashSn in ScaleNote.values) {
      for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
        for (int halfSteps = -15; halfSteps < 15; halfSteps++) {
          for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
            var snHalfSteps = sn.transpose(key, halfSteps);
            var slashSnHalfSteps = slashSn.transpose(key, halfSteps);

            logger.d('$sn${chordDescriptor.shortName}/$slashSn $halfSteps in key $key $beatsPerBar beats');
            expect(
                Chord.parseString('$snHalfSteps${chordDescriptor.shortName}/$slashSnHalfSteps', beatsPerBar),
                CompareTo(Chord.parseString('$sn${chordDescriptor.shortName}/$slashSn', beatsPerBar)
                    ?.transpose(key, halfSteps)));
            count++;
          }
        }
      }
    }
  }
  logger.d('transpose slash count: $count');
}

void main() {
  Logger.level = Level.info;

  group('chords ', () {
    test('testSetScaleChord testing', () {
      SplayTreeSet<ScaleChord> slashScaleChords = SplayTreeSet();
      for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
        for (ChordAnticipationOrDelay anticipationOrDelay in ChordAnticipationOrDelay.values) {
          logger.d('anticipationOrDelay: $anticipationOrDelay');
          for (final scaleNote in ScaleNote.values) {
            if (scaleNote == ScaleNote.X) {
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
                pChord?.beats = chord.beats;

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
      chord =
          chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.D, ChordDescriptor.diminished));
      chord.slashScaleNote = ScaleNote.G;

      logger.i('"${Chord.parseString('Ddim/G', beatsPerBar)}"');
      logger.i('compare: ${Chord.parseString('Ddim/G', beatsPerBar)?.compareTo(chord)}');
      logger.i('==: ${Chord.parseString('Ddim/G', beatsPerBar) == chord ? 'true' : 'false'}');
      Chord? pChord = Chord.parseString('Ddim/G', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));

      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.X, ChordDescriptor.major));
      chord.slashScaleNote = ScaleNote.G;
      pChord = Chord.parseString('X/G', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));

      chord =
          chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.A, ChordDescriptor.diminished));
      chord.slashScaleNote = ScaleNote.G;
      pChord = Chord.parseString('Adim/G', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));

      chord = chordByScaleChord(
          ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.G, ChordDescriptor.suspendedSecond));
      chord.slashScaleNote = ScaleNote.A;
      pChord = Chord.parseString('G2/A', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));
      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.G, ChordDescriptor.add9));
      pChord = Chord.parseString('Gadd9A', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));
      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(ScaleNote.G, ChordDescriptor.madd9));
      pChord = Chord.parseString('Gmadd9A', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));

      chord = Chord.parseString('G', beatsPerBar);
      expect(chord.toString(), 'G');
      expect(chord?.beats, 1);
      chord = Chord.parseString('G.', beatsPerBar);
      expect(chord.toString(), 'G.');
      expect(chord?.beats, 2);
      chord = Chord.parseString('G..', beatsPerBar);
      expect(chord.toString(), 'G..');
      expect(chord?.beats, 3);
      chord = Chord.parseString('G...', beatsPerBar);
      expect(chord.toString(), 'G');
      expect(chord?.beats, 4);
    });

    test('testSimpleChordTranspose testing', () {
      int count = 0;
      for (Key key in <Key>[Key.C, Key.G]) {
        for (final sn in ScaleNote.values) {
          for (int halfSteps = 0; halfSteps < 12; halfSteps++) {
            var snHalfSteps = sn.transpose(key, halfSteps);

            logger.d('$sn $halfSteps in key $key +> $snHalfSteps');
//                                assertEquals(Chord.parse(snHalfSteps + chordDescriptor.getShortName(), beatsPerBar),
//                                        Chord.parse(sn + chordDescriptor.getShortName(), beatsPerBar)
//                                                .transpose(key, halfSteps));
            count++;
          }
        }
      }
      logger.d('transpose count: $count');
    });

    test('testChordTranspose testing', () {
      //  generate the code
      for (KeyEnum key in KeyEnum.values) {
        logger.t('''
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

      Logger.level = Level.info;

      if (Logger.level.index <= Level.debug.index) {
        for (final sn in ScaleNote.values) {
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
          Chord(ScaleChord(ScaleNote.C, ChordDescriptor.major), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.defaultValue, true)
              .pianoChordPitches(),
          [Pitch.get(PitchEnum.C4), Pitch.get(PitchEnum.E4), Pitch.get(PitchEnum.G4)]);
      expect(
          Chord(ScaleChord(ScaleNote.C, ChordDescriptor.minor), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
              .pianoChordPitches(),
          [Pitch.get(PitchEnum.C4), Pitch.get(PitchEnum.Eb4), Pitch.get(PitchEnum.G4)]);
      expect(
          Chord(ScaleChord(ScaleNote.C, ChordDescriptor.dominant7), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
              .pianoChordPitches(),
          [Pitch.get(PitchEnum.C4), Pitch.get(PitchEnum.E4), Pitch.get(PitchEnum.G4), Pitch.get(PitchEnum.Bb4)]);
      expect(
          Chord(ScaleChord(ScaleNote.C, ChordDescriptor.dominant7), beats, beatsPerBar, ScaleNote.G,
                  ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
              .pianoChordPitches(),
          [
            //  slash note not included
            Pitch.get(PitchEnum.C4),
            Pitch.get(PitchEnum.E4),
            Pitch.get(PitchEnum.G4),
            Pitch.get(PitchEnum.Bb4)
          ]);

      expect(
        Chord(ScaleChord(ScaleNote.C, ChordDescriptor.dominant7), beats, beatsPerBar, ScaleNote.G,
                ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
            .pianoSlashPitch(),
        Pitch.get(PitchEnum.G2),
      );

      expect(
        Chord(ScaleChord(ScaleNote.C, ChordDescriptor.dominant7), beats, beatsPerBar, ScaleNote.G,
                ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
            .bassSlashPitch(),
        Pitch.get(PitchEnum.G1),
      );

      expect(
          Chord(ScaleChord(ScaleNote.C, ChordDescriptor.dominant7), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
              .pianoSlashPitch(),
          isNull);

      expect(
          Chord(ScaleChord(ScaleNote.C, ChordDescriptor.dominant7), beats, beatsPerBar, null,
                  ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.anticipate8th), true)
              .bassSlashPitch(),
          isNull);

      //  G♯maj9: {R, 3, 5, 7, 9}: [G♯4, C5, D♯5, G5, C6]
      expect(
          Chord(ScaleChord(ScaleNote.Gs, ChordDescriptor.major9), beats, beatsPerBar, null,
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
