import 'package:bsteeleMusicLib/app_logger.dart';
import 'package:bsteeleMusicLib/songs/chord.dart';
import 'package:bsteeleMusicLib/songs/chord_anticipation_or_delay.dart';
import 'package:bsteeleMusicLib/songs/chord_descriptor.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/scale_chord.dart';
import 'package:bsteeleMusicLib/songs/scale_note.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('Dart list equals', () {
    for (final e1 in ScaleNote.values) {
      final n1 = e1;
      for (final e2 in ScaleNote.values) {
        var n2 = e2;
        if (e1 == e2) {
          expect(n1, n2);
          expect(n1 == n2, isTrue);
        } else {
          expect(n1 != n2, isTrue);
        }
      }
    }

    for (final e1 in ScaleNote.values) {
      var sn1 = e1;
      ScaleChord sc1 = ScaleChord(sn1, ChordDescriptor.major);
      for (final e2 in ScaleNote.values) {
        var sn2 = e2;
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
    ScaleNote? slashScaleNote;
    ChordAnticipationOrDelay anticipationOrDelay = ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.none);
    bool implicitBeats = false;

    for (final e1 in ScaleNote.values) {
      var sn1 = e1;
      ScaleChord sc1 = ScaleChord(sn1, ChordDescriptor.major);
      Chord chord1 = Chord(sc1, beats, beatsPerBar, slashScaleNote, anticipationOrDelay, implicitBeats);
      for (final e2 in ScaleNote.values) {
        var sn2 = e2;
        ScaleChord sc2 = ScaleChord(sn2, ChordDescriptor.major);
        Chord chord2 = Chord(sc2, beats, beatsPerBar, slashScaleNote, anticipationOrDelay, implicitBeats);
        if (e1 == e2) {
          expect(chord1, chord2);
          expect(chord1 == chord2, isTrue);
        } else {
          logger.d('chord1: $chord1');
          logger.d('chord2: $chord2');
          expect(chord1 != chord2, isTrue);
        }
      }
    }

    int beatCount = beatsPerBar;
    for (final e1 in ScaleNote.values) {
      var sn1 = e1;
      ScaleChord sc1 = ScaleChord(sn1, ChordDescriptor.major);
      Chord chord1 = Chord(sc1, beats, beatsPerBar, slashScaleNote, anticipationOrDelay, implicitBeats);
      Measure m1 = Measure(beatCount, List<Chord>.filled(1, chord1));
      for (final e2 in ScaleNote.values) {
        var sn2 = e2;
        ScaleChord sc2 = ScaleChord(sn2, ChordDescriptor.major);
        Chord chord2 = Chord(sc2, beats, beatsPerBar, slashScaleNote, anticipationOrDelay, implicitBeats);
        Measure m2 = Measure(beatCount, List<Chord>.filled(1, chord2));
        if (e1 == e2) {
          expect(m1, m2);
          expect(m1 == m2, isTrue);
        } else {
          logger.d('m1: $m1');
          logger.d('m2: $m2');
          expect(m1 != m2, isTrue);
        }
      }
    }

    for (final e1 in ScaleNote.values) {
      var sn1 = e1;
      ScaleChord sc1 = ScaleChord(sn1, ChordDescriptor.major);
      Chord chord1 = Chord(sc1, beats, beatsPerBar, slashScaleNote, anticipationOrDelay, implicitBeats);
      Measure m1 = Measure(beatCount, List<Chord>.filled(1, chord1));
      Phrase ph1 = Phrase(List<Measure>.filled(1, m1), 0);
      for (final e2 in ScaleNote.values) {
        var sn2 = e2;
        ScaleChord sc2 = ScaleChord(sn2, ChordDescriptor.major);
        Chord chord2 = Chord(sc2, beats, beatsPerBar, slashScaleNote, anticipationOrDelay, implicitBeats);
        Measure m2 = Measure(beatCount, List<Chord>.filled(1, chord2));
        Phrase ph2 = Phrase(List<Measure>.filled(1, m2), 0);
        if (e1 == e2) {
          expect(ph1, ph2);
          expect(ph1 == ph2, isTrue);
        } else {
          logger.d('ph1: $ph1');
          logger.d('ph2: $ph2');
          expect(ph1 != ph2, isTrue);
        }
      }
    }
  });
}
