import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

const DeepCollectionEquality deepCollectionEquality = DeepCollectionEquality();
const DeepCollectionEquality deepUnorderedCollectionEquality = DeepCollectionEquality.unordered();

final DateFormat _dateFormat = DateFormat('yyyyMMdd_HHmmss');
final RegExp _dateRegExp = RegExp(r'(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})');
final RegExp _yyyyMMddRegExp = RegExp(r'(\d{4})[-_](\d{2})[-_](\d{2})');

class Util {
  static String homePath() {
    String home = '';
    Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS || Platform.isLinux) {
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
    s = s.replaceAll("'", "'").replaceAll('\n', "\\n'\n'");
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

  static int intLimit(final int n, final int limit1, final int limit2) {
    return min(max(n, min(limit1, limit2)), max(limit1, limit2)); //  cope with backwards limits, i.e. limit1 > limit2
  }

  static int indexLimit(final int n, final List list) {
    return intLimit(n, 0, list.isEmpty ? 0 : list.length - 1); //  fixme: return 0 on empty list?
  }

  static double doubleLimit(final double n, final double limit1, final double limit2) {
    return min(max(n, min(limit1, limit2)), max(limit1, limit2)); //  cope with backwards limits, i.e. limit1 > limit2
  }

  static String readableJson(final String json) {
    return json.replaceAll(_jsonJunkRegexp, '').replaceAll(',\n', '\n');
  }

  static final RegExp _jsonJunkRegexp = RegExp(r'(",|\s*\[|\s+\n|["{}[\]])');

  static T? enumFromString<T extends Enum>(String key, List<T> values) {
    try {
      return values.firstWhere((v) => key == v.name);
    } catch (e) {
      return null;
    }
  }

  ///  index of the identical list item
  ///  List.index() uses equals so it's not the same.
  int indexOfIdentical<T>(List<T> list, T item) {
    for (var start = 0; start < list.length; start++) // safety only
    {
      int ret = list.indexOf(item, start);
      if (ret < 0) {
        return -1;
      }
      if (identical(item, list[ret])) {
        return ret;
      }
      start = ret;
    }
    return -1;
  }

  /// capitalize the first character
  static String firstToUpper(String s) {
    if (s.isNotEmpty) {
      return s[0].toUpperCase() + s.substring(1);
    }
    return s;
  }

  static String firstToLower(String s) {
    if (s.isNotEmpty) {
      return s[0].toLowerCase() + s.substring(1);
    }
    return s;
  }

  static String utcNow() {
    return utcFormat(DateTime.now().toUtc());
  }

  //  first unix time in local timezone
  static final DateTime firstDateTime = DateTime.fromMillisecondsSinceEpoch(0, isUtc: false);

  //  first unix time in utc
  static final DateTime firstUtcDateTime = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static String utcFormat(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  // ignore: non_constant_identifier_names
  static DateTime yyyyMMdd_HHmmssStringToDate(String s, {bool? isUtc = false}) {
    var m = _dateRegExp.firstMatch(s);
    if (isUtc ?? false) {
      return DateTime.utc(
        int.parse(m?.group(1) ?? firstUtcDateTime.year.toString()), //  year
        int.parse(m?.group(2) ?? firstUtcDateTime.month.toString()), //  month
        int.parse(m?.group(3) ?? firstUtcDateTime.day.toString()), //  day
        int.parse(m?.group(4) ?? firstUtcDateTime.hour.toString()), //  hour
        int.parse(m?.group(5) ?? firstUtcDateTime.minute.toString()), //  minute
        int.parse(m?.group(6) ?? firstUtcDateTime.second.toString()), //  second
      );
    }
    return DateTime(
      int.parse(m?.group(1) ?? firstDateTime.year.toString()), //  year
      int.parse(m?.group(2) ?? firstDateTime.month.toString()), //  month
      int.parse(m?.group(3) ?? firstDateTime.day.toString()), //  day
      int.parse(m?.group(4) ?? firstDateTime.hour.toString()), //  hour
      int.parse(m?.group(5) ?? firstDateTime.minute.toString()), //  minute
      int.parse(m?.group(6) ?? firstDateTime.second.toString()), //  second
    );
  }

  static DateTime? yyyyMMddStringToDate(String s) {
    var m = _yyyyMMddRegExp.firstMatch(s);
    if (m == null) {
      return null;
    }
    return DateTime(
      int.parse(m.group(1) ?? firstDateTime.year.toString()), //  year
      int.parse(m.group(2) ?? firstDateTime.month.toString()), //  month
      int.parse(m.group(3) ?? firstDateTime.day.toString()),
    );
  }

  static String camelCaseToLowercaseSpace(String s) {
    return s.replaceAllMapped(_singleCapRegExp, (Match match) {
      return ' ${match.group(1)!.toLowerCase()}';
    }).trimLeft();
  }

  static String camelCaseToSpace(String s) {
    return firstToUpper(s.replaceAllMapped(_singleCapRegExp, (Match match) {
      return ' ${match.group(1)!}';
    }).trimLeft());
  }

  static String underScoresToCamelCase(String s) {
    return s.replaceAllMapped(_underScoreRegExp, (Match match) {
      return match.group(1)!.toUpperCase();
    }).trimLeft();
  }

  static String underScoresToSpaceUpperCase(String s) {
    return firstToUpper(s.replaceAllMapped(_underScoreRegExp, (Match match) {
      return ' ${match.group(1)!.toUpperCase()}';
    }).trimLeft());
  }

  static String jsonEncodeNewLines(String s) {
    return '${s.replaceAll(_jsonEncodeNewLineRegexp, '},\n{')}\n';
  }

  static String limitLineLength(String s, int limit, {bool ellipsis = false}) {
    StringBuffer sb = StringBuffer();
    limit = max(0, limit);
    var list = s.split('\n');
    var lastIndex = list.length - 1;
    for (int i = 0; i < list.length; i++) {
      var line = list[i];
      if (line.length > limit) {
        sb.write(line.substring(0, min(line.length, limit + (ellipsis ? -3 : 0))));
        if (ellipsis) {
          sb.write('...');
        }
      } else {
        sb.write(line);
      }
      if (i < lastIndex) {
        sb.write('\n');
      }
    }
    return sb.toString();
  }

  static final RegExp _jsonEncodeNewLineRegexp = RegExp(r'\},\{');

  static final _singleCapRegExp = RegExp(r'([A-Z])');
  static final _underScoreRegExp = RegExp(r'_(\w)');
}

class RollingAverage {
  RollingAverage({this.windowSize = 3}) {
    assert(windowSize > 0);
  }

  double average(double value) {
    if (_list.length < windowSize) {
      //  fill the initial values
      _list.add(value);
      _sum += value;
      _index = 0;
    } else {
      //  roll the values over the old ones
      _sum -= _list[_index];
      _list[_index] = value;
      _sum += value;
      _index++;
      if (_index >= windowSize) {
        _index = 0;
      }
    }
    assert((_sum - _list.reduce((value, element) => value += element)).abs() < 1e-6);

    //  average
    return _sum / _list.length;
  }

  void reset() {
    _list.clear();
    _index = 0;
    _sum = 0;
  }

  final int windowSize;
  int _index = 0;
  double _sum = 0;
  final List<double> _list = [];
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

  int getNextWhiteSpaceIndex() {
    RegExpMatch? m = whiteSpaceRegExp.firstMatch(_string.substring(_index));
    if (m == null) {
      return _string.length;
    }
    return _index + m.start;
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

  static final RegExp whiteSpaceRegExp = RegExp(r'\s');
}

class StringTriple {
  StringTriple(this._a, this._b, this._c);

  @override
  String toString() {
    return '($_a: "$_b", "$_c")';
  }

  String get a => _a;
  final String _a;

  String get b => _b;
  final String _b;

  String get c => _c;
  final String _c;
}
