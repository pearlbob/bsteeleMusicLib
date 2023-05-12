import 'music_constants.dart';
import 'scale_chord.dart';
import 'scale_note.dart';

import 'pitch.dart';

class Bass {
  static int mapPitchToBassFret(Pitch pitch) {
    //  deal with the piano numbers starting on A instead of E
    return mapScaleNoteToBassFret(pitch.scaleNote);
  }

  static int mapScaleChordToBassFret(ScaleChord scaleChord) {
    //  deal with the piano numbers starting on A instead of E
    return mapScaleNoteToBassFret(scaleChord.scaleNote);
  }

  static int mapScaleNoteToBassFret(ScaleNote scaleNote) {
    //  deal with the piano numbers starting on A instead of E
    return (scaleNote.halfStep + 5) % MusicConstants.halfStepsPerOctave;
  }

  static Pitch bassFretToPitch(int fret) {
    return _e1.offsetByHalfSteps(fret)!;
  }

  static final Pitch _e1 = Pitch.get(PitchEnum.E1);
}
