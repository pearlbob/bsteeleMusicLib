import 'package:quiver/core.dart';

import 'ChordSection.dart';
import 'ChordSectionLocation.dart';
import 'LyricSection.dart';
import 'Measure.dart';
import 'MeasureNode.dart';
import 'Phrase.dart';

class SongMoment implements Comparable<SongMoment> {
  SongMoment(
      this.momentNumber,
      this.beatNumber,
      this.sectionBeatNumber,
      this.lyricSection,
      this.chordSection,
      this.phraseIndex,
      this.phrase,
      this.measureIndex,
      this.measure,
      this.repeat,
      this.repeatCycleBeats,
      this.repeatMax,
      this.sectionCount);

  int getMomentNumber() {
    return momentNumber;
  }

  int getBeatNumber() {
    return beatNumber;
  }

  int getSectionBeatNumber() {
    return sectionBeatNumber;
  }

  LyricSection getLyricSection() {
    return lyricSection;
  }

  ChordSection getChordSection() {
    return chordSection;
  }

  @deprecated
  MeasureNode getPhrase() {
    return phrase;
  }

  int getPhraseIndex() {
    return phraseIndex;
  }

  int getMeasureIndex() {
    return measureIndex;
  }

  Measure getMeasure() {
    return measure;
  }

  int getRepeat() {
    return repeat;
  }

  int getRepeatCycleBeats() {
    return repeatCycleBeats;
  }

  int getRepeatMax() {
    return repeatMax;
  }

  int getSectionCount() {
    return sectionCount;
  }

  ChordSectionLocation getChordSectionLocation() {
    if (chordSectionLocation == null)
      chordSectionLocation = new ChordSectionLocation(
          chordSection.getSectionVersion(),
          phraseIndex: phraseIndex,
          measureIndex: measureIndex);
    return chordSectionLocation;
  }

  String get momentLocation =>
      getChordSectionLocation().toString() + "#" + sectionCount.toString();

  @override
  String toString() {
    return momentNumber.toString() +
        ": " +
        momentLocation +
        " " +
        measure.toMarkup() +
        " beat " +
        getBeatNumber().toString() +
        (repeatMax > 1
            ? " " + repeat.toString() + "/" + repeatMax.toString()
            : "");
  }

  @override
  int compareTo(SongMoment o) {
    //  number should be unique for a given song
    if (momentNumber == o.momentNumber) return 0;
    return momentNumber < o.momentNumber ? -1 : 1;
  }

//  @override
//  int compareTo(SongMoment other) {
//    int ret = momentNumber.compareTo(other.momentNumber);
//    if (ret != 0) return ret;
//    ret = _phraseIndex - other._phraseIndex;
//    if (ret != 0) return ret;
//    ret = _measureIndex - other._measureIndex;
//    if (ret != 0) return ret;
//
//    if (_labelSectionVersions == null)
//      return other._labelSectionVersions == null ? 0 : -1;
//    if (other._labelSectionVersions == null) return 1;
//
//    ret = _labelSectionVersions.length - other._labelSectionVersions.length;
//    if (ret != 0) return ret;
//    if (_labelSectionVersions.isNotEmpty) {
//      for (int i = 0; i < _labelSectionVersions.length; i++) {
//        ret = _labelSectionVersions
//            .elementAt(i)
//            .compareTo(other._labelSectionVersions.elementAt(i));
//        if (ret != 0) return ret;
//      }
//    }
//    return 0;
//  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return (other is SongMoment &&
        momentNumber == other.momentNumber &&
        chordSectionLocation == other.chordSectionLocation &&
        beatNumber == other.beatNumber &&
        sectionBeatNumber == other.sectionBeatNumber &&
        repeat == other.repeat &&
        repeatMax == other.repeatMax &&
        repeatCycleBeats == other.repeatCycleBeats &&
        lyricSection == other.lyricSection &&
        chordSection == other.chordSection &&
        phraseIndex == other.phraseIndex &&
        phrase == other.phrase &&
        measureIndex == other.measureIndex &&
        measure == other.measure &&
        sectionCount == other.sectionCount &&
        row == other.row);
  }

  @override
  int get hashCode {
    //  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
    int ret = hash3(momentNumber, beatNumber, sectionBeatNumber);
    ret = ret * 13 + hash3(repeat, repeatMax, repeatCycleBeats);
    ret = ret * 17 + hash3(phraseIndex, measureIndex, sectionCount);
    ret = ret * 19 + chordSectionLocation.hashCode;
    ret = ret * 23 + lyricSection.hashCode;
    ret = ret * 29 + chordSection.hashCode;
    ret = ret * 31 + phrase.hashCode;
    ret = ret * 37 + measure.hashCode;
    ret = ret * 41 + row.hashCode;

    return ret;
  }

  final int momentNumber;
  ChordSectionLocation chordSectionLocation;

  ///  total beat count from start of song to the start of the moment
  final int beatNumber;

  ///  total beat count from start of the current section to the start of the moment
  final int sectionBeatNumber;

  ///  current iteration from 0 to repeatMax - 1
  final int repeat;
  final int repeatMax;

  ///  number of beats in one cycle of the repeat
  final int repeatCycleBeats;

  final LyricSection lyricSection;
  final ChordSection chordSection;
  final int phraseIndex;
  final Phrase phrase;
  final int measureIndex;
  final Measure measure;
  final int sectionCount;

  String lyrics;
  int row;
}
