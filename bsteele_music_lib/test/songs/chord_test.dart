import 'dart:collection';
import 'dart:convert';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord.dart';
import 'package:bsteele_music_lib/songs/chord_anticipation_or_delay.dart';
import 'package:bsteele_music_lib/songs/chord_component.dart';
import 'package:bsteele_music_lib/songs/chord_descriptor.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/measure.dart';
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
            CompareTo(
              Chord.parseString(sn.toString() + chordDescriptor.shortName, beatsPerBar)?.transpose(key, halfSteps),
            ),
          );
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
              CompareTo(
                Chord.parseString('$sn${chordDescriptor.shortName}/$slashSn', beatsPerBar)?.transpose(key, halfSteps),
              ),
            );
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

    test('testSetScaleChord testing', () {
      SplayTreeSet<ScaleChord> slashScaleChords = SplayTreeSet();
      for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++) {
        for (ChordAnticipationOrDelay anticipationOrDelay in ChordAnticipationOrDelay.values) {
          logger.d('anticipationOrDelay: $anticipationOrDelay');
          for (final scaleNote in ScaleNote.values) {
            if (scaleNote == .X) {
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

      logger.i('"${Chord.parseString('F....', beatsPerBar)}"'); //  exception throw should not happen
      logger.i('"${Chord.parseString('(F....)', beatsPerBar)}"'); //  exception throw should not happen

      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.D, ChordDescriptor.diminished));
      chord.slashScaleNote = .G;

      logger.i('"${Chord.parseString('Ddim/G', beatsPerBar)}"');
      logger.i('compare: ${Chord.parseString('Ddim/G', beatsPerBar)?.compareTo(chord)}');
      logger.i('==: ${Chord.parseString('Ddim/G', beatsPerBar) == chord ? 'true' : 'false'}');
      Chord? pChord = Chord.parseString('Ddim/G', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));

      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.X, ChordDescriptor.major));
      chord.slashScaleNote = .G;
      pChord = Chord.parseString('X/G', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));

      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.A, ChordDescriptor.diminished));
      chord.slashScaleNote = .G;
      pChord = Chord.parseString('Adim/G', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));

      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.G, ChordDescriptor.suspendedSecond));
      chord.slashScaleNote = .A;
      pChord = Chord.parseString('G2/A', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));
      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.G, ChordDescriptor.add9));
      pChord = Chord.parseString('Gadd9A', beatsPerBar);
      pChord?.beats = beatsPerBar;
      expect(pChord, CompareTo(chord));
      chord = chordByScaleChord(ScaleChord.fromScaleNoteEnumAndChordDescriptor(.G, ChordDescriptor.madd9));
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

      for (final sn in ScaleNote.values) {
        if (sn.isSilent) {
          continue;
        }

        // if (Logger.level.index <= Level.debug.index)
            {
          logger.i('$sn:');
          for (final chordDescriptor in ChordDescriptor.values) {
            ScaleChord scaleChord = ScaleChord(sn, chordDescriptor);
            Chord chord = Chord(scaleChord, beats, beatsPerBar, null, ChordAnticipationOrDelay.defaultValue, true);
            var halfSteps = chordDescriptor.chordComponents.map((chordComponent) {
              return chordComponent.halfSteps;
            }).toList();
            logger.i(
              '  ${chord.toString().padLeft(8)}: ${chordDescriptor.chordComponents.toString().padLeft(28)}'
                  ': ${halfSteps.toString().padLeft(28)},    ${chord.pianoChordPitches()}',
            );
          }
        }
      }
      expect(
        Chord(
          ScaleChord(.C, ChordDescriptor.major),
          beats,
          beatsPerBar,
          null,
          ChordAnticipationOrDelay.defaultValue,
          true,
        ).pianoChordPitches(),
        [Pitch.get(.C4), Pitch.get(.E4), Pitch.get(.G4)],
      );
      expect(
        Chord(
          ScaleChord(.C, ChordDescriptor.minor),
          beats,
          beatsPerBar,
          null,
          ChordAnticipationOrDelay.get(.anticipate8th),
          true,
        ).pianoChordPitches(),
        [Pitch.get(.C4), Pitch.get(.Eb4), Pitch.get(.G4)],
      );
      expect(
        Chord(
          ScaleChord(.C, ChordDescriptor.dominant7),
          beats,
          beatsPerBar,
          null,
          ChordAnticipationOrDelay.get(.anticipate8th),
          true,
        ).pianoChordPitches(),
        [Pitch.get(.C4), Pitch.get(.E4), Pitch.get(.G4), Pitch.get(.Bb4)],
      );
      expect(
        Chord(
          ScaleChord(.C, ChordDescriptor.dominant7),
          beats,
          beatsPerBar,
              .G,
          ChordAnticipationOrDelay.get(.anticipate8th),
          true,
        ).pianoChordPitches(),
        [
          //  slash note not included
          Pitch.get(.C4),
          Pitch.get(.E4),
          Pitch.get(.G4),
          Pitch.get(.Bb4),
        ],
      );

      expect(
        Chord(
          ScaleChord(.C, ChordDescriptor.dominant7),
          beats,
          beatsPerBar,
              .G,
          ChordAnticipationOrDelay.get(.anticipate8th),
          true,
        ).pianoSlashPitch(),
        Pitch.get(.G2),
      );

      expect(
        Chord(
          ScaleChord(.C, ChordDescriptor.dominant7),
          beats,
          beatsPerBar,
              .G,
          ChordAnticipationOrDelay.get(.anticipate8th),
          true,
        ).bassSlashPitch(),
        Pitch.get(.G1),
      );

      expect(
        Chord(
          ScaleChord(.C, ChordDescriptor.dominant7),
          beats,
          beatsPerBar,
          null,
          ChordAnticipationOrDelay.get(.anticipate8th),
          true,
        ).pianoSlashPitch(),
        isNull,
      );

      expect(
        Chord(
          ScaleChord(.C, ChordDescriptor.dominant7),
          beats,
          beatsPerBar,
          null,
          ChordAnticipationOrDelay.get(.anticipate8th),
          true,
        ).bassSlashPitch(),
        isNull,
      );

      //  G♯maj9: {R, 3, 5, 7, 9}: [G♯4, C5, D♯5, G5, A♯5]
      expect(
        Chord(
          ScaleChord(.Gs, ChordDescriptor.major9),
          beats,
          beatsPerBar,
          null,
          ChordAnticipationOrDelay.defaultValue,
          true,
        ).pianoChordPitches(),
        [Pitch.get(.Gs4), Pitch.get(.C5), Pitch.get(.Ds5), Pitch.get(.G5), Pitch.get(.As5)],
      );
    });
  test('test sample chordDescriptors', () {
    print(ChordComponent.values);
    expect(ChordComponent.octave.halfSteps, 12);
    expect(ChordComponent.ninth.halfSteps, 14);
    expect(ChordComponent.eleventh.halfSteps, 17);
    expect(ChordComponent.thirteenth.halfSteps, 21);
    ChordDescriptor chordDescriptor = ChordDescriptor.minor9;
    expect(chordDescriptor.chordComponents.toList(), [
      ChordComponent.root,
      ChordComponent.minorThird,
      ChordComponent.fifth,
      ChordComponent.minorSeventh,
      ChordComponent.ninth
    ]);
    var halfSteps = chordDescriptor.chordComponents.map((chordComponent) {
      return chordComponent.halfSteps;
    }).toList();
    expect(halfSteps, [ 0, 3, 7, 10, 14]);
  });

  test('test simplified chords', () {
    logger.i(
      '${'chord'.padLeft(7)}: simplified'
          '                   comparison                               difference',
    );
    for (var descriptor in ChordDescriptor.values) {
      var comparison = descriptor != descriptor.simplified
          ? '${descriptor.chordComponents.toString().padLeft(25)}'
          ' => ${descriptor.simplified.chordComponents.toString().padRight(25)}'
          : '';
      var inFirst = descriptor.chordComponents.where((e) => !descriptor.simplified.chordComponents.contains(e));
      var inSecond = descriptor.simplified.chordComponents.where((e) => !descriptor.chordComponents.contains(e));
      var diff = inFirst.isEmpty && inSecond.isEmpty
          ? ''
          : '${inFirst.toString().padLeft(10)} => ${inSecond.toString().padRight(10)}';

      logger.i(
        '${descriptor.toString().padLeft(7)}: ${descriptor.simplified.toString().padLeft(7)}'
            ' $comparison'
            ' $diff',
      );
    }

    // for (var descriptor in ChordDescriptor.values) {
    //   logger.i('expect(ChordDescriptor.${descriptor.name.toString()}.simplified.name'
    //       ', \'${descriptor.simplified.name}\');');
    // }
    //  generated:
    expect(ChordDescriptor.major.simplified.name, 'major');
    expect(ChordDescriptor.minor.simplified.name, 'minor');
    expect(ChordDescriptor.dominant7.simplified.name, 'dominant7');
    expect(ChordDescriptor.minor7.simplified.name, 'minor7');
    expect(ChordDescriptor.power5.simplified.name, 'major');
    expect(ChordDescriptor.major7.simplified.name, 'major7');
    expect(ChordDescriptor.major6.simplified.name, 'major');
    expect(ChordDescriptor.suspended2.simplified.name, 'major');
    expect(ChordDescriptor.suspended4.simplified.name, 'major');
    expect(ChordDescriptor.add9.simplified.name, 'major');
    expect(ChordDescriptor.majorSeven.simplified.name, 'major');
    expect(ChordDescriptor.dominant9.simplified.name, 'dominant7');
    expect(ChordDescriptor.sevenSus4.simplified.name, 'dominant7');
    expect(ChordDescriptor.diminished.simplified.name, 'minor');
    expect(ChordDescriptor.minor6.simplified.name, 'minor');
    expect(ChordDescriptor.major9.simplified.name, 'major');
    expect(ChordDescriptor.suspendedSecond.simplified.name, 'major');
    expect(ChordDescriptor.minor9.simplified.name, 'minor');
    expect(ChordDescriptor.augmented.simplified.name, 'major');
    expect(ChordDescriptor.suspended.simplified.name, 'major');
    expect(ChordDescriptor.suspendedFourth.simplified.name, 'major');
    expect(ChordDescriptor.sevenSharp5.simplified.name, 'dominant7');
    expect(ChordDescriptor.maj.simplified.name, 'major');
    expect(ChordDescriptor.minor7b5.simplified.name, 'minor');
    expect(ChordDescriptor.diminished7.simplified.name, 'minor');
    expect(ChordDescriptor.minor11.simplified.name, 'minor');
    expect(ChordDescriptor.six9.simplified.name, 'major');
    expect(ChordDescriptor.msus4.simplified.name, 'minor');
    expect(ChordDescriptor.dominant11.simplified.name, 'dominant7');
    expect(ChordDescriptor.sevenSus.simplified.name, 'dominant7');
    expect(ChordDescriptor.augmented7.simplified.name, 'dominant7');
    expect(ChordDescriptor.capMajor.simplified.name, 'major');
    expect(ChordDescriptor.mmaj7.simplified.name, 'minor');
    expect(ChordDescriptor.dominant13.simplified.name, 'dominant7');
    expect(ChordDescriptor.msus2.simplified.name, 'minor');
    expect(ChordDescriptor.sevenSharp9.simplified.name, 'dominant7');
    expect(ChordDescriptor.sevenFlat9.simplified.name, 'dominant7');
    expect(ChordDescriptor.sevenFlat5.simplified.name, 'dominant7');
    expect(ChordDescriptor.suspended7.simplified.name, 'dominant7');
    expect(ChordDescriptor.minor13.simplified.name, 'minor');
    expect(ChordDescriptor.augmented5.simplified.name, 'major');
    expect(ChordDescriptor.jazz7b9.simplified.name, 'dominant7');
    expect(ChordDescriptor.capMajor7.simplified.name, 'major');
    expect(ChordDescriptor.deltaMajor7.simplified.name, 'major');
    expect(ChordDescriptor.dimMasculineOrdinalIndicator.simplified.name, 'minor');
    expect(ChordDescriptor.dimMasculineOrdinalIndicator7.simplified.name, 'minor');
    expect(ChordDescriptor.diminishedAsCircle.simplified.name, 'minor');
    expect(ChordDescriptor.madd9.simplified.name, 'minor');
    expect(ChordDescriptor.maug.simplified.name, 'minor');
    expect(ChordDescriptor.majorNine.simplified.name, 'major');
    expect(ChordDescriptor.nineSus4.simplified.name, 'dominant7');
    expect(ChordDescriptor.flat5.simplified.name, 'major');
    expect(ChordDescriptor.sevenSus2.simplified.name, 'dominant7');
  });

  test('chord serialization', () {
    Logger.level = Level.info;

    ChordAnticipationOrDelay anticipationOrDelay = ChordAnticipationOrDelay.defaultValue;

    for (int beatsPerBar in [2, 3, 4, 6]) {
      for (var beats = 1; beats <= beatsPerBar; beats++) {
        bool implicitBeats = beats < beatsPerBar; //  chord has fewer beats than the beats per bar
        for (ScaleNote? slashScaleNote in [null, .A, ScaleNote.C]) {
          for (ScaleNote scaleNote in ScaleNote.values) {
            for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
              ScaleChord scaleChord = ScaleChord(scaleNote, chordDescriptor);

              Chord chord = Chord(scaleChord, beats, beatsPerBar, slashScaleNote, anticipationOrDelay, implicitBeats);
              final encoded = jsonEncode(chord);
              logger.i(
                'chord($scaleChord, $beats, $beatsPerBar, $slashScaleNote, $anticipationOrDelay, $implicitBeats)'
                    ': \n$encoded',
              );

              final copy = Chord.fromJson(jsonDecode(encoded));
              expect(copy, chord);
            }
          }
        }
      }
    }
  });

  test('chord beat size test', () {
    Logger.level = Level.info;

    int beatsPerBar = 4;

    Measure m;
    String input;

    input = "GCG";
    m = Measure.parseString(input, beatsPerBar);
    logger.i('m: $m');
    expect(m.toString(), '$input'); //  demand 3 beats in 4/4

    input = "G";
    m = Measure.parseString(input, beatsPerBar);
    logger.i('m: $m');
    expect(m.toString(), input);

    input = "GC";
    m = Measure.parseString(input, beatsPerBar);
    logger.i('m: $m');
    expect(m.toString(), input);

    input = "G.CG";
    m = Measure.parseString(input, beatsPerBar);
    logger.i('m: $m');
    expect(m.toString(), input);

    input = "GXCG";
    m = Measure.parseString(input, beatsPerBar);
    logger.i('m: $m');
    expect(m.toString(), input);

    input = "GXCGX"; //  too many chords!
    m = Measure.parseString(input, beatsPerBar);
    logger.i('m: $m');
    expect(m.toString(), input);
  });
}
