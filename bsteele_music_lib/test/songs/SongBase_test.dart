import 'dart:collection';
import 'dart:math';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/grid.dart';
import 'package:bsteeleMusicLib/gridCoordinate.dart';
import 'package:bsteeleMusicLib/songs/chordSection.dart';
import 'package:bsteeleMusicLib/songs/chordSectionGridData.dart';
import 'package:bsteeleMusicLib/songs/chordSectionLocation.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/lyric.dart';
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/measureNode.dart';
import 'package:bsteeleMusicLib/songs/musicConstants.dart';
import 'package:bsteeleMusicLib/songs/phrase.dart';
import 'package:bsteeleMusicLib/songs/scaleNote.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
import 'package:bsteeleMusicLib/songs/sectionVersion.dart';
import 'package:bsteeleMusicLib/songs/song.dart';
import 'package:bsteeleMusicLib/songs/songBase.dart';
import 'package:bsteeleMusicLib/songs/songMoment.dart';
import 'package:bsteeleMusicLib/songs/timeSignature.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

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

      sb.write('\t' + data.toString() + ' ');
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
    SongBase a = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A B C D', 'v: bob, bob, bob berand');
    SongBase b = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A B C D', 'v: bob, bob, bob berand');

    expect(a == a, isTrue);
    expect(a.hashCode == a.hashCode, isTrue);
    expect(a == b, isTrue);
    expect(a.hashCode == b.hashCode, isTrue);
    b = SongBase.createSongBase(
        'B', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A B C D', 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
    b = SongBase.createSongBase(
        'A', 'bobby', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A B C D', 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
    b = SongBase.createSongBase('A', 'bob', 'photos.bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A B C D',
        'v: bob, bob, bob berand');
    logger.d('a.getSongId(): ' + a.getSongId().hashCode.toString());
    logger.d('b.getSongId(): ' + b.getSongId().hashCode.toString());
    expect(a.getSongId().compareTo(b.getSongId()), 0);
    expect(a.getSongId(), b.getSongId());
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.get(music_key.KeyEnum.Ab), 100, 4, 4,
        'v: A B C D', 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 102, 4, 4, 'v: A B C D', 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 3, 8, 'v: A B C D', 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    //top
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 8, 'v: A B C D', 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A A C D', 'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A B C D', 'v: bob, bob, bob berand.');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
  });

  test('testCurrentLocation', () {
    SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 8,
        'I:v: A BCm7/ADE C D', 'I:v: bob, bob, bob berand');
    expect(MeasureEditType.append, a.currentMeasureEditType);
    logger.d(a.getCurrentChordSectionLocation().toString());

    expect(a.getCurrentMeasureNode(), Measure.parseString('D', a.getBeatsPerBar()));
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:0'));
    expect(a.getCurrentMeasureNode(), Measure.parseString('A', a.getBeatsPerBar()));
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:1'));
    expect(Measure.parseString('BCm7/ADE', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:3')); //  move to end
    expect(Measure.parseString('D', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:0'));
    expect(Measure.parseString('A', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:5')); //  refuse to move past end
    expect(Measure.parseString('D', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:3')); //  move to end
    expect(Measure.parseString('D', a.getBeatsPerBar()), a.getCurrentMeasureNode());

    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 8,
        'I:v: A B C D ch3: [ E F G A ] x4 A# C D# F', 'I:v: bob, bob, bob berand');
    expect(a.currentMeasureEditType, MeasureEditType.append);
    a.setDefaultCurrentChordLocation();
    expect(a.getCurrentMeasureNode(), Measure.parseString('F', a.getBeatsPerBar()));
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:0'));
    expect(Measure.parseString('A', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('i:0:3234234')); //  move to end
    expect(Measure.parseString('D', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('v:0:0'));
    expect(Measure.parseString('A', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('c3:1:0'));
    expect(Measure.parseString('A#', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    a.setCurrentChordSectionLocation(ChordSectionLocation.parseString('c3:1:3')); //  move to end
    expect(Measure.parseString('F', a.getBeatsPerBar()), a.getCurrentMeasureNode());
    ChordSection cs = ChordSection.parseString('c3:', a.getBeatsPerBar());
    ChordSection? chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    expect(cs.sectionVersion, chordSection!.sectionVersion);
  });

  test('test basics', () {
    SongBase a;

    // {
    //   //  trivial first!
    //   a = SongBase.createSongBase(
    //       'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 8, 'I: A B C D v: D C G G', 'v: bob, bob, bob berand');
    //
    //   SplayTreeSet<ChordSection> chordSections = SplayTreeSet<ChordSection>.of(a.getChordSections());
    //   ChordSection chordSection = chordSections.first;
    //   Phrase phrase = chordSection.phrases[0];
    //
    //   Measure measure = phrase.measures[1];
    //   expect(phrase.measures.length, 4);
    //   expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.B;
    // }
    {
      a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 8, 'I:v: A B C D',
          'I:v: bob, bob, bob berand');

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
      SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'i: v: t:',
          'i: dude v: bob, bob, bob berand');

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
      a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'i: v: t:',
          'i: dude v: bob, bob, bob berand');

      expect(a.editList(a.parseChordEntry('I: A B C D A B C D')), isTrue);

      expect(
        a.findChordSectionByString('I:')!.toMarkup().trim(),
        'I: A B C D, A B C D,',
      );
    }
    {
      //  empty sections
      SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'i: v: t:',
          'i: dude v: bob, bob, bob berand');

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
      SongBase a = SongBase.createSongBase(
          'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v:', 'v: bob, bob, bob berand');

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
      SongBase a = SongBase.createSongBase(
          'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v:', 'v: bob, bob, bob berand');

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
    SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
        'i: A B C D v: E F G A# t: Gm Gm', 'i: dude v: bob, bob, bob berand');

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
      SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
          'i: A B C D v: E F G A#', 'i: v: bob, bob, bob berand');

      var gridCoordinate = GridCoordinate(0, 4);
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
      SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
          'i: A B C D v: E F G A#', 'i: v: bob, bob, bob berand');

      logger.d(a.logGrid());
      Grid<ChordSectionGridData> grid;

      grid = a.getChordSectionGrid();
      //  set first row as a repeat from any measure
      for (int row = 0; row < grid.getRowCount(); row++) {
        a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
            'i: A B C D v: E F G A#', 'i: v: bob, bob, bob berand');
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
                expect(s, 'I: [A B C D ] x' + r.toString() + '  V: E F G A#');
              } else {
                expect(
                    s,
                    'I: A B C D'
                            '  V: [E F G A# ] x' +
                        r.toString());
              }
              expect(a.currentChordSectionLocation, chordSectionLocation);
            }
          }
        }
      }
    }

    for (var measureIndex = 0; measureIndex < 4; measureIndex++) {
      //  repeat a row at the start of a phrase
      SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
          'i: A B C D v: E F G A#, B C C# D, D# E F F#, G o: D E F G', 'i: v: bob, bob, bob berand');

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
      SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
          'i: A B C D v: E F G A#, B C C# D, D# E F F#, G o: D E F G', 'i: v: bob, bob, bob berand');
      logger.i(a.toMarkup());

      var gridCoordinate = GridCoordinate(2, 1 + measureIndex % 4);
      ChordSectionLocation? chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
      assert(chordSectionLocation != null);
      logger.d('${chordSectionLocation}: ${a.findMeasureByChordSectionLocation(chordSectionLocation)}');
      a.setCurrentChordSectionLocation(chordSectionLocation);
      a.setRepeat(chordSectionLocation!, 2);
      gridCoordinate = GridCoordinate(2, 1 + 3);
      chordSectionLocation = a.findChordSectionLocationByGrid(gridCoordinate);
      assert(chordSectionLocation != null);
      logger.d('grid: ${chordSectionLocation}: ${a.findMeasureByChordSectionLocation(chordSectionLocation)}');
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
      SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
          'i: A B C D v: E F G A#, B C C# D, D# E F F# o: D E F G', 'i: v: bob, bob, bob berand');
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
      SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
          'i: A B C D v: E F G A#, B C C# D, D# E F F#, G o: D E F G', 'i: v: bob, bob, bob berand');
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
          SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
              'i: A B C D v: E F G A#, B C C# D, D# E F F#, G o: D E F G', 'i: v: bob, bob, bob berand');
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
    SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
        'i: A B C D v: E B C D', 'i: v: bob, bob, bob berand');

    logger.d(a.logGrid());
    logger.d('moment count: ${a.getSongMoments().length}');
    for (SongMoment moment in a.getSongMoments()) {
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

    a = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A B C D', 'v: bob, bob, bob berand');
    chordSections.addAll(a.getChordSections());
    expect(1, chordSections.length);
    chordSection = chordSections.first;
    measures = chordSection.phrases[0].measures;
    expect(4, measures.length);

    a = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4, 'v: A B C D (yo)', 'v: bob, bob, bob berand');
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

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D, E F G A C: D D GD E\n'
            'A B C D x3\n'
            'Ab G Gb F',
        'v: bob, bob, bob berand');
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
          logger.d('measure(' + c.toString() + ',' + r.toString() + '): ' + measure.toMarkup());
          ChordSectionLocation? loc = a.findChordSectionLocationByGrid(GridCoordinate(r, c));
          logger.d('loc: ' + loc.toString());
          a.setCurrentChordSectionLocation(loc);

          logger.d('current: ' + a.getCurrentMeasureNode()!.toMarkup());
          expect(measure, a.getCurrentMeasureNode());
        }
        logger.d('grid[' + r.toString() + ',' + c.toString() + ']: ' + node.toString());
      }
    }
  });

  test('testFindChordSectionLocation', () {
    int beatsPerBar = 4;
    SongBase a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'i: A B C D V: D E F F# '
            'v1:    Em7 E E G \n'
            '       C D E Eb7 x2\n'
            'v2:    A B C D |\n'
            '       E F G7 G#m | x2\n'
            '       D C GB GbB \n'
            'C: F F# G G# Ab A O: C C C C B',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no:');
    logger.d(a.getSongId().toString());
    logger.d('\t' + a.toMarkup());
    logger.d(a.rawLyrics);

    ChordSectionLocation chordSectionLocation;

    chordSectionLocation = ChordSectionLocation.parseString('v:0:0');

    MeasureNode? m = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(Measure.parseString('D', a.getBeatsPerBar()), m);
    expect(m, a.findMeasureNodeByLocation(chordSectionLocation));

    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v:0:3'));
    expect(Measure.parseString('F#', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v:0:4'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:2:0'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:1:1'));
    expect(Measure.parseString('D', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:0:0'));
    expect(Measure.parseString('Em7', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:0:4'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:0:3'));
    expect(m, Measure.parseString('G', a.getBeatsPerBar())); //  default measures per row
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:1:0'));
    expect(Measure.parseString('C', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:1:1'));
    expect(Measure.parseString('D', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v1:0:9')); //    repeats don't count here
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:0:0'));
    expect(Measure.parseString('A', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:0:3'));
    expect(m, Measure.parseString('D,', a.getBeatsPerBar()));
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:0:4'));
    expect(Measure.parseString('E', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:1:3'));
    expect(m, Measure.parseString('GbB', a.getBeatsPerBar()));
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('v2:1:4'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('o:0:4'));
    expect(Measure.parseString('B', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('o:0:5'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('c:0:5'));
    expect(Measure.parseString('A', a.getBeatsPerBar()), m);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('c:0:6'));
    expect(m, isNull);
    m = a.findMeasureNodeByLocation(ChordSectionLocation.parseString('i:0:0'));
    expect(Measure.parseString('A', a.getBeatsPerBar()), m);

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
    SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'i: A B C D V: D E F F# ', 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

    ChordSectionLocation loc;

    loc = ChordSectionLocation.parseString('i:0:2');
    a.setCurrentChordSectionLocation(loc);
    logger.d(a.getCurrentChordSectionLocation().toString());
    logger.d(a.findMeasureNodeByLocation(a.getCurrentChordSectionLocation())!.toMarkup());
    a.chordSectionLocationDelete(loc);
    logger.d(a.findChordSectionBySectionVersion(SectionVersion.parseString('i:'))!.toMarkup());
    logger.d(a.findMeasureNodeByLocation(loc)!.toMarkup());
    logger.d('loc: ' + a.getCurrentChordSectionLocation().toString());
    logger.d(a.findMeasureNodeByLocation(a.getCurrentChordSectionLocation())!.toMarkup());
    expect(a.findMeasureNodeByLocation(loc), a.findMeasureNodeByLocation(a.getCurrentChordSectionLocation()));
    logger.i(a.toMarkup());
    expect(a.getChordSection(SectionVersion.parseString('i:'))!.toMarkup(), 'I: A B D ');
    expect(Measure.parseString('D', beatsPerBar), a.getCurrentChordSectionLocationMeasureNode());
    logger.d('cur: ' + a.getCurrentChordSectionLocationMeasureNode()!.toMarkup());

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
    SongBase a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
        'i: A B C D V: D E F F# ', 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro\n');
    String lyrics = 'i:\n'
        'v: bob, bob, bob berand\n'
        'c: sing chorus here \n'
        'o: last line of outro';
    //logger.d(    a.getRawLyrics());
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, 4, 4,
        'i: A B C D V: D E F F# ', 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
    expect(lyrics, a.rawLyrics);
  });

  test('testSongWithoutStartingSection', () {
//  fixme: doesn't test much, not very well

    SongBase a = SongBase.createSongBase(
        'Rio',
        'Duran Duran',
        'Sony/ATV Music Publishing LLC',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        //  not much of this chord chart is correct!
        'Verse\n'
            'C#m A♭ FE A♭  x4\n'
            'Prechorus\n'
            'C C/\n'
            'chorus\n'
            'C G B♭ F  x4\n'
            'Tag Chorus\n',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro\n');

    logger.d(a.logGrid());
    Grid<ChordSectionGridData> grid = a.getChordSectionGrid();
    expect(10, grid.getRowCount()); //  comments on their own line add a bunch
    List<ChordSectionGridData?>? row = grid.getRow(0);
    if (row == null) throw 'row == null';
    expect(2, row.length);
    row = grid.getRow(1);
    if (row == null) throw 'row == null';
    logger.d('row: ' + row.toString());
    expect(1 + 4 + 1 + 1, row.length);
    row = grid.getRow(2);
    if (row == null) throw 'row == null';
    expect(2, row.length);
    expect(grid.get(0, 5), isNull);
  });

  test('test Songs with blank lyrics lines', () {
    SongBase a;
    int beatsPerBar = 4;

    a = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4, 'v: D D C G x4 c: C C C C x 2', '''
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
    ;
    logger.v('<${a.rawLyrics}>');

    for (var ls in a.lyricSections) {
      logger.v('${ls.sectionVersion.toString()}');
      var i = 1;
      for (var line in ls.lyricsLines) {
        logger.v('    ${i++}: $line');
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

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'O:'
            'D..Dm7 Dm7 C..B♭maj7 B♭maj7  x12',
        'o: nothing');
    logger.v('grid: ' + a.logGrid());
    location = ChordSectionLocation(SectionVersion(Section.get(SectionEnum.outro), 0), phraseIndex: 0, measureIndex: 3);
    MeasureNode? measureNode = a.findMeasureNodeByLocation(location);
    logger.v('measure: ' + measureNode!.toMarkup());
    expect(measureNode, Measure.parseString('B♭maj7', beatsPerBar));
    MeasureNode? mn = a.findMeasureNodeByGrid(GridCoordinate(0, 4));
    Measure? expectedMn = Measure.parseString('B♭maj7', beatsPerBar);
    expect(mn, expectedMn);

    final int row = 0;
    final int lastCol = 3;
    location = ChordSectionLocation(SectionVersion(Section.get(SectionEnum.outro), 0),
        phraseIndex: row, measureIndex: lastCol);
    measureNode = a.findMeasureNodeByLocation(location);
    if (measureNode == null) throw 'measureNode == null';
    logger.d(measureNode.toMarkup());
    expect(measureNode, a.findMeasureNodeByGrid(GridCoordinate(row, lastCol + 1)));

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
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
        'i1:\nv: bob, bob, bob berand\ni2: nope\nc1: sing \ni3: chorus here \ni4: mo chorus here\no: last line of outro');
    logger.d(a.logGrid());
    Measure? m = Measure.parseString('X', a.getBeatsPerBar());
    expect(a.findMeasureNodeByGrid(GridCoordinate(1, 2)), m);
    expect(Measure.parseString('C5D5', a.getBeatsPerBar()), a.findMeasureNodeByGrid(GridCoordinate(5, 4)));
    m = Measure.parseString('DC', a.getBeatsPerBar());
    expect(a.findMeasureNodeByGrid(GridCoordinate(18, 2)), m);
    expect(Measure.parseString('C5D#', a.getBeatsPerBar()), a.findMeasureNodeByGrid(GridCoordinate(20, 4)));

    //  not what's intended, but what's declared
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'V:I:O:\n'
            'Ebsus2 Bb Gm7 C\n'
            '\n'
            'C:\n'
            'Cm F Bb Eb x3\n'
            'Cm F\n'
            '\n'
            'O:V:\n',
        'i1:\nv: bob, bob, bob berand\ni2: nope\nc1: sing \ni3: chorus here \ni4: mo chorus here\no: last line of outro');
    logger.d(a.logGrid());
    expect(Measure.parseString('Gm7', a.getBeatsPerBar()), a.findMeasureNodeByGrid(GridCoordinate(0, 3)));
    expect(Measure.parseString('Cm', a.getBeatsPerBar()), a.findMeasureNodeByGrid(GridCoordinate(2, 1)));
    expect(Measure.parseString('F', a.getBeatsPerBar()), a.findMeasureNodeByGrid(GridCoordinate(2, 2)));

    //  leading blank lines
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        '\n'
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
        'i1:\nv: bob, bob, bob berand\ni2: nope\nc1: sing \ni3: chorus here \ni4: mo chorus here\no: last line of outro');

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
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');

    logger.v(a.toMarkup());
    logger.d('testing: ' + ChordSectionLocation.parseString('I:0:0').toString());
    logger.d('testing2: ' + a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')).toString());
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')), GridCoordinate(0, 1));

    expect(GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('I:')));
    expect(GridCoordinate(1, 0), a.getGridCoordinate(ChordSectionLocation.parseString('V:')));
    expect(GridCoordinate(2, 0), a.getGridCoordinate(ChordSectionLocation.parseString('C:')));

    //  see that section identifiers are on first phrase row
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: Am Am/G Am/F♯ FE, A B C D, v: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');

    logger.d(a.logGrid());

    expect(GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('I:')));
    expect(GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')));

    expect(GridCoordinate(2, 0), a.getGridCoordinate(ChordSectionLocation.parseString('V:')));
    expect(GridCoordinate(3, 0), a.getGridCoordinate(ChordSectionLocation.parseString('C:')));

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: V: [Am Am/G Am/F♯ FE ] x4  I2: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here');

    logger.i(a.toMarkup());
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('V:')), GridCoordinate(0, 0));
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('V:0:0')), GridCoordinate(0, 1));

    expect(a.getGridCoordinate(ChordSectionLocation.parseString('I:')), GridCoordinate(0, 0));
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('C:')), GridCoordinate(2, 0));

    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: V: c: G D G D ', 'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here');

    logger.i(a.toMarkup());

    expect(GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('I:')));
    expect(GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('V:')));
    expect(GridCoordinate(0, 0), a.getGridCoordinate(ChordSectionLocation.parseString('C:')));
    location = ChordSectionLocation.parseString('I:0:0');
    expect(GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')));
    expect(Measure.parseString('G', beatsPerBar), a.findMeasureNodeByLocation(location));
    expect(GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('v:0:0')));
    expect(Measure.parseString('G', beatsPerBar), a.findMeasureNodeByLocation(location));
    expect(GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('c:0:0')));
    expect(Measure.parseString('G', beatsPerBar), a.findMeasureNodeByLocation(location));
    logger.d(a.logGrid());
    gridCoordinate = GridCoordinate(0, 0);
    location = a.getChordSectionLocation(gridCoordinate);
    logger.d(location.toString());
    expect(gridCoordinate, a.getGridCoordinate(location));
    location = ChordSectionLocation.parseString('V:0:0');
    expect(GridCoordinate(0, 1), a.getGridCoordinate(ChordSectionLocation.parseString('i:0:0')));
    expect(Measure.parseString('G', beatsPerBar), a.findMeasureNodeByLocation(location));
    gridCoordinate = GridCoordinate(0, 0);
    location = a.getChordSectionLocation(gridCoordinate);
    logger.d(location.toString());
    expect(gridCoordinate, a.getGridCoordinate(location));
    expect('I: V: C: ', location.toString());

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'verse: A B C D prechorus: D E F F# chorus: G D C G x3',
        'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \no: last line of outro');

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
        logger.d(coordinate.toString() + '  ' + chordSectionLocation.toString());
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
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'verse: C2: V2: A B C D prechorus: D E F F# chorus: G D C G x3',
        'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \no: last line of outro');
    expect(a.toMarkup().trim(), 'V: V2: C2: A B C D  PC: D E F F#  C: [G D C G ] x3');
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'verse: A B C D prechorus: D E F F# chorus: G D C G x3',
        'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \no: last line of outro');
    expect(a.toMarkup().trim(), 'V: A B C D  PC: D E F F#  C: [G D C G ] x3');
  });

  test('testDebugSongMoments', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'verse: C2: V2: A B C D Ab Bb Eb Db prechorus: D E F F# o:chorus: G D C G x3 T: A',
        'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \nv: nope\nc: yes\nv: nope\nt:\no: last line of outro\n');
//    a.debugSongMoments();

    for (int momentNumber = 0; momentNumber < a.getSongMomentsSize(); momentNumber++) {
      SongMoment? songMoment = a.getSongMoment(momentNumber);
      if (songMoment == null) break;
//      logger.d(songMoment.toString());
//      expect(count, songMoment.getMomentNumber());
//      GridCoordinate momentGridCoordinate =
//          a.getMomentGridCoordinate(songMoment);
//      expect(momentGridCoordinate, isNotNull);
    }
  });

  test('testChordSectionBeats', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'verse: C2: V2: A B C D Ab Bb Eb Db prechorus: D E F F# o:chorus: G D C G x3 T: A',
        'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \nv: nope\nc: yes\nv: nope\nt:\no: last line of outro\n');
    expect(8 * 4, a.getChordSectionBeats(SectionVersion.parseString('v:')));
    expect(8 * 4, a.getChordSectionBeats(SectionVersion.parseString('c2:')));
    expect(8 * 4, a.getChordSectionBeats(SectionVersion.parseString('v2:')));
    expect(4 * 3 * 4, a.getChordSectionBeats(SectionVersion.parseString('o:')));
    expect(4, a.getChordSectionBeats(SectionVersion.parseString('t:')));
  });

  test('testSongMomentGridding', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase.createSongBase(
        'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4, 'I: [A B C D, E F]  x2  ', 'i:\n');
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

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'verse: C2: V2: A B C D  x2  prechorus: D E F F#, G# A# B C o:chorus: G D C G x3 T: A',
        'i:\nv: bob, bob, bob berand\npc: nope\nc: sing chorus here \nv: nope\nc: yes\nv: nope\nt:\no: last line of outro\n');
    a.debugSongMoments();

    {
      //  verify beats total as expected
      int beats = 0;
      for (int momentNumber = 0; momentNumber < a.getSongMomentsSize(); momentNumber++) {
        SongMoment? songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) break;
        expect(beats, songMoment.getBeatNumber());
        beats += songMoment.getMeasure().beatCount;
      }
    }
    {
      int count = 0;
      for (int momentNumber = 0; momentNumber < a.getSongMomentsSize(); momentNumber++) {
        SongMoment? songMoment = a.getSongMoment(momentNumber);
        if (songMoment == null) break;
        logger.d(' ');
        logger.d(songMoment.toString());
        expect(count, songMoment.getMomentNumber());
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

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D, E F]  x2 v: D C G G c: Ab Bb C Db o: G G G G ',
        'i:\nv: verse\n c: chorus\nv: verse\n c: chorus\no: outro');
    a.debugSongMoments();
    logger.i(a.toMarkup());
    int size = a.getSongMomentsSize();
    for (int momentNumber = 0; momentNumber < size; momentNumber++) {
      SongMoment? songMoment = a.getSongMoment(momentNumber);
      if (songMoment == null) throw 'songMoment == null';
      GridCoordinate? coordinate = a.getMomentGridCoordinate(songMoment);
      SongMoment? songMomentAtRow = a.getFirstSongMomentAtRow(coordinate!.row);
      GridCoordinate? coordinateAtRow = a.getMomentGridCoordinate(songMomentAtRow!);
      logger.i('songMoment: ' +
          songMoment.toString() +
          ' at: ' +
          coordinate.toString() +
          ' atRow: ' +
          coordinateAtRow.toString());
      expect(coordinate.row, coordinateAtRow!.row);
      expect(coordinateAtRow.col, 1);
    }
  });

  test('testSetMeasuresPerRow', () {
    int beatsPerBar = 4;
    SongBase a;

    //  split a long repeat
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: A B C D E F, G G# Ab Bb x2 \nc: D E F', 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);

    //  don't fix what's not broken
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: [A B C D, E F G G#, Ab Bb] x2 \nc: D E F', 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);
    logger.i(a.toMarkup());
    expect(a.toMarkup().trim(), 'I: [A B C D, E F G G#, Ab Bb ] x2  C: D E F');

    //  take the comma off a repeat
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: [A B C D, E F G G#, ] x2 \nc: D E F', 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);
    logger.i(a.toMarkup());
    expect(a.toMarkup().trim(), 'I: [A B C D, E F G G# ] x2  C: D E F');

    //  not the first section
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: [A B C D ] x2 \nc: D E F A B C D, E F G G#', 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.i(a.toMarkup());
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());
    expect(a.setMeasuresPerRow(4), isFalse);
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());

    //  take a last comma off
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: [A B C D ] x2 \nc: D E F A B C, D E, F G G#,', 'i:\nc: sing chorus');
    logger.i(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.i(a.toMarkup());
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());
    expect(a.setMeasuresPerRow(4), isFalse);
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());
  });

  test('testGetBeatNumberAtTime', () {
    final int dtDiv = 2;
    //int beatsPerBar = 4;

    for (int bpm = 60; bpm < 132; bpm++) {
      double dt = 60.0 / (dtDiv * bpm);

      int expected = -12;
      int count = 0;
      for (double t = (-8 * 3) * dt; t < (8 * 3) * dt; t += dt) {
        logger.d(bpm.toString() +
            ' ' +
            t.toString() +
            ': ' +
            expected.toString() +
            '  ' +
            SongBase.getBeatNumberAtTime(bpm, t).toString());
        int? result = SongBase.getBeatNumberAtTime(bpm, t);
        if (result == null) throw 'result == null';
        logger.v('beat at ' + t.toString() + ' = ' + result.toString());
        logger.v('   expected: ' + expected.toString());
        if (result != expected) {
          //  deal with test rounding issues
          logger.v('t/dt - e: ' + (t / (dtDiv * dt) - expected).toString());
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
    final int dtDiv = 2;
    int beatsPerBar = 4;
    SongBase a;

    for (int bpm = 60; bpm < 132; bpm++) {
      a = SongBase.createSongBase(
          'A', 'bob', 'bsteele.com', music_key.Key.getDefault(), bpm, beatsPerBar, 4, 'I: A B C D E F  x2  ', 'i:\n');

      double dt = 60.0 / (dtDiv * bpm);

      int expected = -3;
      int count = 0;
      for (double t = -8 * 3 * dt; t < 8 * 3 * dt; t += dt) {
        int? result = a.getSongMomentNumberAtSongTime(t);
        if (result == null) throw 'result == null';
        logger.v(t.toString() +
            ' = ' +
            (t / dt).toString() +
            ' x dt ' +
            '  ' +
            expected.toString() +
            '  @' +
            count.toString() +
            '  b:' +
            SongBase.getBeatNumberAtTime(bpm, t).toString() +
            ': ' +
            a.getSongMomentNumberAtSongTime(t).toString() +
            ', bpm: ' +
            bpm.toString());
        if (expected != result) {
          //  deal with test rounding issues
          double e = t / (dtDiv * dt) / beatsPerBar - expected;
          logger.w('error: ' + e.toString());
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

    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: A B C D V: A B C D', 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: V: A B C D  ');
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: A B C D V: [A B C D] x2', 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: A B C D  V: [A B C D ] x2  ');
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: [A B C D] x2 V: A B C D ', 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: [A B C D ] x2  V: A B C D  ');
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: [A B C D] x2 V: [A B C D] x2', 'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: V: [A B C D ] x2  ');
    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: [A B C D] x2 V: [A B C D] x4', 'i:\nv:\n');
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
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');

//    logger.v(a.toMarkup());
//    logger.d('testing: ' + ChordSectionLocation.parseString('I:0:0').toString());
//    logger.d('testing2: ' + a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')).toString());
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')), GridCoordinate(0, 1));

    grid = a.getChordSectionGrid();

    List<ChordSectionGridData?>? row = grid.getRow(0);
    if (row == null) throw 'row == null';
    logger.d(row.length.toString());
    logger.d(grid.toMultiLineString());
    logger.d(chordSectionToMultiLineString(a));
  });

  test('test entryToUppercase', () {
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

    a = SongBase.createSongBase('A', 'bob', 'bsteele.com', music_key.Key.getDefault(), 100, beatsPerBar, 4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G F F  O: Dm C B B♭ A  ', '''
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
      logger.d('  ${songMoment}');
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
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.getLastMeasureLocationOfChordSection(ChordSection.parseString('i:', beatsPerBar)).toString(), 'I:0:3');
    expect(a.getLastMeasureLocationOfChordSection(ChordSection.parseString('c:', beatsPerBar)).toString(), 'C:0:7');
    expect(a.getLastMeasureLocationOfChordSection(ChordSection.parseString('c2:', beatsPerBar)), isNull);
    expect(a.getLastMeasureLocationOfChordSection(ChordSection.parseString('o:', beatsPerBar)).toString(), 'O:0:4');
  });

  test('test in song, chordSection.measureAt', () {
    int beatsPerBar = 4;
    SongBase a;

    //  see that section identifiers are on first phrase row
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G, Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    var lyricSections = a.lyricSections;
    var chordSection = a.getChordSection(lyricSections[1].sectionVersion);
    expect(chordSection?.sectionVersion, SectionVersion.parseString('v:'));

    expect(chordSection?.measureAt(0, expanded: false), Measure.parseString('Am', beatsPerBar));
    expect(chordSection?.measureAt(3), Measure.parseString('FE', beatsPerBar));
    expect(chordSection?.measureAt(4), isNull);
    expect(chordSection?.measureAt(0, expanded: true), Measure.parseString('Am', beatsPerBar));
    expect(chordSection?.measureAt(1, expanded: true), Measure.parseString('Am/G,', beatsPerBar));
    expect(chordSection?.measureAt(3, expanded: true), Measure.parseString('FE', beatsPerBar));
    expect(chordSection?.measureAt(4, expanded: true), Measure.parseString('Am', beatsPerBar));
    expect(chordSection?.measureAt(6, expanded: true), Measure.parseString('Am/F♯', beatsPerBar));
    expect(chordSection?.measureAt(7, expanded: true), Measure.parseString('FE', beatsPerBar));

    chordSection = a.getChordSection(lyricSections[3].sectionVersion);
    expect(chordSection?.measureAt(0, expanded: false), Measure.parseString('F', beatsPerBar));
    expect(chordSection?.measureAt(7), Measure.parseString('F', beatsPerBar));
  });

  test('test in song, chordRowMaxLength', () {
    int beatsPerBar = 4;
    SongBase a;

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: Am Am/G  v: Am Am/G, Am/F♯ FE   C: F F   O: Dm C\n A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 2);

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: Am Am/G Am/F♯ FE   v: Am Am/G, Am/F♯ FE   C: F F   O: Dm C B B♭, A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');

    expect(a.chordRowMaxLength(), 4);

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G, Am/F♯ FE ] x2  C: F F   O: Dm C B B♭, A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 5);

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G, Am/F♯ FE ] x2  C: F F C C G G F  O: Dm C B B♭ A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 7);

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G, Am/F♯ FE ] x2  C: F F C C G G F F  O: Dm C B B♭ A  ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here o: end here');
    expect(a.chordRowMaxLength(), 8);
  });

  test('test SongBase.shareLinesToRow()', () {
    int beatsPerBar = 4;
    SongBase a;

    //  assure that the song can end on an empty section
    a = SongBase.createSongBase('12 Bar Blues', 'All', 'Unknown', music_key.Key.get(music_key.KeyEnum.C), 106,
        beatsPerBar, 4, 'V: C F C C,F F C C,  G F C G', 'v:');
    expect(a.lyricSections.length, 1);
    expect(a.lyricSections.first.lyricsLines.length, 0);
  });

  test('test last modified time', () {
    int now = DateTime.now().millisecondsSinceEpoch;
    logger.d('now: $now');

    int beatsPerBar = 4;
    SongBase a;

    //  assure that the song can end on an empty section
    a = SongBase.createSongBase('12 Bar Blues', 'All', 'Unknown', music_key.Key.get(music_key.KeyEnum.C), 106,
        beatsPerBar, 4, 'V: C F C C,F F C C,  G F C G', 'v:');
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

    a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar, 4,
        'pearlbob', 'i: D C G G V: C F C C,F F C C,  G F C G', 'i: v:');

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

    a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar, 4,
        'pearlbob', 'i: D C G G V: C F C C,F F C C,  G F C G', someRawLyrics);

    b = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar, 4,
        'pearlbob', 'i: D C G G V: C F C C,F F C C,  G F C G', a.rawLyrics);

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

    a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar, 4,
        'pearlbob', 'i: D C G G V: C F C C,F F C C,  G F C G', 'i: v:');

    b = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar, 4,
        'pearlbob', 'i: D C G G V: C F C C,F F C C,  G F C G', a.rawLyrics);
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

    a = SongBase.from();
    expect(a.title, 'unknown');
    a = SongBase.from(title: 'bob song');
    expect(a.title, 'bob song');
    a = SongBase.from(title: 'the bob song');
    expect(a.title, 'bob song, the');
    expect(a.artist, 'unknown');
    expect(a.coverArtist, isEmpty);

    a = SongBase.from(title: 'bob song', artist: 'bob');
    expect(a.title, 'bob song');
    expect(a.artist, 'bob');
    a = SongBase.from(title: 'bob song', artist: 'the bob');
    expect(a.title, 'bob song');
    expect(a.artist, 'bob, the');
    expect(a.coverArtist, isEmpty);

    {
      var coverArtist = 'not really bob';
      a = SongBase.from(title: 'bob song', artist: 'the bob', coverArtist: coverArtist);
      expect(a.title, 'bob song');
      expect(a.artist, 'bob, the');
      expect(a.coverArtist, isNotEmpty);
      expect(a.coverArtist, coverArtist);

      coverArtist = 'the not real bob';
      a = SongBase.from(title: 'bob song', artist: 'the bob', coverArtist: coverArtist);
      expect(a.title, 'bob song');
      expect(a.artist, 'bob, the');
      expect(a.coverArtist, isNotEmpty);
      expect(a.coverArtist, 'not real bob, the');
    }

    a = SongBase.from(title: 'bob song', artist: 'bob', beatsPerBar: beatsPerBar);
    expect(a.title, 'bob song');
    expect(a.artist, 'bob');
    expect(a.timeSignature.beatsPerBar, beatsPerBar);

    a = SongBase.from(title: 'bob song', artist: 'bob', beatsPerBar: beatsPerBar, unitsPerMeasure: unitsPerMeasure);
    expect(a.title, 'bob song');
    expect(a.artist, 'bob');
    expect(a.timeSignature.beatsPerBar, beatsPerBar);
    expect(a.timeSignature.unitsPerMeasure, unitsPerMeasure);
    expect(a.timeSignature, TimeSignature(beatsPerBar, unitsPerMeasure));
    expect(a.beatsPerMinute, MusicConstants.defaultBpm);

    {
      int beatsPerMinute = MusicConstants.defaultBpm;
      a = SongBase.from(
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
        a = SongBase.from(
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
      a = SongBase.from(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: beatsPerMinute);
      expect(a.beatsPerMinute, MusicConstants.minBpm);

      beatsPerMinute = MusicConstants.maxBpm + 1;
      a = SongBase.from(
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
      a = SongBase.from(
          title: 'bob song',
          artist: 'bob',
          beatsPerBar: beatsPerBar,
          unitsPerMeasure: unitsPerMeasure,
          beatsPerMinute: beatsPerMinute,
          copyright: copyright);
      expect(a.copyright, copyright);

      copyright = 'the copyright from 2021';
      a = SongBase.from(
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
        a = SongBase.from(
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
      a = SongBase.from(
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

      a = SongBase.from(
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
      List<String> chordList = ['', 'i: A B C D', 'i: A B C D v: D C X X'];
      List<String> lyricsList = ['', 'i: (instrumental)', 'i: (instrumental)\n  v: sing some words'];
      for (var title in ['title 1', 'bobs song', 'not bobs song']) {
        for (var artist in ['bob', 'fred', 'joe']) {
          for (var coverArtist in ['', 'bob', 'not bob', 'hidden']) {
            for (var timeSignature in knownTimeSignatures) {
              for (var beatsPerMinute = MusicConstants.minBpm;
                  beatsPerMinute <= MusicConstants.maxBpm;
                  beatsPerMinute++) {
                for (var index = 0; index < chordList.length; index++) {
                  a = SongBase.from(
                    title: title,
                    artist: artist,
                    coverArtist: coverArtist,
                    beatsPerBar: timeSignature.beatsPerBar,
                    unitsPerMeasure: timeSignature.unitsPerMeasure,
                    beatsPerMinute: beatsPerMinute,
                    chords: chordList[index],
                    rawLyrics: lyricsList[index],
                  );
                  expect(a.title, title);
                  expect(a.artist, artist);
                  expect(a.coverArtist, coverArtist);
                  expect(a.timeSignature, timeSignature);
                  expect(a.beatsPerMinute, beatsPerMinute);
                  expect(a.getChordSections().length, index);
                  expect(a.lyricSections.length, index);
                }
              }
            }
          }
        }
      }
    }
  });

  test('test songBase toGrid()', () {
    int beatsPerBar = 4;
    SongBase a;

    {
      a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearlbob',
          'v: [ A B C D ] x4',
          'v: foo foo foo foo baby oh baby yesterday\n'
              'bar bar\n'
              'bob, bob, bob berand\n'
              'You got me');

      var grid = a.toLyricsGrid();
      logger.i('a.toGrid(): $grid');
      var momentGridList = a.songMomentToChordGrid();
      logger.i('momentGrid: $momentGridList');
      for (var moment in a.songMoments) {
        var gridCoordinate = momentGridList[moment.momentNumber];
        logger.i('${moment.momentNumber}: ${gridCoordinate}'
            ': ${moment.measure}: grid: ${grid.get(gridCoordinate.row, gridCoordinate.col)}'
            ', "${moment.lyrics}"');
      }
    }

    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb', 'i: v: o:');

      var grid = a.toLyricsGrid();
      logger.d('a.toGrid(): $grid');

      //  assure the lengths are correct
      for (var r = 0; r < 8; r++) {
        expect(grid.rowLength(r), 4 + 1 //  for the lyrics
            );
      }

      expect(grid.get(0, 0), ChordSection.parseString('i: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(0, i), isNull);
      }
      expect(grid.get(1, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(1, 3), Measure.parseString('G#', beatsPerBar));

      expect(grid.get(2, 0), ChordSection.parseString('V: C F C C#,F F C B,  G F C Gb', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(2, i), isNull);
      }
      expect(grid.get(3, 0), Measure.parseString('C', beatsPerBar));
      expect(grid.get(3, 3), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(4, 0), Measure.parseString('F', beatsPerBar));
      expect(grid.get(4, 3), Measure.parseString('B,', beatsPerBar));
      expect(grid.get(5, 0), Measure.parseString('G', beatsPerBar));
      expect(grid.get(5, 3), Measure.parseString('Gb', beatsPerBar));

      expect(grid.get(6, 0), ChordSection.parseString('o: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(6, i), isNull);
      }
      expect(grid.get(7, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(7, 3), Measure.parseString('G#', beatsPerBar));
    }
    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i:o: D C G G# V: C F C C#,F F C B x2,  G F C Gb', 'i: v: o:');

      var grid = a.toLyricsGrid();
      logger.d('a.toGrid(): $grid');

      //  assure the lengths are correct
      for (var r = 0; r < 8; r++) {
        expect(grid.rowLength(r), 5 + 1);
      }

      expect(grid.get(0, 0), ChordSection.parseString('i: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(0, i), isNull);
      }
      expect(grid.get(1, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(1, 3), Measure.parseString('G#', beatsPerBar));

      expect(grid.get(2, 0), ChordSection.parseString('V: C F C C#,F F C B x2  G F C Gb', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(2, i), isNull);
      }
      expect(grid.get(3, 0), Measure.parseString('C', beatsPerBar));
      expect(grid.get(3, 3), Measure.parseString('C#', beatsPerBar));
      expect(grid.get(4, 0), Measure.parseString('F', beatsPerBar));
      expect(grid.get(4, 3), Measure.parseString('B', beatsPerBar));
      expect(grid.get(5, 0), Measure.parseString('G', beatsPerBar));
      expect(grid.get(5, 3), Measure.parseString('Gb', beatsPerBar));

      expect(grid.get(6, 0), ChordSection.parseString('o: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(6, i), isNull);
      }
      expect(grid.get(7, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(7, 3), Measure.parseString('G#', beatsPerBar));
    }

    {
      a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearlbob',
          'i:o: D C G G# V: [C F C C#,F F C B] x2,  G F C Gb',
          'i: intro lyric\n'
              'v: verse lyric 1\nverse lyric 2\no: outro lyric\n');

      var grid = a.toLyricsGrid();
      logger.i('a.toGrid(): $grid');

      //  assure the lengths are correct
      for (var r = 0; r < grid.getRowCount(); r++) {
        expect(grid.rowLength(r), 6 + 1);
      }

      expect(grid.get(0, 0), ChordSection.parseString('i: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(0, i), isNull);
      }
      expect(grid.get(1, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(1, 3), Measure.parseString('G#', beatsPerBar));

      expect(grid.get(2, 0), ChordSection.parseString('V: [C F C C#,F F C B] x2  G F C Gb', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(2, i), isNull);
      }
      expect(grid.get(3, 0), Measure.parseString('C', beatsPerBar));
      expect(grid.get(3, 3), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(4, 0), Measure.parseString('F', beatsPerBar));
      expect(grid.get(4, 3), Measure.parseString('B', beatsPerBar));
      expect(grid.get(5, 0), Measure.parseString('G', beatsPerBar));
      expect(grid.get(5, 3), Measure.parseString('Gb', beatsPerBar));

      expect(grid.get(6, 0), ChordSection.parseString('o: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(6, i), isNull);
      }
      expect(grid.get(7, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(7, 3), Measure.parseString('G#', beatsPerBar));
    }
  });

  test('test songBase toGrid(expanded:true)', () {
    Logger.level = Level.info;

    int beatsPerBar = 4;
    SongBase a;

    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb', 'i: v: o:');

      var grid = a.toLyricsGrid(expanded: true);
      logger.d('a.toGrid(): $grid');

      //  assure the lengths are correct
      for (var r = 0; r < 8; r++) {
        expect(grid.rowLength(r), 4 + 1 //  for lyrics column
            );
      }

      expect(grid.get(0, 0), ChordSection.parseString('i: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(0, i), isNull);
      }
      expect(grid.get(1, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(1, 3), Measure.parseString('G#', beatsPerBar));

      expect(grid.get(2, 0), ChordSection.parseString('V: C F C C#,F F C B,  G F C Gb', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(2, i), isNull);
      }
      expect(grid.get(3, 0), Measure.parseString('C', beatsPerBar));
      expect(grid.get(3, 3), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(4, 0), Measure.parseString('F', beatsPerBar));
      expect(grid.get(4, 3), Measure.parseString('B,', beatsPerBar));
      expect(grid.get(5, 0), Measure.parseString('G', beatsPerBar));
      expect(grid.get(5, 3), Measure.parseString('Gb', beatsPerBar));

      expect(grid.get(6, 0), ChordSection.parseString('o: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(6, i), isNull);
      }
      expect(grid.get(7, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(7, 3), Measure.parseString('G#', beatsPerBar));
    }
    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i:o: D C G G# V: C F C C#,F F C B x2,  G F C Gb', 'i: v: o:');

      var grid = a.toLyricsGrid(expanded: true);
      logger.d('a.toGrid(): $grid');

      expect(grid.getRowCount(), 9);

      //  assure the lengths are correct
      for (var r = 0; r < grid.getRowCount(); r++) {
        expect(grid.rowLength(r), 5 + 1);
      }

      expect(grid.get(0, 0), ChordSection.parseString('i: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(0, i), isNull);
      }
      expect(grid.get(1, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(1, 3), Measure.parseString('G#', beatsPerBar));

      expect(grid.get(2, 0), ChordSection.parseString('V: C F C C#,F F C B x2  G F C Gb', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(2, i), isNull);
      }
      expect(grid.get(3, 0), Measure.parseString('C', beatsPerBar));
      expect(grid.get(3, 3), Measure.parseString('C#', beatsPerBar));
      expect(grid.get(4, 0), Measure.parseString('F', beatsPerBar));
      expect(grid.get(4, 3), Measure.parseString('B', beatsPerBar));
      expect(grid.get(5, 0), Measure.parseString('F', beatsPerBar));
      expect(grid.get(5, 3), Measure.parseString('B', beatsPerBar));
      expect(grid.get(6, 0), Measure.parseString('G', beatsPerBar));
      expect(grid.get(6, 3), Measure.parseString('Gb', beatsPerBar));

      expect(grid.get(7, 0), ChordSection.parseString('o: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(7, i), isNull);
      }
      expect(grid.get(8, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(8, 3), Measure.parseString('G#', beatsPerBar));
    }

    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i:o: D C G G# V: [C F C C#,F F C B] x2,  G F C Gb', 'i: v: o:');

      var grid = a.toLyricsGrid(expanded: true);
      logger.d('a.toGrid(): $grid');

      expect(grid.getRowCount(), 10);

      //  assure the lengths are correct
      for (var r = 0; r < grid.getRowCount(); r++) {
        expect(grid.rowLength(r), 6 + 1);
      }

      expect(grid.get(0, 0), ChordSection.parseString('i: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(0, i), isNull);
      }
      expect(grid.get(1, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(1, 3), Measure.parseString('G#', beatsPerBar));

      expect(grid.get(2, 0), ChordSection.parseString('V: [C F C C#,F F C B] x2  G F C Gb', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(2, i), isNull);
      }
      expect(grid.get(3, 0), Measure.parseString('C', beatsPerBar));
      expect(grid.get(3, 3), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(4, 0), Measure.parseString('F', beatsPerBar));
      expect(grid.get(4, 3), Measure.parseString('B', beatsPerBar));
      expect(grid.get(5, 0), Measure.parseString('C', beatsPerBar));
      expect(grid.get(5, 3), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(6, 0), Measure.parseString('F', beatsPerBar));
      expect(grid.get(6, 3), Measure.parseString('B', beatsPerBar));
      expect(grid.get(7, 0), Measure.parseString('G', beatsPerBar));
      expect(grid.get(7, 3), Measure.parseString('Gb', beatsPerBar));

      expect(grid.get(8, 0), ChordSection.parseString('o: D C G G#', beatsPerBar));
      for (var i = 1; i < 4; i++) {
        expect(grid.get(8, i), isNull);
      }
      expect(grid.get(9, 0), Measure.parseString('D', beatsPerBar));
      expect(grid.get(9, 3), Measure.parseString('G#', beatsPerBar));
    }
  });

  void _testSongMomentToGrid(Song a) {
    for (var expanded in [false, true]) {
      var grid = a.toLyricsGrid(expanded: expanded);
      logger.i('a.toGrid(): ${expanded ? 'expanded:' : ''} $grid ');

      List<GridCoordinate> list = a.songMomentToChordGrid(expanded: expanded);
      assert(list.length == a.getSongMomentsSize());
      for (var songMoment in a.songMoments) {
        var gc = list[songMoment.momentNumber];
        var measureNode = grid.get(gc.row, gc.col);
        logger.i('${songMoment.momentNumber}: $gc: $measureNode');
        assert(measureNode is Measure);
        expect(measureNode, songMoment.measure);
      }
    }
  }

  test('test songBase songMomentToGrid()', () {
    Logger.level = Level.info;

    int beatsPerBar = 4;
    Song a;

    {
      a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearlbob',
          'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb',
          'i: intro lyric\n'
              'v: verse lyric\n'
              'more verse lyrcs\n'
              'o: outro lyric');
      _testSongMomentToGrid(a);
    }
    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i: D C G G# x2', 'i: no lyrics here');
      _testSongMomentToGrid(a);
    }
    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i: D C G G# x2', 'i: no lyrics here');
      _testSongMomentToGrid(a);
    }
    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i:o: D C G G# V: C F C C#,F F C B x2,  G F C Gb', 'i: v: o:');
      _testSongMomentToGrid(a);
    }
    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'V: [C F C C#, F F C B] x2', 'v: hey!');
      _testSongMomentToGrid(a);
    }

    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i:o: D C G G# V: [C F C C#, F F C B] x2,  G F C Gb', 'i: v: o:');
      _testSongMomentToGrid(a);
    }

    {
      //  empty lyrics
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'v: G G G G, C C G G, D C G D', 'v:');
      _testSongMomentToGrid(a);
    }
  });

  test('test songBase validateChords', () {
    int beatsPerBar = 4;

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
      var a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106,
          beatsPerBar, 4, 'pearl bob', 'v: G G G G, C C G G, D C G D', 'v: foobar');
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
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearl bob', 'i:v: G G G G, C C G G, D C G D', 'v: foobar');
      lyrics = 'i: no\n  v:\n foo\n';
      expect(a.validateLyrics('i:v: lkf'), null); // no error

      //  multiple sections, empty last lyrics
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearl bob', 'i:v: G G G G, C C G G, D C G D', 'v: foobar');
      lyrics = 'i: no\n  v:\n foo\ni:';
      expect(a.validateLyrics('i:v: lkf'), null); // no error

      //  unused chord section
      lyrics = 'i: no\n bar bar';
      expect(a.validateLyrics(lyrics).runtimeType, LyricParseException);
      expect(a.validateLyrics(lyrics)?.message, 'Chord section unused:');
      expect(a.validateLyrics(lyrics)?.markedString.toString(), 'V:');
    }
  });

  test('test songBase toMarkup as entry', () {
    int beatsPerBar = 4;
    {
      var a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106,
          beatsPerBar, 4, 'pearl bob', 'v: []', 'v: foobar');
      expect(
          a.toMarkup(asEntry: true),
          'V: \n'
          '  []\n'
          '');
    }
    {
      var a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106,
          beatsPerBar, 4, 'pearl bob', 'v: [] c: []', 'v: foobar');
      expect(
          a.toMarkup(asEntry: true),
          'V: \n'
          '  []\n'
          'C: \n'
          '  []\n'
          '');
    }
    {
      var a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106,
          beatsPerBar, 4, 'pearl bob', 'v: G G G G, C C G G, D C G D', 'v: foobar');
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
      var a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106,
          beatsPerBar, 4, 'pearl bob', 'i: v: G G G G, C C G G, D C G D', 'i: (instrumental) v: foobar');
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
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: [ A B C D ] x2 v: G G G G, [C C G G]x4 D C G D',
          'i: (instrumental) v: foobar');
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
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x4',
          'i: (instrumental) v: foobar');
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
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n A B C D\n'
          'V:\n'
          ' G G G G, C C G G\n'
          'O: C C G G\n');
    }
    {
      //  fixme: force a new line at lyrics entry?
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i:\n(instrumental)\n\nv: line 1\n\no:\n\n');
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
        var lyrics;
        {
          var sb = StringBuffer('i: (instrumental)\n v: ');
          for (var i = 1; i <= lines; i++) {
            sb.write('line $i\n');
          }
          lyrics = sb.toString();
        }
        var a = Song.createSong(
            'ive go the blanks',
            'bob',
            'bob',
            music_key.Key.get(music_key.KeyEnum.C),
            106,
            beatsPerBar,
            4,
            'pearl bob',
            'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x2',
            //  no newline at verse lyrics should not matter
            lyrics);
        logger.i('lines $lines: "${a.chordMarkupForLyrics()}"');
        expect(a.chordMarkupForLyrics().split('\n').length, lines + 3 + 1);
      }
    }
    {
      var a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106,
          beatsPerBar, 4, 'pearl bob', 'i: A B C D  v: G G G G, C C G G o: C C G G', 'i:\nv: line 1\no:');
      expect(
          a.chordMarkupForLyrics(),
          'I: A B C D\n'
          'V:\n'
          ' G G G G, C C G G\n'
          'O: C C G G\n');
    }
    {
      var a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106,
          beatsPerBar, 4, 'pearl bob', 'i: A B C D  v: G G G G, C C G G o: C C G G', 'i:\nv:\nline 1\no:');
      expect(
          a.chordMarkupForLyrics(),
          'I: A B C D\n'
          'V:\n'
          ' G G G G, C C G G\n'
          'O: C C G G\n');
    }
    {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x4',
          'i: (instrumental)\n v: foobar');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n[A B C D] x2#1 [A B C D] x2#2\n'
          'V:\n[G G G G, C C G G, D C G D] x4#1 [G G G G, C C G G, D C G D] x4#2'
          ' [G G G G, C C G G, D C G D] x4#3 [G G G G, C C G G, D C G D] x4#4\n');
    }
    {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x4',
          'i: (instrumental)\n '
              'v:\nline 1\nline 2\nline 3\nline 4\nline 5\nline 6\n');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n'
          '[A B C D] x2#1 [A B C D] x2#2\n'
          'V:\n'
          '[G G G G\n'
          ' C C G G\n'
          ' D C G D] x4#1\n'
          '[G G G G\n'
          ' C C G G\n'
          ' D C G D] x4#2 [G G G G, C C G G, D C G D] x4#3 [G G G G, C C G G, D C G D] x4#4\n');
    }
    {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: [ A B C D ] x2 v: [G G G G, C C G G, D C G D]x4',
          //  no newline at verse lyrics should not matter
          'i: (instrumental)\n v: line 1\nline 2\nline 3\nline 4\nline 5\nline 6\n');
      expect(
          a.chordMarkupForLyrics(),
          'I:\n'
          '[A B C D] x2#1 [A B C D] x2#2\n'
          'V:\n'
          '[G G G G\n'
          ' C C G G\n'
          ' D C G D] x4#1\n'
          '[G G G G\n'
          ' C C G G\n'
          ' D C G D] x4#2 [G G G G, C C G G, D C G D] x4#3 [G G G G, C C G G, D C G D] x4#4\n');
    }
    {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G',
          'i: (instrumental)\nyeah\n v: line 1\nline 2\nline 3\nline 4\nline 5\nline 6\n');
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
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  V: [Am Am/G Am/F# FE] x4',
          'i:\nv:\nWaiting for the break of day\n'
              'Searching for something to say\n'
              'Flashing lights against the sky\n'
              'Giving up I close my eyes\n');
      expect(
          a.chordMarkupForLyrics(),
          'I: A B C D\n'
          'V:\n'
          '[Am Am/G Am/F# FE] x4#1\n'
          '[Am Am/G Am/F# FE] x4#2\n'
          '[Am Am/G Am/F# FE] x4#3\n'
          '[Am Am/G Am/F# FE] x4#4\n');
    }
  });

  final RegExp _lastModifiedDateRegexp = RegExp(r'"lastModifiedDate": \d+,\n');
  test('test songBase to/from JSON', () {
    int beatsPerBar = 4;
    {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      expect(
          a.toJson().replaceAll(_lastModifiedDateRegexp, 'lastModifiedDate was here\n'),
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
          a.toJson().replaceAll(_lastModifiedDateRegexp, 'lastModifiedDate was here\n'),
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
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var totalBeats = a.getTotalBeats();
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
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'copyright $year bob hot music',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }

    for (var year in [179, 0, 20609, 2]) {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'copyright $year bob hot music',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var songYear = a.getCopyrightYear();
      expect(songYear, SongBase.defaultYear);
    }

    for (var year in [1796, 1900, 2069, 2022]) {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'copyright $year',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }

    for (var year in [179, 0, 20609, 2]) {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'copyright $year',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var songYear = a.getCopyrightYear();
      expect(songYear, SongBase.defaultYear);
    }

    for (var year in [1796, 1900, 2069, 2022]) {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          '$year bob music',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }

    for (var year in [179, 0, 20609, 2]) {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          '$year bob music',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var songYear = a.getCopyrightYear();
      expect(songYear, SongBase.defaultYear);
    }

    for (var year in [1796, 1900, 2069, 2022]) {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          '$year',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var songYear = a.getCopyrightYear();
      expect(songYear, year);
    }

    for (var year in [179, 0, 20609, 2]) {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          '$year',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\nv: line 1\no:\n');

      var songYear = a.getCopyrightYear();
      expect(songYear, SongBase.defaultYear);
    }
  });

  test('test songBase read dos files', () {
    int beatsPerBar = 4;
    int bpm = 106;
    {
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  v: G G G G, C C G G o: C C G G',
          'i: (instrumental)\r\nmore instrumental\nv: line 1\r\n line 2\r\no:\r\nyo\ryo2\nyo3\r\nyo4');
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
      var a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          bpm,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  x4 v: G G G G, C C G G o: [ C C G G, E F G E ] x3 A B C',
          'i: (instrumental)\r\nmore instrumental\nv: line 1\r\n line 2\r\no:\r\nyo\ryo2\nyo3\r\nyo4');

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
    SongBase a;

    {
      a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearlbob',
          'v: [ A B C D ] x4',
          'v: foo foo foo foo baby oh baby yesterday\n'
              'bar bar\n'
              'bob, bob, bob berand\n'
              'You got me');
      for (var expanded in [false, true]) {
        var grid = a.toDisplayGrid(UserDisplayStyle.proPlayer, expanded: expanded);
        logger.d('a.toDisplayGrid(): $grid');
        expect(grid.getRowCount(), 2);
        assert(grid.get(0, 0) is ChordSection);
        var chordSection = grid.get(0, 0) as ChordSection;
        expect(chordSection.sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        logger.d(a.songMoments.toString());

        for (var songMoment in a.songMoments) {
          logger.d('$songMoment: ${a.songMomentToGridCoordinate[songMoment.momentNumber]}');
          expect(
              grid.get(0, a.songMomentToGridCoordinate[songMoment.momentNumber].row - 1 /* row is at +1  */)
                  as ChordSection,
              songMoment.chordSection);
        }
        for (var songMoment in a.songMoments) {
          logger.d('$songMoment: ${a.songMomentToGridCoordinate[songMoment.momentNumber]}');
          expect(
              grid.at(a.songMomentToGridCoordinate[songMoment.momentNumber]) as ChordSection, songMoment.chordSection);
        }
      }
    }

    {
      a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
          4, 'pearlbob', 'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb', 'i: v: o:');

      for (var expanded in [false, true]) {
        var grid = a.toDisplayGrid(UserDisplayStyle.proPlayer, expanded: expanded);
        logger.d('a.toDisplayGrid(): $grid');
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
      }
    }
    {
      a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearlbob',
          'v: [ A B C D ] x4',
          'v: foo foo foo foo baby oh baby yesterday\n'
              'bar bar\n'
              'bob, bob, bob berand\n'
              'You got me');
      for (var expanded in [false, true]) //  shouldn't matter
      {
        var grid = a.toDisplayGrid(UserDisplayStyle.singer, expanded: expanded);
        logger.d('a.toDisplayGrid(): $grid');
        expect(grid.getRowCount(), 5);
        assert(grid.get(0, 0) is ChordSection);
        var chordSection = grid.get(0, 0) as ChordSection;
        expect(chordSection.sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect(grid.get(1, 0)!.measureNodeType, MeasureNodeType.lyric);
        var lyric = grid.get(1, 0) as Lyric;
        expect(lyric.line, 'foo foo foo foo baby oh baby yesterday');
        lyric = grid.get(2, 0) as Lyric;
        expect(lyric.line, 'bar bar');
        lyric = grid.get(3, 0) as Lyric;
        expect(lyric.line, 'bob, bob, bob berand');
        lyric = grid.get(4, 0) as Lyric;
        expect(lyric.line, 'You got me');

        for (var songMoment in a.songMoments) {
          //  expect entry for section labels
          var gc = a.songMomentToGridCoordinate[songMoment.momentNumber];
          logger.d('$songMoment: $gc');
          expect(grid.at(gc) as ChordSection, songMoment.chordSection);
        }
      }
    }

    {
      a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          106,
          beatsPerBar,
          4,
          'pearlbob',
          'i:o: D C G G# V: C F C C#,F F C B,  G F C Gb',
          'i: (instrumental)\n '
              'v: v: foo foo foo foo baby\n oh baby yesterday\n'
              'bar bar\no:  yo yo yo\n yeah');

      for (var expanded in [false, true]) //  shouldn't matter
      {
        var grid = a.toDisplayGrid(UserDisplayStyle.singer, expanded: expanded);
        logger.d('a.toDisplayGrid(): $grid');
        expect(grid.getRowCount(), 11);
        expect((grid.get(0, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.intro), 0));
        expect((grid.get(0, 1) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.intro), 0));
        expect(grid.get(0, 2), isNull);
        expect((grid.get(1, 0) as Lyric).line, '(instrumental)');
        expect((grid.get(2, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect((grid.get(2, 1) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect((grid.get(3, 0) as Lyric).line, '');
        expect((grid.get(4, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect((grid.get(4, 1) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.verse), 0));
        expect(grid.get(4, 2), isNull);
        expect((grid.get(5, 0) as Lyric).line, 'foo foo foo foo baby');
        expect(grid.get(5, 1), isNull);
        expect((grid.get(6, 0) as Lyric).line, 'oh baby yesterday');
        expect((grid.get(7, 0) as Lyric).line, 'bar bar');
        expect((grid.get(8, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.outro), 0));
        expect((grid.get(8, 1) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.outro), 0));
        expect((grid.get(9, 0) as Lyric).line, 'yo yo yo');
        expect((grid.get(10, 0) as Lyric).line, 'yeah');
        expect(grid.get(11, 0), isNull);

        for (var songMoment in a.songMoments) {
          //  expect entry for section labels
          var gc = a.songMomentToGridCoordinate[songMoment.momentNumber];
          logger.d('$songMoment: $gc');
          expect(grid.at(gc) as ChordSection, songMoment.chordSection);
        }
      }
    }
    {
      a = Song.createSong(
          'ive go the blanks',
          'bob',
          'bob',
          music_key.Key.get(music_key.KeyEnum.C),
          104,
          beatsPerBar,
          4,
          'pearl bob',
          'i: A B C D  x4 v: G G G G, C C G G o: [ C C G G, E F G E ] x3 A B C',
          'i: (instrumental)\nmore instrumental\nv: line 1\n line 2\n'
              'o:\n'
              'yo1\n'
              'yo2\n'
              'yo3\n'
              'yo4');

      var grid = a.toDisplayGrid(UserDisplayStyle.both, expanded: false);
      logger.i('a.toDisplayGrid(): $grid');
      expect(grid.getRowCount(), 13);
      expect((grid.get(0, 0) as ChordSection).sectionVersion, SectionVersion(Section.get(SectionEnum.intro), 0));
      for (var i = 1; i < 7; i++) {
        expect(grid.get(0, i), isNull);
      }
      var r = 1;
      expect((grid.get(r, 0) as Measure).toMarkup(), 'A');
      expect((grid.get(r, 1) as Measure).toMarkup(), 'B');
      expect((grid.get(r, 2) as Measure).toMarkup(), 'C');
      expect((grid.get(r, 3) as Measure).toMarkup(), 'D');
      expect((grid.get(r, 4) as Measure).toMarkup(), 'x4');
      expect(grid.get(r, 5), isNull);
      expect((grid.get(r, 6) as Lyric).line, '(instrumental)');
      r = 2;
      expect(grid.get(r, 0), isNull);
      expect(grid.get(r, 1), isNull);
      expect(grid.get(r, 2), isNull);
      expect(grid.get(r, 3), isNull);
      expect(grid.get(r, 4), isNull);
      expect(grid.get(r, 5), isNull);
      expect((grid.get(r, 6) as Lyric).line, 'more instrumental');
      r = 9;
      expect((grid.get(r, 0) as Measure).toMarkup(), 'C');
      expect((grid.get(r, 1) as Measure).toMarkup(), 'C');
      expect((grid.get(r, 2) as Measure).toMarkup(), 'G');
      expect((grid.get(r, 3) as Measure).toMarkup(), 'G,');
      expect((grid.get(r, 4) as Measure).toString(), '⎤');
      expect(grid.get(r, 5), isNull);
      expect((grid.get(r, 6) as Lyric).line, 'yo1\nyo2');
      r = 12;
      expect(grid.get(r, 0), isNull);
      expect(grid.get(r, 1), isNull);
      expect(grid.get(r, 2), isNull);
      expect(grid.get(r, 3), isNull);
      expect(grid.get(r, 4), isNull);
      expect(grid.get(r, 5), isNull);
      expect((grid.get(r, 6) as Lyric).line, ''); // fixme: verify this

      //
      // for (var songMoment in a.songMoments) {
      //   //  expect entry for section labels
      //   var gc = a.songMomentToGridCoordinate[songMoment.momentNumber];
      //   logger.i('$songMoment: $gc');
      //   expect(grid.at(gc) as ChordSection, songMoment.chordSection);
      // }
    }
    // {
    //   a = Song.createSong('ive go the blanks', 'bob', 'bob', music_key.Key.get(music_key.KeyEnum.C), 106, beatsPerBar,
    //       4, 'pearlbob', 'i:o: D C G G# V: C F C C#,F F C B x2,  G F C Gb', 'i: v: o:');
    //
    //   var grid = a.toLyricsGrid();
    //   logger.d('a.toGrid(): $grid');
    //
    //   //  assure the lengths are correct
    //   for (var r = 0; r < 8; r++) {
    //     expect(grid.rowLength(r), 5 + 1);
    //   }
    //
    //   expect(grid.get(0, 0), ChordSection.parseString('i: D C G G#', beatsPerBar));
    //   for (var i = 1; i < 4; i++) {
    //     expect(grid.get(0, i), isNull);
    //   }
    //   expect(grid.get(1, 0), Measure.parseString('D', beatsPerBar));
    //   expect(grid.get(1, 3), Measure.parseString('G#', beatsPerBar));
    //
    //   expect(grid.get(2, 0), ChordSection.parseString('V: C F C C#,F F C B x2  G F C Gb', beatsPerBar));
    //   for (var i = 1; i < 4; i++) {
    //     expect(grid.get(2, i), isNull);
    //   }
    //   expect(grid.get(3, 0), Measure.parseString('C', beatsPerBar));
    //   expect(grid.get(3, 3), Measure.parseString('C#', beatsPerBar));
    //   expect(grid.get(4, 0), Measure.parseString('F', beatsPerBar));
    //   expect(grid.get(4, 3), Measure.parseString('B', beatsPerBar));
    //   expect(grid.get(5, 0), Measure.parseString('G', beatsPerBar));
    //   expect(grid.get(5, 3), Measure.parseString('Gb', beatsPerBar));
    //
    //   expect(grid.get(6, 0), ChordSection.parseString('o: D C G G#', beatsPerBar));
    //   for (var i = 1; i < 4; i++) {
    //     expect(grid.get(6, i), isNull);
    //   }
    //   expect(grid.get(7, 0), Measure.parseString('D', beatsPerBar));
    //   expect(grid.get(7, 3), Measure.parseString('G#', beatsPerBar));
    // }
    //
    // {
    //   a = Song.createSong(
    //       'ive go the blanks',
    //       'bob',
    //       'bob',
    //       music_key.Key.get(music_key.KeyEnum.C),
    //       106,
    //       beatsPerBar,
    //       4,
    //       'pearlbob',
    //       'i:o: D C G G# V: [C F C C#,F F C B] x2,  G F C Gb',
    //       'i: intro lyric\n'
    //           'v: verse lyric 1\nverse lyric 2\no: outro lyric\n');
    //
    //   var grid = a.toLyricsGrid();
    //   logger.i('a.toGrid(): $grid');
    //
    //   //  assure the lengths are correct
    //   for (var r = 0; r < grid.getRowCount(); r++) {
    //     expect(grid.rowLength(r), 6 + 1);
    //   }
    //
    //   expect(grid.get(0, 0), ChordSection.parseString('i: D C G G#', beatsPerBar));
    //   for (var i = 1; i < 4; i++) {
    //     expect(grid.get(0, i), isNull);
    //   }
    //   expect(grid.get(1, 0), Measure.parseString('D', beatsPerBar));
    //   expect(grid.get(1, 3), Measure.parseString('G#', beatsPerBar));
    //
    //   expect(grid.get(2, 0), ChordSection.parseString('V: [C F C C#,F F C B] x2  G F C Gb', beatsPerBar));
    //   for (var i = 1; i < 4; i++) {
    //     expect(grid.get(2, i), isNull);
    //   }
    //   expect(grid.get(3, 0), Measure.parseString('C', beatsPerBar));
    //   expect(grid.get(3, 3), Measure.parseString('C#,', beatsPerBar));
    //   expect(grid.get(4, 0), Measure.parseString('F', beatsPerBar));
    //   expect(grid.get(4, 3), Measure.parseString('B', beatsPerBar));
    //   expect(grid.get(5, 0), Measure.parseString('G', beatsPerBar));
    //   expect(grid.get(5, 3), Measure.parseString('Gb', beatsPerBar));
    //
    //   expect(grid.get(6, 0), ChordSection.parseString('o: D C G G#', beatsPerBar));
    //   for (var i = 1; i < 4; i++) {
    //     expect(grid.get(6, i), isNull);
    //   }
    //   expect(grid.get(7, 0), Measure.parseString('D', beatsPerBar));
    //   expect(grid.get(7, 3), Measure.parseString('G#', beatsPerBar));
    // }
  });
}
