import 'dart:math';

import 'chord_section.dart';
import 'key.dart';
import 'measure_node.dart';
import 'package:quiver/collection.dart';

import '../app_logger.dart';
import 'drum_section.dart';
import 'lyric.dart';
import 'section_version.dart';

/// A sectionVersion of a song that carries the lyrics, any special drum sectionVersion,
/// and the chord changes on a measure basis
/// with ultimately beat resolution.

class LyricSection extends MeasureNode implements Comparable<LyricSection> {
  LyricSection(this.sectionVersion, this.index);

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

  /// Split the lyric section into rows for the given chord section and row count
  List<Lyric> asBundledLyrics(ChordSection chordSection, int rows) {
    rows = max(rows, 1);
    int linesPerRow = _lyricsLines.length ~/ rows;
    int lineExtras = _lyricsLines.length % rows;
    var lineCount = 0;
    String lyricString = '';
    int phraseIndex = 0;
    int repeat = 0;
    var phrases = chordSection.phrases;
    assert(phrases.isNotEmpty);
    var phrase = phrases.first;
    var phraseRow = 0;
    List<Lyric> lyrics = [];

    for (var i = 0; i < _lyricsLines.length; i++) {
      //  accumulate the lines into rows
      lyricString += (lyricString.isNotEmpty ? '\n' : '') + _lyricsLines[i];
      lineCount++;

      //  when the row is full, create a lyric measure node for them
      if (lineCount >= linesPerRow + (lineExtras > 0 ? 1 : 0)) {
        lyrics.add(Lyric(lyricString, phraseIndex: phraseIndex, repeat: repeat));
        lyricString = '';
        lineCount = 0;
        lineExtras = max(0, lineExtras - 1);

        //  keep track of the current phrase and repeat for the next lyric row
        phraseRow++;
        if (phraseRow >= phrase.phraseRowCount) {
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

  /// Return the lyric section as rows for each lyric line
  List<Lyric> asLyrics(ChordSection chordSection, int rows) {
    rows = max(rows, 1);
    int phraseIndex = 0;
    int repeat = 0;
    var phrases = chordSection.phrases;
    assert(phrases.isNotEmpty);
    var phrase = phrases.first;
    var phraseRow = 0;
    List<Lyric> lyrics = [];

    for (var i = 0; i < _lyricsLines.length; i++) {
      //  create a lyric measure node for each lyric line
      lyrics.add(Lyric(_lyricsLines[i], phraseIndex: phraseIndex, repeat: repeat));

      //  keep track of the current phrase and repeat for the next lyric row
      phraseRow++;
      if (phraseRow >= phrase.repeatRowCount) {
        phraseRow = 0;
        repeat++;
        if (repeat >= phrase.repeats && !identical(phrase, phrases.last)) {
          phraseIndex++;
          repeat = 0;
          phrase = phrases[phraseIndex];
        }
      }
    }
    return lyrics;
  }

  @override
  MeasureNodeType get measureNodeType => .lyricSection;

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
  String toJsonString() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  String toMarkup({bool expanded = false, bool withInversion = true}) {
    return toString();
  }

  @override
  String toMarkupWithoutEnd() {
    return toString();
  }

  @override
  String transpose(MajorKey key, int halfSteps) {
    return toString();
  }

  @override
  MeasureNode transposeToKey(MajorKey key) {
    return this;
  }

  @override
  String toString() {
    return '${sectionVersion.toString()}#$index';
  }

  @override
  String toNashville(MajorKey key) {
    return ''; //  no lyrics in Nashville!
  }

  /// Get the song's default drum sectionVersion.
  /// The sectionVersion will be played through all of its measures
  /// and then repeated as required for the sectionVersion's duration.
  /// When done, the drums will default back to the song's default drum sectionVersion.

  DrumSection getDrumSection() {
    return drumSection;
  }

  ///Set the song's default drum sectionVersion
  void setDrumSection(DrumSection drumSection) {
    this.drumSection = drumSection;
  }

  /// Compares this object with the specified object for order.  Returns a
  /// negative integer, zero, or a positive integer as this object is less
  /// than, equal to, or greater than the specified object.
  @override
  int compareTo(LyricSection other) {
    int ret = sectionVersion.compareTo(other.sectionVersion);
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
    ret = sectionVersion.compareTo(other.sectionVersion);
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
        sectionVersion == other.sectionVersion &&
        index == other.index &&
        drumSection == other.drumSection &&
        listsEqual(_lyricsLines, other._lyricsLines);
  }

  @override
  int get hashCode {
    int ret = Object.hash(sectionVersion, drumSection, _lyricsLines);
    return ret;
  }

  final SectionVersion sectionVersion;

  final int index;
  DrumSection drumSection = DrumSection();

  List<String> get lyricsLines => _lyricsLines;
  final List<String> _lyricsLines = [];
}
