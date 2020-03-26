import 'dart:math';

import 'package:bsteeleMusicLib/songs/scaleNote.dart';

import 'musicConstants.dart';

///
/// All possible piano pitches and their notational alias's.
/// <p>
/// A pitch has a human readable name based on it's piano based location.
/// A pitch has a frequency but no duration.
/// </p>
/// <p>Black key pitches will have an alias at the same frequency.  This
/// is done to help ease the mapping from keys to pitches.</p>
enum PitchEnum {
  // First tone
  A0,
  As0,
  Bb0,
  B0,
  Bs0,
  Cb1,
  C1,
  Cs1,
  Db1,
  D1,
  Ds1,
  Eb1,
  E1,
  Es1,
  Fb1,
  F1,
  Fs1,
  Gb1,
  G1,
  Gs1,
  Ab1,
  A1,
  As1,
  Bb1,
  B1,
  Bs1,
  Cb2,
  // Low C
  C2,
  Cs2,
  Db2,
  D2,
  Ds2,
  Eb2,
  E2,
  Es2,
  Fb2,
  F2,
  Fs2,
  Gb2,
  G2,
  Gs2,
  Ab2,
  A2,
  As2,
  Bb2,
  B2,
  Bs2,
  Cb3,
  C3,
  Cs3,
  Db3,
  D3,
  Ds3,
  Eb3,
  E3,
  Es3,
  Fb3,
  F3,
  Fs3,
  Gb3,
  G3,
  Gs3,
  Ab3,
  A3,
  As3,
  Bb3,
  B3,
  Bs3,
  Cb4,
  // middle C
  C4,
  Cs4,
  Db4,
  D4,
  Ds4,
  Eb4,
  E4,
  Es4,
  Fb4,
  F4,
  Fs4,
  Gb4,
  G4,
  Gs4,
  Ab4,
  // Concert pitch
  A4,
  As4,
  Bb4,
  B4,
  Bs4,
  Cb5,
  C5,
  Cs5,
  Db5,
  D5,
  Ds5,
  Eb5,
  E5,
  Es5,
  Fb5,
  F5,
  Fs5,
  Gb5,
  G5,
  Gs5,
  Ab5,
  A5,
  As5,
  Bb5,
  B5,
  Bs5,

  // High C
  Cb6,
  C6,
  Cs6,
  Db6,
  D6,
  Ds6,
  Eb6,
  E6,
  Es6,
  Fb6,
  F6,
  Fs6,
  Gb6,
  G6,
  Gs6,
  Ab6,
  A6,
  As6,
  Bb6,
  B6,
  Bs6,
  Cb7,
  C7,
  Cs7,
  Db7,
  D7,
  Ds7,
  Eb7,
  E7,
  Es7,
  Fb7,
  F7,
  Fs7,
  Gb7,
  G7,
  Gs7,
  Ab7,
  A7,
  As7,
  Bb7,
  B7,
  Bs7,
  Cb8,
  // last tone
  C8,
}

class Pitch {
  Pitch._(PitchEnum pe) {
    //  initialize the final values

    RegExpMatch mr = pitchRegExp.firstMatch(pe.toString());
    //   fail early on null!
    _name = mr.group(1) + mr.group(2);
    _scaleNote = ScaleNote.valueOf(mr.group(1));
    _labelNumber = int.parse(mr.group(2));

    //  cope with the piano numbers stepping forward on C
    //  and the label numbers not stepping with sharps and flats,
    //  making the unusual B sharp and C flat very special
    int n = _scaleNote.halfStep;
    if (_name.startsWith('Bs')) {
      n += _labelNumber * MusicConstants.halfStepsPerOctave;
    } else if (_name.startsWith('Cb')) {
      n += (_labelNumber - 1) * MusicConstants.halfStepsPerOctave;
    } else {
      //  offset from A to C
      final int offsetFromAtoC = 3;
      int fromC = (n - offsetFromAtoC) % MusicConstants.halfStepsPerOctave;
      //  compute halfSteps from A0
      n += ((fromC >= (MusicConstants.halfStepsPerOctave - offsetFromAtoC)) ? _labelNumber : _labelNumber - 1) *
          MusicConstants.halfStepsPerOctave;
    }
    _number = n;

    _frequency = 440 * pow(2, ((_number + 1) - 49) / 12);
  }

  static Pitch get(PitchEnum se) {
    return _getPitchMap()[se];
  }

  static Map<PitchEnum, Pitch> _pitchMap;
  static List<Pitch> _pitches;
  static List<Pitch> sharps = [];

  static List<Pitch> flats = [];

  static List<Pitch> getPitches() {
    if (_pitches == null) {
      _getPitchMap();
    }
    return _pitches;
  }

  static Map<PitchEnum, Pitch> _getPitchMap() {
    if (_pitchMap == null) {
      _pitchMap = Map<PitchEnum, Pitch>.identity();
      _pitches = [];
      for (PitchEnum e in PitchEnum.values) {
        Pitch p = Pitch._(e);
        _pitchMap[e] = p;
        _pitches.add(p);
      }

      for (Pitch pitch in _pitches) {
        if (pitch.isSharp()) {
          sharps.add(pitch);
        } else if (pitch.isFlat()) {
          if (flats.isNotEmpty && flats[flats.length - 1].getNumber() != pitch.getNumber()) {
            flats.add(pitch); //    the natural didn't get there first
          }
        } else {
          //  natural
          //  remove duplicates
          if (sharps.isNotEmpty && sharps[sharps.length - 1].getNumber() == pitch.getNumber()) {
            sharps.remove(sharps.length - 1);
          }
          //                if (!flats.isEmpty() && flats.get(flats.size() - 1).getNumber() == pitch.getNumber())
          //                    flats.remove(flats.size() - 1);
          sharps.add(pitch);
          flats.add(pitch);
        }
      }
    }
    return _pitchMap;
  }

  static Pitch findPitch(ScaleNote scaleNote, Pitch atOrAbove) {
    for (Pitch p in getPitches()) {
      if (p.scaleNote == scaleNote && p.getNumber() >= atOrAbove.getNumber()) return p;
    }
    return null;
  }

  int getLabelNumber() {
    return _labelNumber;
  }

  /// Get an integer the represents this pitch.
  int getNumber() {
    return _number;
  }

  /// Return the frequency of the pitch.
  double getFrequency() {
    return _frequency;
  }

  /// Return the scale note represented by this pitch.
  ScaleNote getScaleNote() {
    return _scaleNote;
  }

  /// Return the pitch offset by the given number of half steps.
  Pitch offsetByHalfSteps(int halfSteps) {
    if (halfSteps == 0) {
      return this;
    }
    List<Pitch> list = _scaleNote.isSharp ? sharps : flats;
    int n = _number + halfSteps;
    if (n < 0 || n >= list.length) {
      return null;
    }
    return list[n];
  }

  @override
  String toString() {
    return '${_scaleNote.toString()}${isNatural() ? ' ' : ''}${_labelNumber.toString()} '
        '${isSharp() ? MusicConstants.sharpChar : ' '}'
        '${isNatural() ? MusicConstants.naturalChar : ' '}'
        '${isFlat() ? MusicConstants.flatChar : ' '}';
  }

  bool isSharp() {
    return _scaleNote.isSharp;
  }

  bool isNatural() {
    return _scaleNote.isNatural;
  }

  bool isFlat() {
    return _scaleNote.isFlat;
  }

  String get name => _name;
  String _name;

  ScaleNote get scaleNote => _scaleNote;
  ScaleNote _scaleNote;
  int _labelNumber;
  int _number;
  double _frequency;

  final RegExp pitchRegExp = RegExp(r'^PitchEnum\.([A-G][sb]?)([0-8])$');
}
