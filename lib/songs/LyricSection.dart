import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

import '../appLogger.dart';
import 'LegacyDrumSection.dart';
import 'SectionVersion.dart';

/// A _sectionVersion of a song that carries the lyrics, any special drum _sectionVersion,
/// and the chord changes on a measure basis
/// with ultimately beat resolution.
class LyricSection implements Comparable<LyricSection> {
  /// Get the lyric _sectionVersion's identifier
  void setSectionVersion(SectionVersion _sectionVersion) {
    this._sectionVersion = _sectionVersion;
  }

  /// The _sectionVersion's measures.
  List<String> getLyricsLines() {
    return _lyricsLines;
  }

//  void setLyricsLines(List<LyricsLine> lyricsLines) {
//    this.lyricsLines = lyricsLines;
//  }

  void add(String lyricsLine) {
    logger.v("LyricSection.add($lyricsLine)");
    _lyricsLines.add(lyricsLine);
  }

  @override
  String toString() {
    return _sectionVersion.toString();
  }

  /// Get the song's default drum _sectionVersion.
  /// The _sectionVersion will be played through all of its measures
  /// and then repeated as required for the _sectionVersion's duration.
  /// When done, the drums will default back to the song's default drum _sectionVersion.

  LegacyDrumSection getDrumSection() {
    return drumSection;
  }

  ///Set the song's default drum _sectionVersion
  void setDrumSection(LegacyDrumSection drumSection) {
    this.drumSection = drumSection;
  }

  /// Compares this object with the specified object for order.  Returns a
  /// negative integer, zero, or a positive integer as this object is less
  /// than, equal to, or greater than the specified object.
  @override
  int compareTo(LyricSection other) {
    int ret = _sectionVersion.compareTo(other._sectionVersion);
    if (ret != 0) return ret;

    if (_lyricsLines == null) {
      if (other._lyricsLines != null) return -1;
    } else {
      if (other._lyricsLines == null) return 1;
      if (_lyricsLines.length != other._lyricsLines.length)
        return _lyricsLines.length - other._lyricsLines.length;
      for (int i = 0; i < _lyricsLines.length; i++) {
        ret =
            _lyricsLines.elementAt(i).compareTo(other._lyricsLines.elementAt(i));
        if (ret != 0) return ret;
      }
    }
    ret = drumSection.compareTo(other.drumSection);
    if (ret != 0) return ret;
    ret = _sectionVersion.compareTo(other._sectionVersion);
    if (ret != 0) return ret;

    if (!listsEqual(_lyricsLines, other._lyricsLines)) {
      //  compare the lists
      if (_lyricsLines == null) return other._lyricsLines == null ? 0 : 1;
      if (other._lyricsLines == null) return -1;
      if (_lyricsLines.length != other._lyricsLines.length)
        return _lyricsLines.length < other._lyricsLines.length ? -1 : 1;
      for (int i = 0; i < _lyricsLines.length; i++) {
        int ret = _lyricsLines[i].compareTo(other._lyricsLines[i]);
        if (ret != 0) return ret;
      }
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return other is LyricSection &&
        _sectionVersion == other._sectionVersion &&
        drumSection == other.drumSection &&
        listsEqual(_lyricsLines, other._lyricsLines);
  }

  @override
  int get hashCode {
    int ret = _sectionVersion.hashCode;
    ret = ret * 13 + drumSection.hashCode;
    if (_lyricsLines != null) ret = ret * 17 + hashObjects(_lyricsLines);
    return ret;
  }

  SectionVersion get sectionVersion => _sectionVersion;
  SectionVersion _sectionVersion;
  LegacyDrumSection drumSection = new LegacyDrumSection();

  List<String> get lyricsLines => _lyricsLines;
  List<String> _lyricsLines = new List();
}
