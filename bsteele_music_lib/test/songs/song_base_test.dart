import 'dart:collection';
import 'dart:math';

import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/grid.dart';
import 'package:bsteele_music_lib/grid_coordinate.dart';
import 'package:bsteele_music_lib/songs/chord_section.dart';
import 'package:bsteele_music_lib/songs/chord_section_grid_data.dart';
import 'package:bsteele_music_lib/songs/chord_section_location.dart';
import 'package:bsteele_music_lib/songs/key.dart' as music_key;
import 'package:bsteele_music_lib/songs/lyric.dart';
import 'package:bsteele_music_lib/songs/lyric_section.dart';
import 'package:bsteele_music_lib/songs/measure.dart';
import 'package:bsteele_music_lib/songs/measure_node.dart';
import 'package:bsteele_music_lib/songs/music_constants.dart';
import 'package:bsteele_music_lib/songs/phrase.dart';
import 'package:bsteele_music_lib/songs/scale_note.dart';
import 'package:bsteele_music_lib/songs/section.dart';
import 'package:bsteele_music_lib/songs/section_version.dart';
import 'package:bsteele_music_lib/songs/song.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:bsteele_music_lib/songs/song_moment.dart';
import 'package:bsteele_music_lib/songs/time_signature.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

bool _printOnly = false; //  used to generate diagnostic data

String chordSectionToMultiLineString(SongBase song) {
  Grid<ChordSectionGridData> grid = song.getChordSectionGrid();
  StringBuffer sb = StringBuffer('Grid{\n');

  int rLimit = grid.getRowCount();
  for (int r = 0; r < rLimit; r++) {
    List<ChordSectionGridData?>? row = grid.getRow(r);
    if (row == null) {
      throw 'row == null';
    }
    int colLimit = row.length;
    sb.write('\t[');
    for (int c = 0; c < colLimit; c++) {
      ChordSectionGridData? data = row[c];
      if (data == null) {
        sb.write('\tnull\n');
        continue;
      }

      sb.write('\t$data ');
      if (data.isMeasure) {
        Measure? measure = song.findMeasureByChordSectionLocation(data.chordSectionLocation);
        if (measure == null) {
          throw 'measure == null';
        }
        sb.write('measure: "${measure.toMarkup()}"'
            '${measure.endOfRow ? ', endOfRow' : ''}'
            '${measure.isRepeat() ? ', repeat' : ''}'
            //
            );
      }
      sb.write('\n');
    }
    sb.write('\t]\n');
  }
  sb.write('}');
  return sb.toString();
}

void main() {
  Logger.level = Level.info;

  test('testEquals', () {
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');
    SongBase b = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');

    expect(a == a, isTrue);
    expect(a.hashCode == a.hashCode, isTrue);
    expect(a == b, isTrue);
    expect(a.hashCode == b.hashCode, isTrue);
    b = SongBase(
        title: 'B',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');

    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
    b = SongBase(
        title: 'A',
        artist: 'bobby',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
    b = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'photos.bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');
    logger.d('a.getSongId(): ${a.getSongId().hashCode}');
    logger.d('b.getSongId(): ${b.getSongId().hashCode}');
    expect(a.getSongId().compareTo(b.getSongId()), 0);
    expect(a.getSongId(), b.getSongId());
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.get(music_key.KeyEnum.Ab),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 102,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 3,
        unitsPerMeasure: 8,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    //top
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 8,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A A C D',
        rawLyrics: 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C DD',
        rawLyrics: 'v: bob, bob, bob berand.');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
  });

  test('testCurrentLocation', () {
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'I:v: A BCm7/ADE C D',
        rawLyrics: 'I:v: bob, bob, bob berand');

    expect(MeasureEditType.append, a.currentMeasureEditType);
    logger.d(a.getCurrentChordSectionLocation().toString());

    expect(a.getCurrentMeasureNode(), Measure.parseString('D', a.beatsPerBar));
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:0'));
    expect(a.getCurrentMeasureNode(), Measure.parseString('A', a.beatsPerBar));
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:1'));
    expect(Measure.parseString('BCm7/ADE', a.beatsPerBar), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:3')); //  move to end
    expect(Measure.parseString('D', a.beatsPerBar), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:0'));
    expect(Measure.parseString('A', a.beatsPerBar), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:5')); //  refuse to move past end
    expect(Measure.parseString('D', a.beatsPerBar), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:3')); //  move to end
    expect(Measure.parseString('D', a.beatsPerBar), a.getCurrentMeasureNode());

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 8,
        chords: 'I:v: A B C D ch3: [ E F G A ] x4 A# C D# F',
        rawLyrics: 'I:v: bob, bob, bob berand');
    expect(a.currentMeasureEditType, MeasureEditType.append);
    a.setDefaultCurrentChordLocation();
    expect(a.getCurrentMeasureNode(), Measure.parseString('F', a.beatsPerBar));
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:0'));
    expect(Measure.parseString('A', a.beatsPerBar), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:3234234')); //  move to end
    expect(Measure.parseString('D', a.beatsPerBar), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:0'));
    expect(Measure.parseString('A', a.beatsPerBar), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('c3:1:0'));
    expect(Measure.parseString('A#', a.beatsPerBar), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('c3:1:3')); //  move to end
    expect(Measure.parseString('F', a.beatsPerBar), a.getCurrentMeasureNode());
    ChordSection cs = ChordSection.parseString('c3:', a.beatsPerBar);
    ChordSection? chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    expect(cs.sectionVersion, chordSection!.sectionVersion);
  });

  test('test basics', () {
    SongBase a;

    {
      //  trivial first!
      a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 8,
          chords: 'I: A B C D v: D C G G',
          rawLyrics: 'I:v: bob, bob, bob berand');

      SplayTreeSet<ChordSection> chordSections = SplayTreeSet<ChordSection>.of(a.getChordSections());
      ChordSection chordSection = chordSections.first;
      Phrase phrase = chordSection.phrases[0];

      Measure measure = phrase.measures[1];
      expect(phrase.measures.length, 4);
      expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.B);
    }
    {
      a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 8,
          chords: 'I:v: A B C D',
          rawLyrics: 'I:v: bob, bob, bob berand');
      SplayTreeSet<ChordSection> chordSections = SplayTreeSet<ChordSection>.of(a.getChordSections());
      ChordSection chordSection = chordSections.first;
      Phrase phrase = chordSection.phrases[0];

      Measure measure = phrase.measures[1];
      expect(phrase.measures.length, 4);
      expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.B);
    }

    for (int i = 50; i < 401; i++) {
      a.setBeatsPerMinute(i);
      expect(a.beatsPerMinute, i);
    }
  });

  test('testChordSectionEntry', () {
    {
      //  empty sections
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: v: t:',
          rawLyrics: 'i: dude v: bob, bob, bob berand');

      expect(
        a.toMarkup().trim(),
        'I: []  V: []  T: []',
      );
      expect(a.editList(a.parseChordEntry('t: G G C G')), isTrue);
      expect(a.toMarkup().trim(), 'I: []  V: []  T: G G C G');
      expect(a.editList(a.parseChordEntry('I: V:  A B C D')), isTrue);
      expect(
        a.toMarkup().trim(),
        'I: V: A B C D  T: G G C G',
      );

      expect(
        a.findChordSectionByString('I:')!.toMarkup().trim(),
        'I: A B C D',
      );
      expect(
        a.findChordSectionByString('V:')!.toMarkup().trim(),
        'V: A B C D',
      );
      expect(a.findChordSectionByString('T:')!.toMarkup().trim(), 'T: G G C G');

      //  auto rows of 4 when 8 or more measures entered at once
      a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: v: t:',
          rawLyrics: 'i: dude v: bob, bob, bob berand');

      expect(a.editList(a.parseChordEntry('I: A B C D A B C D')), isTrue);

      expect(
        a.findChordSectionByString('I:')!.toMarkup().trim(),
        'I: A B C D, A B C D,',
      );
    }
    {
      //  empty sections
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: v: t:',
          rawLyrics: 'i: dude v: bob, bob, bob berand');

      expect(
        a.toMarkup().trim(),
        'I: []  V: []  T: []',
      );
      var e = SongBase.entryToUppercase('v: a b c d, e e e e/a');
      expect(e, 'v: A B C D, E E E E/A');
      expect(a.editList(a.parseChordEntry(e)), isTrue);
      expect(a.toMarkup().trim(), 'I: []  V: A B C D, E E E E/A  T: []');
      expect(a.editList(a.parseChordEntry('I: V:  A B C D')), isTrue);
    }

    {
      //  multiple sections
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'v:',
          rawLyrics: 'v: bob, bob, bob berand');

      expect(a.toMarkup().trim(), 'V: []');
      var e = SongBase.entryToUppercase('i:v: a b c d, e e e e/a');
      expect(e, 'i:v: A B C D, E E E E/A');
      expect(a.editList(a.parseChordEntry(e)), isTrue);
      expect(a.toMarkup().trim(), 'I: V: A B C D, E E E E/A');
      expect(a.editList(a.parseChordEntry('I: A A A A')), isTrue);
      expect(a.toMarkup().trim(), 'I: A A A A  V: A B C D, E E E E/A');
    }

    {
      //  multiple sections
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'v:',
          rawLyrics: 'v: bob, bob, bob berand');

      expect(a.toMarkup().trim(), 'V: []');
      var e = SongBase.entryToUppercase('i:v: a b c d, e e e e/a  c: D c g a/g');
      expect(e, 'i:v: A B C D, E E E E/A  C: D C G A/G');
      expect(
          a.parseChordEntry(e).toString(),
          '[I:\n'
          'A B C D, E E E E/A \n'
          ', V:\n'
          'A B C D, E E E E/A \n'
          ', C:\n'
          'D C G A/G \n'
          ']');
      expect(a.editList(a.parseChordEntry(e)), isTrue);
      expect(a.toMarkup().trim(), 'I: V: A B C D, E E E E/A  C: D C G A/G');
      expect(a.editList(a.parseChordEntry('I: A A A A')), isTrue);
      expect(a.toMarkup().trim(), 'I: A A A A  V: A B C D, E E E E/A  C: D C G A/G');
    }

    {
      //  unchanged by repetition
      var e = SongBase.entryToUppercase('i:v: abb b c d#/b, e e esus7 e/a  c: D c g a/g');
      expect(e, 'i:v: AbB B C D#/B, E E Esus7 E/A  C: D C G A/G');
      e = SongBase.entryToUppercase(e);
      expect(e, 'i:v: AbB B C D#/B, E E Esus7 E/A  C: D C G A/G');
    }
  });

  test('testFind', () {
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'i: A B C D v: E F G A# t: Gm Gm',
        rawLyrics: 'i: dude v: bob, bob, bob berand');

    expect(a.findChordSectionByString('ch:'), isNull);
    ChordSection? chordSection = a.findChordSectionByString('i:');
    logger.d(chordSection!.toMarkup());
    expect('I: A B C D ', chordSection.toMarkup());

    chordSection = a.findChordSectionByString('v:');
    logger.d(chordSection!.toMarkup());
    logger.d(a.findChordSectionByString('v:')!.toMarkup());
    expect(chordSection.toMarkup(), 'V: E F G A# ');

    chordSection = a.findChordSectionByString('t:');
    logger.d(chordSection!.toMarkup());
    logger.d(a.findChordSectionByString('t:')!.toMarkup());
    expect('T: Gm Gm ', chordSection.toMarkup());

//            logger.d(a.findMeasureNodeByGrid("i:1"));
//            logger.d(a.findMeasureNodeByGrid("i:3"));
  });

  test('testSetRepeats', () {
    {
      //  set first row as a repeat
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: A B C D v: E F G A#',
          rawLyrics: 'i: v: bob, bob, bob berand');

      var gridCoordinate = const GridCoordinate(0, 4);
      ChordSectionLocation? chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
      a.setCurrentChordSectionLocation(chordSectionLocation);
      logger.d(chordSectionLocation.toString());
      a.setRepeat(chordSectionLocation!, 2);
      logger.i(a.toMarkup());
      expect(a.toMarkup().trim(), 'I: [A B C D ] x2  V: E F G A#');
      expect(a.currentChordSectionLocation, chordSectionLocation);

      //  remove the repeat
      chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
      a.setRepeat(chordSectionLocation!, 1);
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A#');
      expect(a.currentChordSectionLocation, chordSectionLocation);
    }

    {
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: A B C D v: E F G A#',
          rawLyrics: 'i: v: bob, bob, bob berand');

      logger.d(a.logGrid());
      Grid<ChordSectionGridData> grid;

      grid = a.getChordSectionGrid();
      //  set first row as a repeat from any measure
      for (int row = 0; row < grid.getRowCount(); row++) {
        a = SongBase(
            title: 'A',
            artist: 'bob',
            copyright: 'bsteele.com',
            key: music_key.Key.getDefault(),
            beatsPerMinute: 100,
            beatsPerBar: 4,
            unitsPerMeasure: 4,
            chords: 'i: A B C D v: E F G A#',
            rawLyrics: 'i: v: bob, bob, bob berand');

        grid = a.getChordSectionGrid();
        List<ChordSectionGridData?>? cols = grid.getRow(row);
        if (cols != null) {
          for (int col = 1; col < cols.length; col++) {
            for (int r = 6; r > 1; r--) {
              var gridCoordinate = GridCoordinate(row, 4);
              ChordSectionLocation? chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
              assert(chordSectionLocation != null);
              logger.d('chordSectionLocation: $chordSectionLocation');
              a.setCurrentChordSectionLocation(chordSectionLocation);
              a.setRepeat(chordSectionLocation!, r);
              String s = a.toMarkup().trim();
              logger.d(s);
              if (row == 0) {
                expect(s, 'I: [A B C D ] x$r  V: E F G A#');
              } else {
                expect(s, 'I: A B C D  V: [E F G A# ] x$r');
              }
              expect(a.currentChordSectionLocation, chordSectionLocation);
            }
          }
        }
      }
    }

    for (var measureIndex = 0; measureIndex < 4; measureIndex++) {
      //  repeat a row at the start of a phrase
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: A B C D v: E F G A#, B C C# D, D# E F F#, G o: D E F G',
          rawLyrics: 'i: v: bob, bob, bob berand');

      var gridCoordinate = GridCoordinate(1, 1 + measureIndex);
      ChordSectionLocation? chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
      assert(chordSectionLocation != null);
      logger.d(chordSectionLocation.toString());
      a.setCurrentChordSectionLocation(chordSectionLocation);
      a.setRepeat(chordSectionLocation!, 2);
      logger.i(a.toMarkup());
      expect(a.toMarkup().trim(), 'I: A B C D  V: [E F G A# ] x2 B C C# D, D# E F F#, G  O: D E F G');
      chordSectionLocation = ChordSectionLocation(chordSectionLocation.sectionVersion, phraseIndex: 0, measureIndex: 3);
      expect(a.currentChordSectionLocation, chordSectionLocation);

      //  remove the repeat
      var loc = a.findChordSectionLocationByGrid(gridCoordinate);
      assert(loc != null);
      logger.d('loc: $loc');
      a.setRepeat(loc!.asPhraseLocation()!, 1);
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A#, B C C# D, D# E F F#, G  O: D E F G');
      expect(a.currentChordSectionLocation,
          ChordSectionLocation(chordSectionLocation.sectionVersion, phraseIndex: 0, measureIndex: 3));
    }

    for (var measureIndex = 4; measureIndex < 8; measureIndex++) {
      //  repeat a row in the middle of a phrase
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: A B C D v: E F G A#, B C C# D, D# E F F#, G o: D E F G',
          rawLyrics: 'i: v: bob, bob, bob berand');
      logger.i(a.toMarkup());

      var gridCoordinate = GridCoordinate(2, 1 + measureIndex % 4);
      ChordSectionLocation? chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
      assert(chordSectionLocation != null);
      logger.d('$chordSectionLocation: ${a.findMeasureByChordSectionLocation(chordSectionLocation)}');
      a.setCurrentChordSectionLocation(chordSectionLocation);
      a.setRepeat(chordSectionLocation!, 2);
      gridCoordinate = const GridCoordinate(2, 1 + 3);
      chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
      assert(chordSectionLocation != null);
      logger.d('grid: $chordSectionLocation: ${a.findMeasureByChordSectionLocation(chordSectionLocation)}');
      logger.i(a.toMarkup());
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A# [B C C# D ] x2 D# E F F#, G  O: D E F G');
      expect(a.currentChordSectionLocation, chordSectionLocation);

      //  remove the repeat, it's location address may have changed above!
      var loc = a.findChordSectionLocationByGrid(gridCoordinate);
      assert(loc != null);
      a.setRepeat(loc!.asPhraseLocation()!, 1);
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A#, B C C# D, D# E F F#, G  O: D E F G');
      expect(a.currentChordSectionLocation,
          ChordSectionLocation(chordSectionLocation!.sectionVersion, phraseIndex: 0, measureIndex: 7));
    }

    for (var measureIndex = 9; measureIndex < 12; measureIndex++) {
      //  repeat a row in the end of a phrase
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: A B C D v: E F G A#, B C C# D, D# E F F# o: D E F G',
          rawLyrics: 'i: v: bob, bob, bob berand');
      logger.i(a.toMarkup());

      SectionVersion sectionVersion = SectionVersion.bySection(Section.get(SectionEnum.verse));
      ChordSectionLocation? chordSectionLocation =
          ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: measureIndex);
      logger.d(chordSectionLocation.toString());
      a.setCurrentChordSectionLocation(chordSectionLocation);
      a.setRepeat(chordSectionLocation, 2);
      logger.i(a.toMarkup());
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A#, B C C# D [D# E F F# ] x2  O: D E F G');
      chordSectionLocation = ChordSectionLocation(chordSectionLocation.sectionVersion, phraseIndex: 1, measureIndex: 3);
      logger.d(chordSectionLocation.toString());
      expect(a.currentChordSectionLocation, chordSectionLocation);

      //  remove the repeat
      var loc = ChordSectionLocation(sectionVersion, phraseIndex: 1, measureIndex: measureIndex % 4);
      logger.d('loc: $loc, ${loc.asPhraseLocation()}');
      a.setRepeat(loc.asPhraseLocation()!, 1);
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A#, B C C# D, D# E F F#  O: D E F G');
      expect(a.currentChordSectionLocation,
          ChordSectionLocation(chordSectionLocation.sectionVersion, phraseIndex: 0, measureIndex: 11));
    }

    for (var measureIndex = 12; measureIndex < 13; measureIndex++) {
      //  repeat a row in the end of a phrase
      SongBase a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: 100,
          beatsPerBar: 4,
          unitsPerMeasure: 4,
          chords: 'i: A B C D v: E F G A#, B C C# D, D# E F F#, G o: D E F G',
          rawLyrics: 'i: v: bob, bob, bob berand');
      logger.i(a.toMarkup());

      SectionVersion sectionVersion = SectionVersion.bySection(Section.get(SectionEnum.verse));
      ChordSectionLocation? chordSectionLocation =
          ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: measureIndex);
      logger.d(chordSectionLocation.toString());
      a.setCurrentChordSectionLocation(chordSectionLocation);
      a.setRepeat(chordSectionLocation, 2);
      logger.i(a.toMarkup());
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A#, B C C# D, D# E F F# [G ] x2  O: D E F G');
      {
        var gridCoordinate = GridCoordinate(4, 1 + measureIndex % 4);
        chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
      }
      assert(chordSectionLocation != null);
      expect(a.currentChordSectionLocation, chordSectionLocation);

      //  remove the repeat
      var loc = ChordSectionLocation(sectionVersion, phraseIndex: 1, measureIndex: measureIndex % 4);
      a.setRepeat(loc, 1);
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A#, B C C# D, D# E F F#, G  O: D E F G');
      expect(a.currentChordSectionLocation,
          ChordSectionLocation(chordSectionLocation!.sectionVersion, phraseIndex: 0, measureIndex: 12));
    }

    //  test where the current is not necessarily the repeat location
    {
      SectionVersion sectionVersion = SectionVersion.bySection(Section.get(SectionEnum.verse));
      var size = 12;
      for (var currentIndex = 4; currentIndex < 13; currentIndex++) {
        var currentChordSectionLocation =
            ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: currentIndex);
        for (var measureIndex = 0; measureIndex <= size; measureIndex++) {
          //  repeat a row in the end of a phrase
          SongBase a = SongBase(
              title: 'A',
              artist: 'bob',
              copyright: 'bsteele.com',
              key: music_key.Key.getDefault(),
              beatsPerMinute: 100,
              beatsPerBar: 4,
              unitsPerMeasure: 4,
              chords: 'i: A B C D v: E F G A#, B C C# D, D# E F F#, G o: D E F G',
              rawLyrics: 'i: v: bob, bob, bob berand');
          logger.d('');
          logger.i(a.toMarkup());

          ChordSectionLocation? chordSectionLocation =
              ChordSectionLocation(sectionVersion, phraseIndex: 0, measureIndex: measureIndex);
          logger.d('current: $currentChordSectionLocation, chord: $chordSectionLocation');
          a.setCurrentChordSectionLocation(currentChordSectionLocation);
          a.setRepeat(chordSectionLocation, 2);
          logger.i(a.toMarkup());
          ChordSectionLocation? newLoc = a.currentChordSectionLocation;
          assert(newLoc != null);

          //  remove the repeat
          logger.d('remove repeat: $newLoc');
          a.setRepeat(newLoc!, 1);
          logger.i(a.toMarkup());
          expect(
              a.currentChordSectionLocation,
              ChordSectionLocation(chordSectionLocation.sectionVersion,
                  phraseIndex: 0, measureIndex: min(4 * (measureIndex ~/ 4) + 3, size)));
        }
      }
    }
  });

  test('test findChordSectionLocation()', () {
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'i: A B C D v: E B C D',
        rawLyrics: 'i: v: bob, bob, bob berand');

    logger.d(a.logGrid());
    logger.d('moment count: ${a.songMoments.length}');
    for (SongMoment moment in a.songMoments) {
      logger.d('moment: $moment');
      ChordSection? chordSection = a.findChordSectionBySectionVersion(moment.chordSection.sectionVersion);
      if (chordSection == null) throw 'chordSection == null';
      ChordSectionLocation? lastLoc = a.findLastChordSectionLocation(chordSection);
      if (lastLoc == null) throw 'lastLoc == null';
      logger.d('   lastLoc: $lastLoc');
      expect(lastLoc.sectionVersion, chordSection.sectionVersion);
    }
  });

  test('test parsing comments', () {
    SongBase a;
    SplayTreeSet<ChordSection> chordSections = SplayTreeSet();
    ChordSection chordSection;
    List<Measure> measures;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D',
        rawLyrics: 'v: bob, bob, bob berand');
    chordSections.addAll(a.getChordSections());
    expect(1, chordSections.length);
    chordSection = chordSections.first;
    measures = chordSection.phrases[0].measures;
    expect(4, measures.length);

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D (yo)',
        rawLyrics: 'v: bob, bob, bob berand');
    chordSections.clear();
    chordSections.addAll(a.getChordSections());
    expect(1, chordSections.length);
    chordSection = chordSections.first;
    measures = chordSection.phrases[0].measures;
    expect(5, measures.length);
    expect(measures[4].toMarkup(), '(yo)');
  });

  test('testGetGrid', () {
    SongBase a;
    Measure? measure;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'v: A B C D, E F G A C: D D GD E\n'
            'A B C D x3\n'
            'Ab G Gb F',
        rawLyrics: 'v: bob, bob, bob berand');
    logger.d(a.logGrid());
    Grid<ChordSectionGridData> grid = a.getChordSectionGrid();

    expect(grid.getRowCount(), 5);
    for (int r = 2; r < grid.getRowCount(); r++) {
      List<ChordSectionGridData?>? row = grid.getRow(r);
      if (row == null) throw 'row == null';

      for (int c = 1; c < row.length; c++) {
        measure = null;

        MeasureNode? node = a.findMeasureNodeByLocation(row[c]?.chordSectionLocation);
        switch (r) {
          case 0:
            switch (c) {
              case 0:
                expect(node is ChordSection, isTrue);
                expect((node as ChordSection).sectionVersion.section, Section.get(SectionEnum.verse));
                break;
              case 1:
                measure = node as Measure;
                expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.A);
                break;
              case 4:
                measure = node as Measure;
                expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.D);
                break;
            }
            break;
          case 2:
            switch (c) {
              case 0:
                expect(node is ChordSection, isTrue);
                expect((node as ChordSection).sectionVersion.section, Section.get(SectionEnum.chorus));
                break;
              case 1:
              case 2:
                measure = node as Measure;
                expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.D);
                break;
              case 3:
                measure = node as Measure;
                expect(ScaleNote.G, measure.chords[0].scaleChord.scaleNote);
                break;
              case 4:
                measure = node as Measure;
                expect(ScaleNote.E, measure.chords[0].scaleChord.scaleNote);
                break;
            }
            break;
          case 3:
            switch (c) {
              case 0:
                expect(node is ChordSection, isTrue);
                expect(Section.get(SectionEnum.chorus), (node as ChordSection).sectionVersion.section);
                break;
              case 1:
                measure = node as Measure;
                expect(ScaleNote.A, measure.chords[0].scaleChord.scaleNote);
                break;
              case 4:
                measure = node as Measure;
                expect(ScaleNote.D, measure.chords[0].scaleChord.scaleNote);
                break;
            }
            break;
        }

        if (measure != null) {
          expect(measure, a.findMeasureNodeByLocation(a.getChordSectionGrid().get(r, c)?.chordSectionLocation));
          logger.d('measure($c,$r): ${measure.toMarkup()}');
          ChordSectionLocation? loc = a.findChordSectionLocationByGrid(GridCoordinate(r, c));
          logger.d('loc: $loc');
          a.setCurrentChordSectionLocation(loc);

          logger.d('current: ${a.getCurrentMeasureNode()!.toMarkup()}');
          expect(measure, a.getCurrentMeasureNode());
        }
        logger.d('grid[$r,$c]: $node');
      }
    }
  });

  test('testFindChordSectionLocation', () {
    int beatsPerBar = 4;
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'i: A B C D V: D E F F# '
            'v1:    Em7 E E G \n'
            '       C D E Eb7 x2\n'
            'v2:    A B C D |\n'
            '       E F G7 G#m | x2\n'
            '       D C GB GbB \n'
            'C: F F# G G# Ab A O: C C C C B',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no:');
    logger.d(a.getSongId().toString());
    logger.d('\t${a.toMarkup()}');
    logger.d(a.rawLyrics);

    ChordSectionLocation chordSectionLocation;

    chordSectionLocation = ChordSectionLocation.parseString('v:0:0');

    MeasureNode? m = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(Measure.parseString('D', a.beatsPerBar), m);
    expect(m, a.findMeasureNodeByLocation(chordSectionLocation));

    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v:0:3'));
    expect(Measure.parseString('F#', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v:0:4'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:2:0'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:1:1'));
    expect(Measure.parseString('D', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:0:0'));
    expect(Measure.parseString('Em7', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:0:4'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:0:3'));
    expect(m, Measure.parseString('G', a.beatsPerBar)); //  default measures per row
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:1:0'));
    expect(Measure.parseString('C', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:1:1'));
    expect(Measure.parseString('D', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:0:9')); //    repeats don't count here
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:0:0'));
    expect(Measure.parseString('A', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:0:3'));
    expect(m, Measure.parseString('D,', a.beatsPerBar));
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:0:4'));
    expect(Measure.parseString('E', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:1:3'));
    expect(m, Measure.parseString('GbB', a.beatsPerBar));
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:1:4'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('o:0:4'));
    expect(Measure.parseString('B', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('o:0:5'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('c:0:5'));
    expect(Measure.parseString('A', a.beatsPerBar), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('c:0:6'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('i:0:0'));
    expect(Measure.parseString('A', a.beatsPerBar), m);

    chordSectionLocation = ChordSectionLocation.parseString('v:0');
    MeasureNode? mn = a.findMeasureNodeByLocation(chordSectionLocation);
    if (mn == null) throw 'mn == null';

    logger.d(mn.toMarkup());
    expect(mn.toMarkup(), 'D E F F# ');

    chordSectionLocation = ChordSectionLocation.parseString('out:');
    mn = a.findMeasureNodeByLocation(chordSectionLocation);
    if (mn == null) throw 'mn == null';
    logger.d(mn.toMarkup());
    expect('O: C C C C B ', mn.toMarkup());
  });

  test('testMeasureDelete', () {
    int beatsPerBar = 4;
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'i: A B C D V: D E F F# ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

    ChordSectionLocation loc;

    loc = ChordSectionLocation.parseString('i:0:2');
    a.setCurrentChordSectionLocation(loc);
    logger.d(a.getCurrentChordSectionLocation().toString());
    logger.d(a.findMeasureNodeByLocation(a.getCurrentChordSectionLocation())!.toMarkup());
    a.chordSectionLocationDelete(loc);
    logger.d(a.findChordSectionBySectionVersion(SectionVersion.parseString('i:'))!.toMarkup());
    logger.d(a.findMeasureNodeByLocation(loc)!.toMarkup());
    logger.d('loc: ${a.getCurrentChordSectionLocation()}');
    logger.d(a.findMeasureNodeByLocation(a.getCurrentChordSectionLocation())!.toMarkup());
    expect(a.findMeasureNodeByLocation(loc), a.findMeasureNodeByLocation(a.getCurrentChordSectionLocation()));
    logger.i(a.toMarkup());
    expect(a.getChordSection(SectionVersion.parseString('i:'))!.toMarkup(), 'I: A B D ');
    expect(Measure.parseString('D', beatsPerBar), a.getCurrentChordSectionLocationMeasureNode());
    logger.d('cur: ${a.getCurrentChordSectionLocationMeasureNode()!.toMarkup()}');

    a.chordSectionLocationDelete(loc);
    expect('I: A B ', a.getChordSection(SectionVersion.parseString('i:'))!.toMarkup());
    logger.d(a.getCurrentChordSectionLocationMeasureNode()!.toMarkup());
    expect(Measure.parseString('B', beatsPerBar), a.getCurrentChordSectionLocationMeasureNode());

    a.chordSectionLocationDelete(ChordSectionLocation.parseString('i:0:0'));
    expect('I: B ', a.getChordSection(SectionVersion.parseString('i:'))!.toMarkup());
    logger.d(a.getCurrentChordSectionLocationMeasureNode()!.toMarkup());
    expect(Measure.parseString('B', beatsPerBar), a.getCurrentChordSectionLocationMeasureNode());

    a.chordSectionLocationDelete(ChordSectionLocation.parseString('i:0:0'));
    expect(a.getChordSection(SectionVersion.parseString('i:'))!.toMarkup(), 'I: [] ');
    expect(a.getCurrentChordSectionLocationMeasureNode(), isNull);
    //expect(ChordSection.parseString("I:", beatsPerBar ),a.getCurrentChordSectionLocationMeasureNode());

    expect(a.getChordSection(SectionVersion.parseString('v:'))!.toMarkup(), 'V: D E F F# ');
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:3'));
    expect(Measure.parseString('F#', beatsPerBar), a.getCurrentChordSectionLocationMeasureNode());
    a.chordSectionLocationDelete(ChordSectionLocation.parseString('v:0:3'));
    expect(Measure.parseString('F', beatsPerBar), a.getCurrentChordSectionLocationMeasureNode());
  });

  test('testLastLineWithoutNewline', () {
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'i: A B C D V: D E F F# ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro\n');
    String lyrics = 'i:\n'
        'v: bob, bob, bob berand\n'
        'c: sing chorus here \n'
        'o: last line of outro';
    //logger.d(    a.getRawLyrics());
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'i: A B C D V: D E F F# ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    expect(lyrics, a.rawLyrics);
  });

  test('testSongWithoutStartingSection', () {
//  fixme: doesn't test much, not very well

    SongBase a = SongBase(
        title: 'Rio',
        artist: 'Duran Duran',
        copyright: 'Sony/ATV Music Publishing LLC',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: //  not much of this chord chart is correct!
            'Verse\n'
            'C#m A♭ FE A♭  x4\n'
            'Prechorus\n'
            'C C/\n'
            'chorus\n'
            'C G B♭ F  x4\n'
            'Tag Chorus\n',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro\n');
    logger.d(a.logGrid());
    Grid<ChordSectionGridData> grid = a.getChordSectionGrid();
    expect(10, grid.getRowCount()); //  comments on their own line add a bunch
    List<ChordSectionGridData?>? row = grid.getRow(0);
    if (row == null) throw 'row == null';
    expect(2, row.length);
    row = grid.getRow(1);
    if (row == null) throw 'row == null';
    logger.d('row: $row');
    expect(1 + 4 + 1 + 1, row.length);
    row = grid.getRow(2);
    if (row == null) throw 'row == null';
    expect(2, row.length);
    expect(grid.get(0, 5), isNull);
  });

  test('test Songs with blank lyrics lines', () {
    SongBase a;
    int beatsPerBar = 4;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'v: D D C G x4 c: C C C C x 2',
        rawLyrics: '''
v:     
  

line 2
line 3
c:
c line 0
c line 1
      
c line 3
v:
v line 0
     

c2:


    c2 line 2


''');

    logger.t('<${a.rawLyrics}>');

    for (var ls in a.lyricSections) {
      logger.t(ls.sectionVersion.toString());
      var i = 1;
      for (var line in ls.lyricsLines) {
        logger.t('    ${i++}: $line');
      }
    }
    expect(a.lyricSections.length, 4);

    var ls = a.lyricSections[0];
    expect(ls.lyricsLines.length, 4);
    expect(ls.lyricsLines[0], '  ');
    expect(ls.lyricsLines[1], '\n');
    expect(ls.lyricsLines[2], 'line 2');
    expect(ls.lyricsLines[3], 'line 3');

    ls = a.lyricSections[1];
    expect(ls.lyricsLines.length, 4);
    expect(ls.lyricsLines[0], 'c line 0');
    expect(ls.lyricsLines[1], 'c line 1');
    expect(ls.lyricsLines[2], '\n'); //  notice that the whitespace was absorbed
    expect(ls.lyricsLines[3], 'c line 3');

    ls = a.lyricSections[2];
    expect(ls.lyricsLines.length, 2);
    expect(ls.lyricsLines[0], 'v line 0');
    expect(ls.lyricsLines[1], '\n');

    ls = a.lyricSections[3];
    expect(ls.lyricsLines.length, 4);
    expect(ls.lyricsLines[0], '\n');
    expect(ls.lyricsLines[1], '\n');
    expect(ls.lyricsLines[2], 'c2 line 2');
    expect(ls.lyricsLines[3], '\n');
  });

  test('testOddSongs', () {
    SongBase a;
    int beatsPerBar = 4;
    ChordSectionLocation location;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'O:'
            'D..Dm7 Dm7 C..B♭maj7 B♭maj7  x12',
        rawLyrics: 'o: nothing');
    logger.t('grid: ${a.logGrid()}');
    location = ChordSectionLocation(SectionVersion(Section.get(SectionEnum.outro), 0), phraseIndex: 0, measureIndex: 3);
    MeasureNode? measureNode = a.findMeasureNodeByLocation(location);
    logger.t('measure: ${measureNode!.toMarkup()}');
    expect(measureNode, Measure.parseString('B♭maj7', beatsPerBar));
    MeasureNode? mn = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    Measure? expectedMn = Measure.parseString('B♭maj7', beatsPerBar);
    expect(mn, expectedMn);

    const int row = 0;
    const int lastCol = 3;
    location = ChordSectionLocation(SectionVersion(Section.get(SectionEnum.outro), 0),
        phraseIndex: row, measureIndex: lastCol);
    measureNode = a.findMeasureNodeByLocation(location);
    if (measureNode == null) throw 'measureNode == null';
    logger.d(measureNode.toMarkup());
    expect(measureNode, a.findMeasureNodeByGrid(const GridCoordinate(row, lastCol + 1)));

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'I1:\n'
            'CD CD CD A\n' //  toss the dot as a comment
            'D X\n'
            '\n'
            'V:\n'
            'D7 D7 CD CD\n'
            'D7 D7 CD CD\n'
            'D7 D7 CD CD\n'
            'D7 D7 CD D.\n'
            '\n'
            'I2:\n'
            'CD CD CD D.\n'
            'D\n'
            '\n'
            'C1:\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC DC\n'
            'DC\n'
            '\n'
            'I3:\n'
            'D\n'
            '\n'
            'C2:\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC DC\n'
            'DC DC\n'
            '\n'
            'I4:\n'
            'C5D5 C5D5 C5D5 C5D5 x7\n'
            '\n'
            'O:\n'
            'C5D5 C5D5 C5D5 C5D5\n'
            'C5D5 C5D5 C5D5 C5D#',
        rawLyrics: 'i1:\nv: bob, bob, bob berand\ni2: nope\nc1: sing \ni3: chorus here \ni4: mo chorus here\n'
            'o: last line of outro');
    logger.d(a.logGrid());
    Measure? m = Measure.parseString('X', a.beatsPerBar);
    expect(a.findMeasureNodeByGrid(const GridCoordinate(1, 2)), m);
    expect(Measure.parseString('C5D5', a.beatsPerBar), a.findMeasureNodeByGrid(const GridCoordinate(5, 4)));
    m = Measure.parseString('DC', a.beatsPerBar);
    expect(a.findMeasureNodeByGrid(const GridCoordinate(18, 2)), m);
    expect(Measure.parseString('C5D#', a.beatsPerBar), a.findMeasureNodeByGrid(const GridCoordinate(20, 4)));

    //  not what's intended, but what's declared
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'V:I:O:\n'
            'Ebsus2 Bb Gm7 C\n'
            '\n'
            'C:\n'
            'Cm F Bb Eb x3\n'
            'Cm F\n'
            '\n'
            'O:V:\n',
        rawLyrics: 'i1:\nv: bob, bob, bob berand\ni2: nope\nc1: sing \ni3: chorus here \n'
            'i4: mo chorus here\no: last line of outro');
    logger.d(a.logGrid());
    expect(Measure.parseString('Gm7', a.beatsPerBar), a.findMeasureNodeByGrid(const GridCoordinate(0, 3)));
    expect(Measure.parseString('Cm', a.beatsPerBar), a.findMeasureNodeByGrid(const GridCoordinate(2, 1)));
    expect(Measure.parseString('F', a.beatsPerBar), a.findMeasureNodeByGrid(const GridCoordinate(2, 2)));

    //  leading blank lines
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: '\n'
            '   \n'
            '\n'
            'I1:\n'
            'CD CD CD A\n' //  toss the dot as a comment
            'D X\n'
            '\n'
            'V:\n'
            'D7 D7 CD CD\n'
            'D7 D7 CD CD\n'
            'D7 D7 CD CD\n'
            'D7 D7 CD D.\n'
            '\n'
            'I2:\n'
            'CD CD CD D.\n'
            'D\n'
            '\n'
            'C1:\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC DC\n'
            'DC\n'
            '\n'
            'I3:\n'
            'D\n'
            '\n'
            'C2:\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC C\n'
            'DB♭ B♭ DC DC\n'
            'DC DC\n'
            '\n'
            'I4:\n'
            'C5D5 C5D5 C5D5 C5D5 x7\n'
            '\n'
            'O:\n'
            'C5D5 C5D5 C5D5 C5D5\n'
            'C5D5 C5D5 C5D5 C5D#',
        rawLyrics: 'i1:\nv: bob, bob, bob berand\ni2: nope\nc1: sing \n'
            'i3: chorus here \ni4: mo chorus here\no: last line of outro');

    //  assure parse was successful
    expect(a.lyricSections.first.sectionVersion, SectionVersion(Section.get(SectionEnum.intro), 1));
    expect(a.lyricSections.last.sectionVersion, SectionVersion(Section.get(SectionEnum.outro), 0));
  });

  test('testGridStuff', () {
    int beatsPerBar = 4;
    SongBase a;
    Grid<ChordSectionGridData> grid;
    ChordSectionLocation? location;
    GridCoordinate gridCoordinate;

    //  see that section identifiers are on first phrase row
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    logger.t(a.toMarkup());
    logger.d('testing: ${ChordSectionLocation.parseString('I:0:0')}');
    logger.d('testing2: ${a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0'))}');
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')), const GridCoordinate(0, 1));

    expect(const GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('I:')));
    expect(const GridCoordinate(1, 0), a.getGridCoordinate(ChordSectionLocation.parseString('V:')));
    expect(const GridCoordinate(2, 0), a.getGridCoordinate(ChordSectionLocation.parseString('C:')));

    //  see that section identifiers are on first phrase row
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: Am Am/G Am/F♯ FE, A B C D, v: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    logger.d(a.logGrid());

    expect(const GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('I:')));
    expect(const GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')));

    expect(const GridCoordinate(2, 0), a.getGridCoordinate(ChordSectionLocation.parseString('V:')));
    expect(const GridCoordinate(3, 0), a.getGridCoordinate(ChordSectionLocation.parseString('C:')));

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here');
    logger.i(a.toMarkup());
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('V:')), const GridCoordinate(0, 0));
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('V:0:0')), const GridCoordinate(0, 1));

    expect(a.getGridCoordinate(ChordSectionLocation.parseString('I:')), const GridCoordinate(0, 0));
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('C:')), const GridCoordinate(2, 0));

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: V: c: G D G D ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here');
    logger.i(a.toMarkup());

    expect(const GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('I:')));
    expect(const GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('V:')));
    expect(const GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('C:')));
    location = ChordSectionLocation.parseString('I:0:0');
    expect(const GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')));
    expect(Measure.parseString('G', beatsPerBar), a.findMeasureNodeByLocation(location));
    expect(const GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('v:0:0')));
    expect(Measure.parseString('G', beatsPerBar), a.findMeasureNodeByLocation(location));
    expect(const GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('c:0:0')));
    expect(Measure.parseString('G', beatsPerBar), a.findMeasureNodeByLocation(location));
    logger.d(a.logGrid());
    gridCoordinate = const GridCoordinate(0, 0);
    location = a.getChordSectionLocation(gridCoordinate);
    logger.d(location.toString());
    expect(gridCoordinate, a.getGridCoordinate(location));
    location = ChordSectionLocation.parseString('V:0:0');
    expect(const GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('i:0:0')));
    expect(Measure.parseString('G', beatsPerBar), a.findMeasureNodeByLocation(location));
    gridCoordinate = const GridCoordinate(0, 0);
    location = a.getChordSectionLocation(gridCoordinate);
    logger.d(location.toString());
    expect(gridCoordinate, a.getGridCoordinate(location));
    expect('I: V: C: ', location.toString());

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'verse: A B C D prechorus: D E F F# chorus: G D C G x3',
        rawLyrics: 'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \no: last line of outro');
    logger.i(a.toMarkup());

    grid = a.getChordSectionGrid();
    for (int r = 0; r < grid.getRowCount(); r++) {
      List<ChordSectionGridData?>? row = grid.getRow(r);
      if (row == null) throw 'row == null';
      for (int c = 0; c < row.length; c++) {
        GridCoordinate coordinate = GridCoordinate(r, c);
        expect(coordinate, isNotNull);
        expect(coordinate.toString(), isNotNull);
        expect(a.getChordSectionGrid(), isNotNull);
        expect(a.getChordSectionGrid().getRow(r), isNotNull);
        ChordSectionLocation? chordSectionLocation = a.getChordSectionGrid().getRow(r)![c]?.chordSectionLocation;
        if (chordSectionLocation == null) continue;
        expect(chordSectionLocation.toString(), isNotNull);
        logger.d('$coordinate  $chordSectionLocation');
        ChordSectionLocation? loc = a.getChordSectionLocation(coordinate);
        logger.d(loc.toString());
        expect(a.getChordSectionGrid().get(r, c)?.chordSectionLocation, a.getChordSectionLocation(coordinate));
        expect(coordinate, a.getGridCoordinate(loc));
        expect(loc, a.getChordSectionLocation(coordinate)); //  well, yeah
      }
    }
  });

  test('testComputeMarkup', () {
    int beatsPerBar = 4;
    SongBase a;
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'verse: C2: V2: A B C D prechorus: D E F F# chorus: G D C G x3',
        rawLyrics: 'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \no: last line of outro');

    expect(a.toMarkup().trim(), 'V: V2: C2: A B C D  PC: D E F F#  C: [G D C G ] x3');
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'verse: A B C D prechorus: D E F F# chorus: G D C G x3',
        rawLyrics: 'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \no: last line of outro');
    expect(a.toMarkup().trim(), 'V: A B C D  PC: D E F F#  C: [G D C G ] x3');
  });

  test('testDebugSongMoments', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'verse: C2: V2: A B C D Ab Bb Eb Db prechorus: D E F F# o:chorus: G D C G x3 T: A',
        rawLyrics: 'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \nv: nope\nc: yes\n'
            'v: nope\nt:\no: last line of outro\n');
    a.debugSongMoments();

    for (int momentNumber = 0; momentNumber < a.songMoments.length; momentNumber++) {
      SongMoment? songMoment = a.getSongMoment(momentNumber);
      if (songMoment == null) {
        break;
      }
      logger.d(songMoment.toString());
      expect(momentNumber, songMoment.momentNumber);
      GridCoordinate? momentGridCoordinate = a.getMomentGridCoordinateFromMomentNumber(momentNumber);
      expect(momentGridCoordinate, isNotNull);
    }
  });

  test('testChordSectionBeats', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'verse: C2: V2: A B C D Ab Bb Eb Db prechorus: D E F F# o:chorus: G D C G x3 T: A',
        rawLyrics: 'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \nv: nope\n'
            'c: yes\nv: nope\nt:\no: last line of outro\n');

    expect(8 * 4, a.getChordSectionBeats(SectionVersion.parseString('v:')));
    expect(8 * 4, a.getChordSectionBeats(SectionVersion.parseString('c2:')));
    expect(8 * 4, a.getChordSectionBeats(SectionVersion.parseString('v2:')));
    expect(4 * 3 * 4, a.getChordSectionBeats(SectionVersion.parseString('o:')));
    expect(4, a.getChordSectionBeats(SectionVersion.parseString('t:')));
  });

  test('testSongMomentGridding', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D, E F]  x2  ',
        rawLyrics: 'i:\n');
    a.debugSongMoments();
    {
      //  verify repeats stay on correct row
      SongMoment? songMoment;

      for (int momentNumber = 0; momentNumber < 4; momentNumber++) {
        songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) throw 'songMoment == null';
        expect(a.getMomentGridCoordinateFromMomentNumber(songMoment.momentNumber)!.row, 0);
      }
      for (int momentNumber = 4; momentNumber < 6; momentNumber++) {
        songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) throw 'songMoment == null';
        expect(a.getMomentGridCoordinateFromMomentNumber(songMoment.momentNumber)!.row, 1);
      }
      for (int momentNumber = 6; momentNumber < 10; momentNumber++) {
        songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) throw 'songMoment == null';
        expect(a.getMomentGridCoordinateFromMomentNumber(songMoment.momentNumber)!.row, 2);
      }
      for (int momentNumber = 10; momentNumber < 12; momentNumber++) {
        songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) throw 'songMoment == null';
        expect(a.getMomentGridCoordinateFromMomentNumber(songMoment.momentNumber)!.row, 3);
      }
    }

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'verse: C2: V2: A B C D  x2  prechorus: D E F F#, G# A# B C o:chorus: G D C G x3 T: A',
        rawLyrics: 'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \nv: nope\nc: yes\n'
            'v: nope\nt:\no: last line of outro\n');
    a.debugSongMoments();

    {
      //  verify beats total as expected
      int beats = 0;
      for (int momentNumber = 0; momentNumber < a.songMoments.length; momentNumber++) {
        SongMoment? songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) break;
        expect(beats, songMoment.beatNumber);
        beats += songMoment.measure.beatCount;
      }
    }
    {
      int count = 0;
      for (int momentNumber = 0; momentNumber < a.songMoments.length; momentNumber++) {
        SongMoment? songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) break;
        logger.d(' ');
        logger.d(songMoment.toString());
        expect(count, songMoment.momentNumber);
        GridCoordinate? momentGridCoordinate = a.getMomentGridCoordinate(songMoment);
        if (momentGridCoordinate == null) throw 'momentGridCoordinate == null';
        logger.d(momentGridCoordinate.toString());
        expect(momentGridCoordinate, isNotNull);

        count++;
      }
    }
    {
      //  verify repeats stay on correct row
      SongMoment? songMoment;

      for (int momentNumber = 0; momentNumber < 56; momentNumber++) {
        songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) throw 'songMoment == null';
        logger.d(songMoment.toString());
        int e = momentNumber ~/ 4;
        expect(a.getMomentGridCoordinateFromMomentNumber(songMoment.momentNumber)!.row, e);
      }
    }
  });

  test('testGetSongMomentAtRow', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D, E F]  x2 v: D C G G c: Ab Bb C Db o: G G G G ',
        rawLyrics: 'i:\nv: verse\n c: chorus\nv: verse\n c: chorus\no: outro');
    a.debugSongMoments();
    logger.i(a.toMarkup());
    int size = a.songMoments.length;
    for (int momentNumber = 0; momentNumber < size; momentNumber++) {
      SongMoment? songMoment = a.getSongMoment(momentNumber);
      if (songMoment == null) throw 'songMoment == null';
      GridCoordinate? coordinate = a.getMomentGridCoordinate(songMoment);
      SongMoment? songMomentAtRow = a.getFirstSongMomentAtRow(coordinate!.row);
      GridCoordinate? coordinateAtRow = a.getMomentGridCoordinate(songMomentAtRow!);
      logger.i('songMoment: $songMoment at: $coordinate atRow: $coordinateAtRow');
      expect(coordinate.row, coordinateAtRow!.row);
      expect(coordinateAtRow.col, 1);
    }
  });

  test('test first songMoment at next or prior row', () {
    int beatsPerBar = 4;

    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: G C D A [A B C D, E F]  x2 v: D C G G c: Ab Bb C Db o: G G G G ',
        rawLyrics: 'i:\nv: verse\n c: chorus\nv: verse\n c: chorus\no: outro');

    {
      int r = -1;
      for (var m in a.songMoments) {
        if (m.row != r) {
          logger.i('row ${m.row}: momentNumber: ${m.momentNumber}: $m');
          r = m.row!;
        }
      }
    }

    expect(a.getFirstSongMomentAtNextRow(-3), a.getSongMoment(4));
    expect(a.getFirstSongMomentAtNextRow(0), isNotNull);
    expect(a.getFirstSongMomentAtNextRow(0), a.getSongMoment(4));
    expect(a.getFirstSongMomentAtNextRow(4), a.getSongMoment(8));
    expect(a.getFirstSongMomentAtNextRow(8), a.getSongMoment(10));
    expect(a.getFirstSongMomentAtNextRow(9), a.getSongMoment(10));
    expect(a.getFirstSongMomentAtNextRow(10), a.getSongMoment(14));
    expect(a.getFirstSongMomentAtNextRow(11), a.getSongMoment(14));
    expect(a.getFirstSongMomentAtNextRow(12), a.getSongMoment(14));
    expect(a.getFirstSongMomentAtNextRow(14), a.getSongMoment(16));
    expect(a.getFirstSongMomentAtNextRow(16), a.getSongMoment(20));
    expect(a.getFirstSongMomentAtNextRow(20), a.getSongMoment(24));
    expect(a.getFirstSongMomentAtNextRow(24), a.getSongMoment(28));
    expect(a.getFirstSongMomentAtNextRow(28), a.getSongMoment(32));
    expect(a.getFirstSongMomentAtNextRow(29), a.getSongMoment(32));
    expect(a.getFirstSongMomentAtNextRow(30), a.getSongMoment(32));
    expect(a.getFirstSongMomentAtNextRow(31), a.getSongMoment(32));
    expect(a.getFirstSongMomentAtNextRow(32), null);
    expect(a.getFirstSongMomentAtNextRow(33), null);

    expect(a.getFirstSongMomentAtPriorRow(-3), a.getSongMoment(0));
    expect(a.getFirstSongMomentAtPriorRow(0), isNotNull);
    expect(a.getFirstSongMomentAtPriorRow(0), a.getSongMoment(0));
    expect(a.getFirstSongMomentAtPriorRow(4), a.getSongMoment(0));
    expect(a.getFirstSongMomentAtPriorRow(8), a.getSongMoment(4));
    expect(a.getFirstSongMomentAtPriorRow(9), a.getSongMoment(4));
    expect(a.getFirstSongMomentAtPriorRow(10), a.getSongMoment(8));
    expect(a.getFirstSongMomentAtPriorRow(11), a.getSongMoment(8));
    expect(a.getFirstSongMomentAtPriorRow(12), a.getSongMoment(8));
    expect(a.getFirstSongMomentAtPriorRow(14), a.getSongMoment(10));
    expect(a.getFirstSongMomentAtPriorRow(16), a.getSongMoment(14));
    expect(a.getFirstSongMomentAtPriorRow(20), a.getSongMoment(16));
    expect(a.getFirstSongMomentAtPriorRow(24), a.getSongMoment(20));
    expect(a.getFirstSongMomentAtPriorRow(28), a.getSongMoment(24));
    expect(a.getFirstSongMomentAtPriorRow(29), a.getSongMoment(24));
    expect(a.getFirstSongMomentAtPriorRow(30), a.getSongMoment(24));
    expect(a.getFirstSongMomentAtPriorRow(31), a.getSongMoment(24));
    expect(a.getFirstSongMomentAtPriorRow(32), a.getSongMoment(28));
    expect(a.getFirstSongMomentAtPriorRow(33), a.getSongMoment(28));
    expect(a.getFirstSongMomentAtPriorRow(34), a.getSongMoment(28));
    expect(a.getFirstSongMomentAtPriorRow(35), a.getSongMoment(28));
    expect(a.getFirstSongMomentAtPriorRow(36), null);
    expect(a.getFirstSongMomentAtPriorRow(37), null);
  });

  test('testSetMeasuresPerRow', () {
    int beatsPerBar = 4;
    SongBase a;

    //  split a long repeat
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: A B C D E F, G G# Ab Bb x2 \nc: D E F',
        rawLyrics: 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);

    //  don't fix what's not broken
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D, E F G G#, Ab Bb] x2 \nc: D E F',
        rawLyrics: 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);
    logger.i(a.toMarkup());
    expect(a.toMarkup().trim(), 'I: [A B C D, E F G G#, Ab Bb ] x2  C: D E F');

    //  take the comma off a repeat
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D, E F G G#, ] x2 \nc: D E F',
        rawLyrics: 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);
    logger.i(a.toMarkup());
    expect(a.toMarkup().trim(), 'I: [A B C D, E F G G# ] x2  C: D E F');

    //  not the first section
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D ] x2 \nc: D E F A B C D, E F G G#',
        rawLyrics: 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.i(a.toMarkup());
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());
    expect(a.setMeasuresPerRow(4), isFalse);
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());

    //  take a last comma off
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D ] x2 \nc: D E F A B C, D E, F G G#,',
        rawLyrics: 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.i(a.toMarkup());
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());
    expect(a.setMeasuresPerRow(4), isFalse);
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());
  });

  test('testGetBeatNumberAtTime', () {
    const int dtDiv = 2;
    //int beatsPerBar = 4;

    for (int bpm = 60; bpm < 132; bpm++) {
      double dt = 60.0 / (dtDiv * bpm);

      int expected = -12;
      int count = 0;
      for (double t = (-8 * 3) * dt; t < (8 * 3) * dt; t += dt) {
        logger.d('$bpm $t: $expected  ${SongBase.getBeatNumberAtTime(bpm, t)}');
        int? result = SongBase.getBeatNumberAtTime(bpm, t);
        if (result == null) throw 'result == null';
        logger.t('beat at $t = $result');
        logger.t('   expected: $expected');
        if (result != expected) {
          //  deal with test rounding issues
          logger.t('t/dt - e: ${t / (dtDiv * dt) - expected}');
          expect((t / (dtDiv * dt) - expected).abs() < 1.5e-14, isTrue);
        }
        count++;
        if (count >= dtDiv) {
          count = 0;
          expected++;
        }
      }
    }
  });

  test('testGetSongMomentNumberAtTime', () {
    const int dtDiv = 2;
    int beatsPerBar = 4;
    SongBase a;

    for (int bpm = 60; bpm < 132; bpm++) {
      a = SongBase(
          title: 'A',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.getDefault(),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          chords: 'I: A B C D E F  x2  ',
          rawLyrics: 'i:\n');

      double dt = 60.0 / (dtDiv * bpm);

      int expected = -3;
      int count = 0;
      for (double t = -8 * 3 * dt; t < 8 * 3 * dt; t += dt) {
        int? result = a.getSongMomentNumberAtSongTime(t);
        if (result == null) throw 'result == null';
        logger.t(
            '$t = ${t / dt} x dt   $expected  @$count  b:${SongBase.getBeatNumberAtTime(bpm, t)}: ${a.getSongMomentNumberAtSongTime(t)}, bpm: $bpm');
        if (expected != result) {
          //  deal with test rounding issues
          double e = t / (dtDiv * dt) / beatsPerBar - expected;
          logger.w('error: $e');
          expect(e < 1e-14, isTrue);
        }
        // expect(expected, );
        count++;
        if (count >= 8) {
          count = 0;
          expected++;
        }
      }
    }
  });

  test('testSong Section collapse', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: A B C D V: A B C D',
        rawLyrics: 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: V: A B C D  ');
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: A B C D V: [A B C D] x2',
        rawLyrics: 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: A B C D  V: [A B C D ] x2  ');
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D] x2 V: A B C D ',
        rawLyrics: 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: [A B C D ] x2  V: A B C D  ');
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D] x2 V: [A B C D] x2',
        rawLyrics: 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: V: [A B C D ] x2  ');
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [A B C D] x2 V: [A B C D] x4',
        rawLyrics: 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: [A B C D ] x2  V: [A B C D ] x4  ');
  });

  test('test chord Grid repeats', () {
    int beatsPerBar = 4;
    SongBase a;
    Grid<ChordSectionGridData> grid;
//    ChordSectionLocation location;
//    GridCoordinate gridCoordinate;

    //  see that section identifiers are on first phrase row
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');

//    logger.t(a.toMarkup());
//    logger.d('testing: ' + ChordSectionLocation.parseString('I:0:0').toString());
//    logger.d('testing2: ' + a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')).toString());
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')), const GridCoordinate(0, 1));

    grid = a.getChordSectionGrid();

    List<ChordSectionGridData?>? row = grid.getRow(0);
    if (row == null) throw 'row == null';
    logger.d(row.length.toString());
    logger.d(grid.toMultiLineString());
    logger.d(chordSectionToMultiLineString(a));
  });

  test('test entryToUppercase', () {
    expect(SongBase.entryToUppercase('1a'), '1A');
    expect(SongBase.entryToUppercase('emaj9'), 'Emaj9');
    expect(SongBase.entryToUppercase('bbdim7'), 'Bbdim7');
    expect(SongBase.entryToUppercase('abdim7'), 'Abdim7');
    expect(SongBase.entryToUppercase('ddim7'), 'Ddim7');
    expect(SongBase.entryToUppercase('dbdim7'), 'Dbdim7');
    expect(SongBase.entryToUppercase('adadd9'), 'ADadd9');
    expect(SongBase.entryToUppercase('aadd9'), 'Aadd9');
    expect(SongBase.entryToUppercase('addadd9'), 'ADDadd9');
    expect(SongBase.entryToUppercase('aadd9dadd9'), 'Aadd9Dadd9');
    expect(SongBase.entryToUppercase('aaddadd9'), 'AADDadd9');
    expect(SongBase.entryToUppercase('afaflat5'), 'AFAflat5');
    expect(SongBase.entryToUppercase('a9'), 'A9');
    expect(SongBase.entryToUppercase('a9b'), 'A9B');
    expect(SongBase.entryToUppercase('a9b5ab9'), 'A9B5Ab9');
    expect(SongBase.entryToUppercase('a7bb5a7b9'), 'A7Bb5A7b9');
    expect(SongBase.entryToUppercase('a7b9b7b9'), 'A7b9B7b9');
    expect(SongBase.entryToUppercase('a7b9b7B9'), 'A7b9B7B9');
    expect(SongBase.entryToUppercase('a7B9bb7b9'), 'A7B9Bb7b9');
  });

  test('test lyrics to moment mapping', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G F F  O: Dm C B B♭ A  ',
        rawLyrics: '''
c: Make me an angel that flies from Montgomery
	Make me a poster of an old rodeo
	Just give me one thing that I can hold on to
	To believe in this living is just a hard way to go
o: end here''');

    //induce grid generation
    //Grid<SongMoment> grid =
    a.songMomentGrid;

    //     logger.d('a.lyricSections: ${a.lyricSections}');
//     // for (LyricSection lyricSection in a.lyricSections) {
//     //   logger.d('${lyricSection}');
//     //   for (String line in lyricSection.getLyricsLines()) {
//     //     logger.d('  "$line"');
//     //   }
//     // }

    for (SongMoment songMoment in a.songMoments) {
      logger.d('  $songMoment');
      logger.d('      ${songMoment.lyrics}');
    }

    // for (int measures = 2; measures <= 5; measures++) {
    //   for (int rows = 1; rows <= 2* 5; rows++) {
    //     for (int words = 1; words < 2; words++) {
    //       List<String> lines = [];
    //       for (int row = 1; row <= rows; row++) {
    //         String s = '';
    //         for (int word = 1; word <= words; word++) {
    //           s += ' r${row}_w$word';
    //         }
    //         lines.add(s);
    //       }
    //       logger.d('\nmeasures: $measures, row: $rows, word: $words:');
    //       logger.d(lines.toString());
    //
    //       for (int m = 0; m < measures; m++) {
    //         logger.d('     $m: ${splitWordsToMeasure(measures, m, lines)}');
    //       }
    //     }
    //   }
    // }

    //  fixme: not much testing here!
    // for (int measureRows = 3; measureRows <= 3; measureRows++) {
    //   for (int lyricRows = 2; lyricRows <= 4; lyricRows++) {
    //     for (int words = 1; words <= 5; words++) {
    //       List<String> lines = [];
    //       for (int row = 0; row <= lyricRows; row++) {
    //         String s = '';
    //         for (int word = 0; word < words; word++) {
    //           s += 'r${row}_w$word '; // right space is significant
    //         }
    //         lines.add(s.trimRight());
    //       }
    //       logger.d(
    //           '\nmeasureRows: $measureRows, lyricRows: $lyricRows'
    //               ', words: $words: ${lines.toString()}');
    //
    //       for (int mr = 0; mr < measureRows; mr++) {
    //         String rowString = shareLinesToRow(measureRows, mr, lines);
    //         logger.d('     measureRow $mr: $rowString');
    //
    //         for (int measures = 1; measures <= 6; measures++) {
    //           logger.d('       measures $measures:');
    //           for (int m = 0; m < measures; m++) {
    //             String s = splitWordsToMeasure(measures, m, rowString);
    //             logger.d('          mr $mr: m:$m $s');
    //           }
    //         }
    //       }
    //     }
    //   }
    // }
  });

  test('test getLastMeasureLocation()', () {
    int beatsPerBar = 4;
    SongBase a;

    //  see that section identifiers are on first phrase row
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.getLastMeasureLocationOfChordSection(ChordSection.parseString('i:', beatsPerBar)).toString(), 'I:0:3');
    expect(a.getLastMeasureLocationOfChordSection(ChordSection.parseString('c:', beatsPerBar)).toString(), 'C:0:7');
    expect(a.getLastMeasureLocationOfChordSection(ChordSection.parseString('c2:', beatsPerBar)), isNull);
    expect(a.getLastMeasureLocationOfChordSection(ChordSection.parseString('o:', beatsPerBar)).toString(), 'O:0:4');
  });

  test('test in song, chordSection.measureAt', () {
    int beatsPerBar = 4;
    SongBase a;

    //  see that section identifiers are on first phrase row
    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G, Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    var lyricSections = a.lyricSections;
    var chordSection = a.getChordSection(lyricSections[1].sectionVersion);
    expect(chordSection?.sectionVersion, SectionVersion.parseString('v:'));

    expect(chordSection?.measureAt(0), Measure.parseString('Am', beatsPerBar));
    expect(chordSection?.measureAt(1), Measure.parseString('Am/G,', beatsPerBar));
    expect(chordSection?.measureAt(3), Measure.parseString('FE', beatsPerBar));
    expect(chordSection?.measureAt(4), Measure.parseString('Am', beatsPerBar));
    expect(chordSection?.measureAt(6), Measure.parseString('Am/F♯', beatsPerBar));
    expect(chordSection?.measureAt(7), Measure.parseString('FE', beatsPerBar));

    chordSection = a.getChordSection(lyricSections[3].sectionVersion);
    expect(chordSection?.measureAt(0), Measure.parseString('F', beatsPerBar));
    expect(chordSection?.measureAt(7), Measure.parseString('F', beatsPerBar));
  });

  test('test in song, chordRowMaxLength', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: Am Am/G  v: Am Am/G, Am/F♯ FE   C: F F   O: Dm C\n A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 2);

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: Am Am/G Am/F♯ FE   v: Am Am/G, Am/F♯ FE   C: F F   O: Dm C B B♭, A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 4);

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G, Am/F♯ FE ] x2  C: F F   O: Dm C B B♭, A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 5);

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G, Am/F♯ FE ] x2  C: F F C C G G F  O: Dm C B B♭ A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 7);

    a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G, Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 8);
  });

  test('test SongBase.shareLinesToRow()', () {
    int beatsPerBar = 4;
    SongBase a;

    //  assure that the song can end on an empty section
    a = SongBase(
        title: '12 Bar Blues',
        artist: 'All',
        copyright: 'Unknown',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'V: C F C C,F F C C,  G F C G',
        rawLyrics: 'v:');
    expect(a.lyricSections.length, 1);
    expect(a.lyricSections.first.lyricsLines.length, 0);
  });

  test('test last modified time', () {
    int now = DateTime.now().millisecondsSinceEpoch;
    logger.d('now: $now');

    int beatsPerBar = 4;
    SongBase a;

    //  assure that the song can end on an empty section
    a = SongBase(
        title: '12 Bar Blues',
        artist: 'All',
        copyright: 'Unknown',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        chords: 'V: C F C C,F F C C,  G F C G',
        rawLyrics: 'v:');
    logger.d('a.lastModifiedTime: ${a.lastModifiedTime}');
    expect(now <= a.lastModifiedTime, isTrue);
    now = DateTime.now().millisecondsSinceEpoch;
    logger.d('now: $now');
    expect(now >= a.lastModifiedTime, isTrue);
  });

  test('test empty lyrics rows', () {
    int beatsPerBar = 4;
    Song a;
    String s;

    a = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearlbob',
        chords: 'i: D C G G V: C F C C,F F C C,  G F C G',
        rawLyrics: 'i: v:');

    logger.d('a.rawLyrics: <${a.rawLyrics}>');

    expect(a.lyricsAsString(), 'I:, V:');

    s = 'v:';
    a.rawLyrics = s;
    expect(a.rawLyrics, s);

    a.rawLyrics = 'v:\nnot the last\n\n\nv:\nnot the last\n\n\n';
    expect(a.lyricsAsString(), 'V: "not the last" "\n", V: "not the last" "\n"');

    a.rawLyrics = 'v:\n';
    expect(a.lyricsAsString(), 'V:');

    a.rawLyrics = 'v:\n\n';
    expect(a.lyricsAsString(), 'V:');

    a.rawLyrics = 'v:\n\n\n';
    expect(a.lyricsAsString(), 'V: "\n"');

    a.rawLyrics = 'v:\nA\n';
    expect(a.lyricsAsString(), 'V: "A"');

    a.rawLyrics = 'v:\nA\n\n';
    expect(a.lyricsAsString(), 'V: "A"');

    a.rawLyrics = 'v:    \n      A   \n\n';
    expect(a.lyricsAsString(), 'V: "      A   "');

    a.rawLyrics = 'v: A';
    expect(a.lyricsAsString(), 'V: "A"');

    a.rawLyrics = 'v: A\n';
    expect(a.lyricsAsString(), 'V: "A"');

    a.rawLyrics = 'i:v:\n';
    expect(a.lyricsAsString(), 'I:, V:');

    a.rawLyrics = 'i:\n\nv:\n\n';
    expect(a.lyricsAsString(), 'I:, V:');
    a.rawLyrics = 'i:\n\nv:\n\nv:\n\n';
    expect(a.lyricsAsString(), 'I:, V:, V:');

    a.rawLyrics = 'i:\n\n\n';
    expect(a.lyricsAsString(), 'I: "\n"');

    a.rawLyrics = 'i:\n\n\nv:\n\n\n';
    expect(a.lyricsAsString(), 'I: "\n", V: "\n"');

    a.rawLyrics = 'i:\n\n\nv:\n\n\nv:\n\n\n';
    // for (var lyricSection in a.lyricSections) {
    //   logger.d('${lyricSection.sectionVersion}  lines: ${lyricSection.lyricsLines.length}');
    //   for (var line in lyricSection.lyricsLines) {
    //     logger.d('    "$line"');
    //   }
    // }
    // logger.d(a.toJson());
    expect(a.lyricsAsString(), 'I: "\n", V: "\n", V: "\n"');

    a.rawLyrics = 'i: A\n\nv: B\n\n';
    expect(a.lyricsAsString(), 'I: "A", V: "B"');
    a.rawLyrics = 'i: A\n\nv: B\n\nv: C\n\n';
    expect(a.lyricsAsString(), 'I: "A", V: "B", V: "C"');

    a.rawLyrics = 'i: a\n\n\n';
    expect(a.lyricsAsString(), 'I: "a" "\n"');

    a.rawLyrics = 'i: a\n\n\nv: b\n\n\n';
    expect(a.lyricsAsString(), 'I: "a" "\n", V: "b" "\n"');

    a.rawLyrics = 'i: a\n\n\nv: b\n\n\nv: c\n\n\n';
    expect(a.lyricsAsString(), 'I: "a" "\n", V: "b" "\n", V: "c" "\n"');

    a.rawLyrics = 'i:\n(instrumental)\nv: give me shelter\n';
    expect(a.lyricsAsString(), 'I: "(instrumental)", V: "give me shelter"');

    a.rawLyrics = 'i:v:\n';
    expect(a.lyricsAsString(), 'I:, V:');

    a.rawLyrics = 'a\n\n\n'; //  default to verse
    expect(a.lyricsAsString(), 'V: "a" "\n"');

    //  two blank lines
    a.rawLyrics = 'i: A\n\n\n\nv: B\n\n\n\nv: C\n\n\n\n';
    expect(a.lyricsAsString(), 'I: "A" "\n" "\n", V: "B" "\n" "\n", V: "C" "\n" "\n"');

    a.rawLyrics = 'i: A\n\n\nB\n\n\n\nv: C\n\n\n\n';
    expect(a.lyricsAsString(), 'I: "A" "\n" "\n" "B" "\n" "\n", V: "C" "\n" "\n"');
  });

  void testRawLyricsLoop(String someRawLyrics) {
    int beatsPerBar = 4;
    Song a, b;

    a = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearlbob',
        chords: 'i: D C G G V: C F C C,F F C C,  G F C G',
        rawLyrics: someRawLyrics);

    b = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearlbob',
        chords: 'i: D C G G V: C F C C,F F C C,  G F C G',
        rawLyrics: a.rawLyrics);

    logger.d('testRawLyricsLoop(  ${someRawLyrics.replaceAll('\n', '\\n')})');
    logger.d('a.lyricsAsString(): ${a.lyricsAsString().replaceAll('\n', '\\n')}');
    expect(a.lyricsAsString(), b.lyricsAsString());
    expect(a.songBaseSameContent(b), isTrue);
    expect(someRawLyrics, a.rawLyrics);
    expect(someRawLyrics, b.rawLyrics);
  }

  test('test lyrics parse loop', () {
    int beatsPerBar = 4;
    Song a, b;

    a = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearlbob',
        chords: 'i: D C G G V: C F C C,F F C C,  G F C G',
        rawLyrics: 'i: v:');

    b = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearlbob',
        chords: 'i: D C G G V: C F C C,F F C C,  G F C G',
        rawLyrics: a.rawLyrics);

    expect(a.lyricsAsString(), b.lyricsAsString());
    expect(a.songBaseSameContent(b), isTrue);

    testRawLyricsLoop('v:');
    testRawLyricsLoop('v:\n');
    testRawLyricsLoop('v:\n\n');
    testRawLyricsLoop('v:\n\n\n');
    testRawLyricsLoop('v:\n\n\n\n');

    testRawLyricsLoop('v:\nA\n');
    testRawLyricsLoop('v:v:\nA\n\n');
    testRawLyricsLoop('v:    \n      A   \n\n');
    testRawLyricsLoop('v: A');
    testRawLyricsLoop('v: A\n');
    testRawLyricsLoop('i:v:\n');
    testRawLyricsLoop('i:\n\nv:\n\n');
    testRawLyricsLoop('i:\n\nv:\n\nv:\n\n');
    testRawLyricsLoop('i:\n\n\n');
    testRawLyricsLoop('i:\n\n\nv:\n\n\n');
    testRawLyricsLoop('i:\n\n\nv:\n\n\nv:\n\n\n');
    testRawLyricsLoop('i: A\n\nv: B\n\n');
    testRawLyricsLoop('i: A\n\nv: B\n\nv: C\n\n');
    testRawLyricsLoop('i: a\n\n\n');
    testRawLyricsLoop('i: a\n\n\nv: b\n\n\n');
    testRawLyricsLoop('i: a\n\n\nv: b\n\n\nv: c\n\n\n');
    testRawLyricsLoop('i:\n(instrumental)\nv: give me shelter\n');
    testRawLyricsLoop('i:v:\n');
    testRawLyricsLoop('a\n\n\n');
    testRawLyricsLoop('i: A\n\n\n\nv: B\n\n\n\nv: C\n\n\n\n');
    testRawLyricsLoop('i: A\n\n\n\nB\n\n\n\nv: C\n\n\n\n');

    testRawLyricsLoop('i:\n A B\nv: C D  \n');
  });

  test('test songBase from constructor', () {
    int beatsPerBar = 4;
    int unitsPerMeasure = 4;
    SongBase a;

    {
      a = SongBase(
          title: 'bob song',
          artist: 'bob',
          coverArtist: 'Rolling Stones, The ',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: 100,
          copyright: 'bob stuff');
      expect(a.artist, 'bob');
      expect(a.coverArtist, 'Rolling Stones, The');
    }

    a = SongBase();
    expect(a.title, 'unknown');
    a = SongBase(title: 'bob song');
    expect(a.title, 'bob song');
    a = SongBase(title: 'the bob song');
    expect(a.title, 'bob song, the');
    expect(a.artist, 'unknown');
    expect(a.coverArtist, isEmpty);

    a = SongBase(title: 'bob song', artist: 'bob');
    expect(a.title, 'bob song');
    expect(a.artist, 'bob');
    a = SongBase(title: 'bob song', artist: 'the bob');
    expect(a.title, 'bob song');
    expect(a.artist, 'bob, the');
    expect(a.coverArtist, isEmpty);

    {
      var coverArtist = 'not really bob';
      a = SongBase(title: 'bob song', artist: 'the bob', coverArtist: coverArtist);
      expect(a.title, 'bob song');
      expect(a.artist, 'bob, the');
      expect(a.coverArtist, isNotEmpty);
      expect(a.coverArtist, coverArtist);

      coverArtist = 'the not real bob';
      a = SongBase(title: 'bob song', artist: 'the bob', coverArtist: coverArtist);
      expect(a.title, 'bob song');
      expect(a.artist, 'bob, the');
      expect(a.coverArtist, isNotEmpty);
      expect(a.coverArtist, 'not real bob, the');
    }

    a = SongBase(title: 'bob song', artist: 'bob', beatsPerBar: beatsPerBar);
    expect(a.title, 'bob song');
    expect(a.artist, 'bob');
    expect(a.timeSignature.beatsPerBar, beatsPerBar);

    a = SongBase(title: 'bob song', artist: 'bob', beatsPerBar: beatsPerBar, unitsPerMeasure: unitsPerMeasure);
    expect(a.title, 'bob song');
    expect(a.artist, 'bob');
    expect(a.timeSignature.beatsPerBar, beatsPerBar);
    expect(a.timeSignature.unitsPerMeasure, unitsPerMeasure);
    expect(a.timeSignature, TimeSignature(beatsPerBar, unitsPerMeasure));
    expect(a.beatsPerMinute, MusicConstants.defaultBpm);

    {
      int beatsPerMinute = MusicConstants.defaultBpm;
      a = SongBase(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: beatsPerMinute);
      expect(a.title, 'bob song');
      expect(a.artist, 'bob');
      expect(a.timeSignature.beatsPerBar, beatsPerBar);
      expect(a.timeSignature.unitsPerMeasure, unitsPerMeasure);
      expect(a.timeSignature, TimeSignature(beatsPerBar, unitsPerMeasure));
      expect(a.beatsPerMinute, beatsPerMinute);
    }

    {
      for (var beatsPerMinute = MusicConstants.minBpm; beatsPerMinute <= MusicConstants.maxBpm; beatsPerMinute++) {
        logger.d('bpm: $beatsPerMinute');
        a = SongBase(
            title: 'bob song',
            artist: 'bob',
            beatsPerBar: beatsPerBar,
            unitsPerMeasure: unitsPerMeasure,
            beatsPerMinute: beatsPerMinute);
        expect(a.beatsPerMinute, beatsPerMinute);
      }
    }
    {
      int beatsPerMinute = MusicConstants.minBpm - 1;
      a = SongBase(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: beatsPerMinute);
      expect(a.beatsPerMinute, MusicConstants.minBpm);

      beatsPerMinute = MusicConstants.maxBpm + 1;
      a = SongBase(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: beatsPerMinute);
      expect(a.beatsPerMinute, MusicConstants.maxBpm);
    }

    {
      int beatsPerMinute = MusicConstants.defaultBpm;
      var copyright = '2021 bob';
      a = SongBase(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: beatsPerMinute,
          copyright: copyright);
      expect(a.copyright, copyright);

      copyright = 'the copyright from 2021';
      a = SongBase(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: beatsPerMinute,
          copyright: copyright);
      expect(a.copyright, copyright);
    }

    {
      for (var timeSignature in knownTimeSignatures) {
        a = SongBase(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: timeSignature.beatsPerBar,
          unitsPerMeasure: timeSignature.unitsPerMeasure,
        );
        expect(a.timeSignature, timeSignature);
      }
    }

    {
      var chords = 'i: A B C D v: D C G G';
      a = SongBase(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: MusicConstants.defaultBpm,
          copyright: '2021 bob',
          chords: chords,
          rawLyrics: 'i: intro\nv: i got you');
      logger.d('lyrics: ${a.lyricSections.toString()}');
      expect(a.lyricSections.length, 2);
      expect(a.lyricSections.last.lyricsLines.last, 'i got you');
      expect(a.lyricSections.first.lyricsLines.last, 'intro');
      expect(a.key, music_key.Key.getDefault());

      a = SongBase(
        title: 'bob song',
        artist: 'bob',
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: unitsPerMeasure,
        beatsPerMinute: MusicConstants.defaultBpm,
        copyright: '2021 bob',
        chords: chords,
      );
      logger.d('lyrics: ${a.lyricSections.toString()}');
      expect(a.lyricSections.length, 0);
      try {
        a.checkSong();
        expect(true, isFalse); //  not expected, i.e. expect exception thrown
      } catch (e) {
        expect(e.toString(), 'no lyrics given!');
      }

      expect(a.key, music_key.Key.getDefault());
    }

    {
      //  try some permutations
      List<String> chordList = ['', 'i: A B C D', ''];
      List<String> lyricsList = ['', '', 'i: (instrumental)'];
      for (var title in ['title 1', 'bobs song', 'not bobs song']) {
        for (var artist in ['bob', 'fred', 'joe']) {
          for (var coverArtist in ['', 'bob', 'not bob', 'hidden']) {
            for (var timeSignature in knownTimeSignatures) {
              for (var beatsPerMinute = MusicConstants.minBpm;
                  beatsPerMinute <= MusicConstants.maxBpm;
                  beatsPerMinute++) {
                for (var index = 0; index < chordList.length; index++) {
                  a = SongBase(
                    title: title,
                    artist: artist,
                    coverArtist: coverArtist,
                    user: 'pearlbob',
                    beatsPerBar: timeSignature.beatsPerBar,
                    unitsPerMeasure: timeSignature.unitsPerMeasure,
                    beatsPerMinute: beatsPerMinute,
                    chords: chordList[index],
                    rawLyrics: lyricsList[index],
                  );
                  try {
                    a.checkSong();
                    expect(true, isFalse); //  not expected, i.e. expect exception thrown
                  } catch (e) {
                    switch (index) {
                      case 0:
                      case 2:
                        expect(e.toString(), 'no chords given!');
                        break;
                      case 1:
                        expect(e.toString(), 'no lyrics given!');
                        break;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    {
      a = SongBase(
        title: 'bobs song',
        artist: 'bob',
        coverArtist: 'joe',
        user: 'bob',
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        beatsPerMinute: 4,
        chords: 'i: 2AG#m',
        rawLyrics: 'i: (instrumental)',
      );
      try {
        a.checkSong();
        expect(true, isTrue); //  not expected, i.e. expect exception thrown
      } catch (e) {
        expect(e.toString(), 'no error here!');
      }
      logger.i(a.chords);
      expect(
          a.chords,
          'I:\n'
          '2AG#m\n');
    }
  });

  test('test songBase toGrid()', () {
    int beatsPerBar = 4;
    Song a;

    Logger.level = Level.info;

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'v: [ A B C D ] x4',
          rawLyrics: 'v: foo foo2 foo3 foo4 baby, oh baby2 yesterday\n'
              'bar bar2\n'
              'bob, bob2, bob3 berand\n'
              'You got me');

      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i('a.toGrid(): $grid');
        expect(grid.toString(), '''
Grid{
	V:#0
\tA       B       C       D       x1/4    "foo foo2 foo3 foo4 baby, oh baby2 yesterday"
\tA       B       C       D       x2/4    "bar bar2"
\tA       B       C       D       x3/4    "bob, bob2, bob3 berand"
\tA       B       C       D       x4/4    "You got me"
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	V:#0
	A       B       C       D       x1/4    "foo foo2 foo3 foo4 baby, oh baby2 yesterday"
	A       B       C       D       x2/4    "bar bar2"
	A       B       C       D       x3/4    "bob, bob2, bob3 berand"
	A       B       C       D       x4/4    "You got me"
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
    }
    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'v: [ A B C D ] x2 D C G G x2',
          rawLyrics: 'v: foo foo2 foo3 foo4 baby, oh baby2 yesterday\n'
              'bar bar2\n'
              'bob, bob2, bob3 berand\n'
              'You got me'
              '\nlast lyric');

      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	V:#0
\tA       B       C       D       x1/2    "foo foo2 foo3 foo4 baby, oh baby2 yesterday\\nbar bar2"
\tA       B       C       D       x2/2    "bob, bob2, bob3 berand"
\tD       C       G       G       x1/2    "You got me"
\tD       C       G       G       x2/2    "last lyric"
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	V:#0
	A       B       C       D       x1/2    "foo foo2 foo3 foo4 baby, oh baby2 yesterday\\nbar bar2"
	A       B       C       D       x2/2    "bob, bob2, bob3 berand"
	D       C       G       G       x1/2    "You got me"
	D       C       G       G       x2/2    "last lyric"
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
    }

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb',
          rawLyrics: 'i: v: o:');

      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#
	V:#1
	C       F       C       C#,
	F       F       C       B,
	G       F       C       Gb
	O:#2
	D       C       G       G#
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#
	V:#1
	C       F       C       C#,
	F       F       C       B,
	G       F       C       Gb
	O:#2
	D       C       G       G#
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
    }
    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bsteele.com',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: C F C C# [ F F C B ] x2,  G F C Gb',
          rawLyrics: 'i: v: o:');

      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#      (1,4)
	V:#1
	C       F       C       C#      (3,4)
	F       F       C       B       x1/2    (4,5)
	G       F       C       Gb      (5,4)
	O:#2
	D       C       G       G#      (7,4)
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#      (1,4)
	V:#1
	C       F       C       C#      (3,4)
	F       F       C       B       x1/2    (4,5)
	G       F       C       Gb      (5,4)
	O:#2
	D       C       G       G#      (7,4)
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
    }

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: [C F C C#,F F C B] x2,  G F C Gb',
          rawLyrics: 'i: intro lyric\n'
              'v: verse lyric 1\nverse lyric 2\no: outro lyric\n');

      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#      (1,4)   (1,5)   "intro lyric"
	V:#1
	C       F       C       C#,     ⎤       (3,5)   "verse lyric 1"
\tF       F       C       B       ⎦       x1/2    "verse lyric 2"
\tC       F       C       C#,     ⎤       (5,5)   (5,6)
\tF       F       C       B       ⎦       x2/2    (6,6)
\tG       F       C       Gb      (7,4)   (7,5)
\tO:#2
\tD       C       G       G#      (9,4)   (9,5)   "outro lyric"
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#      (1,4)   (1,5)   "intro lyric"
	V:#1
	C       F       C       C#,     ⎤       (3,5)   "verse lyric 1"
	F       F       C       B       ⎦       x1/2    "verse lyric 2"
	C       F       C       C#,     ⎤       (5,5)   (5,6)
	F       F       C       B       ⎦       x2/2    (6,6)
	G       F       C       Gb      (7,4)   (7,5)
	O:#2
	D       C       G       G#      (9,4)   (9,5)   "outro lyric"
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
    }
    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: [C F C C#,F F C B] x2,  G F C Gb',
          rawLyrics: 'i: intro lyric\n'
              'v: verse lyric 1\nverse lyric 2\nverse lyric 3\n'
              'o: outro lyric\n');

      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#      (1,4)   (1,5)   "intro lyric"
	V:#1
\tC       F       C       C#,     ⎤       (3,5)   "verse lyric 1"
\tF       F       C       B       ⎦       x1/2    "verse lyric 2"
\tC       F       C       C#,     ⎤       (5,5)   "verse lyric 3"
\tF       F       C       B       ⎦       x2/2    (6,6)
\tG       F       C       Gb      (7,4)   (7,5)
\tO:#2
	D       C       G       G#      (9,4)   (9,5)   "outro lyric"
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
      {
        var grid = a.toDisplayGrid(UserDisplayStyle.both);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#      (1,4)   (1,5)   "intro lyric"
	V:#1
	C       F       C       C#,     ⎤       (3,5)   "verse lyric 1"
	F       F       C       B       ⎦       x1/2    "verse lyric 2"
	C       F       C       C#,     ⎤       (5,5)   "verse lyric 3"
	F       F       C       B       ⎦       x2/2    (6,6)
	G       F       C       Gb      (7,4)   (7,5)
	O:#2
	D       C       G       G#      (9,4)   (9,5)   "outro lyric"
}''');
        _testSongMomentToGrid(a, UserDisplayStyle.both);
      }
    }
  });

  test('test song toGrid()', () {
    Logger.level = Level.info;

    int beatsPerBar = 4;
    Song a;

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb',
          rawLyrics: 'i: v: o:');
      var grid = a.toDisplayGrid(UserDisplayStyle.both);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#
	V:#1
	C       F       C       C#,
	F       F       C       B,
	G       F       C       Gb
	O:#2
	D       C       G       G#
}''');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }
    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B x2,  G F C Gb',
          rawLyrics: 'i: v: o:');

      var grid = a.toDisplayGrid(UserDisplayStyle.both);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	D       C       G       G#      (1,4)
	V:#1
	C       F       C       C#      (3,4)
	F       F       C       B       x1/2    (4,5)
	G       F       C       Gb      (5,4)
	O:#2
	D       C       G       G#      (7,4)
}''');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: [C F C C#,F F C B] x2,  G F C Gb',
          rawLyrics: 'i: v: o:');
      var grid = a.toDisplayGrid(UserDisplayStyle.both);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
\tD       C       G       G#      (1,4)   (1,5)
\tV:#1
\tC       F       C       C#,     ⎤       (3,5)   (3,6)
\tF       F       C       B       ⎦       x1/2    (4,6)
\tG       F       C       Gb      (5,4)   (5,5)
\tO:#2
\tD       C       G       G#      (7,4)   (7,5)
}''');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }
  });

  test('test songBase songMomentToGrid()', () {
    Logger.level = Level.info;

    int beatsPerBar = 4;
    Song a;

    {
      //  empty lyrics
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'v: G G G G, C C G G, D C G D',
          rawLyrics: 'v:');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }
    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i: D C G G# x2',
          rawLyrics: 'i: no lyrics here');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }
    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb',
          rawLyrics: 'i: intro lyric\n'
              'v: verse lyric\n'
              'more verse lyrcs\n'
              'o: outro lyric');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i: D C G G# x2',
          rawLyrics: 'i: no lyrics here');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }
    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B x2,  G F C Gb',
          rawLyrics: 'i: v: o:');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }
    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'V: [C F C C#, F F C B] x2',
          rawLyrics: 'v: hey!');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:o: D C G G# V: [C F C C#, F F C B] x2,  G F C Gb',
          rawLyrics: 'i: v: o:');
      _testSongMomentToGrid(a, UserDisplayStyle.both);
    }
  });

  test('test songBase validateChords', () {
    int beatsPerBar = 4;

    {
//  allow single beat measures
      var chordEntry = '''
i: 1A 2B 3C D
''';
      var markedString = SongBase.validateChords(SongBase.entryToUppercase(chordEntry), beatsPerBar);
      expect(markedString, isNull);
    }
    {
//  don't allow empty chord sections
      var chordEntry = '''
i: A B C D , []
''';
      var markedString = SongBase.validateChords(SongBase.entryToUppercase(chordEntry), beatsPerBar);
      expect(markedString, isNotNull);
      expect(markedString.toString(), ']\n');
      expect(markedString!.getMark(), 14);
    }
    {
//  don't allow empty chord sections
      var chordEntry = '''
i:
''';
      var markedString = SongBase.validateChords(SongBase.entryToUppercase(chordEntry), beatsPerBar);
      expect(markedString, isNotNull);
      expect(markedString.toString(), 'I: [] ');
    }
    {
//  don't allow empty chord phrase sections
      var chordEntry = '''
i: []
''';
      var markedString = SongBase.validateChords(SongBase.entryToUppercase(chordEntry), beatsPerBar);
      expect(markedString, isNotNull);
      expect(markedString.toString(), ']\n');
      expect(markedString!.getMark(), 4);
    }

    expect(SongBase.validateChords('', beatsPerBar), null);
    expect(SongBase.validateChords('i: A', beatsPerBar), null);
    {
      var markedString = SongBase.validateChords(
          SongBase.entryToUppercase('i: d c g g, [ A B c/f# d/gb ] x4 v: [ C F ] x14 asus7 ajklm b C D'), beatsPerBar);
      if (markedString == null) {
        expect(markedString, isNotNull); //  fail
      } else {
        logger.i('m: \'$markedString\'');

        expect(markedString.toString(), 'jklm B C D');
        expect(markedString.getMark(), 55);
        expect(markedString.getNextWhiteSpaceIndex(), 59);
        expect(markedString.remainingStringLimited(markedString.getNextWhiteSpaceIndex() - markedString.getMark()),
            'jklm');
      }
    }
    {
      var chordEntry = '''
i:
  d c g g
  [ A B c/f# d/gb ] x4
v:
 [ C F ] x14
 asus7 ajklm b
 C D
''';
      var markedString = SongBase.validateChords(SongBase.entryToUppercase(chordEntry), beatsPerBar);
      if (markedString == null) {
        expect(markedString, isNotNull); //  fail
      } else {
        logger.i('m: \'$markedString\'');
        assert(markedString.toString().startsWith('jklm '));
        expect(markedString.getMark(), 60);
        expect(markedString.getNextWhiteSpaceIndex(), 64);
        var error = markedString.remainingStringLimited(markedString.getNextWhiteSpaceIndex() - markedString.getMark());
        expect(error, 'jklm');
      }
    }
  });

  test('test songBase validateLyrics', () {
    int beatsPerBar = 4;
    {
//  empty lyrics
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'v: G G G G, C C G G, D C G D',
          rawLyrics: 'v: foobar');
      expect(a.validateLyrics(''), null);
      expect(a.validateLyrics('no section here').runtimeType, LyricParseException);
      expect(a.validateLyrics('no section here')?.message, 'Lyrics prior to section version');
      expect(a.validateLyrics('no section here  v: foo').runtimeType, LyricParseException);
      expect(a.validateLyrics('no section here  v: foo')?.message, 'Lyrics prior to section version');

//  non-empty lyrics
      var lyrics = '    v:\n foo\n';
      expect(a.validateLyrics(lyrics), null); //  no error

//  missing lead section
      lyrics = 'no\n  v:\n foo\n';
      expect(a.validateLyrics(lyrics).runtimeType, LyricParseException);
      expect(a.validateLyrics(lyrics)?.message, 'Lyrics prior to section version');
      expect(a.validateLyrics(lyrics)?.markedString.toString(), 'no\n  v:\n foo\n');

//  damaged section
      expect(a.validateLyrics('herev: foo').runtimeType, LyricParseException);
      expect(a.validateLyrics('herev: foo')?.message, 'Lyrics prior to section version');
      expect(a.validateLyrics('herev: foo')?.markedString.toString(), 'herev: foo');

//  missing chords
      expect(a.validateLyrics('v: lkf'), null); // no error
      expect(a.validateLyrics('i: lkf').runtimeType, LyricParseException);
      expect(a.validateLyrics('i: lkf')?.message, 'Section version not found');

//  multiple sections
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearlbob',
          chords: 'i:v: G G G G, C C G G, D C G D',
          rawLyrics: 'v: foobar');
      lyrics = 'i: no\n  v:\n foo\n';
      expect(a.validateLyrics('i:v: lkf'), null); // no error

//  multiple sections, empty last lyrics
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i:v: G G G G, C C G G, D C G D',
          rawLyrics: 'v: foobar');
      lyrics = 'i: no\n  v:\n foo\ni:';
      expect(a.validateLyrics('i:v: lkf'), null); // no error

//  unused chord section
      lyrics = 'i: no\n bar bar';
      expect(a.validateLyrics(lyrics).runtimeType, LyricParseException);
      expect(a.validateLyrics(lyrics)?.message,
          'Chord section V: is missing from the lyrics, add at least one use or remove it from the chords.');
      expect(a.validateLyrics(lyrics)?.markedString.toString(), 'V:');
    }
  });

  test('test songBase toMarkup as entry', () {
    int beatsPerBar = 4;
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'v: []',
          rawLyrics: 'v: foobar');
      expect(
          a.toMarkup(asEntry: true),
          'V: \n'
          '  []\n'
          '');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'v: [] c: []',
          rawLyrics: 'v: foobar');
      expect(
          a.toMarkup(asEntry: true),
          'V: \n'
          '  []\n'
          'C: \n'
          '  []\n'
          '');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'v: G G G G, C C G G, D C G D',
          rawLyrics: 'v: foobar');
      expect(
          a.toMarkup(asEntry: true),
          'V: \n'
          '  G G G G\n'
          '  C C G G\n'
          '  D C G D\n'
          '\n'
          '');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: v: G G G G, C C G G, D C G D',
          rawLyrics: 'i: (instrumental) v: foobar');
      expect(
          a.toMarkup(asEntry: true),
          'I: V: \n'
          '  G G G G\n'
          '  C C G G\n'
          '  D C G D\n'
          '\n'
          '');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: [ A B C D ] x2 v: G G G G, [C C G G]x4 D C G D',
          rawLyrics: 'i: (instrumental) v: foobar');

      expect(
          a.toMarkup(asEntry: true),
          'I: \n'
          ' [A B C D] x2\n'
          '\n'
          'V: \n'
          '  G G G G\n'
          ' [C C G G] x4\n'
          '  D C G D\n'
          '\n');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x4',
          rawLyrics: 'i: (instrumental) v: foobar');
      expect(
          a.toMarkup(asEntry: true),
          'I: \n'
          ' [A B C D] x2\n'
          '\n'
          'V: \n'
          ' [G G G G\n'
          '  C C G G\n'
          '  D C G D] x4\n'
          '\n');
    }
  });

  test('test songBase chordMarkupForLyrics()', () {
    int beatsPerBar = 4;
    {
//  fixme: force a new line at lyrics entry?
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n A B C D\n'
          'V:\n'
          ' G G G G, C C G G\n'
          'O: C C G G\n');
    }
    {
//  fixme: force a new line at lyrics entry?
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i:\n(instrumental)\n\nv: line 1\n\no:\n\n');
      logger.i(a.lyricSectionsAsEntryString);

      expect(
          a.chordMarkupForLyrics(),
          'I:\n'
          ' A B C D\n'
          'V:\n'
          ' G G G G, C C G G\n'
          'O: C C G G\n');
    }
    {
      for (var lines = 1; lines < 20; lines++) {
        String lyrics;
        {
          var sb = StringBuffer('i: (instrumental)\n v: ');
          for (var i = 1; i <= lines; i++) {
            sb.write('line $i\n');
          }
          lyrics = sb.toString();
        }
        var a = Song(
            title: 'ive go the blanks',
            artist: 'bob',
            copyright: 'bob',
            key: music_key.Key.get(music_key.KeyEnum.C),
            beatsPerMinute: 106,
            beatsPerBar: beatsPerBar,
            unitsPerMeasure: 4,
            user: 'pearl bob',
            chords: 'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x2',
            rawLyrics: //  no newline at verse lyrics should not matter
                lyrics);
        logger.i('lines $lines: "${a.chordMarkupForLyrics()}"');
        expect(a.chordMarkupForLyrics().split('\n').length, lines + 3 + 1);
      }
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i:\nv: line 1\no:');
      expect(
          a.chordMarkupForLyrics(),
          'I: A B C D\n'
          'V:\n'
          ' G G G G, C C G G\n'
          'O: C C G G\n');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i:\nv:\nline 1\no:');
      expect(
          a.chordMarkupForLyrics(),
          'I: A B C D\n'
          'V:\n'
          ' G G G G, C C G G\n'
          'O: C C G G\n');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x4',
          rawLyrics: 'i: (instrumental)\n v: foobar');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n[A B C D] x1/2 [A B C D] x2/2\n'
          'V:\n[G G G G, C C G G, D C G D] x1/4 [G G G G, C C G G, D C G D] x2/4'
          ' [G G G G, C C G G, D C G D] x3/4 [G G G G, C C G G, D C G D] x4/4\n');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x4',
          rawLyrics: 'i: (instrumental)\n '
              'v:\nline 1\nline 2\nline 3\nline 4\nline 5\nline 6\n');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n'
          '[A B C D] x1/2 [A B C D] x2/2\n'
          'V:\n'
          '[G G G G\n'
          ' C C G G\n'
          ' D C G D] x1/4\n'
          '[G G G G\n'
          ' C C G G\n'
          ' D C G D] x2/4 [G G G G, C C G G, D C G D] x3/4 [G G G G, C C G G, D C G D] x4/4\n');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x4',
          rawLyrics: //  no newline at verse lyrics should not matter
              'i: (instrumental)\n v: line 1\nline 2\nline 3\nline 4\nline 5\nline 6\n');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n'
          '[A B C D] x1/2 [A B C D] x2/2\n'
          'V:\n'
          '[G G G G\n'
          ' C C G G\n'
          ' D C G D] x1/4\n'
          '[G G G G\n'
          ' C C G G\n'
          ' D C G D] x2/4 [G G G G, C C G G, D C G D] x3/4 [G G G G, C C G G, D C G D] x4/4\n');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G',
          rawLyrics: 'i: (instrumental)\nyeah\n v: line 1\nline 2\nline 3\nline 4\nline 5\nline 6\n');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n'
          ' A B C D\n'
          '\n'
          'V:\n'
          ' G G G G\n'
          '\n'
          '\n'
          ' C C G G\n'
          '\n'
          '\n');
    }
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  V: [Am Am/G Am/F# FE] x4',
          rawLyrics: 'i:\nv:\nWaiting for the break of day\n'
              'Searching for something to say\n'
              'Flashing lights against the sky\n'
              'Giving up I close my eyes\n');

      expect(
          a.chordMarkupForLyrics(),
          'I: A B C D\n'
          'V:\n'
          '[Am Am/G Am/F# FE] x1/4\n'
          '[Am Am/G Am/F# FE] x2/4\n'
          '[Am Am/G Am/F# FE] x3/4\n'
          '[Am Am/G Am/F# FE] x4/4\n');
    }
  });

  final RegExp lastModifiedDateRegexp = RegExp(r'"lastModifiedDate": \d+,\n');
  test('test songBase to/from JSON', () {
    int beatsPerBar = 4;
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

      expect(
          a.toJson().replaceAll(lastModifiedDateRegexp, 'lastModifiedDate was here\n'),
          '{\n'
          '"title": "ive go the blanks",\n'
          '"artist": "bob",\n'
          '"user": "pearl bob",\n'
          'lastModifiedDate was here\n'
          '"copyright": "bob",\n'
          '"key": "C",\n'
          '"defaultBpm": 106,\n'
          '"timeSignature": "4/4",\n'
          '"chords": \n'
          '    [\n'
          '\t"I:",\n'
          '\t"A B C D",\n'
          '\t"V:",\n'
          '\t"G G G G",\n'
          '\t"C C G G",\n'
          '\t"O:",\n'
          '\t"C C G G"\n'
          '    ],\n'
          '"lyrics": \n'
          '    [\n'
          '\t"i: (instrumental)",\n'
          '\t"v: line 1",\n'
          '\t"o:"\n'
          '    ]\n'
          '}\n'
          '');
      expect(a.toString(), 'ive go the blanks by bob');
      Song b = Song.songListFromJson(a.toJson()).first;
      expect(a.toString(), b.toString());
      expect(a.toJson(), b.toJson());
      expect(a.compareBySongId(b), 0);
      expect(a.songBaseSameContent(b), true);
      expect(a.songBaseSameContent(b.copySong()), true);

      a.coverArtist = 'Bob Marley';
      expect(a.toString(), 'ive go the blanks by bob, cover by Bob Marley');
      expect(
          a.toJson().replaceAll(lastModifiedDateRegexp, 'lastModifiedDate was here\n'),
          '{\n'
          '"title": "ive go the blanks",\n'
          '"artist": "bob",\n'
          '"coverArtist": "Bob Marley",\n'
          '"user": "pearl bob",\n'
          'lastModifiedDate was here\n'
          '"copyright": "bob",\n'
          '"key": "C",\n'
          '"defaultBpm": 106,\n'
          '"timeSignature": "4/4",\n'
          '"chords": \n'
          '    [\n'
          '\t"I:",\n'
          '\t"A B C D",\n'
          '\t"V:",\n'
          '\t"G G G G",\n'
          '\t"C C G G",\n'
          '\t"O:",\n'
          '\t"C C G G"\n'
          '    ],\n'
          '"lyrics": \n'
          '    [\n'
          '\t"i: (instrumental)",\n'
          '\t"v: line 1",\n'
          '\t"o:"\n'
          '    ]\n'
          '}\n'
          '');
      expect(a.songBaseSameContent(a.copySong()), true);
      b = Song.songListFromJson(a.toJson()).first;
      expect(a.toString(), b.toString());
      expect(a.toJson(), b.toJson());
      expect(a.compareBySongId(b), 0);
      expect(a.songBaseSameContent(b), true);
      expect(a.songBaseSameContent(b.copySong()), true);
    }
  });

  test('test songBase getSongMomentNumberAtSongTime', () {
    int beatsPerBar = 4;
    int bpm = 106;
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var totalBeats = a.totalBeats;
      var beatDuration = 60.0 / bpm;
      expect(totalBeats, 64); //  sanity only

      expect(a.duration, greaterThan((totalBeats * beatDuration).floor()));
      expect(a.duration, lessThan((totalBeats * beatDuration).ceil()));

      expect(a.getSongMomentNumberAtSongTime(2 * beatDuration), 0);
      expect(a.getSongMomentNumberAtSongTime(3 * beatDuration), 0);
      expect(a.getSongMomentNumberAtSongTime(4 * beatDuration), 1);

      var limit = beatsPerBar * (36 + 3);
      for (var beat = -2 * beatsPerBar; beat < limit; beat++) {
        var d = beatDuration * beat;
        expect(a.getSongMomentNumberAtSongTime(d),
            (beat < totalBeats) ? (d / (beatsPerBar * beatDuration)).floor() : null);
      }
    }
  });

  test('test songBase getYear', () {
    int beatsPerBar = 4;
    int bpm = 106;
    for (var year in [1796, 1900, 2069, 2022]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'copyright $year bob hot music',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }

    for (var year in [179, 0, 20609, 2]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'copyright $year bob hot music',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, SongBase.defaultYear);
    }

    for (var year in [1796, 1900, 2069, 2022]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'copyright $year',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }

    for (var year in [179, 0, 20609, 2]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'copyright $year',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, SongBase.defaultYear);
    }

    for (var year in [1796, 1900, 2069, 2022]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: '$year bob music',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }

    for (var year in [179, 0, 20609, 2]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: '$year bob music',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, SongBase.defaultYear);
    }

    for (var year in [1796, 1900, 2069, 2022]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: '$year',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }

    for (var year in [179, 0, 20609, 2]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: '$year',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, SongBase.defaultYear);
    }

    for (var year in [2002, 1960]) {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: '℗© $year Hollywood Records, Inc.',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');
      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }
  });

  test('test songBase read dos files', () {
    int beatsPerBar = 4;
    int bpm = 106;
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\r\nmore instrumental\nv: line 1\r\n line 2\r\no:\r\nyo\ryo2\nyo3\r\nyo4');
      for (var lyricSection in a.lyricSections) {
        for (var line in lyricSection.lyricsLines) {
          expect(line.trim().isNotEmpty, isTrue);
        }
      }
    }
  });

  test('test ChordSectionGridData toString()', () {
    int beatsPerBar = 4;
    int bpm = 106;
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: bpm,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  x4 v: G G G G, C C G G o: [ C C G G, E F G E ] x3 A B C',
          rawLyrics: 'i: (instrumental)\r\nmore instrumental\nv: line 1\r\n line 2\r\no:\r\nyo\ryo2\nyo3\r\nyo4');

      var grid = a.chordSectionGrid;
// for (int r = 0; r < grid.getRowCount(); r++) {
//   var row = grid.getRow(r);
//   for (int c = 0; c < row!.length; c++) {
//     var data = grid.get(r, c);
//     logger.i('expect(grid.get($r,$c)?.toMarkup(), \'${data?.toMarkup() ?? 'isNull'}\');');  //  almost
//   }
// }

      expect(grid.get(0, 0)?.transpose(music_key.Key.C, 0), 'I:');
      expect(grid.get(0, 1)?.transpose(music_key.Key.C, 0), 'A');
      expect(grid.get(0, 2)?.transpose(music_key.Key.C, 0), 'B');
      expect(grid.get(0, 3)?.transpose(music_key.Key.C, 0), 'C');
      expect(grid.get(0, 4)?.transpose(music_key.Key.C, 0), 'D');
      expect(grid.get(0, 5)?.transpose(music_key.Key.C, 0), ']');
      expect(grid.get(0, 6)?.transpose(music_key.Key.C, 0), 'x4');
      expect(grid.get(1, 0)?.transpose(music_key.Key.C, 0), 'V:');
      expect(grid.get(1, 1)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(1, 2)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(1, 3)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(1, 4)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(2, 0)?.transpose(music_key.Key.C, 0), isNull);
      expect(grid.get(2, 1)?.transpose(music_key.Key.C, 0), 'C');
      expect(grid.get(2, 2)?.transpose(music_key.Key.C, 0), 'C');
      expect(grid.get(2, 3)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(2, 4)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(3, 0)?.transpose(music_key.Key.C, 0), 'O:');
      expect(grid.get(3, 1)?.transpose(music_key.Key.C, 0), 'C');
      expect(grid.get(3, 2)?.transpose(music_key.Key.C, 0), 'C');
      expect(grid.get(3, 3)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(3, 4)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(3, 5)?.transpose(music_key.Key.C, 0), '⎤');
      expect(grid.get(4, 0)?.transpose(music_key.Key.C, 0), isNull);
      expect(grid.get(4, 1)?.transpose(music_key.Key.C, 0), 'E');
      expect(grid.get(4, 2)?.transpose(music_key.Key.C, 0), 'F');
      expect(grid.get(4, 3)?.transpose(music_key.Key.C, 0), 'G');
      expect(grid.get(4, 4)?.transpose(music_key.Key.C, 0), 'E');
      expect(grid.get(4, 5)?.transpose(music_key.Key.C, 0), '⎦');
      expect(grid.get(4, 6)?.transpose(music_key.Key.C, 0), 'x3');
      expect(grid.get(5, 0)?.transpose(music_key.Key.C, 0), isNull);
      expect(grid.get(5, 1)?.transpose(music_key.Key.C, 0), 'A');
      expect(grid.get(5, 2)?.transpose(music_key.Key.C, 0), 'B');
      expect(grid.get(5, 3)?.transpose(music_key.Key.C, 0), 'C');
    }
  });

  test('test songBase toDisplayGrid()', () {
    int beatsPerBar = 4;
    Song a;
    var userDisplayStyle = UserDisplayStyle.proPlayer;
    Grid<MeasureNode> grid;
    Logger.level = Level.info;

    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D x3 v: D C G G',
          rawLyrics: 'i: (instrumental)\nlast lyric of intro repeat\n'
              'v: one verse lyric line');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	A       B       C       D       x1/3    "(instrumental)"
	A       B       C       D       x2/3    "last lyric of intro repeat"
	A       B       C       D       x3/3    (3,5)
	V:#1
	D       C       G       G       (5,4)   "one verse lyric line"
}''');
    }

    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D x3 v: D C G G',
          rawLyrics: 'i: (instrumental)\nanother lyrics line\nlast lyric of intro repeat\n'
              'v: one verse lyric line');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	A       B       C       D       x1/3    "(instrumental)"
	A       B       C       D       x2/3    "another lyrics line"
	A       B       C       D       x3/3    "last lyric of intro repeat"
	V:#1
	D       C       G       G       (5,4)   "one verse lyric line"
}''');
    }

    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D x3 v: D C G G',
          rawLyrics: 'i: (instrumental)\n lyrics due in first line\nanother lyrics line\nlast lyric of intro repeat\n'
              'v: one verse lyric line');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	A       B       C       D       x1/3    "(instrumental)\\nlyrics due in first line"
	A       B       C       D       x2/3    "another lyrics line"
	A       B       C       D       x3/3    "last lyric of intro repeat"
	V:#1
	D       C       G       G       (5,4)   "one verse lyric line"
}''');
    }

    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D x3 v: D C G G',
          rawLyrics: 'i: (instrumental)\n lyrics due in first line\nanother lyrics line\nlast lyric of intro repeat\n'
              'v: one verse lyric line');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	A       B       C       D       x1/3    "(instrumental)\\nlyrics due in first line"
	A       B       C       D       x2/3    "another lyrics line"
	A       B       C       D       x3/3    "last lyric of intro repeat"
	V:#1
	D       C       G       G       (5,4)   "one verse lyric line"
}''');
    }

    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D x3 C D G C v: D C G G',
          rawLyrics: 'i: (instrumental)\nmore instrumental\nyet more intro2\nlast line of intro: C D G C\n'
              'v: one verse lyric line');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	A       B       C       D       x1/3    "(instrumental)"
	A       B       C       D       x2/3    "more instrumental"
	A       B       C       D       x3/3    "yet more intro2"
	C       D       G       C       (4,4)   "last line of intro: C D G C"
	V:#1
	D       C       G       G       (6,4)   "one verse lyric line"
}''');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
\tA       B       C       D       x1/3    "(instrumental)"
\tA       B       C       D       x2/3    "more instrumental"
\tA       B       C       D       x3/3    "yet more intro2"
\tC       D       G       C       (4,4)   "last line of intro: C D G C"
	V:#1
	D       C       G       G       (6,4)   "one verse lyric line"
}''');
    }

//     {
//       //  fixme: UserDisplayStyle.proPlayer
//       userDisplayStyle = UserDisplayStyle.proPlayer;
//       a = Song(
//           title: 'ive go the blanks',
//           artist: 'bob',
//           copyright: 'bob',
//           key: music_key.Key.get(music_key.KeyEnum.C),
//           beatsPerMinute: 104,
//           beatsPerBar: beatsPerBar,
//           unitsPerMeasure: 4,
//           user: 'pearl bob',
//           chords: 'v: [ A B C D ] x4',
//           rawLyrics: 'v: foo foo foo foo baby oh baby yesterday\n'
//               'bar bar\n'
//               'bob, bob, bob berand\n'
//               'You got me');
//
//       var grid = a.toDisplayGrid(userDisplayStyle);
//       logger.i(grid.toString());
//       expect(grid.toString(), '''
// Grid{
// 	V:\\nA B C D  x4\\n
// 	V:\\nA B C D  x4\\nV:\\nA B C D  x4\\n
// }''');
//       _testSongMomentToGrid(a, userDisplayStyle);
//     }

    {
      userDisplayStyle = UserDisplayStyle.proPlayer;
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb',
          rawLyrics: 'i: v: o:');

      {
        var grid = a.toDisplayGrid(userDisplayStyle);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:\\nD C G G# \\nV:\\nC F C C#, F F C B, G F C Gb \\nO:\\nD C G G# \\n
	I:\\nD C G G# \\nI:\\nD C G G# \\n
	V:\\nC F C C#, F F C B, G F C Gb \\nV:\\nC F C C#, F F C B, G F C Gb \\n
	O:\\nD C G G# \\nO:\\nD C G G# \\n
}''');
        expect(grid.getRowCount(), 3 + 1);
        expect((grid.get(0, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.intro), 0));
        expect((grid.get(0, 1) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect((grid.get(0, 2) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.outro), 0));
        expect((grid.get(1, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.intro), 0));
        expect((grid.get(1, 1) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.intro), 0));
        expect((grid.get(2, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect((grid.get(2, 1) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect((grid.get(3, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.outro), 0));
        expect((grid.get(3, 1) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.outro), 0));

//  in pro, verify top row of chord sections in song order
        for (var songMoment in a.songMoments) {
          logger.d('$songMoment: ${a.songMomentToGridCoordinate[songMoment.momentNumber]}');
          expect(
              grid.get(0, a.songMomentToGridCoordinate[songMoment.momentNumber].row - 1 /* row is at +1  */)
                  as ChordSection,
              songMoment.chordSection);
        }
//  in pro, verify each section has it's label and duplicate for chords
        for (var songMoment in a.songMoments) {
//  expect entry for section labels
          var gc = a.songMomentToGridCoordinate[songMoment.momentNumber];
          logger.d('$songMoment: $gc');
          expect(grid.at(gc) as ChordSection, songMoment.chordSection);
//  expect duplicate for chords
          expect(grid.at(GridCoordinate(gc.row, gc.col + 1)) as ChordSection, songMoment.chordSection);
        }
        _testSongMomentToGrid(a, userDisplayStyle);
      }
    }
    {
      userDisplayStyle = UserDisplayStyle.singer;
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'v: [ A B C D ] x4',
          rawLyrics: 'v: foo foo foo foo baby oh baby yesterday\n'
              'bar bar\n'
              'bob, bob, bob berand\n'
              'You got me');

      {
        var grid = a.toDisplayGrid(userDisplayStyle);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	V:#0    V:\\nA B C D  x4\\n
	(1,0)   "foo foo foo foo baby oh baby yesterday"
	(2,0)   "bar bar"
	(3,0)   "bob, bob, bob berand"
	(4,0)   "You got me"
}''');
        expect(grid.getRowCount(), 5);
        assert(grid.get(0, 0) is LyricSection);
        var lyricSection = grid.get(0, 0) as LyricSection;
        expect(lyricSection.sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect(grid.get(1, 0), isNull);
        expect(grid.get(1, 1)!.measureNodeType, MeasureNodeType.lyric);
        var lyric = grid.get(1, 1) as Lyric;
        expect(lyric.line, 'foo foo foo foo baby oh baby yesterday');
        expect(grid.get(2, 0), isNull);
        lyric = grid.get(2, 1) as Lyric;
        expect(lyric.line, 'bar bar');
        expect(grid.get(3, 0), isNull);
        lyric = grid.get(3, 1) as Lyric;
        expect(lyric.line, 'bob, bob, bob berand');
        expect(grid.get(4, 0), isNull);
        lyric = grid.get(4, 1) as Lyric;
        expect(lyric.line, 'You got me');

        _testSongMomentToGrid(a, userDisplayStyle);
      }
    }
    {
      userDisplayStyle = UserDisplayStyle.singer;
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb',
          rawLyrics: 'i: (instrumental)\n '
              'v: v: foo foo foo foo baby\n oh baby yesterday\n'
              'bar bar\no:  yo yo yo\n yeah');

      {
        var grid = a.toDisplayGrid(userDisplayStyle);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	I:#0    I:\\nD C G G# \\n
	(1,0)   "(instrumental)"
	V:#1    V:\\nC F C C#, F F C B, G F C Gb \\n
	V:#2    V:\\nC F C C#, F F C B, G F C Gb \\n
	(4,0)   "foo foo foo foo baby"
	(5,0)   "oh baby yesterday"
	(6,0)   "bar bar"
	O:#3    O:\\nD C G G# \\n
	(8,0)   "yo yo yo"
	(9,0)   "yeah"
}''');
        _testSongMomentToGrid(a, userDisplayStyle);
      }
    }

    {
      userDisplayStyle = UserDisplayStyle.both;
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  x4 v: G G G G, C C G G o: [ C C G G, E F G E ] x3 A B C',
          rawLyrics: 'i: (instrumental)\nmore instrumental\n'
              'v: line 1\n line 2\n'
              'o:\n'
              'yo1\n'
              'yo2\n'
              'yo3\n'
              'yo4');

      var grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
\tA       B       C       D       x1/4    (1,5)   "(instrumental)"
\tA       B       C       D       x2/4    (2,5)   "more instrumental"
\tA       B       C       D       x3/4    (3,5)   (3,6)
\tV:#1
\tG       G       G       G,      (5,4)   (5,5)   "line 1"
\tC       C       G       G       (6,4)   (6,5)   "line 2"
\tO:#2
\tC       C       G       G,      ⎤       (8,5)   "yo1"
\tE       F       G       E       ⎦       x1/3    "yo2"
\tC       C       G       G,      ⎤       (10,5)  "yo3"
\tE       F       G       E       ⎦       x2/3    "yo4"
\tC       C       G       G,      ⎤       (12,5)  (12,6)
\tE       F       G       E       ⎦       x3/3    (13,6)
\tA       B       C       (14,3)  (14,4)  (14,5)
}''');
    }

    {
      userDisplayStyle = UserDisplayStyle.both;
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  x4 v: G G G G, C C G G o: [ C C G G, E F G E ] x3 A B C',
          rawLyrics: 'i: (instrumental)\nmore instrumental'
              'v: line 1\n line 2\n'
              'o:\n'
              'yo1\n'
              'yo2\n'
              'yo3\n'
              'yo4\nyo5\nyo6');

      var grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
\tA       B       C       D       x1/4    (1,5)   "(instrumental)"
\tA       B       C       D       x2/4    (2,5)   "more instrumentalv: line 1"
\tA       B       C       D       x3/4    (3,5)   "line 2"
\tA       B       C       D       x4/4    (4,5)   (4,6)
\tO:#1
\tC       C       G       G,      ⎤       (6,5)   "yo1"
\tE       F       G       E       ⎦       x1/3    "yo2"
\tC       C       G       G,      ⎤       (8,5)   "yo3"
\tE       F       G       E       ⎦       x2/3    "yo4"
\tC       C       G       G,      ⎤       (10,5)  "yo5"
\tE       F       G       E       ⎦       x3/3    "yo6"
\tA       B       C       (12,3)  (12,4)  (12,5)
}''');

//  validate song moment to grid coordinates
      _testSongMomentToGrid(a, userDisplayStyle);
    }
    {
      userDisplayStyle = UserDisplayStyle.both;
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  x4 v: G G G G, C C G G o: [ C C G G, E F G E ] x3 A B C',
          rawLyrics: 'i: (instrumental)\nmore instrumental\n'
              'v: line 1\n line 2\n'
              'o:\n'
              'yo1\n'
              'yo2\n'
              'yo3\n'
              'yo4\nyo5\nyo6\nyo7');

      var grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
\tA       B       C       D       x1/4    (1,5)   "(instrumental)"
\tA       B       C       D       x2/4    (2,5)   "more instrumental"
\tA       B       C       D       x3/4    (3,5)   (3,6)
\tV:#1
\tG       G       G       G,      (5,4)   (5,5)   "line 1"
\tC       C       G       G       (6,4)   (6,5)   "line 2"
\tO:#2
\tC       C       G       G,      ⎤       (8,5)   "yo1"
\tE       F       G       E       ⎦       x1/3    "yo2"
\tC       C       G       G,      ⎤       (10,5)  "yo3"
\tE       F       G       E       ⎦       x2/3    "yo4"
\tC       C       G       G,      ⎤       (12,5)  "yo5"
\tE       F       G       E       ⎦       x3/3    "yo6"
\tA       B       C       (14,3)  (14,4)  (14,5)  "yo7"
}''');
      _testSongMomentToGrid(a, userDisplayStyle);
    }
  });

  test('test songBase toDisplayGrid() instrumental exception', () {
    int beatsPerBar = 4;
    Song a;
    var userDisplayStyle = UserDisplayStyle.proPlayer;
    Grid<MeasureNode> grid;
    Logger.level = Level.info;

    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D x3 v: D C G G',
          rawLyrics: 'i: (instrumental)\n'
              'v: one verse lyric line');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	A       B       C       D       x1/3    "(instrumental)"
	V:#1
	D       C       G       G       (3,4)   "one verse lyric line"
}''');

      for (var i = 0; i < 16; i++) {
        expect(a.songMomentToRepeatRowRange(i), (0, 3));
      }
    }
    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D x3 v: D C G G',
          rawLyrics: 'i: line 1\nline 2\n'
              'v: one verse lyric line');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	I:#0
	A       B       C       D       x1/3    "line 1"
\tA       B       C       D       x2/3    "line 2"
\tA       B       C       D       x3/3    (3,5)
	V:#1
	D       C       G       G       (5,4)   "one verse lyric line"
}''');

      for (var i = 0; i < 4; i++) {
        expect(a.songMomentToRepeatRowRange(i), (0, 3));
      }
      for (var i = 4; i < 8; i++) {
        expect(a.songMomentToRepeatRowRange(i), (1, 3));
      }
      for (var i = 8; i < 12; i++) {
        expect(a.songMomentToRepeatRowRange(i), (1, 5));
      }
      for (var i = 12; i < 16; i++) {
        expect(a.songMomentToRepeatRowRange(i), (0, 5));
      }
    }
  });

  test('test more songBase toDisplayGrid()', () {
    int beatsPerBar = 4;
    Song a;
    var userDisplayStyle = UserDisplayStyle.proPlayer;
    Grid<MeasureNode> grid;
    Logger.level = Level.info;

    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'v: C7 C7 C7 C7, F7 F7 C7 C7, G7 F7 C7 G7',
          rawLyrics: 'v:');

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	V:#0
	C7      C7      C7      C7,
	F7      F7      C7      C7,
	G7      F7      C7      G7
}''');
//  validate song moment to grid coordinates
      _testSongMomentToGrid(a, userDisplayStyle);

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	V:#0
	C7      C7      C7      C7,
	F7      F7      C7      C7,
	G7      F7      C7      G7
}''');

//  validate song moment to grid coordinates
      _testSongMomentToGrid(a, userDisplayStyle);
    }

    {
      userDisplayStyle = UserDisplayStyle.both;

      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'v: [  B D#m G#m G#m/F#,A C#m G#m,A A. C#m. ] x3, B D#m G#m G#m/F#, A A. C#m. C#m C#m',
          rawLyrics: '''v:
I hear the drums echoing tonight but she hears only
Whispers of some quiet conversation
-
She's coming in twelve-thirty flight, her moonlit wings
Reflect the stars that guide me towards salvation
-
I stopped an old man along the way hoping to find some
Old forgotten words or ancient melodies
-
He turned to me as if to say, "Hurry, boy, it's
Waiting there for you"
''');

      {
        grid = a.toDisplayGrid(userDisplayStyle);
        logger.i(grid.toString());
        expect(grid.toString(), '''
Grid{
	V:#0
\tB       D#m     G#m     G#m/F#, ⎤       (1,5)   "I hear the drums echoing tonight but she hears only"
\tA       C#m     G#m,    (2,3)   ⎥       (2,5)   "Whispers of some quiet conversation"
\tA       A.      C#m.    (3,3)   ⎦       x1/3    "-"
\tB       D#m     G#m     G#m/F#, ⎤       (4,5)   "She's coming in twelve-thirty flight, her moonlit wings"
\tA       C#m     G#m,    (5,3)   ⎥       (5,5)   "Reflect the stars that guide me towards salvation"
\tA       A.      C#m.    (6,3)   ⎦       x2/3    "-"
\tB       D#m     G#m     G#m/F#, ⎤       (7,5)   "I stopped an old man along the way hoping to find some"
\tA       C#m     G#m,    (8,3)   ⎥       (8,5)   "Old forgotten words or ancient melodies"
\tA       A.      C#m.    (9,3)   ⎦       x3/3    "-"
\tB       D#m     G#m     G#m/F#, (10,4)  (10,5)  "He turned to me as if to say, "Hurry, boy, it's"
\tA       A.      C#m.    C#m     C#m     (11,5)  "Waiting there for you""
}''');

//  validate song moment to grid coordinates
        _testSongMomentToGrid(a, userDisplayStyle);
      }

      grid = a.toDisplayGrid(userDisplayStyle);
      logger.i(grid.toString());
      expect(grid.toString(), '''
Grid{
	V:#0
	B       D#m     G#m     G#m/F#, ⎤       (1,5)   "I hear the drums echoing tonight but she hears only"
	A       C#m     G#m,    (2,3)   ⎥       (2,5)   "Whispers of some quiet conversation"
	A       A.      C#m.    (3,3)   ⎦       x1/3    "-"
	B       D#m     G#m     G#m/F#, ⎤       (4,5)   "She's coming in twelve-thirty flight, her moonlit wings"
	A       C#m     G#m,    (5,3)   ⎥       (5,5)   "Reflect the stars that guide me towards salvation"
	A       A.      C#m.    (6,3)   ⎦       x2/3    "-"
	B       D#m     G#m     G#m/F#, ⎤       (7,5)   "I stopped an old man along the way hoping to find some"
	A       C#m     G#m,    (8,3)   ⎥       (8,5)   "Old forgotten words or ancient melodies"
	A       A.      C#m.    (9,3)   ⎦       x3/3    "-"
	B       D#m     G#m     G#m/F#, (10,4)  (10,5)  "He turned to me as if to say, "Hurry, boy, it's"
	A       A.      C#m.    C#m     C#m     (11,5)  "Waiting there for you""
}''');
//  validate song moment to grid coordinates
      _testSongMomentToGrid(a, userDisplayStyle);
    }
  });

  test('test more songBase firstMomentInLyricSection()', () {
    int beatsPerBar = 4;
    Song a;
    Logger.level = Level.info;

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'v: C7 C7 C7 C7, F7 F7 C7 C7, G7 F7 C7 G7',
          rawLyrics: 'v:');

      for (var lyricSection in a.lyricSections) {
        logger.t('$lyricSection: ${a.firstMomentInLyricSection(lyricSection).lyricSection.index}');
      }
      expect(a.firstMomentInLyricSection(a.lyricSections[0]).momentNumber, 0);
    }

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 104,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  x4 v: G G G G, C C G G o: [ C C G G, E F G E ] x3 A B C',
          rawLyrics: 'i: (instrumental)\nmore instrumental'
              'v: line 1\n line 2\n'
              'o:\n'
              'yo1\n'
              'yo2\n'
              'yo3\n'
              'yo4\nyo5\nyo6\nyo7');

      for (var lyricSection in a.lyricSections) {
        logger.t('$lyricSection: ${a.firstMomentInLyricSection(lyricSection).lyricSection.index}');
      }
      expect(a.firstMomentInLyricSection(a.lyricSections[0]).momentNumber, 0);
      expect(a.firstMomentInLyricSection(a.lyricSections[1]).momentNumber, 16);
    }

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb',
          rawLyrics: 'i: v: o:');

      for (var lyricSection in a.lyricSections) {
        logger.i('$lyricSection: ${a.firstMomentInLyricSection(lyricSection).lyricSection.index}');
      }
      expect(a.firstMomentInLyricSection(a.lyricSections[0]).momentNumber, 0);
      expect(a.firstMomentInLyricSection(a.lyricSections[1]).momentNumber, 4);
      expect(a.firstMomentInLyricSection(a.lyricSections[2]).momentNumber, 16);
    }

    {
      a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i:o: D C G G# V: C F C C#,F F C B c: [ A B C D ] x4',
          rawLyrics: 'i: v: c: v: c: o:');

      for (var lyricSection in a.lyricSections) {
        logger.i('$lyricSection: ${a.firstMomentInLyricSection(lyricSection).lyricSection.index}');
      }
      expect(a.firstMomentInLyricSection(a.lyricSections[0]).momentNumber, 0);
      expect(a.firstMomentInLyricSection(a.lyricSections[1]).momentNumber, 4);
      expect(a.firstMomentInLyricSection(a.lyricSections[2]).momentNumber, 12);
      expect(a.firstMomentInLyricSection(a.lyricSections[3]).momentNumber, 28);
      expect(a.firstMomentInLyricSection(a.lyricSections[4]).momentNumber, 36);
      expect(a.firstMomentInLyricSection(a.lyricSections[5]).momentNumber, 52);
    }
  });

  test('test songBaseSameContent', () {
    int beatsPerBar = 4;
    {
      var a = Song(
          title: 'ive go the blanks',
          artist: 'bob',
          copyright: 'bob',
          key: music_key.Key.get(music_key.KeyEnum.C),
          beatsPerMinute: 106,
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: 4,
          user: 'pearl bob',
          chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
          rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

      var b = a.copyWith();
      expect(a, b);
      expect(a.compareBySongId(b), 0);
      expect(a.songBaseSameContent(b), isTrue);

      b = a.copyWith(title: 'bob test');
      expect(a == b, isFalse);
      expect(a.compareBySongId(b), 1);
      expect(a.songBaseSameContent(b), isFalse);

      b = a.copyWith(user: 'pillyweed');
      expect(a == b, isFalse);
      expect(a.compareBySongId(b), 0);
      expect(a.songBaseSameContent(b), isFalse);
    }
  });

  test('test scaleChordsUsed', () {
    int beatsPerBar = 4;
    Song a;
    a = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: 'bob',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: A B C D  v: G G G G, C C G G o: C C G G',
        rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

    logger.i('scaleChordsUsed: ${a.scaleChordsUsed()}');
    expect(a.scaleChordsUsed().toString(), '[A, B, C, D, G]');

    a = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: 'bob',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: AbBbmaj7 Bsus4 Cm/G D  v: G5 G7b5G7#9 G G, C C G G o: C C G G',
        rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

    logger.i('scaleChordsUsed: ${a.scaleChordsUsed()}');
    expect(a.scaleChordsUsed().toString(), '[A♭, B♭maj7, Bsus4, C, Cm, D, G, G5, G7b5, G7#9]');
  });

  test('test short measures', () {
    int beatsPerBar = 4;
    Song a;
    a = Song(
        title: 'ive go the blanks',
        artist: 'bob',
        copyright: 'bob',
        key: music_key.Key.get(music_key.KeyEnum.C),
        beatsPerMinute: 106,
        beatsPerBar: beatsPerBar,
        unitsPerMeasure: 4,
        user: 'pearl bob',
        chords: 'i: 1A 2B 3C 3DEF  v: G G G G, C C G G o: C C G G',
        rawLyrics: 'i: (instrumental)\nv: line 1\no:\n');

    logger.i(a.toJson());
  });

  test('generate song repeat tests', () {
    int beatsPerBar = 4;

    bool first = true;
    Song a;
    Grid<MeasureNode> displayGrid = Grid();

    for (int rows = 2; rows <= 3; rows++) {
      for (int repeat = 3; repeat <= 5; repeat++) {
        for (int lyricsLines = 1; lyricsLines <= repeat * rows; lyricsLines++) {
          StringBuffer sb = StringBuffer();
          for (int line = 1; line <= lyricsLines; line++) {
            sb.write('Line $line/$lyricsLines\n');
          }
          String chordRow = 'A B C D';
          if (rows > 1) {
            chordRow += '\nD C G G';
            if (rows > 2) {
              chordRow += '\nE E F G';
            }
            chordRow = '[$chordRow]';
          }
          String v = 'v: $chordRow ${repeat > 1 ? 'x$repeat' : ''}';

          a = Song(
              title: '000 repeat test $repeat/$lyricsLines',
              artist: 'bob',
              copyright: 'bob',
              key: music_key.Key.get(music_key.KeyEnum.C),
              beatsPerMinute: 106,
              beatsPerBar: beatsPerBar,
              unitsPerMeasure: 4,
              user: 'pearl bob',
              chords: //'i: 1A 2B 3C 3DEF '
                  '$v o: C C G G',
              rawLyrics: //'i: (instrumental)\n'
                  'v: ${sb.toString()}\no:\n');
          displayGrid = a.toDisplayGrid(UserDisplayStyle.both);

          if (_printOnly) {
            if (first) {
              first = false;
              logger.i('[');
            } else {
              logger.i(',');
            }
            logger.i(a.toJson());
          } else {
            logger.i('');
            logger.i('title: ${a.title}');

            logger.i(displayGrid.toString());
            expect(displayGrid.getRowCount(), 1 + min(rows * ((lyricsLines / rows).ceil() + 1), rows * repeat) + 2);
          }

          //  songMoment moment ranges
          for (var songMoment in a.songMoments) {
            var (min, max) = a.songMomentToRepeatMomentRange(UserDisplayStyle.both, songMoment.momentNumber);
            //logger.i('range: ${songMoment.momentNumber}:  $min, $max');
            assert(songMoment.momentNumber >= min);
            assert(songMoment.momentNumber <= max);
            if (songMoment.phrase.length <= 1) {
              logger.i('bad phrase length: ${songMoment.phrase}');
              assert(false);
            }
            if (min == max /*  && phrase.length > 1*/) {
              assert(songMoment.measure.measureNodeType != MeasureNodeType.repeat);
            }
            var (rowMin, rowMax) = a.songMomentToRepeatRowRange(songMoment.momentNumber);
            // logger.i('${songMoment.momentNumber}: rows: ${(rowMin, rowMax)}');
            assert(rowMin >= 0);
            assert(rowMin < displayGrid.getRowCount());
            assert(rowMax >= 0);
            assert(rowMax < displayGrid.getRowCount());
            switch (songMoment.phrase.measureNodeType) {
              case MeasureNodeType.repeat:
                var row = a.songMomentToGridCoordinate[songMoment.momentNumber].row;
                assert(rowMin <= row);
                var first =
                    songMoment.momentNumber - songMoment.measureIndex - songMoment.repeat * songMoment.phrase.length;
                var firstRow = a.songMomentToGridCoordinate[first].row;
                expect(rowMin, songMoment.repeat == 0 ? 0 : firstRow);
                var last = first + songMoment.repeatMax * songMoment.phrase.length - 1;
                var lastRow = a.songMomentToGridCoordinate[last].row;
                expect(rowMax, songMoment.repeat == songMoment.repeatMax - 1 ? displayGrid.getRowCount() - 1 : lastRow);
                break;
              default:
                assert(rowMin == 0);
                assert(rowMax == displayGrid.getRowCount() - 1);
                break;
            }
            logger.i('moment ${songMoment.momentNumber.toString().padLeft(3)}:'
                ' moment range:({${min.toString().padLeft(3)},${max.toString().padLeft(3)}), rows:'
                ' ${a.songMomentToGridCoordinate[min].row} to ${a.songMomentToGridCoordinate[max].row}');
          }
        }
      }
    }
    if (_printOnly) {
      logger.i(']');
    }
  });
}

void _testSongMomentToGrid(Song a, UserDisplayStyle userDisplayStyle) {
  var grid = a.toDisplayGrid(userDisplayStyle);
  logger.i('');
  logger.i('a.toGrid(): ${userDisplayStyle.name}: $grid ');

  List<GridCoordinate> list = a.songMomentToGridCoordinate;
  expect(list.length, a.songMoments.length);
  for (var songMoment in a.songMoments) {
    var gc = list[songMoment.momentNumber];
    var measureNode = grid.get(gc.row, gc.col);
    logger.i('${songMoment.momentNumber}: $gc: $measureNode');
    expect(measureNode, isNotNull);
    if (measureNode is Measure) {
      expect(measureNode, songMoment.measure);
    } else if (userDisplayStyle == UserDisplayStyle.singer && gc.col == 0) {
      expect(measureNode, songMoment.lyricSection);
    } else if (userDisplayStyle == UserDisplayStyle.proPlayer) {
      expect(measureNode, songMoment.chordSection);
    } else {
      expect(measureNode, songMoment.lyricSection);
    }
  }
}
