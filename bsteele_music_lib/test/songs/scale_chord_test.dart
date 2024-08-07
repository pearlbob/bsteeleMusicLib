import 'dart:convert';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord_component.dart';
import 'package:bsteele_music_lib/songs/chord_descriptor.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/scale_chord.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';
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
        '<html lang="en">\n'
        '  <head>\n'
        '    <meta charset="utf-8">\n'
        '    <title>title</title>\n'
        '    <link rel="stylesheet" href="style.css">\n'
        '    <script src="script.js"></script>\n'
        '  </head>\n'
        '  <body>\n'
        '    <table border="1" >\n');

    for (final sn in ScaleNote.values) {
      if (sn == ScaleNote.X) {
        continue;
      }
      String s = sn.toString();
      ScaleChord? sc;

      sc = ScaleChord.parseString(s);

      expect(sn, sc!.scaleNote);

      s = '$snº';
      sc = ScaleChord.parseString(s);
      expect(sn, sc!.scaleNote);
      expect(ChordDescriptor.diminished, sc.chordDescriptor);

      s = '$snº7';
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

        sb.write(
            '<tr><td>$builtScaleChord</td><td>${chordComponentsToString(builtScaleChord.getChordComponents())}</td><td>${key.getKeyScaleNote()}</td><td>${chordComponentScaleNotesToString(key, builtScaleChord)}</td></tr>\n');
      }
    }
    sb.write('  </table>\n' '  </body>\n' '</html>');
    logger.i(sb.toString());
  });

  test('testScaleChordParse', () {
    ScaleChord? a = ScaleChord.parseString('A13');
    ScaleChord ref = ScaleChord(ScaleNote.A, ChordDescriptor.dominant13);
    expect(a, ref);
    expect(ScaleChord.parseString('A13'), ScaleChord(ScaleNote.A, ChordDescriptor.dominant13));
    expect(ScaleChord(ScaleNote.F, ChordDescriptor.major), ScaleChord.parseString('F'));
    expect(ScaleChord(ScaleNote.F, ChordDescriptor.major), ScaleChord.parseString('FGm'));
    expect(ScaleChord(ScaleNote.F, ChordDescriptor.minor), ScaleChord.parseString('Fm'));
    expect(ScaleChord(ScaleNote.Fs, ChordDescriptor.minor), ScaleChord.parseString('F#m'));
    expect(ScaleChord(ScaleNote.Fs, ChordDescriptor.minor), ScaleChord.parseString('F#mGm'));
    expect(ScaleChord(ScaleNote.D, ChordDescriptor.diminished), ScaleChord.parseString('Ddim/G'));
    expect(ScaleChord(ScaleNote.A, ChordDescriptor.diminished), ScaleChord.parseString('Adim/G'));
    expect(ScaleChord(ScaleNote.X, ChordDescriptor.major), ScaleChord.parseString('X/G'));
  });

  test('test ScaleChord scale notes', () {
    Key key = Key.C;

    expect(ScaleChord(ScaleNote.C, ChordDescriptor.major).chordNotes(key).toString(), '[C, E, G]');
    expect(ScaleChord(ScaleNote.C, ChordDescriptor.minor).chordNotes(key).toString(), '[C, E♭, G]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.major).chordNotes(key).toString(), '[G, B, D]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.dominant7).chordNotes(key).toString(), '[G, B, D, F]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.dominant9).chordNotes(key).toString(), '[G, B, D, F, B]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.minor7).chordNotes(key).toString(), '[G, B♭, D, F]');

    key = Key.E; //  4 #
    expect(ScaleChord(ScaleNote.C, ChordDescriptor.major).chordNotes(key).toString(), '[C, E, G]');
    expect(ScaleChord(ScaleNote.C, ChordDescriptor.minor).chordNotes(key).toString(), '[C, D♯, G]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.major).chordNotes(key).toString(), '[G, B, D]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.dominant7).chordNotes(key).toString(), '[G, B, D, F]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.dominant9).chordNotes(key).toString(), '[G, B, D, F, B]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.minor7).chordNotes(key).toString(), '[G, A♯, D, F]');

    key = Key.Ab; //  4 b
    expect(ScaleChord(ScaleNote.C, ChordDescriptor.major).chordNotes(key).toString(), '[C, E, G]');
    expect(ScaleChord(ScaleNote.C, ChordDescriptor.minor).chordNotes(key).toString(), '[C, E♭, G]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.major).chordNotes(key).toString(), '[G, B, D]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.dominant7).chordNotes(key).toString(), '[G, B, D, F]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.dominant9).chordNotes(key).toString(), '[G, B, D, F, B]');
    expect(ScaleChord(ScaleNote.G, ChordDescriptor.minor7).chordNotes(key).toString(), '[G, B♭, D, F]');
  });

  test('scale chord serialization', () {
    Logger.level = Level.info;

    for (ScaleNote scaleNote in ScaleNote.values) {
      for (ChordDescriptor chordDescriptor in ChordDescriptor.values) {
        ScaleChord scaleChord = ScaleChord(scaleNote, chordDescriptor);
        final encoded = jsonEncode(scaleChord);
        logger.i('scaleChord($scaleNote,$chordDescriptor): $encoded');

        final copy = ScaleChord.fromJson(jsonDecode(encoded));
        expect(copy, scaleChord);
      }
    }
  });
}
