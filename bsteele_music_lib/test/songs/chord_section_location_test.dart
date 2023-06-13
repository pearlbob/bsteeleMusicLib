import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/songs/chord_section.dart';
import 'package:bsteele_music_lib/songs/chord_section_location.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/measure.dart';
import 'package:bsteele_music_lib/songs/section.dart';
import 'package:bsteele_music_lib/songs/section_version.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test('parse testing', () {
    int beatsPerBar = 4;

    {
      expect(ChordSection.parseString('i:', beatsPerBar).toString().trim(),
          ChordSectionLocation.parseString('i:').toString());
      ChordSectionLocation chordSectionLocation = ChordSectionLocation.parseString('i:');
      expect(chordSectionLocation.toString(), 'I:');
      expect(chordSectionLocation.isPhrase, isFalse);
      expect(chordSectionLocation.isMeasure, isFalse);

      chordSectionLocation = ChordSectionLocation.parseString('verse2:');
      expect(chordSectionLocation.toString(), 'V2:');
      expect(chordSectionLocation.isPhrase, isFalse);
      expect(chordSectionLocation.isMeasure, isFalse);

      chordSectionLocation = ChordSectionLocation.parseString('verse2:0');
      expect(chordSectionLocation.toString(), 'V2:0');
      expect(chordSectionLocation.isPhrase, isTrue);
      expect(chordSectionLocation.isMeasure, isFalse);

      chordSectionLocation = ChordSectionLocation.parseString('verse2:0:12');
      expect(chordSectionLocation.toString(), 'V2:0:12');
      expect(chordSectionLocation.isPhrase, isFalse);
      expect(chordSectionLocation.isMeasure, isTrue);
    }

    for (Section section in Section.values) {
      for (int v = 1; v <= 4; v++) {
        for (int phraseIndex = 1; phraseIndex <= 3; phraseIndex++) {
          SectionVersion sectionVersion = SectionVersion(section, v);
          for (int index = 1; index <= 40; index++) {
            ChordSectionLocation chordSectionLocationExpected =
                ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex, measureIndex: index);
            ChordSectionLocation chordSectionLocation =
                ChordSectionLocation.parseString('${sectionVersion.id}:$phraseIndex:$index');
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
                ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex, measureIndex: index);
            logger.i('chordSectionLocationExpected: $chordSectionLocationExpected');
            ChordSectionLocation chordSectionLocation =
                ChordSectionLocation.parseString(chordSectionLocationExpected.toString());
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
  test('find testing', () {
    int beatsPerBar = 4;
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'i: A B C D V: D E F F# '
            'v1:    Em7 E E G \n'
            '       C D E Eb7 x2\n'
            'v2:    A B C D |\n'
            '       E F G7 G#m | x2\n'
            '       D C GB GbB \n'
            'C: F F# G G# Ab A Bb B C O: C C C C B',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv1: lala \nv2: sosos \nc: sing chorus here \no:');
    Section section = Section.get(SectionEnum.verse);
    int v = 1;
    SectionVersion sectionVersion = SectionVersion(section, v);

    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 0)),
        Measure.parseString('Em7', beatsPerBar));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 3)),
        Measure.parseString('G', beatsPerBar));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 1, measureIndex: 3)),
        Measure.parseString('Eb7', beatsPerBar));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 9)), isNull);

    sectionVersion = SectionVersion.parseString('v2:');
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 0)),
        Measure.parseString('A', beatsPerBar));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 3)),
        Measure.parseString('D', beatsPerBar, endOfRow: true));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 7)),
        Measure.parseString('G#m', beatsPerBar));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 1, measureIndex: 3)),
        Measure.parseString('GbB', beatsPerBar));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 1, measureIndex: 4)), isNull);
    expect(
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 1, measureIndex: 4234)), isNull);

    //  no Ch1:
    section = Section.get(SectionEnum.chorus);
    sectionVersion = SectionVersion(section, v);
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 0)), isNull);

    sectionVersion = SectionVersion(section, 0);
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 0)),
        Measure.parseString('F', beatsPerBar));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 3)),
        Measure.parseString('G#', beatsPerBar, endOfRow: true)); //  test forced end of row
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 7)),
        Measure.parseString('B', beatsPerBar, endOfRow: true)); //  test forced end of row
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 8)),
        Measure.parseString('C', beatsPerBar)); //  no end of row

    sectionVersion = SectionVersion(Section.get(SectionEnum.outro), 0);
    expect(Measure.parseString('B', beatsPerBar),
        a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 4)));
    expect(a.findMeasureNodeByLocation(ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: 5)), isNull);
  });

  test('ChordSectionLocation.fromString testing', () {
    Logger.level = Level.info;
    ChordSectionLocation loc;

    expect(ChordSectionLocation.fromString('asdf:3:3'), isNull);
    expect(ChordSectionLocation.fromString('V:3k:3'), isNull);
    expect(ChordSectionLocation.fromString('V:3:3x'), isNull);
    expect(ChordSectionLocation.fromString('V:3:3:x4'), isNull);

    for (var sectionEnum in SectionEnum.values) {
      var section = Section.get(sectionEnum);
      for (var version = 0; version < 10; version++) {
        var sectionVersion = SectionVersion(section, version);
        loc = ChordSectionLocation(sectionVersion);
        expect(ChordSectionLocation.fromString(loc.toString()), loc);
        for (var phraseIndex = 0; phraseIndex <= 4; phraseIndex++) {
          loc = ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex);
          expect(ChordSectionLocation.fromString(loc.toString()), loc);
          for (var measureIndex = 0; measureIndex <= 4; measureIndex++) {
            loc = ChordSectionLocation(sectionVersion, phraseIndex: phraseIndex, measureIndex: measureIndex);
            expect(ChordSectionLocation.fromString(loc.toString()), loc);
          }
        }
      }
    }
  });
}
