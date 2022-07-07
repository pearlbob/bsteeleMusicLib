import 'package:bsteeleMusicLib/songs/musicConstants.dart';
import 'package:bsteeleMusicLib/songs/pitch.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';

class Bass{
    static int mapPitchToBassFret( Pitch pitch ){
        //  deal with the piano numbers starting on A instead of E
        return mapScaleNoteToBassFret( pitch.scaleNote);
    }

    static int mapScaleChordToBassFret( ScaleChord scaleChord ){
        //  deal with the piano numbers starting on A instead of E
        return mapScaleNoteToBassFret( scaleChord.scaleNote);
    }

    static int mapScaleNoteToBassFret( ScaleNote scaleNote ){
        //  deal with the piano numbers starting on A instead of E
        return (scaleNote.halfStep + 5) % MusicConstants.halfStepsPerOctave;
  }

    static Pitch bassFretToPitch( int fret ){
        return _E1.offsetByHalfSteps(fret)!;
    }

    static final Pitch _E1 = Pitch.get(PitchEnum.E1);
}