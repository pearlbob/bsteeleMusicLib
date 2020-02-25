//

import 'dart:collection';

import '../util/util.dart';
import 'MusicConstants.dart';
import 'Key.dart';

enum ScaleNoteEnum {
  A,
  As,
  B,
  C,
  Cs,
  D,
  Ds,
  E,
  F,
  Fs,
  G,
  Gs,
  Gb,
  Eb,
  Db,
  Bb,
  Ab,
  Cb, //  used for Gb (-6) key
  Es, //  used for Fs (+6) key
  Bs, //   for completeness of piano expression
  Fb, //   for completeness of piano expression
  X //  No scale note!  Used to avoid testing for null
}

///
class ScaleNote {
  ScaleNote._(ScaleNoteEnum scaleNoteE) {
    this._enum = scaleNoteE;
    switch (scaleNoteE) {
      case ScaleNoteEnum.A:
      case ScaleNoteEnum.X:
        _halfStep = 0;
        break;
      case ScaleNoteEnum.As:
      case ScaleNoteEnum.Bb:
        _halfStep = 1;
        break;
      case ScaleNoteEnum.B:
      case ScaleNoteEnum.Cb:
        _halfStep = 2;
        break;
      case ScaleNoteEnum.C:
      case ScaleNoteEnum.Bs:
        _halfStep = 3;
        break;
      case ScaleNoteEnum.Cs:
      case ScaleNoteEnum.Db:
        _halfStep = 4;
        break;
      case ScaleNoteEnum.D:
        _halfStep = 5;
        break;
      case ScaleNoteEnum.Ds:
      case ScaleNoteEnum.Eb:
        _halfStep = 6;
        break;
      case ScaleNoteEnum.E:
      case ScaleNoteEnum.Fb:
        _halfStep = 7;
        break;
      case ScaleNoteEnum.F:
      case ScaleNoteEnum.Es:
        _halfStep = 8;
        break;
      case ScaleNoteEnum.Fs:
      case ScaleNoteEnum.Gb:
        _halfStep = 9;
        break;
      case ScaleNoteEnum.G:
        _halfStep = 10;
        break;
      case ScaleNoteEnum.Gs:
      case ScaleNoteEnum.Ab:
        _halfStep = 11;
        break;
    }

    String mod = "";
    String modMarkup = "";

    _isSharp = false;
    _isFlat = false;
    _isNatural = false;
    _isSilent = false;

    switch (scaleNoteE) {
      case ScaleNoteEnum.A:
      case ScaleNoteEnum.B:
      case ScaleNoteEnum.C:
      case ScaleNoteEnum.D:
      case ScaleNoteEnum.E:
      case ScaleNoteEnum.F:
      case ScaleNoteEnum.G:
        //mod += '\u266E';  //  fixme: natural sign on scale not is overkill?
        _isNatural = true;
        break;
      case ScaleNoteEnum.X:
        _isSilent = true;
        break;
      case ScaleNoteEnum.As:
      case ScaleNoteEnum.Bs:
      case ScaleNoteEnum.Cs:
      case ScaleNoteEnum.Ds:
      case ScaleNoteEnum.Es:
      case ScaleNoteEnum.Fs:
      case ScaleNoteEnum.Gs:
        mod += '\u266F';
        modMarkup = "#";
        _isSharp = true;
        break;
      case ScaleNoteEnum.Ab:
      case ScaleNoteEnum.Bb:
      case ScaleNoteEnum.Cb:
      case ScaleNoteEnum.Db:
      case ScaleNoteEnum.Eb:
      case ScaleNoteEnum.Fb:
      case ScaleNoteEnum.Gb:
        mod += '\u266D';
        modMarkup = "b";
        _isFlat = true;
        break;
    }
    String base = scaleNoteE.toString().split('.').last;
    base = base.substring(0, 1);
    _scaleNoteString = base + mod;
    _scaleNoteMarkup = base + modMarkup;

    //  alia's done at the static class level
  }

  ScaleNoteEnum getEnum() {
    return _enum;
  }

  /// A utility to map the sharp scale notes to their half step offset.
  /// Should use the scale notes from the key under normal situations.
  ///
  /// @param step the number of half steps from A
  /// @return the sharp scale note
  static ScaleNote getSharpByHalfStep(int step) {
    return get(_sharps[step % halfStepsPerOctave]);
  }

  /// A utility to map the flat scale notes to their half step offset.
  /// Should use the scale notes from the key under normal situations.
  ///
  /// @param step the number of half steps from A
  /// @return the sharp scale note
  static ScaleNote getFlatByHalfStep(int step) {
    return get(_flats[step % halfStepsPerOctave]);
  }

  static ScaleNote parseString(String s) {
    return parse(new MarkedString(s));
  }

  /// Return the ScaleNote represented by the given string.
//  Is case sensitive.
  static ScaleNote parse(MarkedString markedString) {
    if (markedString == null || markedString.isEmpty)
      throw new ArgumentError("no data to parse");

    int c = markedString.firstUnit();
    if (c < 'A'.codeUnitAt(0) || c > 'G'.codeUnitAt(0)) {
      if (c == 'X'.codeUnitAt(0)) {
        markedString.getNextChar();
        return get(ScaleNoteEnum.X);
      }
      throw new ArgumentError("scale note must start with A to G");
    }

    StringBuffer stringBuffer = new StringBuffer();
    stringBuffer.write(markedString.getNextChar());

//  look for modifier
    if (markedString.isNotEmpty) {
      switch (markedString.first()) {
        case 'b':
        case MusicConstants.flatChar:
          stringBuffer.write('b');
          markedString.getNextChar();
          break;

        case '#':
        case MusicConstants.sharpChar:
          stringBuffer.write('s');
          markedString.getNextChar();
          break;
      }
    }

    return ScaleNote.valueOf(stringBuffer.toString());
  }

  ScaleNote transpose(Key key, int steps) {
    if (getEnum() == ScaleNoteEnum.X) return get(ScaleNoteEnum.X);
    return key.getScaleNoteByHalfStep(halfStep + steps);
  }

  /// Return the scale note as markup.
  String toMarkup() {
    return _scaleNoteMarkup;
  }

  //  all sharps
  static final _sharps = [
    ScaleNoteEnum.A,
    ScaleNoteEnum.As,
    ScaleNoteEnum.B,
    ScaleNoteEnum.C,
    ScaleNoteEnum.Cs,
    ScaleNoteEnum.D,
    ScaleNoteEnum.Ds,
    ScaleNoteEnum.E,
    ScaleNoteEnum.F,
    ScaleNoteEnum.Fs,
    ScaleNoteEnum.G,
    ScaleNoteEnum.Gs
  ];

  //  all flats
  static final _flats = [
    ScaleNoteEnum.A,
    ScaleNoteEnum.Bb,
    ScaleNoteEnum.B,
    ScaleNoteEnum.C,
    ScaleNoteEnum.Db,
    ScaleNoteEnum.D,
    ScaleNoteEnum.Eb,
    ScaleNoteEnum.E,
    ScaleNoteEnum.F,
    ScaleNoteEnum.Gb,
    ScaleNoteEnum.G,
    ScaleNoteEnum.Ab
  ];

  static ScaleNote get(ScaleNoteEnum e) {
    return _map()[e];
  }

  static Iterable<ScaleNote> get values {
    return _map().values;
  }

  static HashMap<ScaleNoteEnum, ScaleNote> _map() {
    //  lazy eval
    if (_hashmap == null) {
      _hashmap = HashMap.identity();

      //  fill the map
      for (ScaleNoteEnum e in ScaleNoteEnum.values) {
        _hashmap[e] = ScaleNote._(e);
      }

      //  find and assign the alias, if it exists
      for (ScaleNoteEnum e1 in ScaleNoteEnum.values) {
        if (e1 == ScaleNoteEnum.X) continue;
        ScaleNote scaleNote1 = get(e1);
        if (scaleNote1.isNatural || scaleNote1._alias != null)
          continue; //  don't duplicate the effort
        for (ScaleNoteEnum e2 in ScaleNoteEnum.values) {
          if (e2 == ScaleNoteEnum.X) continue;
          ScaleNote scaleNote2 = get(e2);
          if (scaleNote2.isNatural || scaleNote2._alias != null)
            continue; //  don't duplicate the effort
          if (e1 != e2 && scaleNote1.halfStep == scaleNote2.halfStep) {
            scaleNote1._alias = scaleNote2;
            scaleNote2._alias = scaleNote1;
          }
        }
      }
    }
    return _hashmap;
  }

  static ScaleNote valueOf(String name) {
    //  lazy eval
    if (_parseMap == null) {
      _parseMap = Map();
      for (ScaleNoteEnum e in ScaleNoteEnum.values) {
        ScaleNote sn = get(e);
        _parseMap[sn._scaleNoteMarkup] = sn;
        _parseMap[sn._scaleNoteString] = sn;
        _parseMap[e.toString().split('.').last] = sn;
      }
    }
    return _parseMap[name];
  }

  int compareTo(ScaleNote other) {
    return getEnum().index - other.getEnum().index;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ScaleNote && _enum == other._enum;
  }

  @override
  int get hashCode {
    return _enum.hashCode;
  }

  static final int halfStepsPerOctave = 12;

  ScaleNoteEnum _enum;

  int get halfStep => _halfStep;
  int _halfStep;

  String get scaleNoteString => _scaleNoteString;
  String _scaleNoteString;
  String _scaleNoteMarkup;

  ScaleNote _alias;

  ScaleNote get alias => _alias;

  bool _isSharp;

  bool get isSharp => _isSharp;

  bool _isFlat;

  bool get isFlat => _isFlat;

  bool _isNatural;

  bool get isNatural => _isNatural;

  bool _isSilent;

  bool get isSilent => _isSilent;

  ///  Returns the name of this scale note in a user friendly text format,
  //  i.e. as UTF-8
  @override
  String toString() {
    return _scaleNoteString;
  }

  static Map<ScaleNoteEnum, ScaleNote> _hashmap;
  static Map<String, ScaleNote> _parseMap;
}
