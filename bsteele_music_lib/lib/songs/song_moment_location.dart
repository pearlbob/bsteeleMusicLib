import '../util/util.dart';
import 'chord_section_location.dart';

class SongMomentLocation {
  SongMomentLocation(this._chordSectionLocation, this._index);

  static SongMomentLocation? parseString(String? s) {
    if (s == null) {
      return null;
    }
    return parse(MarkedString(s));
  }

  static SongMomentLocation? parse(MarkedString markedString) {
    ChordSectionLocation chordSectionLocation =
        ChordSectionLocation.parse(markedString);

    if (markedString.available() < 2) {
      return null;
    }

    RegExpMatch? mr =
        numberRegexp.firstMatch(markedString.remainingStringLimited(5));
    if (mr != null) {
      try {
        int index = int.parse(mr.group(1)!);
        if (index <= 0) {
          return null;
        }
        markedString.consume(mr.group(0)!.length);
        return SongMomentLocation(chordSectionLocation, index);
      } catch (nfe) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return getId();
  }

  String getId() {
    return _chordSectionLocation.getId() + separator + _index.toString();
  }

  int getIndex() {
    return _index;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType && other is SongMomentLocation &&
        _chordSectionLocation == other._chordSectionLocation &&
        _index == other._index;
  }

  @override
  int get hashCode {
    //  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
    int ret = _chordSectionLocation.hashCode;
    ret = ret * 29 + _index.hashCode;
    return ret;
  }

  final ChordSectionLocation _chordSectionLocation;
  final int _index;
  static const String separator = '#';

  static final RegExp numberRegexp = RegExp('^$separator(\\d+)');
}
