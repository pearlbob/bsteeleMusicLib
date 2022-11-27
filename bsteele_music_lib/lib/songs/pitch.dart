// ignore_for_file: constant_identifier_names

import 'dart:math';

import 'package:bsteeleMusicLib/songs/scale_note.dart';

import 'music_constants.dart';

///
/// All possible piano pitches and their notational alias's.
///
/// A pitch has a human readable name based on it's piano based location.
/// A pitch has a frequency but no duration.
///
/// Black key pitches will have an alias at the same frequency.  This
/// is done to help ease the mapping from keys to pitches.
enum PitchEnum {
  // First tone on 88 key piano
  A0,
  As0,
  Bb0,
  B0, // 5 string bass low string
  Bs0,
  Cb1,
  C1,
  Cs1,
  Db1,
  D1,
  Ds1,
  Eb1,
  E1, //  41.2hz, 4 string bass low string
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
  E2, //  82.4hz, guitar low string
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

class Pitch implements Comparable<Pitch> {
  Pitch._(this._pitchEnum) {
    //  initialize the final values

    RegExpMatch? mr = pitchRegExp.firstMatch(_pitchEnum.toString());
    if (mr == null) {
      throw 'bad pitch! "${_pitchEnum.toString()}"';
    }
    //   fail early on null!
    _name = mr.group(1)! + mr.group(2)!;
    _scaleNote = ScaleNote.valueOf(mr.group(1)!)!;
    _octaveNumber = int.parse(mr.group(2)!);

    //  cope with the piano numbers stepping forward on C
    //  and the label numbers not stepping with sharps and flats,
    //  making the unusual B sharp and C flat very special
    int n = _scaleNote.halfStep;
    if (_name.startsWith('Bs')) {
      n += _octaveNumber * MusicConstants.halfStepsPerOctave;
    } else if (_name.startsWith('Cb')) {
      n += (_octaveNumber - 1) * MusicConstants.halfStepsPerOctave;
    } else {
      //  offset from A to C
      int fromC = (n - MusicConstants.halfStepsFromAtoC) % MusicConstants.halfStepsPerOctave;
      //  compute halfSteps from A0
      n += ((fromC >= (MusicConstants.halfStepsPerOctave - MusicConstants.halfStepsFromAtoC))
              ? _octaveNumber
              : _octaveNumber - 1) *
          MusicConstants.halfStepsPerOctave;
    }
    _number = n;

    _frequency = 440.0 * MusicConstants.halfStepsToRatio((_number + 1) - 49);
  }

  static const a0MidiNoteNumber = 21;

  static Pitch getFromMidiNoteNumber(int noteNumber, {bool? asSharp}) {
    List<Pitch> list = (asSharp ?? true) ? sharps : flats;
    var index = min(max(0, noteNumber - a0MidiNoteNumber), list.length - 1);
    return list[index];
  }

  static Pitch get(PitchEnum se) {
    return _getPitchMap()[se]!;
  }

  static final Map<PitchEnum, Pitch> _pitchMap = Map<PitchEnum, Pitch>.identity();
  static final List<Pitch> _pitches = [];

  static List<Pitch> get sharps {
    getPitches();
    return _sharps;
  }

  static final List<Pitch> _sharps = [];

  static List<Pitch> get flats {
    getPitches();
    return _flats;
  }

  static final List<Pitch> _flats = [];

  static List<Pitch> getPitches() {
    if (_pitches.isEmpty) {
      _getPitchMap(); //  note that the alignment in pitch map requires the singletons be generated there
    }
    return _pitches;
  }

  static Map<PitchEnum, Pitch> _getPitchMap() {
    if (_pitches.isEmpty) {
      //  instantiate all the pitches
      for (PitchEnum e in PitchEnum.values) {
        Pitch p = Pitch._(e);
        //  note the alignment with the enum
        _pitchMap[e] = p;
        _pitches.add(p);
      }

      //  populate the sharps and flats
      for (Pitch pitch in _pitches) {
        if (pitch.isSharp) {
          _sharps.add(pitch); //    the natural didn't get there first
        } else if (pitch.isFlat) {
          if (_flats.isNotEmpty && _flats[_flats.length - 1].number != pitch.number) {
            _flats.add(pitch); //    the natural didn't get there first
          }
        } else {
          //  natural

          if (_sharps.isNotEmpty && _sharps[_sharps.length - 1].number == pitch.number) {
            //  remove sharp duplicates
            _sharps[_sharps.length - 1] = pitch;
          } else {
            _sharps.add(pitch);
          }

          if (flats.isNotEmpty && flats[flats.length - 1].number == pitch.number) {
            //  remove flat duplicates
            flats[flats.length - 1] = pitch;
          } else {
            _flats.add(pitch);
          }
        }
      }

      //  load all the "as" alternatives
      for (Pitch pitch in _pitches) {
        if (pitch.isSharp) {
          pitch._asSharp = pitch;
          pitch._asFlat = _flats[pitch._number];
        } else if (pitch.isFlat) {
          pitch._asSharp = _sharps[pitch._number];
          pitch._asFlat = pitch;
        } else {
          //  natural
          pitch._asSharp = pitch;
          pitch._asFlat = pitch;
        }
      }
    }
    return _pitchMap;
  }

  static Pitch findPitch(ScaleNote scaleNote, Pitch atOrAbove) {
    Pitch lastPitch = getPitches().first; // anything that's not null
    for (Pitch p in getPitches()) {
      if (p.scaleNote == scaleNote) {
        lastPitch = p;
        if (p.number >= atOrAbove.number) {
          return p;
        }
      }
    }
    return lastPitch; //  only close, better than nothing
  }

  static Pitch findFlatFromFrequency(double frequency) {
    Pitch ret = flats[0];
    double bestError = (ret.frequency - frequency).abs();
    for (Pitch p in flats) {
      double e = (p.frequency - frequency).abs();
      if (p.frequency > frequency) {
        return bestError < e ? ret : p;
      }
      ret = p;
      bestError = e;
    }
    return ret;
  }

  static Pitch findSharpFromFrequency(double frequency) {
    Pitch ret = sharps[0];
    double bestError = (ret.frequency - frequency).abs();
    for (Pitch p in sharps) {
      double e = (p.frequency - frequency).abs();
      if (p.frequency > frequency) {
        return bestError < e ? ret : p;
      }
      ret = p;
      bestError = e;
    }
    return ret;
  }

  Pitch octaveLower() {
    int retNumber = _number - MusicConstants.halfStepsPerOctave;
    if (retNumber < 0) {
      return this;
    }
    return (isSharp ? sharps : flats)[retNumber];
  }

  Pitch? nextHigherPitch() {
    List<Pitch> list = (isSharp ? sharps : flats);
    int n = _number + 1;
    if (n >= list.length) {
      return null;
    }
    return list[n];
  }

  Pitch? nextLowerPitch() {
    List<Pitch> list = (isSharp ? sharps : flats);
    int n = _number - 1;
    if (n < 0) {
      return null;
    }
    return list[n];
  }

  /// Return the scale note represented by this pitch.
  ScaleNote getScaleNote() {
    return _scaleNote;
  }

  /// Return the pitch offset by the given number of half steps.
  Pitch? offsetByHalfSteps(int halfSteps) {
    if (halfSteps == 0) {
      return this;
    }
    List<Pitch> list = _scaleNote.isSharp ? _sharps : _flats;
    int n = _number + halfSteps;
    if (n < 0 || n >= list.length) {
      return null;
    }
    return list[n];
  }

  String toDebug() {
    return '${_scaleNote.toString()}${isNatural ? ' ' : ''}${_octaveNumber.toString()} '
        '${isSharp ? MusicConstants.sharpChar : ' '}'
        '${isNatural ? MusicConstants.naturalChar : ' '}'
        '${isFlat ? MusicConstants.flatChar : ' '}';
  }

  @override
  String toString() {
    return '${_scaleNote.toString()}${_octaveNumber.toString()}';
  }

  bool get isSharp => _scaleNote.isSharp;

  bool get isNatural => _scaleNote.isNatural;

  bool get isFlat => _scaleNote.isFlat;

  @override
  int compareTo(Pitch other) {
    return _pitchEnum.index.compareTo(other._pitchEnum.index);
  }

  final PitchEnum _pitchEnum;

  String get name => _name;
  late String _name;

  ScaleNote get scaleNote => _scaleNote;
  late ScaleNote _scaleNote;

  int get scaleNumber => _scaleNote.scaleNumber;

  Accidental get accidental => _scaleNote.accidental;

  /// A number identifying the pitch's octave.  They range from 0 to 8 based on a piano's range.
  int get octaveNumber => _octaveNumber;
  late int _octaveNumber;

  /// A number representing the pitch's halfStep count offset from A0.
  /// Thus A0's number is 0, C8's number is 87.
  int get number => _number;
  late int _number;

  /// Return the frequency of the pitch in cycles per second (Hertz).
  double get frequency => _frequency;
  late double _frequency;

  /// return matching sharp accidental
  /// Naturals and sharps return themselves
  Pitch asSharp() {
    return _asSharp;
  }

  late Pitch _asSharp;

  /// return matching flat accidental
  /// Naturals and flats return themselves
  Pitch asFlat() {
    return _asFlat;
  }

  late Pitch _asFlat;

  static final RegExp pitchRegExp = RegExp(r'^PitchEnum\.([A-G][sb]?)([0-8])$');
}
