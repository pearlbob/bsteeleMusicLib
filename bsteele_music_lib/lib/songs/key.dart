// ignore_for_file: non_constant_identifier_names

import 'dart:collection';

import 'package:meta/meta.dart';

import 'music_constants.dart';
import 'pitch.dart';
import 'scale_chord.dart';
import 'scale_note.dart';

/// An enumeration of all major keys.

enum MajorKeyEnum {
  // ignore: constant_identifier_names
  /// G flat
  // ignore: constant_identifier_names
  Gb,

  /// D flat
  // ignore: constant_identifier_names
  Db,

  /// A flat
  // ignore: constant_identifier_names
  Ab,

  /// E flat
  // ignore: constant_identifier_names
  Eb,

  /// B flat
  // ignore: constant_identifier_names
  Bb,

  /// F
  F,

  /// CS
  C,

  /// G
  G,

  /// D
  D,

  /// A
  A,

  /// E
  E,

  /// B
  B,

  /// F sharp (aka. G flat)
  // ignore: constant_identifier_names
  Fs,
}

enum MinorKeyEnum {
  //  in order of their major key enum above
  // ignore: constant_identifier_names
  /// E flat minor
  // ignore: constant_identifier_names
  eb,

  /// B flat minor
  // ignore: constant_identifier_names
  bb,

  /// F minor
  // ignore: constant_identifier_names
  f,

  /// C minor
  // ignore: constant_identifier_names
  c,

  /// G minor
  // ignore: constant_identifier_names
  g,

  /// D minor
  d,

  /// A minor
  a,

  /// E minor
  e,

  /// B minor
  b,

  /// F sharp minor
  fs,

  /// C sharp minor
  cs,

  /// G sharp minor
  gs,

  /// D sharp minor (aka. E flat minor)
  // ignore: constant_identifier_names
  ds,
}

// Each major key has a relative minor, with which it shares a key signature.
// The relative minor is found on the sixth scale degree of a major key,
//     or three semitones down from its corresponding major key.

//  local private universal values
Map<MajorKeyEnum, MajorKey> _keyMap = {};
List<MajorKey> _keysByHalfStep = [];
final List<dynamic> _initialization = [
  //  KeyEnum, keyValue, key halfSteps from A
  [MajorKeyEnum.Gb, -6, 9, MinorKeyEnum.eb],
  [MajorKeyEnum.Db, -5, 4, MinorKeyEnum.bb],
  [MajorKeyEnum.Ab, -4, 11, MinorKeyEnum.f],
  [MajorKeyEnum.Eb, -3, 6, MinorKeyEnum.c],
  [MajorKeyEnum.Bb, -2, 1, MinorKeyEnum.g],
  [MajorKeyEnum.F, -1, 8, MinorKeyEnum.d],
  [MajorKeyEnum.C, 0, 3, MinorKeyEnum.a],
  [MajorKeyEnum.G, 1, 10, MinorKeyEnum.e],
  [MajorKeyEnum.D, 2, 5, MinorKeyEnum.b],
  [MajorKeyEnum.A, 3, 0, MinorKeyEnum.fs],
  [MajorKeyEnum.E, 4, 7, MinorKeyEnum.cs],
  [MajorKeyEnum.B, 5, 2, MinorKeyEnum.gs],
  [MajorKeyEnum.Fs, 6, 9, MinorKeyEnum.ds],
];
Map<String, MajorKeyEnum> keyEnumMap = {};

///
/// Representation of the song key used generate the expression of the proper scales.
/// NOTE: since this is dart, they key here is the musical key and not a flutter widget key.
///
/// Six flats (G♭) and six sharps (F♯) are labeled differently but are otherwise the same key.
/// Seven flats and seven sharps are not included.
@immutable
class MajorKey extends Key implements Comparable<MajorKey> {
  MajorKey._(this.majorKeyEnum, this.keyValue, this.halfStep, this.capoLocation, this.minorKeyEnum)
    : keyScaleNote = ScaleNote.valueOf(keyEnumToString(majorKeyEnum))!,
      _minorKey = MinorKey.get(minorKeyEnum);

  static final Gb = get(.Gb);
  static final Db = get(.Db);
  static final Ab = get(.Ab);
  static final Eb = get(.Eb);
  static final Bb = get(.Bb);
  static final F = get(.F);
  static final C = get(.C);
  static final G = get(.G);
  static final D = get(.D);
  static final A = get(.A);
  static final E = get(.E);
  static final B = get(.B);
  static final Fs = get(.Fs);

  static String keyEnumToString(MajorKeyEnum ke) {
    return ke.toString().split('.').last;
  }

  static List<MajorKey> keysByHalfStep() {
    if (_keysByHalfStep.isEmpty) {
      SplayTreeSet<MajorKey> sortedSet = SplayTreeSet((a1, a2) {
        return a1.halfStep.compareTo(a2.halfStep);
      });
      sortedSet.addAll(_getMajorKeys().values);
      _keysByHalfStep = List.unmodifiable(sortedSet.toList());
    }
    return _keysByHalfStep;
  }

  static MajorKey byHalfStep({int offset = 0}) {
    var off = offset % halfStepsPerOctave;
    if (offset > 0 && off == MusicConstants.halfStepsFromAtoC + halfStepsPerOctave / 2) {
      //  the F# vs Gb split
      return MajorKey.Fs;
    }
    return keysByHalfStep()[off];
  }

  static List<MajorKey> keysByHalfStepFrom(MajorKey key) {
    return List.generate(halfStepsPerOctave + 1, (i) {
      return byHalfStep(offset: key.halfStep + i);
    });
  }

  static Map<MajorKeyEnum, MajorKey> _getMajorKeys() {
    if (_keyMap.isEmpty) {
      _keyMap = Map<MajorKeyEnum, MajorKey>.identity();

      //  calculation constants
      const int keyCHalfStep = 3;
      const int keyGHalfStep = 10;

      for (var init in _initialization) {
        MajorKeyEnum keInit = init[0];
        var halfStep = init[2];

        //  compute capo location
        var capoLocation = halfStep;
        if (halfStep >= keyGHalfStep) {
          capoLocation = halfStep - keyGHalfStep;
        } else if (halfStep >= keyCHalfStep) {
          capoLocation = halfStep - keyCHalfStep;
        } else {
          capoLocation = (halfStep + MusicConstants.halfStepsPerOctave) - keyGHalfStep;
        }

        _keyMap[keInit] = MajorKey._(keInit, init[1], halfStep, capoLocation, init[3]);
      }

      //  majorDiatonics needs majorScale which is initialized after the initialization
      final MajorKey keyC = _keyMap[MajorKeyEnum.C]!;
      final MajorKey keyG = _keyMap[MajorKeyEnum.G]!;
      for (MajorKey key in _keyMap.values) {
        //  compute capo key... now that keys mostly exist
        if (key.halfStep >= keyGHalfStep) {
          key._capoKey = keyG;
        } else if (key.halfStep >= keyCHalfStep) {
          key._capoKey = keyC;
        } else {
          key._capoKey = keyG;
        }

        key._majorDiatonics = List<ScaleChord>.generate(MusicConstants.notesPerScale, (i) {
          return ScaleChord(key.getMajorScaleByNote(i), MusicConstants.getMajorDiatonicChordModifier(i));
        });

        key._minorDiatonics = List<ScaleChord>.generate(MusicConstants.notesPerScale, (i) {
          return ScaleChord(key.getMinorScaleByNote(i), MusicConstants.getMinorDiatonicChordModifier(i));
        });
      }

      //  compute the minor scale note
      for (MajorKey key in _keyMap.values) {
        key._keyMinorScaleNote = key.getMajorDiatonicByDegree(6 - 1).scaleNote;
      }
    }
    return _keyMap;
  }

  static MajorKey get(MajorKeyEnum ke) {
    return _getMajorKeys()[ke]!;
  }

  static Iterable<MajorKey> get values => _getMajorKeys().values;

  static MajorKeyEnum? _getKeyEnum(String s) {
    //  lazy eval
    if (keyEnumMap.isEmpty) {
      keyEnumMap = <String, MajorKeyEnum>{};
      for (MajorKeyEnum ke in MajorKeyEnum.values) {
        keyEnumMap[keyEnumToString(ke)] = ke;
      }
    }
    return keyEnumMap[s];
  }

  static final RegExp _hashSignRegExp = RegExp(r'[♯#]');

  static MajorKey? parseString(String s) {
    s = s.replaceAll('♭', 'b').replaceAll(_hashSignRegExp, 's');
    MajorKeyEnum? keyEnum = _getKeyEnum(s);
    if (keyEnum != null) {
      return get(keyEnum);
    }
    return null;
  }

  static final trebleStaffTopPitch = Pitch.get(.F5);
  static final double trebleStaffTop = _staffSpacesFromA0(trebleStaffTopPitch);
  static final bassStaffTopPitch = Pitch.get(.A3);
  static final double bassStaffTop = _staffSpacesFromA0(bassStaffTopPitch);
  static final bass8vbStaffTopPitch = Pitch.get(.A2);
  static final double bass8vbStaffTop = _staffSpacesFromA0(bass8vbStaffTopPitch);

  static double _staffSpacesFromA0(Pitch pitch) {
    return (pitch.scaleNumber +
            (pitch.scaleNumber >= _notesFromAtoC ? pitch.octaveNumber - 1 : pitch.octaveNumber) *
                MusicConstants.notesPerScale) /
        2;
  }

  static double getStaffPosition(Clef clef, Pitch pitch) {
    switch (clef) {
      case Clef.treble:
        return trebleStaffTop - _staffSpacesFromA0(pitch);
      case Clef.bass:
        return bassStaffTop - _staffSpacesFromA0(pitch);
      case Clef.bass8vb:
        return bass8vbStaffTop - _staffSpacesFromA0(pitch);
    }
  }

  /// Map from an arbitrary pitch to the correct pitch expression for this key.
  ///
  /// Note: pitch number will be identical but the sharp or flat will change
  /// as appropriate.
  Pitch mappedPitch(Pitch pitch) {
    return isSharp ? pitch.asSharp() : pitch.asFlat();
  }

  @override
  MajorKey get majorKey => this;

  @override
  MinorKey get minorKey => _minorKey;

  /// Return the next key that is one half step higher.
  MajorKey nextKeyByHalfStep() {
    return _getKeyByHalfStep(halfStep + 1);
  }

  MajorKey nextKeyByHalfSteps(int step) {
    if (step == 0) {
      return this; //  don't fool with the key if we don't have to
    }
    return _getKeyByHalfStep(halfStep + step);
  }

  MajorKey nextKeyByFifth() {
    return _getKeyByHalfStep(halfStep + MusicConstants.notesPerScale);
  }

  /// Return the next key that is one half step lower.
  MajorKey previousKeyByHalfStep() {
    return _getKeyByHalfStep(halfStep - 1);
  }

  MajorKey previousKeyByFifth() {
    return _getKeyByHalfStep(halfStep - MusicConstants.notesPerScale);
  }

  MajorKey _getKeyByHalfStep(int step) {
    step = step % _flatKeyEnumsByHalfStep.length;
    if (isSharp && step == MusicConstants.halfStepsFromAtoC + halfStepsPerOctave / 2) {
      //  the F# vs Gb split
      return MajorKey.Fs;
    }
    return _getMajorKeys()[_flatKeyEnumsByHalfStep[step]]!;
  }

  ScaleNote inKey(ScaleNote scaleNote) {
    if (isSharp) {
      if (scaleNote.isFlat) {
        return scaleNote.alias;
      }
    } else {
      //  key is flat
      if (scaleNote.isSharp) {
        return scaleNote.alias;
      }
    }
    return scaleNote;
  }

  /// Transpose the given scale note by the requested offset.
  ScaleNote transpose(ScaleNote scaleNote, int offset) {
    return getScaleNoteByHalfStep(scaleNote.halfStep + offset);
  }

  /// Return an integer value that represents the key.
  int getKeyValue() {
    return keyValue;
  }

  /// Return the scale note of the key, i.e. the musician's label for the key.
  ScaleNote getKeyScaleNote() {
    return keyScaleNote;
  }

  ScaleNote getKeyMinorScaleNote() {
    return _keyMinorScaleNote;
  }

  @override
  ScaleNote get keyMinorScaleNote => _keyMinorScaleNote;

  /// Return an integer value that represents the key's number of half steps from the key of A.
  int getHalfStep() {
    return keyScaleNote.halfStep;
  }

  /// Return the key represented by the given integer value.
  static MajorKey getKeyByValue(int keyValue) {
    for (MajorKey key in _getMajorKeys().values) {
      if (key.keyValue == keyValue) {
        return key;
      }
    }
    return MajorKey.C; //  not found, so use the default, expected to be C
  }

  static MajorKey getKeyByHalfStep(int halfStep) {
    return keysByHalfStep()[halfStep % halfStepsPerOctave];
  }

  static MajorKey getKeyByScaleNote(final ScaleNote scaleNote) {
    var keyEnums = MajorKeyEnum.values.where((e) => MajorKey.get(e).keyScaleNote == scaleNote);
    if (keyEnums.isEmpty) return MajorKey.getDefault();
    return MajorKey.get(keyEnums.first);
  }

  /// Return this major key representation as a minor key.
  MajorKey getMinorKey() {
    // the key's tonic    fixme: should be calculated once only
    return getKeyByHalfStep(getHalfStep() + _majorScale[6 - 1]); //  counts from 0
  }

  /// Guess the key from the collection of scale notes in a given song.
  static MajorKey guessKey(Iterable<ScaleChord> scaleChords) {
    MajorKey ret = getDefault(); //  default answer

    //  minimize the chord variations and keep a count of the scale note use
    Map<ScaleNote, int> useMap = Map<ScaleNote, int>.identity();
    for (ScaleChord scaleChord in scaleChords) {
      //  minimize the variation by using only the scale note
      ScaleNote scaleNote = scaleChord.scaleNote;

      //  count the uses
      //  fixme: account for song section repeats
      useMap[scaleNote] = (useMap[scaleNote] ?? 0) + 1;
    }

    //  find the key with the longest greatest parse to the major chord
    int maxScore = 0;
    int minKeyValue = 2 ^ 63 - 1;

    //  find the key with the greatest parse to it's diatonic chords
    {
      int? count;
      ScaleChord? diatonic;
      ScaleNote diatonicScaleNote;
      for (MajorKey key in _getMajorKeys().values) {
        //  score by weighted uses of the scale chords
        int score = 0;
        for (int i = 0; i < key._majorDiatonics.length; i++) {
          diatonic = key.getMajorDiatonicByDegree(i);
          diatonicScaleNote = diatonic.scaleNote;
          if ((count = useMap[diatonicScaleNote]) != null) {
            score += count! * _guessWeights[i];
          } else {
            diatonic = diatonic.getAlias();
            diatonicScaleNote = diatonic.scaleNote;
            if ((count = useMap[diatonicScaleNote]) != null) {
              score += count! * _guessWeights[i];
            }
          }
        }

        //  find the max score with the minimum key value
        if (score > maxScore || (score == maxScore && key.keyValue.abs() < minKeyValue)) {
          ret = key;
          maxScore = score;
          minKeyValue = key.keyValue.abs();
        }
      }
    }
    //GWT.log("guess: " + ret.toString() + ": score: " + maxScore);
    return ret;
  }

  /// Return the requested diatonic chord by degree.
  /// Counts from zero. For example, 0 represents the I chord, 3 represents the IV chord.
  ScaleChord getMajorDiatonicByDegree(int note) {
    note = note % _majorDiatonics.length;
    return _majorDiatonics[note];
  }

  ScaleChord getMajorScaleChord() {
    return _majorDiatonics[0];
  }

  ScaleChord getMinorDiatonicByDegree(int degree) {
    degree = degree % _minorDiatonics.length;
    return _minorDiatonics[degree];
  }

  ScaleChord getMinorScaleChord() {
    return _minorDiatonics[0];
  }

  /// Return true if the given scale chord is one of this key's major diatonics.
  bool isDiatonic(ScaleChord scaleChord) {
    return _majorDiatonics.contains(scaleChord);
  }

  /// Return the major scale note by it's note number.
  /// Counts from zero.
  ScaleNote getMajorScaleByNote(int note) {
    note = note % MusicConstants.notesPerScale;
    return getKeyScaleNoteByHalfStep(_majorScale[note]);
  }

  int getMajorScaleHalfStepsByNote(int note) {
    return _majorScale[note % _majorScale.length];
  }

  int? getMajorScaleNumberByHalfStep(int halfStep) {
    halfStep = halfStep % MusicConstants.halfStepsPerOctave;
    for (var i = 0; i < _majorScale.length; i++) {
      if (_majorScale[i] == halfStep) {
        return i;
      }
    }
    return null;
  }

  /// Return the minor scale note by it's note number.
  /// Counts from zero.
  ScaleNote getMinorScaleByNote(int note) {
    note = note % MusicConstants.notesPerScale;
    return getKeyScaleNoteByHalfStep(_minorScale[note]);
  }

  int? getMinorScaleNumberByHalfStep(int halfStep) {
    halfStep = halfStep % MusicConstants.halfStepsPerOctave;
    for (var i = 0; i < _minorScale.length; i++) {
      if (_minorScale[i] == halfStep) {
        return i;
      }
    }
    return null;
  }

  /// get the key's scale note for the given note
  ScaleNote getKeyScaleNoteFor(ScaleNote note) {
    return getMajorScaleByNote(note.scaleNumber - getKeyScaleNote().scaleNumber);
  }

  /// Return the required accidental for this pitch in terms of the key.
  /// Note that a null return means that no accidental should be applied.
  Accidental? accidental(final Pitch pitch) {
    //  adjust the pitch to the key's accidental
    var scaleNote = mappedPitch(pitch).scaleNote;

    //  get the key's scale note for the pitch
    var keyScaleNote = getKeyScaleNoteFor(scaleNote);

    //  deal with exceptions
    switch (majorKeyEnum) {
      case .Gb:
        if (scaleNote == .B) {
          return null;
        }
        break;
      case .Fs:
        if (scaleNote == .F) {
          return null;
        }
        break;
      default:
        break;
    }

    //  adjust the expressed accidental as required (i.e. if different)
    if (keyScaleNote.accidental == scaleNote.accidental) {
      return null;
    }
    return scaleNote.accidental;
  }

  /// Return an expression of the pitch expressed in terms of the key.
  String accidentalString(final Pitch pitch) {
    //  adjust the pitch to the key's accidental
    ScaleNote scaleNote = mappedPitch(pitch).scaleNote;

    //  get the key's scale note for the pitch
    ScaleNote keyScaleNote = getKeyScaleNoteFor(scaleNote);

    //  deal with exceptions
    switch (majorKeyEnum) {
      case .Gb:
        if (scaleNote == .B) {
          return 'C';
        }
        break;
      case .Fs:
        if (scaleNote == .F) {
          return 'E';
        }
        break;
      default:
        break;
    }

    //  adjust the expressed accidental as required (i.e. if different)
    switch (keyScaleNote.accidental) {
      case .natural:
        return scaleNote.toString();
      case .sharp:
        switch (scaleNote.accidental) {
          case .natural:
            return scaleNote.scaleNoteString + MusicConstants.naturalChar;
          case .sharp:
            return scaleNote.scaleNoteString;
          case .flat:
            return scaleNote.scaleNoteString + MusicConstants.flatChar;
        }
      case .flat:
        switch (scaleNote.accidental) {
          case .natural:
            return scaleNote.scaleNoteString + MusicConstants.naturalChar;
          case .sharp:
            return scaleNote.scaleNoteString + MusicConstants.sharpChar;
          case .flat:
            return scaleNote.scaleNoteString;
        }
    }
    //  should never get here
  }

  /// Counts from zero.
  ScaleNote getKeyScaleNoteByHalfStep(int halfStep) {
    halfStep += keyValue * MusicConstants.halfStepsToFifth + MusicConstants.halfStepsFromAtoC;
    return getScaleNoteByHalfStep(halfStep);
  }

  /// Return the scale note offset by the given half steps in the accidental required by this key.
  ScaleNote getScaleNoteByHalfStep(int halfSteps) {
    ScaleNote ret = _getScaleNoteByHalfStepNoAdjustment(halfSteps);
    //  deal with exceptions at +-6
    if (keyValue == 6 && ret == .F) {
      return .Es;
    } else if (keyValue == -6 && ret == .B) {
      return .Cb;
    }
    return ret;
  }

  ScaleNote _getScaleNoteByHalfStepNoAdjustment(int halfSteps) {
    halfSteps = halfSteps % halfStepsPerOctave;
    ScaleNote ret = isSharp ? ScaleNote.getSharpByHalfStep(halfSteps) : ScaleNote.getFlatByHalfStep(halfSteps);
    return ret;
  }

  /// Return the scale note offset by the given half steps in the accidental required by this key.
  ScaleNote getScaleNoteEnum3ByHalfStep(int halfSteps) {
    ScaleNote ret = _getScaleNoteEnum3ByHalfStepNoAdjustment(halfSteps);
    //  deal with exceptions at +-6
    if (keyValue == 6 && ret == .F) {
      return .Es;
    } else if (keyValue == -6 && ret == .B) {
      return .Cb;
    }
    return ret;
  }

  ScaleNote _getScaleNoteEnum3ByHalfStepNoAdjustment(int halfSteps) {
    halfSteps = halfSteps % halfStepsPerOctave;
    ScaleNote ret = isSharp ? ScaleNote.getSharpByHalfStep(halfSteps) : ScaleNote.getFlatByHalfStep(halfSteps);
    return ret;
  }

  /// Default key is C.
  static MajorKey getDefault() {
    return MajorKey.C;
  }

  /// Returns a string representing the number of sharps or flats associated with this key
  /// using their musical font character values ( ♭ or ♯ ) instead of b or #.
  String sharpsFlatsToString() {
    if (keyValue < 0) {
      return keyValue.abs().toString() + MusicConstants.flatChar;
    }
    if (keyValue > 0) {
      return keyValue.toString() + MusicConstants.sharpChar;
    }
    return '';
  }

  /// Returns a string representing the number of sharps or flats associated with this key
  /// using the simpler b or # instead of their musical font character values ( ♭ or ♯ ).
  String sharpsFlatsToMarkup() {
    if (keyValue < 0) {
      return '${keyValue.abs()}b';
    }
    if (keyValue > 0) {
      return '$keyValue#';
    }
    return '';
  }

  @override
  int compareTo(MajorKey other) {
    return majorKeyEnum.index - other.majorKeyEnum.index;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MajorKey && runtimeType == other.runtimeType && majorKeyEnum == other.majorKeyEnum;

  @override
  int get hashCode => majorKeyEnum.hashCode;

  /// Return true if this key is a sharp key.
  /// That is, true if the key accidental is sharp.
  bool get isSharp => keyValue > 0;

  String toJsonString() {
    return '"key":      $halfStep';
  }

  /// Returns the name of this key in a formal format using UTF-8.
  /// That is flats and sharps are expressed in their musical font character
  /// values ( ♭ or ♯ ) instead of b or #.
  @override
  String toString() {
    return keyScaleNote.toString();
  }

  @override
  String get name => majorKeyEnum.name;

  /// Express the key name as markup.
  String toMarkup() {
    return keyScaleNote.toMarkup();
  }

  static MajorKey fromMarkup(String s) {
    var sn = ScaleNote.parseString(s);
    if (sn == null) {
      return MajorKey.C;
    }
    try {
      return _getMajorKeys().values.where((k) => k.keyScaleNote == sn).first;
    } catch (e) {
      return MajorKey.C;
    }
  }

  /// Express the key name as a sharp note string.
  String toStringAsSharp() {
    if (keyScaleNote.isFlat) {
      return keyScaleNote.alias.toString();
    }
    return keyScaleNote.toString();
  }

  /// Express the key name as a flat note string.
  String toStringAsFlat() {
    if (keyScaleNote.isSharp) {
      return keyScaleNote.alias.toString();
    }
    return keyScaleNote.toString();
  }

  //                                    1  2  3  4  5  6  7
  //                                    0  1  2  3  4  5  6
  static const List<int> _majorScale = [0, 2, 4, 5, 7, 9, 11];

  // static const List<int> _majorScaleHalfstepsToScale = [
  //   0, // 0
  //   0, // 1
  //   2 - 1, // 2
  //   2 - 1, // 3
  //   3 - 1, // 4
  //   4 - 1, // 5
  //   4 - 1, // 6
  //   5 - 1, // 7
  //   5 - 1, // 8
  //   6 - 1, // 9
  //   6 - 1, // 10
  //   7 - 1, // 11
  // ];

  //                                   1  2  3  4  5  6  7
  //                                   0  1  2  3  4  5  6
  static const List<int> _minorScale = [0, 2, 3, 5, 7, 8, 10];

  // static final List<ChordDescriptor> _diatonic7ChordModifiers = [
  //   ChordDescriptor.major, //  0 + 1 = 1
  //   ChordDescriptor.minor, //  1 + 1 = 2
  //   ChordDescriptor.minor, //  2 + 1 = 3
  //   ChordDescriptor.major, //  3 + 1 = 4
  //   ChordDescriptor.dominant7, //  4 + 1 = 5
  //   ChordDescriptor.minor, //  5 + 1 = 6
  //   ChordDescriptor.minor7b5, //  6 + 1 = 7
  // ];
  static const List<MajorKeyEnum> _flatKeyEnumsByHalfStep = <MajorKeyEnum>[
    .A,
    .Bb,
    .B,
    .C,
    .Db,
    .D,
    .Eb,
    .E,
    .F,
    .Gb, //  the problem child, is it F#?
    .G,
    .Ab,
  ];

  static const int halfStepsPerOctave = MusicConstants.halfStepsPerOctave;

  //                                     1  2  3  4  5  6  7
  static const List<int> _guessWeights = [9, 1, 1, 4, 4, 1, 3];
  static const int _notesFromAtoC = 2;

  /// The matching key enumeration.
  final MajorKeyEnum majorKeyEnum;

  final int keyValue;

  final MinorKeyEnum minorKeyEnum;
  final MinorKey _minorKey;

  /// The number of half steps from the key of C.
  /// Will be between -6 and +6 inclusive.
  final int halfStep;
  final ScaleNote keyScaleNote;

  /// The location of the guitar capo required to map this key to a simpler key to play.
  final int capoLocation;

  /// Guitar key that should be played for this key when the guitar capo is placed on the capo location.
  /// Typically this will be either the key of C or G.
  MajorKey get capoKey => _capoKey;
  late final MajorKey _capoKey;

  //  have to be set after initialization of all keys
  late final ScaleNote _keyMinorScaleNote;
  late final List<ScaleChord> _majorDiatonics;
  late final List<ScaleChord> _minorDiatonics;
}

@immutable
abstract class Key {
  ScaleNote get keyMinorScaleNote;

  MajorKey get majorKey;

  MinorKey get minorKey;

  String get name;
}

@immutable
class MinorKey implements Key, Comparable<MinorKey> {
  static final eb = get(.eb);
  static final bb = get(.bb);
  static final f = get(.f);
  static final c = get(.c);
  static final g = get(.g);
  static final d = get(.d);
  static final a = get(.a);
  static final e = get(.e);
  static final b = get(.b);
  static final fs = get(.fs);
  static final cs = get(.cs);
  static final gs = get(.gs);
  static final ds = get(.ds);

  MinorKey._(this.minorKeyEnum) : _majorKeyEnum = MajorKeyEnum.values[minorKeyEnum.index];

  static MinorKey get(final MinorKeyEnum ke) {
    if (_minorMap == null) {
      _minorMap = {};
      for (var ke in MinorKeyEnum.values) {
        _minorMap![ke] = MinorKey._(ke);
      }
    }
    return _minorMap![ke]!;
  }

  static Map<MinorKeyEnum, MinorKey>? _minorMap;

  @override
  MajorKey get majorKey => _majorKey;

  @override
  MinorKey get minorKey => this;

  @override
  ScaleNote get keyMinorScaleNote => _majorKey.keyMinorScaleNote;

  @override
  int compareTo(final MinorKey other) {
    return minorKeyEnum.index.compareTo(other.minorKeyEnum.index);
  }

  @override
  String toString() {
    return minorKeyEnum.name;
  }

  @override
  String get name => minorKeyEnum.name;

  final MinorKeyEnum minorKeyEnum;
  final MajorKeyEnum _majorKeyEnum;

  MajorKey get _majorKey => _keyMap[_majorKeyEnum]!;
}

/*                     1  2  3  4  5  6  7                 I    II   III  IV   V    VI   VII               0  1  2  3  4  5  6  7  8  9  10 11
-6 Gb (G♭)		scale: G♭ A♭ B♭ C♭ D♭ E♭ F  	majorDiatonics: G♭   A♭m  B♭m  C♭   D♭7  E♭m  Fm7b5 	all notes: A  B♭ C♭ C  D♭ D  E♭ E  F  G♭ G  A♭
-5 Db (D♭)		scale: D♭ E♭ F  G♭ A♭ B♭ C  	majorDiatonics: D♭   E♭m  Fm   G♭   A♭7  B♭m  Cm7b5 	all notes: A  B♭ B  C  D♭ D  E♭ E  F  G♭ G  A♭
-4 Ab (A♭)		scale: A♭ B♭ C  D♭ E♭ F  G  	majorDiatonics: A♭   B♭m  Cm   D♭   E♭7  Fm   Gm7b5 	all notes: A  B♭ B  C  D♭ D  E♭ E  F  G♭ G  A♭
-3 Eb (E♭)		scale: E♭ F  G  A♭ B♭ C  D  	majorDiatonics: E♭   Fm   Gm   A♭   B♭7  Cm   Dm7b5 	all notes: A  B♭ B  C  D♭ D  E♭ E  F  G♭ G  A♭
-2 Bb (B♭)		scale: B♭ C  D  E♭ F  G  A  	majorDiatonics: B♭   Cm   Dm   E♭   F7   Gm   Am7b5 	all notes: A  B♭ B  C  D♭ D  E♭ E  F  G♭ G  A♭
-1 F (F)		scale: F  G  A  B♭ C  D  E  	majorDiatonics: F    Gm   Am   B♭   C7   Dm   Em7b5 	all notes: A  B♭ B  C  D♭ D  E♭ E  F  G♭ G  A♭
 0 C (C)		scale: C  D  E  F  G  A  B  	majorDiatonics: C    Dm   Em   F    G7   Am   Bm7b5 	all notes: A  A♯ B  C  C♯ D  D♯ E  F  F♯ G  G♯
 1 G (G)		scale: G  A  B  C  D  E  F♯ 	majorDiatonics: G    Am   Bm   C    D7   Em   F♯m7b5 	all notes: A  A♯ B  C  C♯ D  D♯ E  F  F♯ G  G♯
 2 D (D)		scale: D  E  F♯ G  A  B  C♯ 	majorDiatonics: D    Em   F♯m  G    A7   Bm   C♯m7b5 	all notes: A  A♯ B  C  C♯ D  D♯ E  F  F♯ G  G♯
 3 A (A)		scale: A  B  C♯ D  E  F♯ G♯ 	majorDiatonics: A    Bm   C♯m  D    E7   F♯m  G♯m7b5 	all notes: A  A♯ B  C  C♯ D  D♯ E  F  F♯ G  G♯
 4 E (E)		scale: E  F♯ G♯ A  B  C♯ D♯ 	majorDiatonics: E    F♯m  G♯m  A    B7   C♯m  D♯m7b5 	all notes: A  A♯ B  C  C♯ D  D♯ E  F  F♯ G  G♯
 5 B (B)		scale: B  C♯ D♯ E  F♯ G♯ A♯ 	majorDiatonics: B    C♯m  D♯m  E    F♯7  G♯m  A♯m7b5 	all notes: A  A♯ B  C  C♯ D  D♯ E  F  F♯ G  G♯
 6 Fs (F♯)		scale: F♯ G♯ A♯ B  C♯ D♯ E♯ 	majorDiatonics: F♯   G♯m  A♯m  B    C♯7  D♯m  E♯m7b5 	all notes: A  A♯ B  C  C♯ D  D♯ E  E♯ F♯ G  G♯
 */
