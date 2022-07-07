import 'chordSection.dart';
import 'chordSectionLocation.dart';
import 'measure.dart';
import 'measureRepeatExtension.dart';
import 'phrase.dart';
import 'sectionVersion.dart';
import 'key.dart' as music_key;

class ChordSectionGridData {
  ChordSectionGridData(this.chordSectionLocation, this.chordSection, this.phrase, this.measure) {
    //  assure data was set properly
    assert(isSection == (phrase == null));

    //  sanity checks during testing
    if (isMarker) {
      assert(chordSectionLocation.marker != ChordSectionLocationMarker.none);
      assert(phrase != null);
      assert(measure != null); //  marker is after an explicit end of a repeat
    } else if (isRepeat) {
      assert(phrase != null);
      assert(measure != null);
    } else if (isPhrase) {
      assert(phrase != null);
      assert(measure == null);
    } else if (isMeasure) {
      assert(phrase != null);
      assert(measure != null);
    } else if (isSection) {
      assert(phrase == null);
      assert(measure == null);
    } else {
      assert(false);
    }
  }

  //  convenience methods
  bool get isSection => chordSectionLocation.isSection;

  bool get isPhrase => chordSectionLocation.isPhrase;

  bool get isRepeat => chordSectionLocation.isRepeat;

  bool get isMeasure => chordSectionLocation.isMeasure;

  bool get isMarker => chordSectionLocation.isMarker;

  SectionVersion get sectionVersion => chordSection.sectionVersion;

  String transpose(final music_key.Key key, final int halfSteps) {
    if (isSection) {
      return chordSectionLocation.sectionVersion.toString();
    }
    if (isMeasure) {
      return measure!.transpose(key, halfSteps);
    }
    if (isMarker) {
      return MeasureRepeatExtension.get(chordSectionLocation.marker).toString();
    }
    if (isRepeat) {
      return 'x${chordSectionLocation.repeats}';
    }
    return 'fixme';
  }

  @override
  String toString() {
    return '(${chordSectionLocation} ${sectionVersion} \'${phrase?.toMarkup()}\':'
        ' ${(measure != null && isMeasure) ? measure?.toMarkupWithoutEnd() : ''})';
  }

  final ChordSectionLocation chordSectionLocation;
  final ChordSection chordSection;
  final Phrase? phrase;
  final Measure? measure;
}
