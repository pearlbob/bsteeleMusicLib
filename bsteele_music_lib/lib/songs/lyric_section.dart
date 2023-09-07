import 'dart:math';

import 'chord_section.dart';
import 'key.dart';
import 'measure_node.dart';
import 'package:quiver/collection.dart';

import '../app_logger.dart';
import 'drum_section.dart';
import 'lyric.dart';
import 'section_version.dart';

/// A _sectionVersion of a song that carries the lyrics, any special drum _sectionVersion,
/// and the chord changes on a measure basis
/// with ultimately beat resolution.
class LyricSection extends MeasureNode implements Comparable<LyricSection> {
  LyricSection(this._sectionVersion, this._index);

  void addLine(String lyricsLine) {
    logger.t('LyricSection.add($lyricsLine)');
    _lyricsLines.add(lyricsLine);
  }

  void stripLastEmptyLyricLine() {
    if (_lyricsLines.isNotEmpty) {
      if (_lyricsLines.last.isEmpty || _lyricsLines.last == '\n') {
        _lyricsLines.removeLast();
      }
    }
  }

  List<Lyric> asExpandedLyrics(ChordSection chordSection, int rows) {
    rows = max(rows, 1);

    List<Lyric> lyrics = [];

    int linesPerRow = lyricsLines.length ~/ rows;
    int lineExtra = lyricsLines.length % rows;
    var lineCount = 0;
    String lyricString = '';

    int phraseIndex = 0;
    int repeat = 0;
    var phrases = chordSection.phrases;
    assert(phrases.isNotEmpty);
    var phrase = phrases.first;
    var phraseRow = 0;
    for (var i = 0; i < lyricsLines.length; i++) {
      lyricString += (lyricString.isNotEmpty ? '\n' : '') + lyricsLines[i];
      lineCount++;
      if (lineCount >= linesPerRow + (lineExtra > 0 ? 1 : 0)) {
        lyrics.add(Lyric(lyricString, phraseIndex: phraseIndex, repeat: repeat));
        lyricString = '';
        lineCount = 0;
        lineExtra = max(0, lineExtra - 1);
        phraseRow++;
        if (phraseRow >= phrase.rowCount(expanded: false)) {
          phraseRow = 0;
          repeat++;
          if (repeat >= phrase.repeats && !identical(phrase, phrases.last)) {
            phraseIndex++;
            repeat = 0;
            phrase = phrases[phraseIndex];
          }
        }
      }
    }
    return lyrics;
  }

  @override
  MeasureNodeType get measureNodeType => MeasureNodeType.lyricSection;

  @override
  bool setMeasuresPerRow(int measuresPerRow) {
    // TODO: implement setMeasuresPerRow
    throw UnimplementedError();
  }

  @override
  String toEntry() {
    return toString();
  }

  @override
  String toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  String toMarkup({bool expanded = false}) {
    return toString();
  }

  @override
  String toMarkupWithoutEnd() {
    return toString();
  }

  @override
  String transpose(Key key, int halfSteps) {
    return toString();
  }

  @override
  MeasureNode transposeToKey(Key key) {
    return this;
  }

  @override
  String toString() {
    return '${_sectionVersion.toString()}#$_index';
  }

  @override
  String toNashville(Key key) {
    return ''; //  no lyrics in Nashville!
  }

  /// Get the song's default drum _sectionVersion.
  /// The _sectionVersion will be played through all of its measures
  /// and then repeated as required for the _sectionVersion's duration.
  /// When done, the drums will default back to the song's default drum _sectionVersion.

  DrumSection getDrumSection() {
    return drumSection;
  }

  ///Set the song's default drum _sectionVersion
  void setDrumSection(DrumSection drumSection) {
    this.drumSection = drumSection;
  }

  /// Compares this object with the specified object for order.  Returns a
  /// negative integer, zero, or a positive integer as this object is less
  /// than, equal to, or greater than the specified object.
  @override
  int compareTo(LyricSection other) {
    int ret = _sectionVersion.compareTo(other._sectionVersion);
    if (ret != 0) {
      return ret;
    }

    if (_lyricsLines.isEmpty) {
      if (other._lyricsLines.isNotEmpty) {
        return -1;
      }
    } else {
      if (other._lyricsLines.isEmpty) {
        return 1;
      }
      if (_lyricsLines.length != other._lyricsLines.length) {
        return _lyricsLines.length - other._lyricsLines.length;
      }
      for (int i = 0; i < _lyricsLines.length; i++) {
        ret = _lyricsLines.elementAt(i).compareTo(other._lyricsLines.elementAt(i));
        if (ret != 0) {
          return ret;
        }
      }
    }
    ret = drumSection.compareTo(other.drumSection);
    if (ret != 0) {
      return ret;
    }
    ret = _sectionVersion.compareTo(other._sectionVersion);
    if (ret != 0) {
      return ret;
    }

    if (!listsEqual(_lyricsLines, other._lyricsLines)) {
      //  compare the lists
      if (_lyricsLines.isEmpty) {
        return other._lyricsLines.isEmpty ? 0 : 1;
      }
      if (other._lyricsLines.isEmpty) {
        return -1;
      }
      if (_lyricsLines.length != other._lyricsLines.length) {
        return _lyricsLines.length < other._lyricsLines.length ? -1 : 1;
      }
      for (int i = 0; i < _lyricsLines.length; i++) {
        int ret = _lyricsLines[i].compareTo(other._lyricsLines[i]);
        if (ret != 0) {
          return ret;
        }
      }
    }
    return 0;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return runtimeType == other.runtimeType &&
        other is LyricSection &&
        _sectionVersion == other._sectionVersion &&
        _index == other._index &&
        drumSection == other.drumSection &&
        listsEqual(_lyricsLines, other._lyricsLines);
  }

  @override
  int get hashCode {
    int ret = Object.hash(_sectionVersion, drumSection, _lyricsLines);
    return ret;
  }

  SectionVersion get sectionVersion => _sectionVersion;
  final SectionVersion _sectionVersion;

  int get index => _index;
  final int _index;
  DrumSection drumSection = DrumSection();

  List<String> get lyricsLines => _lyricsLines;
  final List<String> _lyricsLines = [];
}
