// ignore_for_file: non_constant_identifier_names

import 'package:bsteeleMusicLib/songs/scale_note.dart';

import 'key.dart';

const whole = 2;
const half = 1;
const T = 2;
const S = 1;

class Scale {
  static final major = Scale._([T, T, S, T, T, T, S]);
  static final dorian = Scale._([T, S, T, T, T, S, T]);
  static final phrygian = Scale._([S, T, T, T, S, T, T]);
  static final lydian = Scale._([T, T, T, S, T, T, S]);
  static final mixolydian = Scale._([T, T, S, T, T, S, T]);

  static final minor = Scale._([T, S, T, T, S, T, T]);
  static final locrian = Scale._([S, T, T, S, T, T, T]);

  static Scale get ionian => major;

  static Scale get aeolian => minor;

  static final majorPentatonic = Scale._([T, T, S + T, T, T + S]);
  static final minorPentatonic = Scale._([T + S, T, T, S + T, T]);

  static Scale get I => major;

  static Scale get II => dorian;

  static Scale get III => phrygian;

  static Scale get IV => lydian;

  static Scale get V => mixolydian;

  Scale._(this._intervals) : _halfSteps = [0] {
    var halfStep = 0;
    for (var i in _intervals) {
      halfStep += i;
      _halfSteps.add(halfStep);
    }
  }

  List<ScaleNote> inKey(Key key) {
    var ret = <ScaleNote>[];
    for (var halfStep in _halfSteps) {
      ret.add(key.getKeyScaleNoteByHalfStep(halfStep));
    }
    return ret;
  }

  List<int> get intervals => _intervals;
  final List<int> _intervals;

  //  includes the octave
  List<int> get halfSteps => _halfSteps;
  final List<int> _halfSteps;
}
