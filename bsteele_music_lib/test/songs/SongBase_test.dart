import 'dart:collection';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/grid.dart';
import 'package:bsteeleMusicLib/gridCoordinate.dart';
import 'package:bsteeleMusicLib/songs/chordSection.dart';
import 'package:bsteeleMusicLib/songs/chordSectionLocation.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
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
  Grid<ChordSectionLocation> grid = song.getChordSectionLocationGrid();
  StringBuffer sb = StringBuffer('Grid{\n');

  int rLimit = grid.getRowCount();
  for (int r = 0; r < rLimit; r++) {
    List<ChordSectionLocation?>? row = grid.getRow(r);
    if (row == null) {
      throw 'row == null';
    }
    int colLimit = row.length;
    sb.write('\t[');
    for (int c = 0; c < colLimit; c++) {
      ChordSectionLocation? loc = row[c];
      if (loc == null) {
        sb.write('\tnull\n');
        continue;
      }

      sb.write('\t' + loc.toString() + ' ');
      if (loc.isMeasure) {
        Measure? measure = song.findMeasureByChordSectionLocation(loc);
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
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand');
    SongBase b = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand');

    expect(a == a, isTrue);
    expect(a.hashCode == a.hashCode, isTrue);
    expect(a == b, isTrue);
    expect(a.hashCode == b.hashCode, isTrue);
    b = SongBase.createSongBase(
        'B',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
    b = SongBase.createSongBase(
        'A',
        'bobby',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
    b = SongBase.createSongBase(
        'A',
        'bob',
        'photos.bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand');
    logger.d('a.getSongId(): ' + a
        .getSongId()
        .hashCode
        .toString());
    logger.d('b.getSongId(): ' + b
        .getSongId()
        .hashCode
        .toString());
    expect(a.getSongId().compareTo(b.getSongId()), 0);
    expect(a.getSongId(), b.getSongId());
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.get(music_key.KeyEnum.Ab),
        100,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        102,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        3,
        8,
        'v: A B C D',
        'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    //top
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        8,
        'v: A B C D',
        'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A A C D',
        'v: bob, bob, bob berand');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);

    b = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand.');
    expect(a != b, isTrue);
    expect(a.hashCode != b.hashCode, isTrue);
  });

  test('testCurrentLocation', () {
    SongBase a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        8,
        'I:v: A BCm7/ADE C D',
        'I:v: bob, bob, bob berand');
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

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        8,
        'I:v: A B C D ch3: [ E F G A ] x4 A# C D# F',
        'I:v: bob, bob, bob berand');
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
    //   expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.get(ScaleNoteEnum.B));
    // }
        {
      a = SongBase.createSongBase(
          'A',
          'bob',
          'bsteele.com',
          music_key.Key.getDefault(),
          100,
          4,
          8,
          'I:v: A B C D',
          'I:v: bob, bob, bob berand');

      SplayTreeSet<ChordSection> chordSections = SplayTreeSet<ChordSection>.of(a.getChordSections());
      ChordSection chordSection = chordSections.first;
      Phrase phrase = chordSection.phrases[0];

      Measure measure = phrase.measures[1];
      expect(phrase.measures.length, 4);
      expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.get(ScaleNoteEnum.B));
    }

    for (int i = 50; i < 401; i++) {
      a.setBeatsPerMinute(i);
      expect(a.beatsPerMinute, i);
    }
  });

  test('testChordSectionEntry', () {
    SongBase a;

    //  empty sections
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'i: v: t:',
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
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'i: v: t:',
        'i: dude v: bob, bob, bob berand');

    expect(a.editList(a.parseChordEntry('I: A B C D A B C D')), isTrue);

    expect('I: A B C D, A B C D', a.findChordSectionByString('I:')!.toMarkup().trim());
  });

  test('testFind', () {
    SongBase a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D v: E F G A# t: Gm Gm',
        'i: dude v: bob, bob, bob berand');

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
      SongBase a = SongBase.createSongBase(
          'A',
          'bob',
          'bsteele.com',
          music_key.Key.getDefault(),
          100,
          4,
          4,
          'i: A B C D v: E F G A#',
          'i: v: bob, bob, bob berand');

      MeasureNode? m = a.findMeasureNodeByGrid(GridCoordinate(0, 4));
      ChordSectionLocation? chordSectionLocation = a.findChordSectionLocation(m);
      logger.d(chordSectionLocation.toString());
      a.setRepeat(chordSectionLocation!, 2);
      logger.d(a.toMarkup());
      expect(a.toMarkup().trim(), 'I: [A B C D ] x2  V: E F G A#');

      //  remove the repeat
      chordSectionLocation = a.findChordSectionLocation(m);
      a.setRepeat(chordSectionLocation!, 1);
      expect(a.toMarkup().trim(), 'I: A B C D  V: E F G A#');
    }

    {
      SongBase a = SongBase.createSongBase(
          'A',
          'bob',
          'bsteele.com',
          music_key.Key.getDefault(),
          100,
          4,
          4,
          'i: A B C D v: E F G A#',
          'i: v: bob, bob, bob berand');

      logger.d(a.logGrid());
      Grid<ChordSectionLocation> grid;

      grid = a.getChordSectionLocationGrid();
      for (int row = 0; row < grid.getRowCount(); row++) {
        a = SongBase.createSongBase(
            'A',
            'bob',
            'bsteele.com',
            music_key.Key.getDefault(),
            100,
            4,
            4,
            'i: A B C D v: E F G A#',
            'i: v: bob, bob, bob berand');
        grid = a.getChordSectionLocationGrid();
        List<ChordSectionLocation?>? cols = grid.getRow(row);
        if (cols != null) {
          for (int col = 1; col < cols.length; col++) {
            for (int r = 6; r > 1; r--) {
              MeasureNode? m = a.findMeasureNodeByGrid(GridCoordinate(row, col));
              ChordSectionLocation? chordSectionLocation = a.findChordSectionLocation(m);
              if (chordSectionLocation == null) throw 'chordSectionLocation == null';
              a.setRepeat(chordSectionLocation, r);
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
            }
          }
        }
      }
    }
  });

  test('test findChordSectionLocation()', () {
    SongBase a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D v: E B C D',
        'i: v: bob, bob, bob berand');

    logger.d(a.logGrid());
    logger.d('moment count: ${a
        .getSongMoments()
        .length}');
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
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D',
        'v: bob, bob, bob berand');
    chordSections.addAll(a.getChordSections());
    expect(1, chordSections.length);
    chordSection = chordSections.first;
    measures = chordSection.phrases[0].measures;
    expect(4, measures.length);

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'v: A B C D (yo)',
        'v: bob, bob, bob berand');
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
    Grid<ChordSectionLocation> grid = a.getChordSectionLocationGrid();

    expect(grid.getRowCount(), 5);
    for (int r = 2; r < grid.getRowCount(); r++) {
      List<ChordSectionLocation?>? row = grid.getRow(r);
      if (row == null) throw 'row == null';

      for (int c = 1; c < row.length; c++) {
        measure = null;

        MeasureNode? node = a.findMeasureNodeByLocation(row[c]);
        switch (r) {
          case 0:
            switch (c) {
              case 0:
                expect(node is ChordSection, isTrue);
                expect((node as ChordSection).sectionVersion.section, Section.get(SectionEnum.verse));
                break;
              case 1:
                measure = node as Measure;
                expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.get(ScaleNoteEnum.A));
                break;
              case 4:
                measure = node as Measure;
                expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.get(ScaleNoteEnum.D));
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
                expect(measure.chords[0].scaleChord.scaleNote, ScaleNote.get(ScaleNoteEnum.D));
                break;
              case 3:
                measure = node as Measure;
                expect(ScaleNote.get(ScaleNoteEnum.G), measure.chords[0].scaleChord.scaleNote);
                break;
              case 4:
                measure = node as Measure;
                expect(ScaleNote.get(ScaleNoteEnum.E), measure.chords[0].scaleChord.scaleNote);
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
                expect(ScaleNote.get(ScaleNoteEnum.A), measure.chords[0].scaleChord.scaleNote);
                break;
              case 4:
                measure = node as Measure;
                expect(ScaleNote.get(ScaleNoteEnum.D), measure.chords[0].scaleChord.scaleNote);
                break;
            }
            break;
        }

        if (measure != null) {
          expect(measure, a.findMeasureNodeByLocation(a.getChordSectionLocationGrid().get(r, c)));
          logger.d('measure(' + c.toString() + ',' + r.toString() + '): ' + measure.toMarkup());
          ChordSectionLocation? loc = a.findChordSectionLocation(measure);
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
    SongBase a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'i: A B C D V: D E F F# ',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

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
    logger.d(a.toMarkup());
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
    SongBase a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# ',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro\n');
    String lyrics = 'i:\n'
        'v: bob, bob, bob berand\n'
        'c: sing chorus here \n'
        'o: last line of outro';
    //logger.d(    a.getRawLyrics());
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'i: A B C D V: D E F F# ',
        'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');
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
    Grid<ChordSectionLocation> grid = a.getChordSectionLocationGrid();
    expect(10, grid.getRowCount()); //  comments on their own line add a bunch
    List<ChordSectionLocation?>? row = grid.getRow(0);
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
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'v: D D C G x4 c: C C C C x 2',
        '''
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
            'D..Dm7 Dm7 C..B♭maj7 B♭maj7\n'
            ' x12',
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
    Grid<ChordSectionLocation> grid;
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
    logger.i('testing: ' + ChordSectionLocation.parseString('I:0:0').toString());
    logger.i('testing2: ' + a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')).toString());
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

    logger.d(a.toMarkup());
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('V:')), GridCoordinate(0, 0));
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('V:0:0')), GridCoordinate(0, 1));

    expect(a.getGridCoordinate(ChordSectionLocation.parseString('I:')), GridCoordinate(0, 0));
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('C:')), GridCoordinate(2, 0));

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: V: c: G D G D ',
        'i:\nv: bob, bob, bob berand\nv: nope\nc: sing chorus here');

    logger.d(a.toMarkup());

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

    logger.d(a.toMarkup());

    grid = a.getChordSectionLocationGrid();
    for (int r = 0; r < grid.getRowCount(); r++) {
      List<ChordSectionLocation?>? row = grid.getRow(r);
      if (row == null) throw 'row == null';
      for (int c = 0; c < row.length; c++) {
        GridCoordinate coordinate = GridCoordinate(r, c);
        expect(coordinate, isNotNull);
        expect(coordinate.toString(), isNotNull);
        expect(a.getChordSectionLocationGrid(), isNotNull);
        expect(a.getChordSectionLocationGrid().getRow(r), isNotNull);
        ChordSectionLocation? chordSectionLocation = a.getChordSectionLocationGrid().getRow(r)![c];
        if (chordSectionLocation == null) continue;
        expect(chordSectionLocation.toString(), isNotNull);
        logger.d(coordinate.toString() + '  ' + chordSectionLocation.toString());
        ChordSectionLocation? loc = a.getChordSectionLocation(coordinate);
        logger.d(loc.toString());
        expect(a.getChordSectionLocationGrid().getRow(r)![c], a.getChordSectionLocation(coordinate));
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
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D, E F]  x2  ',
        'i:\n');
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
        beats += songMoment
            .getMeasure()
            .beatCount;
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
    logger.d(a.toMarkup());
    int size = a.getSongMomentsSize();
    for (int momentNumber = 0; momentNumber < size; momentNumber++) {
      SongMoment? songMoment = a.getSongMoment(momentNumber);
      if (songMoment == null) throw 'songMoment == null';
      GridCoordinate? coordinate = a.getMomentGridCoordinate(songMoment);
      SongMoment? songMomentAtRow = a.getFirstSongMomentAtRow(coordinate!.row);
      GridCoordinate? coordinateAtRow = a.getMomentGridCoordinate(songMomentAtRow!);
      logger.d('songMoment: ' +
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
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: A B C D E F, G G# Ab Bb x2 \nc: D E F',
        'i:\nc: sing chorus');
    logger.d(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.d(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);

    //  don't fix what's not broken
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D, E F G G#, Ab Bb] x2 \nc: D E F',
        'i:\nc: sing chorus');
    logger.d(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);
    logger.d(a.toMarkup());
    expect(a.toMarkup().trim(), 'I: [A B C D, E F G G#, Ab Bb ] x2  C: D E F');

    //  take the comma off a repeat
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D, E F G G#, ] x2 \nc: D E F',
        'i:\nc: sing chorus');
    logger.d(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isFalse);
    logger.d(a.toMarkup());
    expect(a.toMarkup().trim(), 'I: [A B C D, E F G G# ] x2  C: D E F');

    //  not the first section
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D ] x2 \nc: D E F A B C D, E F G G#',
        'i:\nc: sing chorus');
    logger.d(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.d(a.toMarkup());
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());
    expect(a.setMeasuresPerRow(4), isFalse);
    expect('I: [A B C D ] x2  C: D E F A, B C D E, F G G#', a.toMarkup().trim());

    //  take a last comma off
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D ] x2 \nc: D E F A B C, D E, F G G#,',
        'i:\nc: sing chorus');
    logger.d(a.toMarkup());
    expect(a.setMeasuresPerRow(4), isTrue);
    logger.d(a.toMarkup());
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
          'A',
          'bob',
          'bsteele.com',
          music_key.Key.getDefault(),
          bpm,
          beatsPerBar,
          4,
          'I: A B C D E F  x2  ',
          'i:\n');

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

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: A B C D V: A B C D',
        'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: V: A B C D  ');
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: A B C D V: [A B C D] x2',
        'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: A B C D  V: [A B C D ] x2  ');
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D] x2 V: A B C D ',
        'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: [A B C D ] x2  V: A B C D  ');
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D] x2 V: [A B C D] x2',
        'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: V: [A B C D ] x2  ');
    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [A B C D] x2 V: [A B C D] x4',
        'i:\nv:\n');
    logger.i(a.toMarkup());
    expect(a.toMarkup(), 'I: [A B C D ] x2  V: [A B C D ] x4  ');
  });

  test('test chord Grid repeats', () {
    int beatsPerBar = 4;
    SongBase a;
    Grid<ChordSectionLocation> grid;
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
//    logger.i('testing: ' + ChordSectionLocation.parseString('I:0:0').toString());
//    logger.i('testing2: ' + a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')).toString());
    expect(a.getGridCoordinate(ChordSectionLocation.parseString('I:0:0')), GridCoordinate(0, 1));

    grid = a.getChordSectionLocationGrid();

    List<ChordSectionLocation?>? row = grid.getRow(0);
    if (row == null) throw 'row == null';
    logger.i(row.length.toString());
    logger.i(grid.toMultiLineString());
    logger.i(chordSectionToMultiLineString(a));
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

    a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        beatsPerBar,
        4,
        'I: [Am Am/G Am/F♯ FE ] x4  v: [Am Am/G Am/F♯ FE ] x2  C: F F C C, G G F F  O: Dm C B B♭ A  ',
        '''
c: cMake me an angel that flies from Montgomery
	cMake me a poster of an old rodeo
	cJust give me one thing that I can hold on to
	cTo believe in this living is just a hard way to go
o: end here''');

    //induce grid generation
    //Grid<SongMoment> grid =
    a.songMomentGrid;

    //     logger.i('a.lyricSections: ${a.lyricSections}');
//     // for (LyricSection lyricSection in a.lyricSections) {
//     //   logger.i('${lyricSection}');
//     //   for (String line in lyricSection.getLyricsLines()) {
//     //     logger.i('  "$line"');
//     //   }
//     // }

    for (SongMoment songMoment in a.songMoments) {
      logger.i('  ${songMoment}');
      logger.i('      ${songMoment.lyrics}');
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
    //       logger.i('\nmeasures: $measures, row: $rows, word: $words:');
    //       logger.i(lines.toString());
    //
    //       for (int m = 0; m < measures; m++) {
    //         logger.i('     $m: ${splitWordsToMeasure(measures, m, lines)}');
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
    //       logger.i(
    //           '\nmeasureRows: $measureRows, lyricRows: $lyricRows'
    //               ', words: $words: ${lines.toString()}');
    //
    //       for (int mr = 0; mr < measureRows; mr++) {
    //         String rowString = shareLinesToRow(measureRows, mr, lines);
    //         logger.i('     measureRow $mr: $rowString');
    //
    //         for (int measures = 1; measures <= 6; measures++) {
    //           logger.i('       measures $measures:');
    //           for (int m = 0; m < measures; m++) {
    //             String s = splitWordsToMeasure(measures, m, rowString);
    //             logger.i('          mr $mr: m:$m $s');
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
    expect(a.chordRowMaxLength(), 6);

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
    a = SongBase.createSongBase(
        '12 Bar Blues',
        'All',
        'Unknown',
        music_key.Key.get(music_key.KeyEnum.C),
        106,
        beatsPerBar,
        4,
        'V: C F C C,F F C C,  G F C G',
        'v:');
    expect(a.lyricSections.length, 1);
    expect(a.lyricSections.first.lyricsLines.length, 0);
  });

  test('test last modified time', () {
    int now = DateTime
        .now()
        .millisecondsSinceEpoch;
    logger.i('now: $now');

    int beatsPerBar = 4;
    SongBase a;

    //  assure that the song can end on an empty section
    a = SongBase.createSongBase(
        '12 Bar Blues',
        'All',
        'Unknown',
        music_key.Key.get(music_key.KeyEnum.C),
        106,
        beatsPerBar,
        4,
        'V: C F C C,F F C C,  G F C G',
        'v:');
    logger.i('a.lastModifiedTime: ${a.lastModifiedTime}');
    expect(now <= a.lastModifiedTime, isTrue);
    now = DateTime
        .now()
        .millisecondsSinceEpoch;
    logger.i('now: $now');
    expect(now >= a.lastModifiedTime, isTrue);
  });

  test('test empty lyrics rows', () {
    int beatsPerBar = 4;
    Song a;
    String s;

    a = Song.createSong(
        'ive go the blanks',
        'bob',
        'bob',
        music_key.Key.get(music_key.KeyEnum.C),
        106,
        beatsPerBar,
        4,
        'pearlbob',
        'i: D C G G V: C F C C,F F C C,  G F C G',
        'i: v:');

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
    //   logger.i('${lyricSection.sectionVersion}  lines: ${lyricSection.lyricsLines.length}');
    //   for (var line in lyricSection.lyricsLines) {
    //     logger.i('    "$line"');
    //   }
    // }
    // logger.i(a.toJson());
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

    a = Song.createSong(
        'ive go the blanks',
        'bob',
        'bob',
        music_key.Key.get(music_key.KeyEnum.C),
        106,
        beatsPerBar,
        4,
        'pearlbob',
        'i: D C G G V: C F C C,F F C C,  G F C G',
        someRawLyrics);

    b = Song.createSong(
        'ive go the blanks',
        'bob',
        'bob',
        music_key.Key.get(music_key.KeyEnum.C),
        106,
        beatsPerBar,
        4,
        'pearlbob',
        'i: D C G G V: C F C C,F F C C,  G F C G',
        a.rawLyrics);

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

    a = Song.createSong(
        'ive go the blanks',
        'bob',
        'bob',
        music_key.Key.get(music_key.KeyEnum.C),
        106,
        beatsPerBar,
        4,
        'pearlbob',
        'i: D C G G V: C F C C,F F C C,  G F C G',
        'i: v:');

    b = Song.createSong(
        'ive go the blanks',
        'bob',
        'bob',
        music_key.Key.get(music_key.KeyEnum.C),
        106,
        beatsPerBar,
        4,
        'pearlbob',
        'i: D C G G V: C F C C,F F C C,  G F C G',
        a.rawLyrics);
    // expect(a.lyricsAsString(), b.lyricsAsString());
    // expect(a.songBaseSameContent(b), isTrue);
    //
    // testRawLyricsLoop('v:');
    // testRawLyricsLoop('v:\n');
    // testRawLyricsLoop('v:\n\n');
    // testRawLyricsLoop('v:\n\n\n');
    // testRawLyricsLoop('v:\n\n\n\n');
    //
    // testRawLyricsLoop('v:\nA\n');
    // testRawLyricsLoop('v:v:\nA\n\n');
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
    expect(a.title, 'bob song, the ');
    expect(a.artist, 'unknown');
    expect(a.coverArtist, isEmpty);

    a = SongBase.from(title: 'bob song', artist: 'bob');
    expect(a.title, 'bob song');
    expect(a.artist, 'bob');
    a = SongBase.from(title: 'bob song', artist: 'the bob');
    expect(a.title, 'bob song');
    expect(a.artist, 'bob, the ');
    expect(a.coverArtist, isEmpty);

    {
      var coverArtist = 'not really bob';
      a = SongBase.from(title: 'bob song', artist: 'the bob', coverArtist: coverArtist);
      expect(a.title, 'bob song');
      expect(a.artist, 'bob, the ');
      expect(a.coverArtist, isNotEmpty);
      expect(a.coverArtist, coverArtist);

      coverArtist = 'the not real bob';
      a = SongBase.from(title: 'bob song', artist: 'the bob', coverArtist: coverArtist);
      expect(a.title, 'bob song');
      expect(a.artist, 'bob, the ');
      expect(a.coverArtist, isNotEmpty);
      expect(a.coverArtist, 'not real bob, the ');
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
}
