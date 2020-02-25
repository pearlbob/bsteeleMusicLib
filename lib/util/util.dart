import 'dart:core';

import 'dart:math';

class Util {

  /// add quotes to a string so it can be used as a dart constant
  static String quote(String s){
    if ( s == null)
      return null;
    if ( s.length==0)
      return "";
    s = s.replaceAll("'", "\'")
    .replaceAll("\n", "\\n'\n'")
    ;
    return "'$s'";
  }

  /// capitalize the first character
  static String firstToUpper(String s) => s[0].toUpperCase() + s.substring(1);
}

/// A String with a marked location to be used in parsing.
/// The current location is remembered.
/// Characters can be consumed by asking for the next character.
/// Locations in the string can be marked and returned to.
/// Typically this happens on a failed lookahead parse effort.
class MarkedString {
  MarkedString(this._string);

  /// mark the current location
  int mark() {
    _markIndex = _index;
    return _markIndex;
  }

  /// set the mark to the given location
  void setMark(int m) {
    _markIndex = m;
    resetToMark();
  }

  /// Return the current mark
  int getMark() {
    return _markIndex;
  }

  /// Return the current location to the mark
  void resetToMark() {
    _index = _markIndex;
  }

  /// Return the current location to the given mark
  void resetTo(int i) {
    _index = i;
  }

  bool get isEmpty => _string.length <= 0 || _index >= _string.length;

  bool get isNotEmpty => _string.length > 0 && _index < _string.length;

  String getNextChar() {
    return _string[_index++];
  }

  int codeUnitAt(int index) {
    return _string[_index].codeUnitAt(0);
  }

  int firstUnit() {
    return _string[_index].codeUnitAt(0);
  }

  String first() {
    return _string[_index].substring(0, 1);
  }

  int indexOf(String s) {
    return _string.indexOf(s, _index);
  }

  String remainingStringLimited(int limitLength) {
    int i = _index + limitLength;
    i = min(i, _string.length);
    return _string.substring(_index, i);
  }

  ///  return character at location relative to current _index
  String charAt(int i) {
    return _string[_index + i];
  }

  void consume(int n) {
    _index += n;
  }

  int available() {
    int ret = _string.length - _index;
    return (ret < 0 ? 0 : ret);
  }

  ///Strip leading space and tabs but newline is not considered a space!
  void stripLeadingSpaces() {
    while (!isEmpty) {
      switch (charAt(0)) {
        case ' ':
        case '\t':
        case '\r':
          getNextChar();
          continue;
      }
      break;
    }
  }

  /// Strip leading space and tabs.  newline is white space!
  void stripLeadingWhitespace() {
    while (!isEmpty) {
      switch (charAt(0)) {
        case ' ':
        case '\t':
        case '\r':
        case '\n':
          getNextChar();
          continue;
      }
      break;
    }
  }

  @override
  String toString() {
    return _string.substring(_index);
  }

  int _index = 0;
  int _markIndex = 0;
  final String _string;
}

class StringTriple {
  StringTriple(this._a, this._b, this._c);

  @override
  String toString() {
    return "(" + _a + ": \"" + _b + "\", \"" + _c + "\")";
  }

  String get a => _a;
  String _a;

  String get b => _b;
  String _b;

  String get c => _c;
  String _c;
}
