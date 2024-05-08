// ignore_for_file: non_constant_identifier_names

import 'package:meta/meta.dart';

import 'key.dart';
import 'scale_note.dart';

const whole = 2;
const half = 1;
const T = 2;
const S = 1;

@immutable
class Scale {
  static final major = Scale._(const [T, T, S, T, T, T, S]);
  static final dorian = Scale._(const [T, S, T, T, T, S, T]);
  static final phrygian = Scale._(const [S, T, T, T, S, T, T]);
  static final lydian = Scale._(const [T, T, T, S, T, T, S]);
  static final mixolydian = Scale._(const [T, T, S, T, T, S, T]);

  static final minor = Scale._(const [T, S, T, T, S, T, T]);
  static final locrian = Scale._(const [S, T, T, S, T, T, T]);

  static Scale get ionian => major;

  static Scale get aeolian => minor;

  static final majorPentatonic = Scale._(const [T, T, S + T, T, T + S]);
  static final minorPentatonic = Scale._(const [T + S, T, T, S + T, T]);

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
