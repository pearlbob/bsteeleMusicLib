import 'package:bsteele_music_lib/songs/scale_chord.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';

final circleOfFifths = <ScaleNote, ScaleChord>{
  ScaleNote.C: ScaleChord.parseString('Am')!,
  ScaleNote.G: ScaleChord.parseString('Em')!,
  ScaleNote.D: ScaleChord.parseString('Bm')!,
  ScaleNote.A: ScaleChord.parseString('F#m')!,
  ScaleNote.E: ScaleChord.parseString('C#m')!,
  ScaleNote.B: ScaleChord.parseString('G#m')!,
  ScaleNote.Cb: ScaleChord.parseString('G#m')!,
  ScaleNote.Gb: ScaleChord.parseString('Ebm')!,
  ScaleNote.Fs: ScaleChord.parseString('Ebm')!,
  ScaleNote.Db: ScaleChord.parseString('Bbm')!,
  ScaleNote.Cs: ScaleChord.parseString('Bbm')!,
  ScaleNote.Ab: ScaleChord.parseString('Fm')!,
  ScaleNote.Eb: ScaleChord.parseString('Cm')!,
  ScaleNote.Bb: ScaleChord.parseString('Gm')!,
  ScaleNote.F: ScaleChord.parseString('Dm')!,
};
