import 'dart:collection';

import 'package:bsteeleMusicLib/songs/pitch.dart';
import 'package:bsteeleMusicLib/songs/scaleChord.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'chordDescriptor.dart';
import 'musicConstants.dart';

enum KeyEnum { Gb, Db, Ab, Eb, Bb, F, C, G, D, A, E, B, Fs }

///
/// Representation of the song key used generate the expression of the proper scales.
/// <p>Six flats and six sharps are labeled differently but are otherwise the same key.
/// Seven flats and seven sharps are not included.</p>
class Key implements Comparable<Key> {
  Key._(this._keyEnum, this._keyValue, this._halfStep, this._capoLocation)
      : _name = _keyEnumToString(_keyEnum),
        _keyScaleNote = ScaleNote.valueOf(_keyEnumToString(_keyEnum))!;

  static String _keyEnumToString(KeyEnum ke) {
    return ke.toString().split('.').last;
  }

  static Map<KeyEnum, Key> _keyMap = {};
  static List<Key> _keysByHalfStep = [];
  static final List<dynamic> _initialization = [
    //  KeyEnum, keyValue, key halfsteps from A
    [KeyEnum.Gb, -6, 9],
    [KeyEnum.Db, -5, 4],
    [KeyEnum.Ab, -4, 11],
    [KeyEnum.Eb, -3, 6],
    [KeyEnum.Bb, -2, 1],
    [KeyEnum.F, -1, 8],
    [KeyEnum.C, 0, 3],
    [KeyEnum.G, 1, 10],
    [KeyEnum.D, 2, 5],
    [KeyEnum.A, 3, 0],
    [KeyEnum.E, 4, 7],
    [KeyEnum.B, 5, 2],
    [KeyEnum.Fs, 6, 9]
  ];
  static late Map<String, KeyEnum> _keyEnumMap = {};

  static List<Key> keysByHalfStep() {
    if (_keysByHalfStep.isEmpty) {
      SplayTreeSet<Key> sortedSet = SplayTreeSet((a1, a2) {
        return a1._halfStep.compareTo(a2._halfStep);
      });
      sortedSet.addAll(_getKeys().values);
      _keysByHalfStep = List.unmodifiable(sortedSet.toList());
    }
    return _keysByHalfStep;
  }

  static Key byHalfStep({int offset = 0}) {
    return keysByHalfStep()[offset % halfStepsPerOctave];
  }

  static List<Key> keysByHalfStepFrom(Key key) {
    return List.generate(halfStepsPerOctave + 1, (i) {
      return byHalfStep(offset: key._halfStep + i);
    });
  }

  static Map<KeyEnum, Key> _getKeys() {
    if (_keyMap.isEmpty) {
      _keyMap = Map<KeyEnum, Key>.identity();

      //  calculation constants
      const int keyCHalfStep = 3;
      const int keyGHalfStep = 10;

      for (var init in _initialization) {
        KeyEnum keInit = init[0];
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

        _keyMap[keInit] = Key._(keInit, init[1], halfStep, capoLocation);
      }

      //  majorDiatonics needs majorScale which is initialized after the initialization
      final Key keyC = _keyMap[KeyEnum.C]!;
      final Key keyG = _keyMap[KeyEnum.G]!;
      for (Key key in _keyMap.values) {
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
      for (Key key in _keyMap.values) {
        key._keyMinorScaleNote = key.getMajorDiatonicByDegree(6 - 1).scaleNote;
      }
    }
    return _keyMap;
  }

  static Key get(KeyEnum ke) {
    return _getKeys()[ke]!;
  }

  static Iterable<Key> get values => _getKeys().values;

  static KeyEnum? _getKeyEnum(String s) {
    //  lazy eval
    if (_keyEnumMap.isEmpty) {
      _keyEnumMap = <String, KeyEnum>{};
      for (KeyEnum ke in KeyEnum.values) {
        _keyEnumMap[_keyEnumToString(ke)] = ke;
      }
    }
    return _keyEnumMap[s];
  }

  static final RegExp _hashSignRegExp = RegExp(r'[♯#]');

  static Key? parseString(String s) {
    s = s.replaceAll('♭', 'b').replaceAll(_hashSignRegExp, 's');
    KeyEnum? keyEnum = _getKeyEnum(s);
    if (keyEnum != null) {
      return get(keyEnum);
    }
    return null;
  }

  static final trebleStaffTopPitch = Pitch.get(PitchEnum.F5);
  static final double trebleStaffTop = _staffSpacesFromA0(trebleStaffTopPitch);
  static final bassStaffTopPitch = Pitch.get(PitchEnum.A3);
  static final double bassStaffTop = _staffSpacesFromA0(bassStaffTopPitch);
  static final bass8vbStaffTopPitch = Pitch.get(PitchEnum.A2);
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

  /// map from an arbitrary pitch to the correct pitch expression for this key.
  /// Note: pitch number will be identical but the sharp or flat will change
  /// as appropriate.
  Pitch mappedPitch(Pitch pitch) {
    return isSharp ? pitch.asSharp() : pitch.asFlat();
  }

  /// Return the next key that is one half step higher.
  Key nextKeyByHalfStep() {
    return _getKeys()[keyEnumsByHalfStep[(_halfStep + 1) % keyEnumsByHalfStep.length]]!;
  }

  Key nextKeyByHalfSteps(int step) {
    return _getKeys()[keyEnumsByHalfStep[(_halfStep + step) % keyEnumsByHalfStep.length]]!;
  }

  Key nextKeyByFifth() {
    return _getKeys()[keyEnumsByHalfStep[(_halfStep + MusicConstants.notesPerScale) % keyEnumsByHalfStep.length]]!;
  }

  /// Return the next key that is one half step lower.
  Key previousKeyByHalfStep() {
    return _getKeys()[keyEnumsByHalfStep[(_halfStep - 1) % keyEnumsByHalfStep.length]]!;
  }

  Key previousKeyByFifth() {
    return _getKeys()[keyEnumsByHalfStep[(_halfStep - MusicConstants.notesPerScale) % keyEnumsByHalfStep.length]]!;
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
    return _keyValue;
  }

  /// Return the scale note of the key, i.e. the musician's label for the key.
  ScaleNote getKeyScaleNote() {
    return _keyScaleNote;
  }

  ScaleNote getKeyMinorScaleNote() {
    return _keyMinorScaleNote;
  }

  /// Return an integer value that represents the key's number of half steps from A.
  int getHalfStep() {
    return _keyScaleNote.halfStep;
  }

  /// Return the key represented by the given integer value.
  static Key getKeyByValue(int keyValue) {
    for (Key key in _getKeys().values) {
      if (key._keyValue == keyValue) {
        return key;
      }
    }
    return get(KeyEnum.C); //  not found, so use the default, expected to be C
  }

  static Key getKeyByHalfStep(int halfStep) {
    return keysByHalfStep()[halfStep % halfStepsPerOctave];
  }

  Key getMinorKey() {
    // the key's tonic    fixme: should be calculated once only
    return getKeyByHalfStep(getHalfStep() + majorScale[6 - 1]); //  counts from 0
  }

  /// Guess the key from the collection of scale notes in a given song.
  static Key guessKey(Iterable<ScaleChord> scaleChords) {
    Key ret = getDefault(); //  default answer

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
      for (Key key in _getKeys().values) {
        //  score by weighted uses of the scale chords
        int score = 0;
        for (int i = 0; i < key._majorDiatonics.length; i++) {
          diatonic = key.getMajorDiatonicByDegree(i);
          diatonicScaleNote = diatonic.scaleNote;
          if ((count = useMap[diatonicScaleNote]) != null) {
            score += count! * guessWeights[i];
          } else {
            diatonic = diatonic.getAlias();
            diatonicScaleNote = diatonic.scaleNote;
            if ((count = useMap[diatonicScaleNote]) != null) {
              score += count! * guessWeights[i];
            }
          }
        }

        //  find the max score with the minimum key value
        if (score > maxScore || (score == maxScore && key._keyValue.abs() < minKeyValue)) {
          ret = key;
          maxScore = score;
          minKeyValue = key._keyValue.abs();
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

  bool isDiatonic(ScaleChord scaleChord) {
    return _majorDiatonics.contains(scaleChord);
  }

  ScaleNote getMajorScaleByNote(int note) {
    note = note % MusicConstants.notesPerScale;
    return getKeyScaleNoteByHalfStep(majorScale[note]);
  }

  /// get the key's scale note for the given note
  ScaleNote getKeyScaleNoteFor(ScaleNote note) {
    return getMajorScaleByNote(note.scaleNumber - getKeyScaleNote().scaleNumber);
  }

  /// required accidental for this pitch in terms of the key
  /// Note that a null return means that no accidental should be applied.
  Accidental? accidental(final Pitch pitch) {
    //  adjust the pitch to the key's accidental
    ScaleNote scaleNote = mappedPitch(pitch).scaleNote;

    //  get the key's scale note for the pitch
    ScaleNote keyScaleNote = getKeyScaleNoteFor(scaleNote);

    //  deal with exceptions
    switch (keyEnum) {
      case KeyEnum.Gb:
        if (scaleNote == ScaleNote.get(ScaleNoteEnum.B)) {
          return null;
        }
        break;
      case KeyEnum.Fs:
        if (scaleNote == ScaleNote.get(ScaleNoteEnum.F)) {
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

  /// return an expression of the pitch in terms of the key
  String accidentalString(final Pitch pitch) {
    //  adjust the pitch to the key's accidental
    ScaleNote scaleNote = mappedPitch(pitch).scaleNote;

    //  get the key's scale note for the pitch
    ScaleNote keyScaleNote = getKeyScaleNoteFor(scaleNote);

    //  deal with exceptions
    switch (keyEnum) {
      case KeyEnum.Gb:
        if (scaleNote == ScaleNote.get(ScaleNoteEnum.B)) {
          return 'C';
        }
        break;
      case KeyEnum.Fs:
        if (scaleNote == ScaleNote.get(ScaleNoteEnum.F)) {
          return 'E';
        }
        break;
      default:
        break;
    }

    //  adjust the expressed accidental as required (i.e. if different)
    switch (keyScaleNote.accidental) {
      case Accidental.natural:
        return scaleNote.toString();
      case Accidental.sharp:
        switch (scaleNote.accidental) {
          case Accidental.natural:
            return scaleNote.scaleNoteString + MusicConstants.naturalChar;
          case Accidental.sharp:
            return scaleNote.scaleString;
          case Accidental.flat:
            return scaleNote.scaleNoteString + MusicConstants.flatChar;
        }
      case Accidental.flat:
        switch (scaleNote.accidental) {
          case Accidental.natural:
            return scaleNote.scaleNoteString + MusicConstants.naturalChar;
          case Accidental.sharp:
            return scaleNote.scaleNoteString + MusicConstants.sharpChar;
          case Accidental.flat:
            return scaleNote.scaleString;
        }
    }
    //  should never get here
  }

  ScaleNote getMinorScaleByNote(int note) {
    note = note % MusicConstants.notesPerScale;
    return getKeyScaleNoteByHalfStep(minorScale[note]);
  }

  /// Counts from zero.
  ScaleNote getKeyScaleNoteByHalfStep(int halfStep) {
    halfStep += _keyValue * MusicConstants.halfStepsToFifth + MusicConstants.halfStepsFromAtoC;
    return getScaleNoteByHalfStep(halfStep);
  }

  ScaleNote getScaleNoteByHalfStep(int halfSteps) {
    ScaleNote ret = _getScaleNoteByHalfStepNoAdjustment(halfSteps);
    //  deal with exceptions at +-6
    if (_keyValue == 6 && ret == ScaleNote.get(ScaleNoteEnum.F)) {
      return ScaleNote.get(ScaleNoteEnum.Es);
    } else if (_keyValue == -6 && ret == ScaleNote.get(ScaleNoteEnum.B)) {
      return ScaleNote.get(ScaleNoteEnum.Cb);
    }
    return ret;
  }

  ScaleNote _getScaleNoteByHalfStepNoAdjustment(int halfSteps) {
    halfSteps = halfSteps % halfStepsPerOctave;
    ScaleNote ret = isSharp ? ScaleNote.getSharpByHalfStep(halfSteps) : ScaleNote.getFlatByHalfStep(halfSteps);
    return ret;
  }

  static Key getDefault() {
    return get(KeyEnum.C);
  }

  String sharpsFlatsToString() {
    if (_keyValue < 0) {
      return _keyValue.abs().toString() + MusicConstants.flatChar;
    }
    if (_keyValue > 0) {
      return _keyValue.toString() + MusicConstants.sharpChar;
    }
    return '';
  }

  String sharpsFlatsToMarkup() {
    if (_keyValue < 0) {
      return _keyValue.abs().toString() + 'b';
    }
    if (_keyValue > 0) {
      return _keyValue.toString() + '#';
    }
    return '';
  }

  @override
  int compareTo(Key other) {
    return _keyEnum.index - other._keyEnum.index;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Key && runtimeType == other.runtimeType && _keyEnum == other._keyEnum;

  @override
  int get hashCode => _keyEnum.hashCode;

  bool get isSharp => _keyValue > 0;

  /// Returns the name of this enum constant in a user friendly format,
  /// i.e. as UTF-8
  @override
  String toString() {
    return _keyScaleNote.toString();
  }

  String toMarkup() {
    return _keyScaleNote.toMarkup();
  }

  String toStringAsSharp() {
    if (_keyScaleNote.isFlat) {
      return _keyScaleNote.alias.toString();
    }
    return _keyScaleNote.toString();
  }

  String toStringAsFlat() {
    if (_keyScaleNote.isSharp) {
      return _keyScaleNote.alias.toString();
    }
    return _keyScaleNote.toString();
  }

  //                                   1  2  3  4  5  6  7
  //                                   0  1  2  3  4  5  6
  static const List<int> majorScale = [0, 2, 4, 5, 7, 9, 11];
  static const List<int> majorScaleHalfstepsToScale = [
    0, // 0
    0, // 1
    2 - 1, // 2
    2 - 1, // 3
    3 - 1, // 4
    4 - 1, // 5
    4 - 1, // 6
    5 - 1, // 7
    5 - 1, // 8
    6 - 1, // 9
    6 - 1, // 10
    7 - 1, // 11
  ];

  //                                   1  2  3  4  5  6  7
  //                                   0  1  2  3  4  5  6
  static const List<int> minorScale = [0, 2, 3, 5, 7, 8, 10];

  static final List<ChordDescriptor> diatonic7ChordModifiers = [
    ChordDescriptor.major, //  0 + 1 = 1
    ChordDescriptor.minor, //  1 + 1 = 2
    ChordDescriptor.minor, //  2 + 1 = 3
    ChordDescriptor.major, //  3 + 1 = 4
    ChordDescriptor.dominant7, //  4 + 1 = 5
    ChordDescriptor.minor, //  5 + 1 = 6
    ChordDescriptor.minor7b5, //  6 + 1 = 7
  ];
  static const List<KeyEnum> keyEnumsByHalfStep = <KeyEnum>[
    KeyEnum.A,
    KeyEnum.Bb,
    KeyEnum.B,
    KeyEnum.C,
    KeyEnum.Db,
    KeyEnum.D,
    KeyEnum.Eb,
    KeyEnum.E,
    KeyEnum.F,
    KeyEnum.Gb,
    KeyEnum.G,
    KeyEnum.Ab
  ];

  static const int halfStepsPerOctave = MusicConstants.halfStepsPerOctave;

  //                                     1  2  3  4  5  6  7
  static const List<int> guessWeights = [9, 1, 1, 4, 4, 1, 3];
  static const int _notesFromAtoC = 2;

  KeyEnum get keyEnum => _keyEnum;
  final KeyEnum _keyEnum;

  String get name => _name;
  final String _name;
  final int _keyValue;

  int get halfStep => _halfStep;
  final int _halfStep;
  final ScaleNote _keyScaleNote;

  int get capoLocation => _capoLocation;
  final int _capoLocation;

  Key get capoKey => _capoKey;
  late Key _capoKey;

  //  have to be set after initialization of all keys
  late ScaleNote _keyMinorScaleNote;
  List<ScaleChord> _majorDiatonics = [];
  List<ScaleChord> _minorDiatonics = [];
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
