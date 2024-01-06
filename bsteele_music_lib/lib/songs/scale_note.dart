//

import '../util/util.dart';
import 'key.dart';
import 'music_constants.dart';
// ignore_for_file: constant_identifier_names

import 'nashville_note.dart';

/// Musical accidentals
enum Accidental {
  sharp,
  flat,
  natural,
}

/// Musical scale notes and their properties
enum ScaleNote implements Comparable<ScaleNote> {
  Ab(11, 'Ab', 'A♭', false, true, scaleNumber: 0, isSilent: false),
  A(0, 'A', 'A', false, false, scaleNumber: 0, isSilent: false),
  As(1, 'A#', 'A♯', true, false, scaleNumber: 0, isSilent: false),
  Bb(1, 'Bb', 'B♭', false, true, scaleNumber: 1, isSilent: false),
  B(2, 'B', 'B', false, false, scaleNumber: 1, isSilent: false),
  Bs(3, 'B#', 'B♯', true, false, scaleNumber: 1, isSilent: false), //   for completeness of piano expression
  Cb(2, 'Cb', 'C♭', false, true, scaleNumber: 2, isSilent: false), //  used for Gb (-6) key
  C(3, 'C', 'C', false, false, scaleNumber: 2, isSilent: false),
  Cs(4, 'C#', 'C♯', true, false, scaleNumber: 2, isSilent: false),
  Db(4, 'Db', 'D♭', false, true, scaleNumber: 3, isSilent: false),
  D(5, 'D', 'D', false, false, scaleNumber: 3, isSilent: false),
  Ds(6, 'D#', 'D♯', true, false, scaleNumber: 3, isSilent: false),
  Eb(6, 'Eb', 'E♭', false, true, scaleNumber: 4, isSilent: false),
  E(7, 'E', 'E', false, false, scaleNumber: 4, isSilent: false),
  Es(8, 'E#', 'E♯', true, false, scaleNumber: 4, isSilent: false), //  used for Fs (+6) key
  Fb(7, 'Fb', 'F♭', false, true, scaleNumber: 5, isSilent: false), //   for completeness of piano expression
  F(8, 'F', 'F', false, false, scaleNumber: 5, isSilent: false),
  Fs(9, 'F#', 'F♯', true, false, scaleNumber: 5, isSilent: false),
  Gb(9, 'Gb', 'G♭', false, true, scaleNumber: 6, isSilent: false),
  G(10, 'G', 'G', false, false, scaleNumber: 6, isSilent: false),
  Gs(11, 'G#', 'G♯', true, false, scaleNumber: 6, isSilent: false),

  /// As a convenience, silence is considered a scale note.
  X(0, 'X', 'X', false, false, scaleNumber: -1, isSilent: true); //  No scale note!  Used to avoid testing for null

  /// Return the alias for this note.
  /// If the note is sharp, return its matching flat equivalent.
  /// If the note is flat, return its matching sharp equivalent.
  ScaleNote get alias => (isSharp ? asFlat() : (isFlat ? asSharp() : this));

  NashvilleNote getNashvilleNote(Key key) => NashvilleNote.byHalfStep(halfStep - key.halfStep);

  @override
  String toString() {
    return _scaleNoteString;
  }

  String toMarkup() {
    return _markup;
  }

  /// A utility to map the sharp scale notes to their half step offset.
  /// Should use the scale notes from the key under normal situations.
  ///
  /// @param step the number of half steps from A
  /// @return the sharp scale note
  static ScaleNote getSharpByHalfStep(int step) {
    return _sharps[step % MusicConstants.halfStepsPerOctave];
  }

  /// A utility to map the flat scale notes to their half step offset.
  /// Should use the scale notes from the key under normal situations.
  ///
  /// @param step the number of half steps from A
  /// @return the sharp scale note
  static ScaleNote getFlatByHalfStep(int step) {
    return _flats[step % MusicConstants.halfStepsPerOctave];
  }

  ScaleNote asSharp({bool value = true}) {
    if (this == ScaleNote.X) {
      return ScaleNote.X;
    }
    return value ? _sharps[_halfStep] : _flats[_halfStep];
  }

  ScaleNote asFlat({bool value = true}) {
    if (this == ScaleNote.X) {
      return ScaleNote.X;
    }
    return value ? _flats[_halfStep] : _sharps[_halfStep];
  }

  ScaleNote asEasyRead() {
    if (this == ScaleNote.X) {
      return ScaleNote.X;
    }
    return _easyRead[_halfStep];
  }

  //  all sharps
  static final _sharps = [
    ScaleNote.A,
    ScaleNote.As,
    ScaleNote.B,
    ScaleNote.C,
    ScaleNote.Cs,
    ScaleNote.D,
    ScaleNote.Ds,
    ScaleNote.E,
    ScaleNote.F,
    ScaleNote.Fs,
    ScaleNote.G,
    ScaleNote.Gs
  ];

  //  all flats
  static final _flats = [
    ScaleNote.A,
    ScaleNote.Bb,
    ScaleNote.B,
    ScaleNote.C,
    ScaleNote.Db,
    ScaleNote.D,
    ScaleNote.Eb,
    ScaleNote.E,
    ScaleNote.F,
    ScaleNote.Gb,
    ScaleNote.G,
    ScaleNote.Ab
  ];

  //  easy read
  static final _easyRead = [
    ScaleNote.A,
    ScaleNote.Bb,
    ScaleNote.B,
    ScaleNote.C,
    ScaleNote.Db,
    ScaleNote.D,
    ScaleNote.Eb,
    ScaleNote.E,
    ScaleNote.F,
    ScaleNote.Fs,
    ScaleNote.G,
    ScaleNote.Ab
  ];

  static ScaleNote? parseString(String s) {
    return parse(MarkedString(s));
  }

  /// Return the ScaleNote represented by the given string.
  //  Is case sensitive.
  static ScaleNote? parse(MarkedString markedString) {
    if (markedString.isEmpty) {
      throw ArgumentError('no data to parse');
    }

    int c = markedString.firstUnit();
    if (c < 'A'.codeUnitAt(0) || c > 'G'.codeUnitAt(0)) {
      if (c == 'X'.codeUnitAt(0)) {
        markedString.pop();
        return ScaleNote.X;
      }
      throw ArgumentError('scale note must start with A to G');
    }

    StringBuffer stringBuffer = StringBuffer();
    stringBuffer.write(markedString.pop());

    //  look for modifier
    if (markedString.isNotEmpty) {
      switch (markedString.first()) {
        case 'b':
        case MusicConstants.flatChar:
          stringBuffer.write('b');
          markedString.pop();
          break;

        case '#':
        case MusicConstants.sharpChar:
          stringBuffer.write('s');
          markedString.pop();
          break;
      }
    }

    var parsedName = stringBuffer.toString();
    return ScaleNote.values.firstWhere((v) => v.name == parsedName);
  }

  /// Transpose this key to the given key with the given steps offset.
  ScaleNote transpose(Key key, int steps) {
    if (this == ScaleNote.X) {
      return ScaleNote.X;
    }
    return key.getScaleNoteEnum3ByHalfStep(halfStep + steps);
  }

  NashvilleNote nashvilleNote(Key key) {
    return NashvilleNote.byHalfStep(halfStep - key.halfStep);
  }

  /// Return the scale note class instance of the given string.
  static ScaleNote? valueOf(String name) {
    try {
      return ScaleNote.values.firstWhere((e) => e.name == name);
    } catch (e) {
      return null;
    }
  }

  @override
  int compareTo(ScaleNote other) {
    return index - other.index;
  }

  const ScaleNote(this._halfStep, this._markup, this._scaleNoteString, this.isSharp, this.isFlat,
      {this.scaleNumber = -1, this.isSilent = false})
      : isNatural = !isSharp && !isFlat && !isSilent,
        accidental = (isSharp ? Accidental.sharp : (isFlat ? Accidental.flat : Accidental.natural));

  int get halfStep => _halfStep;
  final int _halfStep;
  final String _markup;

  String get scaleNoteString => _scaleNoteString;
  final String _scaleNoteString;
  final bool isSilent;
  final bool isSharp;
  final bool isFlat;
  final bool isNatural;
  final Accidental accidental;
  final int scaleNumber;
}

/// ScaleNoteIntervals
abstract class _ScaleNoteInterval {
  const _ScaleNoteInterval(this.name, this.numerator, this.denominator);

  double get ratio => numerator.toDouble() / denominator;

  final String name;
  final int numerator;
  final int denominator;
}

class FiveLimitScaleNoteInterval extends _ScaleNoteInterval {
  const FiveLimitScaleNoteInterval._(super.name, super.numerator, super.denominator);

  static const intervals = [
    FiveLimitScaleNoteInterval._('P1', 1, 1), // C
    FiveLimitScaleNoteInterval._('m2', 16, 15), //  Db
    FiveLimitScaleNoteInterval._('M2', 10, 9), // D
    FiveLimitScaleNoteInterval._('m3', 6, 5), //  Eb
    FiveLimitScaleNoteInterval._('M3', 5, 4), // E
    FiveLimitScaleNoteInterval._('P4', 4, 3), //  F
    FiveLimitScaleNoteInterval._('d5', 64, 45), //  Gb
    FiveLimitScaleNoteInterval._('P5', 3, 2), //  G
    FiveLimitScaleNoteInterval._('m6', 8, 5), //  Ab
    FiveLimitScaleNoteInterval._('M6', 5, 3), //  A
    FiveLimitScaleNoteInterval._('m7', 9, 5), //  Bb
    FiveLimitScaleNoteInterval._('M7', 15, 8), //  B
  ];
}

class DPythagoreanScaleNoteInterval extends _ScaleNoteInterval {
  const DPythagoreanScaleNoteInterval._(super.name, super.numerator, super.denominator);

  static const intervals = [
    DPythagoreanScaleNoteInterval._('P1', 1, 1),
    DPythagoreanScaleNoteInterval._('m2', 256, 243),
    DPythagoreanScaleNoteInterval._('M2', 9, 8),
    DPythagoreanScaleNoteInterval._('m3', 32, 27),
    DPythagoreanScaleNoteInterval._('M3', 81, 64),
    DPythagoreanScaleNoteInterval._('P4', 4, 3),
    DPythagoreanScaleNoteInterval._('d5', 1024, 729),
    DPythagoreanScaleNoteInterval._('P5', 3, 2),
    DPythagoreanScaleNoteInterval._('m6', 128, 81),
    DPythagoreanScaleNoteInterval._('M6', 27, 16),
    DPythagoreanScaleNoteInterval._('m7', 16, 9),
    DPythagoreanScaleNoteInterval._('M7', 243, 128),
  ];
}

class EqualTemperamentScaleNoteInterval extends _ScaleNoteInterval {
  const EqualTemperamentScaleNoteInterval._(name, this._ratio) : super(name, 1, 1);

  @override
  double get ratio => _ratio;

  static final intervals = [
    EqualTemperamentScaleNoteInterval._('P1', MusicConstants.halfStepsToRatio(0)),
    EqualTemperamentScaleNoteInterval._('m2', MusicConstants.halfStepsToRatio(1)),
    EqualTemperamentScaleNoteInterval._('M2', MusicConstants.halfStepsToRatio(2)),
    EqualTemperamentScaleNoteInterval._('m3', MusicConstants.halfStepsToRatio(3)),
    EqualTemperamentScaleNoteInterval._('M3', MusicConstants.halfStepsToRatio(4)),
    EqualTemperamentScaleNoteInterval._('P4', MusicConstants.halfStepsToRatio(5)),
    EqualTemperamentScaleNoteInterval._('d5', MusicConstants.halfStepsToRatio(6)),
    EqualTemperamentScaleNoteInterval._('P5', MusicConstants.halfStepsToRatio(7)),
    EqualTemperamentScaleNoteInterval._('m6', MusicConstants.halfStepsToRatio(8)),
    EqualTemperamentScaleNoteInterval._('M6', MusicConstants.halfStepsToRatio(9)),
    EqualTemperamentScaleNoteInterval._('m7', MusicConstants.halfStepsToRatio(10)),
    EqualTemperamentScaleNoteInterval._('M7', MusicConstants.halfStepsToRatio(11)),
  ];

  final double _ratio;
}
