import 'dart:core';
import 'dart:io';

import 'dart:math';

class Util {
  static String homePath() {
    String home = '';
    Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS) {
      home = envVars['HOME'] ?? '';
    } else if (Platform.isLinux) {
      home = envVars['HOME'] ?? '';
    } else if (Platform.isWindows) {
      home = envVars['UserProfile'] ?? '';
    }
    return home;
  }

  /// add quotes to a string so it can be used as a dart constant
  static String? quote(String? s) {
    if (s == null) {
      return null;
    }
    if (s.isEmpty) {
      return '';
    }
    s = s.replaceAll("'", "\'").replaceAll('\n', "\\n'\n'");
    return "'$s'";
  }

  static num? limit(final num? n, final num? limit1, final num? limit2) {
    if (n == null) {
      return n;
    }
    if (limit1 == null) {
      if (limit2 == null) {
        return n;
      } else {
        return min(n, limit2);
      }
    }
    if (limit2 == null) {
      return max(n, limit1);
    }
    return min(max(n, min(limit1, limit2)), max(limit1, limit2)); //  cope with backwards limits, i.e. limit1 > limit2
  }

  static String enumToString(Object o) =>
      o
          .toString()
          .split('.')
          .last;

  static T? enumFromString<T>(String key, List<T> values) {
    try {
      return values.firstWhere((v) => key == enumToString(v!));
    } catch (e) {
      return null;
    }
  }

  /// capitalize the first character
  static String firstToUpper(String s) => s[0].toUpperCase() + s.substring(1);

  static String camelCaseToLowercaseSpace(String s) {
    return s.replaceAllMapped(_singleCapRegExp, (Match match) {
      return ' ${match.group(1)!.toLowerCase()}';
    }).trimLeft();
  }

  static final _singleCapRegExp = RegExp(r'([A-Z])');
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

  bool get isEmpty => _string.isEmpty || _index >= _string.length;

  bool get isNotEmpty => _string.isNotEmpty && _index < _string.length;

  String pop() {
    var ret = charAt(0);
    _index = min(_index + 1, _string.length);
    return ret;
  }

  int codeUnitAt(int index) {
    return charAt(0).codeUnitAt(0);
  }

  int firstUnit() {
    return charAt(0).codeUnitAt(0);
  }

  String first() {
    var s = charAt(0);
    if (s.isEmpty) {
      return '';
    }
    return charAt(0).substring(0, 1);
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
  String charAt(int n) {
    var i = _index + n;
    if (i >= _string.length) {
      return '';
    }
    return _string[i];
  }

  void consume(int? n) {
    _index += n ?? 0;
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
          pop();
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
          pop();
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
    return '(' + _a + ': \"' + _b + '\", \"' + _c + '\")';
  }

  String get a => _a;
  final String _a;

  String get b => _b;
  final String _b;

  String get c => _c;
  final String _c;
}
