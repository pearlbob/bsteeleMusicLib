import 'chord_section.dart';
import 'chord_section_location.dart';
import 'lyric_section.dart';
import 'measure.dart';
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

  ChordSectionLocation getChordSectionLocation() {
    chordSectionLocation ??=
        ChordSectionLocation(chordSection.sectionVersion, phraseIndex: phraseIndex, measureIndex: measureIndex);
    return chordSectionLocation!;
  }

  @override
  String toString() {
    return '${momentNumber.toString().padLeft(4)}: ${measure.toMarkup().padLeft(10)}'
        ' beat ${beatNumber.toString().padLeft(3)},'
        '${(repeatMax > 1 ? ' $repeat/$repeatMax' : '    ')}'
        ' ${chordSection.sectionVersion} #$sectionCount';
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
  ChordSectionLocation? chordSectionLocation;
  int? row; //  fixme: this is likely useless.  Only valid if display is expanded.
  int? col;
}
