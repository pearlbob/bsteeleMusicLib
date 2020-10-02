import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/bass.dart';
import 'package:bsteeleMusicLib/songs/chord.dart';
import 'package:bsteeleMusicLib/songs/chordAnticipationOrDelay.dart';
import 'package:bsteeleMusicLib/songs/chordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/pitch.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

Pitch _atOrAbove = Pitch.get(PitchEnum.A3);

String _stringChord(Chord chord) {
  StringBuffer sb = StringBuffer();
  sb.write('${chord.toMarkup()}:');
  for (Pitch p in chord.getPitches(_atOrAbove)) {
    sb.write(' ${p.toString()}');
  }
  sb.write(' bass: '
      '${Bass.bassFretToPitch(Bass.mapScaleNoteToBassFret(chord.slashScaleNote ?? chord.scaleChord.scaleNote)).toString()}');
  return sb.toString();
}

void main() {
  Logger.level = Level.warning;

  test('chord playback testing', () {
    int beatsPerBar = 4;

    //  sample a few from the print below
    expect(_stringChord(Chord.parseString('A/A', beatsPerBar)),
        'A/A: A3 D♭4 E4 bass: A1');
    expect(_stringChord(Chord.parseString('A', beatsPerBar)),
        'A: A3 D♭4 E4 bass: A1');
    expect(_stringChord(Chord.parseString('Fb5/Fb', beatsPerBar)),
        'Fb5/Fb: F♭4 B4 bass: E1');
    expect(_stringChord(Chord.parseString('Fb69', beatsPerBar)),
        'Fb69: F♭4 G♭4 A♭4 B4 D♭5 bass: E1');
    expect(_stringChord(Chord.parseString('Em6', beatsPerBar)),
        'Em6: E4 G4 B4 D♭5 bass: E1');
    expect(_stringChord(Chord.parseString('C/C', beatsPerBar)),
        'C/C: C4 E4 G4 bass: C2');

    // invent some
    expect(_stringChord(Chord.parseString('C/G', beatsPerBar)),
        'C/G: C4 E4 G4 bass: G1');
    expect(_stringChord(Chord.parseString('Am7/G', beatsPerBar)),
        'Am7/G: A3 C4 E4 G4 bass: G1');
  });

  test('chord playback printing', () {
    if (Logger.level.index <= Level.info.index) {
      int beatsPerBar = 4;

      for (ScaleNote scaleNote in ScaleNote.values) {
        if (scaleNote.isSilent) {
          continue;
        }
        Pitch pitch = Pitch.findPitch(scaleNote, _atOrAbove);
        assert(pitch != null);
        int beats = beatsPerBar; //  default only

        for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
          ScaleChord scaleChord =
              ScaleChord(pitch.getScaleNote(), chordDescriptor);

          assert(scaleChord != null);

          ChordAnticipationOrDelay anticipationOrDelay =
              ChordAnticipationOrDelay.get(ChordAnticipationOrDelayEnum.none);

          ScaleNote slashScaleNote = pitch.getScaleNote();

          Chord chord = Chord(scaleChord, beats, beatsPerBar, slashScaleNote,
              anticipationOrDelay, (beats == beatsPerBar)); //  fixme

          logger.i(_stringChord(chord));
        }
      }
    }
  });
}
