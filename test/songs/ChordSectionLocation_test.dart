import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/ChordSection.dart';
import 'package:bsteeleMusicLib/songs/ChordSectionLocation.dart';
import 'package:bsteeleMusicLib/songs/Measure.dart';
import 'package:bsteeleMusicLib/songs/Section.dart';
import 'package:bsteeleMusicLib/songs/SectionVersion.dart';
import 'package:bsteeleMusicLib/songs/SongBase.dart';
import 'package:bsteeleMusicLib/songs/Key.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test("parse testing", () {
    int beatsPerBar = 4;

    {
      expect(ChordSection.parseString("i:", beatsPerBar).toString().trim(),
          ChordSectionLocation.parseString("i:").toString());
      ChordSectionLocation chordSectionLocation =
          ChordSectionLocation.parseString("i:");
      expect(chordSectionLocation.toString(), "I:");
      expect(chordSectionLocation.isPhrase, isFalse);
      expect(chordSectionLocation.isMeasure, isFalse);

      chordSectionLocation = ChordSectionLocation.parseString("verse2:");
      expect(chordSectionLocation.toString(), "V2:");
      expect(chordSectionLocation.isPhrase, isFalse);
      expect(chordSectionLocation.isMeasure, isFalse);

      chordSectionLocation = ChordSectionLocation.parseString("verse2:0");
      expect(chordSectionLocation.toString(), "V2:0");
      expect(chordSectionLocation.isPhrase, isTrue);
      expect(chordSectionLocation.isMeasure, isFalse);

      chordSectionLocation = ChordSectionLocation.parseString("verse2:0:12");
      expect(chordSectionLocation.toString(), "V2:0:12");
      expect(chordSectionLocation.isPhrase, isFalse);
      expect(chordSectionLocation.isMeasure, isTrue);
    }

    for (Section section in Section.values) {
      for (int v = 1; v <= 4; v++) {
        for (int phraseIndex = 1; phraseIndex <= 3; phraseIndex++) {
          SectionVersion sectionVersion = SectionVersion(section, v);
          for (int index = 1; index <= 40; index++) {
            ChordSectionLocation chordSectionLocationExpected =
                ChordSectionLocation(sectionVersion,
                    phraseIndex: phraseIndex, measureIndex: index);
            ChordSectionLocation chordSectionLocation =
                ChordSectionLocation.parseString(sectionVersion.id.toString() +
                    ":" +
                    phraseIndex.toString() +
                    ":" +
                    index.toString());
            logger.d(chordSectionLocationExpected.toString());
            expect(chordSectionLocation, chordSectionLocationExpected);
          }
        }
      }
    }

    for (Section section in Section.values) {
      for (int v = 1; v <= 4; v++) {
        for (int phraseIndex = 1; phraseIndex <= 3; phraseIndex++) {
          SectionVersion sectionVersion = SectionVersion(section, v);
          for (int index = 1; index <= 40; index++) {
            ChordSectionLocation chordSectionLocationExpected =
                ChordSectionLocation(sectionVersion,
                    phraseIndex: phraseIndex, measureIndex: index);
            logger.i("chordSectionLocationExpected: " +
                chordSectionLocationExpected.toString());
            ChordSectionLocation chordSectionLocation =
                ChordSectionLocation.parseString(
                    chordSectionLocationExpected.toString());
            logger.d(chordSectionLocationExpected.toString());
            expect(chordSectionLocation, chordSectionLocationExpected);
          }
        }
      }
    }
  });

  /**
   * find the chord section in the song
   */
  test("find testing", () {
    int beatsPerBar = 4;
    SongBase a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "i: A B C D V: D E F F# " +
            "v1:    Em7 E E G \n" +
            "       C D E Eb7 x2\n" +
            "v2:    A B C D |\n" +
            "       E F G7 G#m | x2\n" +
            "       D C GB GbB \n" +
            "C: F F# G G# Ab A O: C C C C B",
        "i:\nv: bob, bob, bob berand\nv1: lala \nv2: sosos \nc: sing chorus here \no:");
    Section section = Section.get(SectionEnum.verse);
    int v = 1;
    SectionVersion sectionVersion = SectionVersion(section, v);

    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 0)),
        Measure.parseString("Em7", beatsPerBar));
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 3)),
        Measure.parseString("G", beatsPerBar, endOfRow: true));
    expect(
        Measure.parseString("Eb7", beatsPerBar),
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 1, measureIndex: 3)));
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 9)),
        isNull);

    sectionVersion = SectionVersion.parseString("v2:");
    expect(
        Measure.parseString("A", beatsPerBar),
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 0)));
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 3)),
        Measure.parseString("D", beatsPerBar, endOfRow: true));
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 7)),
        Measure.parseString("G#m", beatsPerBar));
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 1, measureIndex: 3)),
        Measure.parseString("GbB", beatsPerBar, endOfRow: true));
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 1, measureIndex: 4)),
        isNull);
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 1, measureIndex: 4234)),
        isNull);

    //  no Ch2:
    section = Section.get(SectionEnum.chorus);
    sectionVersion = SectionVersion(section, v);
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 0)),
        isNull);

    sectionVersion = SectionVersion(section, 0);
    expect(
        Measure.parseString("F", beatsPerBar),
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 0)));

    sectionVersion = SectionVersion(Section.get(SectionEnum.outro), 0);
    expect(
        Measure.parseString("B", beatsPerBar),
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 4)));
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion,
            phraseIndex: 0, measureIndex: 5)),
        isNull);
  });
}
