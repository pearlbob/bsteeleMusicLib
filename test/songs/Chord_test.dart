import 'dart:collection';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/Chord.dart';
import 'package:bsteeleMusicLib/songs/ChordAnticipationOrDelay.dart';
import 'package:bsteeleMusicLib/songs/ChordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/Key.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../CustomMatchers.dart';

void main() {
  Logger.level = Level.warning;

  test("testSetScaleChord testing", () {
    SplayTreeSet<ScaleChord> slashScaleChords = SplayTreeSet();
    for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++)
      for (ChordAnticipationOrDelay anticipationOrDelay
          in ChordAnticipationOrDelay.values) {
        logger.d("anticipationOrDelay: " + anticipationOrDelay.toString());
        for (ScaleNote scaleNote in ScaleNote.values) {
          if (scaleNote.getEnum() == ScaleNoteEnum.X) continue;
          for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
            for (int beats = 2; beats <= 4; beats++) {
              ScaleChord scaleChord =  new ScaleChord(scaleNote, chordDescriptor);
              if (chordDescriptor == ChordDescriptor.minor)
                slashScaleChords.add(scaleChord);
              Chord chord = new Chord(scaleChord, beats, beatsPerBar, null,
                  anticipationOrDelay, true);
              logger.d(chord.toString());
              Chord pChord = Chord.parseString(chord.toString(), beatsPerBar);

              if (beats != beatsPerBar) {
                //  the beats will default to beats per bar if unspecified
                expect(pChord.scaleChord, CompareTo(chord.scaleChord));
                expect(pChord.slashScaleNote, chord.slashScaleNote);
              } else
                expect( pChord, CompareTo(chord) );
            }
          }
        }
      }
  });

  test("testChordParse testing", () {
    Chord chord;
    int beatsPerBar = 4;
    chord = new Chord.byScaleChord(
        ScaleChord.fromScaleNoteEnumAndChordDescriptor(
            ScaleNoteEnum.D, ChordDescriptor.diminished));
    chord.slashScaleNote = ScaleNote.get(ScaleNoteEnum.G);

    logger.i("\""+Chord.parseString("Ddim/G", beatsPerBar).toString()+"\"");
    logger.i("compare: "+Chord.parseString("Ddim/G", beatsPerBar).compareTo(chord).toString());
    logger.i("==: "+(Chord.parseString("Ddim/G", beatsPerBar)==chord?"true":"false"));
    Chord pChord =Chord.parseString("Ddim/G", beatsPerBar);
    expect(pChord, CompareTo(chord));

    chord = new Chord.byScaleChord(
        new ScaleChord.fromScaleNoteEnumAndChordDescriptor(
            ScaleNoteEnum.X, ChordDescriptor.major));
    chord.slashScaleNote = ScaleNote.get(ScaleNoteEnum.G);
    expect(Chord.parseString("X/G", beatsPerBar), CompareTo(chord));

    chord = new Chord.byScaleChord(
        new ScaleChord.fromScaleNoteEnumAndChordDescriptor(
            ScaleNoteEnum.A, ChordDescriptor.diminished));
    chord.slashScaleNote = ScaleNote.get(ScaleNoteEnum.G);
    expect(Chord.parseString("Adim/G", beatsPerBar), CompareTo(chord));
    chord = new Chord.byScaleChord(
        new ScaleChord.fromScaleNoteEnumAndChordDescriptor(
            ScaleNoteEnum.G, ChordDescriptor.suspendedSecond));
    chord.slashScaleNote = ScaleNote.get(ScaleNoteEnum.A);
    expect(Chord.parseString("G2/A", beatsPerBar), CompareTo(chord));
    chord = new Chord.byScaleChord(
        new ScaleChord.fromScaleNoteEnumAndChordDescriptor(
            ScaleNoteEnum.G, ChordDescriptor.add9));
    expect(Chord.parseString("Gadd9A", beatsPerBar), CompareTo(chord));

    chord = Chord.parseString("G.1", beatsPerBar);
    expect(chord.toString(), "G.1");
    chord = Chord.parseString("G.2", beatsPerBar);
    expect(chord.toString(), "G.");
    chord = Chord.parseString("G.3", beatsPerBar);
    expect(chord.toString(), "G..");
    chord = Chord.parseString("G.4", beatsPerBar);
    expect(chord.toString(), "G");
  });


  test("testSimpleChordTranspose testing", () {
    int count = 0;
    for (Key key in <Key>[Key.get(KeyEnum.C), Key.get(KeyEnum.G)])
      for (ScaleNote sn in ScaleNote.values)
        for (int halfSteps = 0; halfSteps < 12; halfSteps++) {
          ScaleNote snHalfSteps = sn.transpose(key, halfSteps);

          logger.d(sn.toString() +
              " " +
              halfSteps.toString() +
              " in key " +
              key.toString() +
              " +> " +
              snHalfSteps.toString());
//                                assertEquals(Chord.parse(snHalfSteps + chordDescriptor.getShortName(), beatsPerBar),
//                                        Chord.parse(sn + chordDescriptor.getShortName(), beatsPerBar)
//                                                .transpose(key, halfSteps));
          count++;
        }
    logger.d("transpose count: " + count.toString());
  });


  void testChordTranspose( Key key ){
    int count = 0;
    for (ScaleNote sn in ScaleNote.values)
      for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++)
        for (int halfSteps = -15; halfSteps < 15; halfSteps++)
          for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
            ScaleNote snHalfSteps = sn.transpose(key, halfSteps);

            logger.d(sn.toString() +
                chordDescriptor.shortName +
                " " +
                halfSteps.toString() +
                " in key " +
                key.toString() +
                " " +
                beatsPerBar.toString() +
                " beats");
            expect(
                Chord.parseString(
                    snHalfSteps.toString() + chordDescriptor.shortName,
                    beatsPerBar),
                CompareTo(Chord.parseString(sn.toString() + chordDescriptor.shortName,
                    beatsPerBar)
                    .transpose(key, halfSteps)));
            count++;
          }
    logger.d("transpose count: " + count.toString());

    count = 0;
    for (ScaleNote sn in ScaleNote.values)
      for (ScaleNote slashSn in ScaleNote.values)
        for (int beatsPerBar = 2; beatsPerBar <= 4; beatsPerBar++)
          for (int halfSteps = -15; halfSteps < 15; halfSteps++)
            for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
              ScaleNote snHalfSteps = sn.transpose(key, halfSteps);
              ScaleNote slashSnHalfSteps = slashSn.transpose(key, halfSteps);

              logger.d(sn.toString() +
                  chordDescriptor.shortName +
                  "/" +
                  slashSn.toString() +
                  " " +
                  halfSteps.toString() +
                  " in key " +
                  key.toString() +
                  " " +
                  beatsPerBar.toString() +
                  " beats");
              expect(
                  Chord.parseString(
                      snHalfSteps.toString() +
                          chordDescriptor.shortName +
                          "/" +
                          slashSnHalfSteps.toString(),
                      beatsPerBar),
                  CompareTo(Chord.parseString(
                      sn.toString() +
                          chordDescriptor.shortName +
                          "/" +
                          slashSn.toString(),
                      beatsPerBar)
                      .transpose(key, halfSteps)));
              count++;
            }
    logger.d("transpose slash count: " + count.toString());
  }

  test("testChordTranspose testing", () {
    //  generate the code
    for (KeyEnum key in KeyEnum.values) {
      logger.v('''
  test("testChordTranspose $key", () {
    testChordTranspose(Key.get($key));
  });
      ''');

    }
  });

  //  from the generated code:
  test("testChordTranspose KeyEnum.Gb", () {
    testChordTranspose(Key.get(KeyEnum.Gb));
  });

  test("testChordTranspose KeyEnum.Db", () {
    testChordTranspose(Key.get(KeyEnum.Db));
  });

  test("testChordTranspose KeyEnum.Ab", () {
    testChordTranspose(Key.get(KeyEnum.Ab));
  });

  test("testChordTranspose KeyEnum.Eb", () {
    testChordTranspose(Key.get(KeyEnum.Eb));
  });

  test("testChordTranspose KeyEnum.Bb", () {
    testChordTranspose(Key.get(KeyEnum.Bb));
  });

  test("testChordTranspose KeyEnum.F", () {
    testChordTranspose(Key.get(KeyEnum.F));
  });

  test("testChordTranspose KeyEnum.C", () {
    testChordTranspose(Key.get(KeyEnum.C));
  });

  test("testChordTranspose KeyEnum.G", () {
    testChordTranspose(Key.get(KeyEnum.G));
  });

  test("testChordTranspose KeyEnum.D", () {
    testChordTranspose(Key.get(KeyEnum.D));
  });

  test("testChordTranspose KeyEnum.A", () {
    testChordTranspose(Key.get(KeyEnum.A));
  });

  test("testChordTranspose KeyEnum.E", () {
    testChordTranspose(Key.get(KeyEnum.E));
  });

  test("testChordTranspose KeyEnum.B", () {
    testChordTranspose(Key.get(KeyEnum.B));
  });

  test("testChordTranspose KeyEnum.Fs", () {
    testChordTranspose(Key.get(KeyEnum.Fs));
  });

}
