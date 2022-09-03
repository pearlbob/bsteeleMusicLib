import 'chordSection.dart';
import 'chordSectionLocation.dart';
import 'lyricSection.dart';
import 'measure.dart';
import 'measureNode.dart';
import 'phrase.dart';

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
      this.sectionCount,
      this.chordSectionSongMomentNumber);

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
    chordSectionLocation ??=
        ChordSectionLocation(chordSection.sectionVersion, phraseIndex: phraseIndex, measureIndex: measureIndex);
    return chordSectionLocation!;
  }

  String get momentLocation => getChordSectionLocation().toString() + '#' + sectionCount.toString();

  @override
  String toString() {
    return '$momentNumber: $momentLocation  ${measure.toMarkup()}'
        ' beat  ${getBeatNumber()}'
        '${(repeatMax > 1 ? ' ' + repeat.toString() + '/' + repeatMax.toString() : '')}'
        ' ${chordSection.sectionVersion} #${sectionCount}';
  }

  @override
  int compareTo(SongMoment o) {
    //  number should be unique for a given song
    if (momentNumber == o.momentNumber) {
      return 0;
    }
    return momentNumber < o.momentNumber ? -1 : 1;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    return (runtimeType == other.runtimeType &&
        other is SongMoment &&
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
    return momentNumber; //  all else is dependent on the song
  }

  final int momentNumber;
  ChordSectionLocation? chordSectionLocation;

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
  final int sectionCount; //  of this type of section
  final int chordSectionSongMomentNumber;

  String? lyrics;
  int? row;
  int? col;
}
