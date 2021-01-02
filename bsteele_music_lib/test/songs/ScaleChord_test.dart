import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/chordComponent.dart';
import 'package:bsteeleMusicLib/songs/chordDescriptor.dart';
import 'package:bsteeleMusicLib/songs/key.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

String chordComponentsToString(Set<ChordComponent> chordComponents) {
  StringBuffer sb = StringBuffer();
  for (ChordComponent chordComponent in chordComponents) {
    if (chordComponent != chordComponents.first) sb.write(' ');
    sb.write(chordComponent.shortName);
  }
  return sb.toString();
}

String chordComponentScaleNotesToString(Key key, ScaleChord scaleChord) {
  StringBuffer sb = StringBuffer();
  Set<ChordComponent> chordComponents = scaleChord.getChordComponents();
  for (ChordComponent chordComponent in chordComponents) {
    if (chordComponent != chordComponents.first) sb.write(' ');
    sb.write(key.getScaleNoteByHalfStep(key.getHalfStep() + chordComponent.halfSteps));
  }
  return sb.toString();
}

void main() {
  Logger.level = Level.warning;

  test('ScaleChord HTML', () {
    StringBuffer sb = StringBuffer();
    sb.write('<!DOCTYPE html>\n'
        '<html lang=\"en\">\n'
        '  <head>\n'
        '    <meta charset=\"utf-8\">\n'
        '    <title>title</title>\n'
        '    <link rel=\"stylesheet\" href=\"style.css\">\n'
        '    <script src=\"script.js\"></script>\n'
        '  </head>\n'
        '  <body>\n'
        '    <table border=\"1\" >\n');

    for (ScaleNote sn in ScaleNote.values) {
      if (sn == ScaleNote.get(ScaleNoteEnum.X)) continue;
      String s = sn.toString();
      ScaleChord? sc;

      sc = ScaleChord.parseString(s);

      expect(sn, sc!.scaleNote);

      s = sn.toString() + 'º';
      sc = ScaleChord.parseString(s);
      expect(sn, sc!.scaleNote);
      expect(ChordDescriptor.diminished, sc.chordDescriptor);

      s = sn.toString() + 'º7';
      sc = ScaleChord.parseString(s);
      expect(sn, sc!.scaleNote);
      expect(ChordDescriptor.diminished7, sc.chordDescriptor);

      for (ChordDescriptor cd in ChordDescriptor.values) {
        s = sn.toString() + cd.shortName;
        sc = ScaleChord.parseString(s);
        expect(sn, sc!.scaleNote);
        ChordDescriptor chordDescriptor = sc.chordDescriptor;
        expect(cd.deAlias(), chordDescriptor);

        s = sn.toString() + cd.shortName;
        sc = ScaleChord.parseString(s);

        ScaleChord builtScaleChord = ScaleChord(sn, cd);

        expect(sc, builtScaleChord);
        expect(sn, sc!.scaleNote);
        expect(cd.deAlias(), sc.chordDescriptor);

        List<ScaleChord> scaleChords = [];
        scaleChords.add(builtScaleChord);
        Key key = Key.guessKey(scaleChords);

        sb.write('<tr><td>' +
            builtScaleChord.toString() +
            '</td><td>' +
            chordComponentsToString(builtScaleChord.getChordComponents()) +
            '</td><td>' +
            key.getKeyScaleNote().toString() +
            '</td><td>' +
            chordComponentScaleNotesToString(key, builtScaleChord) +
            '</td></tr>\n');
      }
    }
    sb.write('  </table>\n' '  </body>\n' '</html>');
    logger.i(sb.toString());
  });

  test('testScaleChordParse', () {
    ScaleChord? a = ScaleChord.parseString('A13');
    ScaleChord ref = ScaleChord(ScaleNote.get(ScaleNoteEnum.A), ChordDescriptor.dominant13);
    expect(a, ref);
    expect(ScaleChord.parseString('A13'), ScaleChord(ScaleNote.get(ScaleNoteEnum.A), ChordDescriptor.dominant13));
    expect(ScaleChord(ScaleNote.get(ScaleNoteEnum.F), ChordDescriptor.major), ScaleChord.parseString('F'));
    expect(ScaleChord(ScaleNote.get(ScaleNoteEnum.F), ChordDescriptor.major), ScaleChord.parseString('FGm'));
    expect(ScaleChord(ScaleNote.get(ScaleNoteEnum.F), ChordDescriptor.minor), ScaleChord.parseString('Fm'));
    expect(ScaleChord(ScaleNote.get(ScaleNoteEnum.Fs), ChordDescriptor.minor), ScaleChord.parseString('F#m'));
    expect(ScaleChord(ScaleNote.get(ScaleNoteEnum.Fs), ChordDescriptor.minor), ScaleChord.parseString('F#mGm'));
    expect(ScaleChord(ScaleNote.get(ScaleNoteEnum.D), ChordDescriptor.diminished), ScaleChord.parseString('Ddim/G'));
    expect(ScaleChord(ScaleNote.get(ScaleNoteEnum.A), ChordDescriptor.diminished), ScaleChord.parseString('Adim/G'));
    expect(ScaleChord(ScaleNote.get(ScaleNoteEnum.X), ChordDescriptor.major), ScaleChord.parseString('X/G'));
  });
}
