import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chord.dart';
import 'package:bsteeleMusicLib/songs/chordAnticipationOrDelay.dart';
import 'package:bsteeleMusicLib/songs/chordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('Dart list equals', () {
    for (ScaleNoteEnum e1 in ScaleNoteEnum.values) {
      ScaleNote n1 = ScaleNote.get(e1);
      for (ScaleNoteEnum e2 in ScaleNoteEnum.values) {
        ScaleNote n2 = ScaleNote.get(e2);
        if (e1 == e2) {
          expect(n1, n2);
          expect(n1 == n2, isTrue);
        } else {
          expect(n1 != n2, isTrue);
        }
      }
    }

    for (ScaleNoteEnum e1 in ScaleNoteEnum.values) {
      ScaleNote sn1 = ScaleNote.get(e1);
      ScaleChord sc1 = ScaleChord(sn1, ChordDescriptor.major);
      for (ScaleNoteEnum e2 in ScaleNoteEnum.values) {
        ScaleNote sn2 = ScaleNote.get(e2);
        ScaleChord sc2 = ScaleChord(sn2, ChordDescriptor.major);
        if (e1 == e2) {
          expect(sc1, sc2);
          expect(sc1 == sc2, isTrue);
        } else {
          expect(sc1 != sc2, isTrue);
        }
      }
    }

    int beats = 4;
    int beatsPerBar = 4;
    ScaleNote slashScaleNote;
    ChordAnticipationOrDelay anticipationOrDelay =
        ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.none);
    bool implicitBeats = false;

    for (ScaleNoteEnum e1 in ScaleNoteEnum.values) {
      ScaleNote sn1 = ScaleNote.get(e1);
      ScaleChord sc1 = ScaleChord(sn1, ChordDescriptor.major);
      Chord chord1 = Chord(sc1, beats, beatsPerBar, slashScaleNote,
          anticipationOrDelay, implicitBeats);
      for (ScaleNoteEnum e2 in ScaleNoteEnum.values) {
        ScaleNote sn2 = ScaleNote.get(e2);
        ScaleChord sc2 = ScaleChord(sn2, ChordDescriptor.major);
        Chord chord2 = Chord(sc2, beats, beatsPerBar, slashScaleNote,
            anticipationOrDelay, implicitBeats);
        if (e1 == e2) {
          expect(chord1, chord2);
          expect(chord1 == chord2, isTrue);
        } else {
          logger.d('chord1: ' + chord1.toString());
          logger.d('chord2: ' + chord2.toString());
          expect(chord1 != chord2, isTrue);
        }
      }
    }

    int beatCount = beatsPerBar;
    for (ScaleNoteEnum e1 in ScaleNoteEnum.values) {
      ScaleNote sn1 = ScaleNote.get(e1);
      ScaleChord sc1 = ScaleChord(sn1, ChordDescriptor.major);
      Chord chord1 = Chord(sc1, beats, beatsPerBar, slashScaleNote,
          anticipationOrDelay, implicitBeats);
      Measure m1 = Measure(beatCount, List<Chord>.filled(1,chord1));
      for (ScaleNoteEnum e2 in ScaleNoteEnum.values) {
        ScaleNote sn2 = ScaleNote.get(e2);
        ScaleChord sc2 = ScaleChord(sn2, ChordDescriptor.major);
        Chord chord2 = Chord(sc2, beats, beatsPerBar, slashScaleNote,
            anticipationOrDelay, implicitBeats);
        Measure m2 = Measure(beatCount, List<Chord>.filled(1,chord2));
        if (e1 == e2) {
          expect(m1, m2);
          expect(m1 == m2, isTrue);
        } else {
          logger.d('m1: ' + m1.toString());
          logger.d('m2: ' + m2.toString());
          expect(m1 != m2, isTrue);
        }
      }
    }

    for (ScaleNoteEnum e1 in ScaleNoteEnum.values) {
      ScaleNote sn1 = ScaleNote.get(e1);
      ScaleChord sc1 = ScaleChord(sn1, ChordDescriptor.major);
      Chord chord1 = Chord(sc1, beats, beatsPerBar, slashScaleNote,
          anticipationOrDelay, implicitBeats);
      Measure m1 = Measure(beatCount, List<Chord>.filled(1,chord1));
      Phrase ph1 = Phrase(List<Measure>.filled(1, m1),  0);
      for (ScaleNoteEnum e2 in ScaleNoteEnum.values) {
        ScaleNote sn2 = ScaleNote.get(e2);
        ScaleChord sc2 = ScaleChord(sn2, ChordDescriptor.major);
        Chord chord2 = Chord(sc2, beats, beatsPerBar, slashScaleNote,
            anticipationOrDelay, implicitBeats);
        Measure m2 = Measure(beatCount, List<Chord>.filled(1,chord2));
        Phrase ph2 = Phrase(List<Measure>.filled(1, m2),  0);
        if (e1 == e2) {
          expect(ph1, ph2);
          expect(ph1 == ph2, isTrue);
        } else {
          logger.d('ph1: ' + ph1.toString());
          logger.d('ph2: ' + ph2.toString());
          expect(ph1 != ph2, isTrue);
        }
      }
    }
  });
}
