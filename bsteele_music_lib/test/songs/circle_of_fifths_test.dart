import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord_descriptor.dart';
import 'package:bsteele_music_lib/songs/circle_of_fifths.dart';
import 'package:bsteele_music_lib/songs/scale_chord.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('test circle of fifths', () {
    logger.i('circle of fifths');
    expect(circleOfFifths[ScaleNote.C], ScaleChord.parseString('Am')!);
    expect(circleOfFifths[ScaleNote.C], ScaleChord(ScaleNote.A, ChordDescriptor.minor));
    // ScaleNote.C: ScaleChord.parseString('Am')!,
    // ScaleNote.G: ScaleChord.parseString('Em')!,
    // ScaleNote.D: ScaleChord.parseString('Bm')!,
    // ScaleNote.A: ScaleChord.parseString('F#m')!,
    // ScaleNote.E: ScaleChord.parseString('C#m')!,
    // ScaleNote.B: ScaleChord.parseString('G#m')!,
    // ScaleNote.Cb: ScaleChord.parseString('G#m')!,
    // ScaleNote.Gb: ScaleChord.parseString('Ebm')!,
    // ScaleNote.Fs: ScaleChord.parseString('Ebm')!,
    // ScaleNote.Db: ScaleChord.parseString('Bbm')!,
    expect(circleOfFifths[ScaleNote.Db], ScaleChord(ScaleNote.Bb, ChordDescriptor.minor));
    // ScaleNote.Cs: ScaleChord.parseString('Bbm')!,
    // ScaleNote.Ab: ScaleChord.parseString('Fm')!,
    // ScaleNote.Eb: ScaleChord.parseString('Cm')!,
    // ScaleNote.Bb: ScaleChord.parseString('Gm')!,
    // ScaleNote.F: ScaleChord.parseString('Dm')!,
    expect(circleOfFifths[ScaleNote.F], ScaleChord(ScaleNote.D, ChordDescriptor.minor));
  });

  test('test circle print', () {
    logger.i('circle of fifths');
    for (ScaleNote key in circleOfFifths.keys) {
      var fifth = circleOfFifths[key]!;
      logger.i('major: ${key.toString().padLeft(2)} =>  $fifth');
    }
    logger.i('');
    logger.i('circle of fifths backwards');
    for (ScaleChord value in circleOfFifths.values) {
      var major = circleOfFifths.keys.where((key) => circleOfFifths[key] == value);
      logger.i('${value.toString().padLeft(3)}  => major: ${major.toString().padLeft(3)}');
      expect(circleOfFifths[major.first], value);
    }
  });
}
