import 'package:bsteele_music_lib/songs/scale_note.dart';

import 'chord_component.dart';
import 'key.dart';
import 'music_constants.dart';

enum Mode {
  ionian(0, '1 2 3 4 5 6 7'), // The standard major scale (e.g., C-D-E-F-G-A-B-C).
  dorian(2, '1 2 b3 4 5 6 b7'), // A minor mode with a raised 6th (e.g., D-E-F-G-A-B-C-D).
  phrygian(4, '1 b2 b3 4 5 b6 b7'), // A minor mode with a lowered 2nd (e.g., E-F-G-A-B-C-D-E).
  lydian(5, '1 2 3 #4 5 6 7'), // A major mode with a raised 4th (e.g., F-G-A-B-C-D-E-F).
  mixolydian(7, '1 2 3 4 5 6 b7'), // A major mode with a lowered 7th (e.g., G-A-B-C-D-E-F-G).
  aeolian(9, '1 2 b3 4 5 b6 b7'), // The natural minor scale (e.g., A-B-C-D-E-F-G-A).
  locrian(11, '1 b2 b3 4 b5 b6 b7'); // A diminished mode, rarely used (e.g., B-C-D-E-F-G-A-B).

  const Mode(this.halfStep, this.formula);

  final int halfStep;
  final String formula;

  List<ChordComponent> get chordComponents => ChordComponent.parse(formula).toList(growable: false);
}

Map<Mode, List<ChordComponent>> _map = Map();

List<ChordComponent> getModeChordComponents(final Mode mode) {
  //  lazy eval
  List<ChordComponent>? ret = _map[mode];
  if (ret != null) {
    return ret;
  }

  ret = mode.chordComponents;
  _map[mode] = ret;
  return ret;
}

ScaleNote getModeScaleNote(final Key key, final Mode mode, final int note) {
  final List<ChordComponent> components = getModeChordComponents(mode);
  final modalKey = Key.getKeyByHalfStep(key.halfStep + mode.halfStep);
  return modalKey
      .getKeyScaleNoteByHalfStep(components[note % MusicConstants.notesPerScale].halfSteps)
      .asSharp(value: key.isSharp);
}

ScaleNote getModeChromaticNote(final Key key, final Mode mode, final int halfStep) {
  final modalKey = Key.getKeyByHalfStep(key.halfStep + mode.halfStep);
  return modalKey.getKeyScaleNoteByHalfStep(halfStep).asSharp(value: key.isSharp);
}
