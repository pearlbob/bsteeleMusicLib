import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/grid.dart';
import 'package:bsteele_music_lib/grid_coordinate.dart';
import 'package:bsteele_music_lib/songs/chord_section.dart';
import 'package:bsteele_music_lib/songs/chord_section_location.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/measure.dart';
import 'package:bsteele_music_lib/songs/measure_node.dart';
import 'package:bsteele_music_lib/songs/measure_repeat.dart';
import 'package:bsteele_music_lib/songs/measure_repeat_extension.dart';
import 'package:bsteele_music_lib/songs/measure_repeat_marker.dart';
import 'package:bsteele_music_lib/songs/phrase.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:bsteele_music_lib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.info;

  test('parseMarkup', () {
    MeasureRepeat measureRepeat;

    try {
      //  bad input means this is not a repeat
      measureRepeat = MeasureRepeat.parseString('[A B C D [ x2 E F', 0, 4, null);
      fail('bad input was parsed');
    } catch (e) {
      //  expected
    }

    String s;

    s = 'A B C D |\n E F G Gb x2 ';
    MarkedString markedString = MarkedString(s);
    MeasureRepeat refRepeat = MeasureRepeat.parse(markedString, 0, 4, null);
    expect(refRepeat, isNotNull);
    expect(refRepeat.measureNodeType, MeasureNodeType.repeat);
    expect(refRepeat.toMarkup(), '[A B C D, E F G Gb ] x2 ');
    expect(0, markedString.available());

    s = '[A B C D ] x2 ';
    markedString = MarkedString(s);
    refRepeat = MeasureRepeat.parse(markedString, 0, 4, null);
    expect(refRepeat, isNotNull);
    expect(s, refRepeat.toMarkup());
    expect(0, markedString.available());

    s = '[A B C D ] x2 E F';
    measureRepeat = MeasureRepeat.parseString(s, 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect(s, startsWith(measureRepeat.toMarkup()));
    expect(refRepeat, measureRepeat);

    s = '   [   A B   C D ]\nx2 Eb Fmaj7';
    measureRepeat = MeasureRepeat.parseString(s, 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect(refRepeat, measureRepeat);

    s = 'A B C D x2 Eb Fmaj7';
    measureRepeat = MeasureRepeat.parseString(s, 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect(refRepeat, measureRepeat);

    //  test without brackets
    measureRepeat = MeasureRepeat.parseString('   A B C D  x2 E F', 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect(refRepeat, measureRepeat);

    //  test with comment
    refRepeat = MeasureRepeat.parseString('   A B(yo)C D  x2 E F', 0, 4, null);
    expect(refRepeat, isNotNull);
    expect('[A B (yo) C D ] x2 ', refRepeat.toMarkup());

    measureRepeat = MeasureRepeat.parseString('   A B (yo)|\nC D  x2 E F', 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect('[A B (yo) C D ] x2 ', measureRepeat.toMarkup());
    expect(refRepeat, measureRepeat);

    measureRepeat = MeasureRepeat.parseString(' [   A B (yo)|\nC D]x2 E F', 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect('[A B (yo) C D ] x2 ', measureRepeat.toMarkup());
    expect(refRepeat, measureRepeat);

    measureRepeat = MeasureRepeat.parseString(' [   A B (yo)   C D]x2 E F', 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect('[A B (yo) C D ] x2 ', measureRepeat.toMarkup());
    expect(refRepeat, measureRepeat);
  });

  test('testMultilineInput', () {
    MeasureRepeat measureRepeat;

    ChordSection chordSection;

    chordSection = ChordSection.parseString('v3: A B C D | \n E F G G# | x2   \n', 4);

    expect(chordSection, isNotNull);
    Phrase? phrase = chordSection.getPhrase(0);
    expect(phrase is MeasureRepeat, isTrue);
    measureRepeat = phrase as MeasureRepeat;
    logger.d(measureRepeat.toMarkup());
    ChordSectionLocation loc = ChordSectionLocation(chordSection.sectionVersion, phraseIndex: 0);
    logger.d(loc.toString());
    expect('V3:0', loc.toString());

    chordSection = ChordSection.parseString('v3:A B C D|\nE F G G#|x2\n', 4);

    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(0);
    expect(phrase is MeasureRepeat, isTrue);
    measureRepeat = phrase as MeasureRepeat;
    logger.d(measureRepeat.toMarkup());
    loc = ChordSectionLocation(chordSection.sectionVersion, phraseIndex: 0);
    logger.d(loc.toString());
    expect('V3:0', loc.toString());
  });

  test('testGridMapping', () {
    int beatsPerBar = 4;
    SongBase a;
    Measure? m;
    ChordSection cs;
    ChordSection? chordSection;
    Phrase? phrase;
    MeasureRepeat measureRepeat;
    MeasureNode? measureNode;
    ChordSectionLocation? chordSectionLocation;

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'V: [G Bm F♯m G, GBm ] x3',
      rawLyrics: 'v: bob, bob, bob berand\n',
    );
    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(0);
    expect(phrase?.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(5, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('G', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 2));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('Bm', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 3));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('F♯m', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('G', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('GBm', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 2));
    expect(measureNode, isNull);
    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 3));
    expect(measureNode, isNull);
    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 4));
    expect(measureNode, isNull);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(1, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    logger.i(a.logGrid());
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.repeatLowerRight);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(1, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);

    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'v: [A B , Ab Bb Eb, D C G G# ] x3 T: A',
      rawLyrics: 'i:\nv: bob, bob, bob berand\nt: last line \n',
    );
    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(0);
    expect(phrase!.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(9, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('A', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 2));
    expect(measureNode, isNotNull);
    m = Measure.parseString('B', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 3));
    expect(measureNode, isNull);
    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    expect(measureNode, isNull);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 3));
    expect(measureNode, isNotNull);
    m = Measure.parseString('Eb', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 4));
    expect(measureNode, isNull);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 4));
    expect(measureNode, isNull);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('G#', a.beatsPerBar), measureNode);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight, chordSectionLocation!.marker);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.none);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'v: E F F# G [A B C D Ab Bb Eb Db, D C G Gb D C G# A#] x3 T: A',
      //          1 2 3  4  1 2 3 4 5  6  7  8  1 2 3 4  5 6 7  8
      //                                       9 101112 131415 16
      rawLyrics: 'i:\nv: bob, bob, bob berand\nt: last line \n',
    );

    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(1);
    expect(phrase!.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(16, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 1));
    expect(measureNode, isNotNull);
    expect(measureNode, Measure.parseString('A', a.beatsPerBar));

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 1));
    expect(measureNode, isNotNull);
    expect(measureNode, Measure.parseString('D', a.beatsPerBar));

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    expect(measureNode, Measure.parseString('Gb', a.beatsPerBar));

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 7));
    expect(measureNode, isNotNull);
    expect(measureNode, Measure.parseString('G#', a.beatsPerBar));

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 8));
    expect(measureNode, isNotNull);
    expect(measureNode, Measure.parseString('A#', a.beatsPerBar));

    logger.i(a.logGrid());
    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 8 + 1));
    expect(chordSectionLocation, isNotNull);
    logger.i(chordSectionLocation.toString());
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.repeatLowerRight);
    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 8 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.none);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'v: A B C D x3 T: A',
      rawLyrics: 'i:\nv: bob, bob, bob berand\nt: last line \n',
    );
    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(0);
    expect(phrase!.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(4, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('A', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('D', a.beatsPerBar), measureNode);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(0, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.repeatOnOneLineRight);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'v: [A B C D] x3 T: A',
      rawLyrics: 'i:\nv: bob, bob, bob berand\nt: last line \n',
    );
    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(0);
    expect(phrase!.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(4, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('A', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('D', a.beatsPerBar), measureNode);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(0, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.repeatOnOneLineRight);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'v: [A B C D, Ab Bb Eb Db, D C G G# ] x3 T: A',
      rawLyrics: 'i:\nv: bob, bob, bob berand\nt: last line \n',
    );
    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(0);
    expect(phrase!.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(12, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('A', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('D', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('Db', a.beatsPerBar);
    m.endOfRow = true;

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('G#', a.beatsPerBar), measureNode);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight, chordSectionLocation!.marker);
    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.none);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'v: [A B C D, Ab Bb Eb Db, D C G# ] x3 T: A',
      rawLyrics: 'i:\nv: bob, bob, bob berand\nt: last line \n',
    );
    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(0);
    expect(phrase!.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(11, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('A', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('D', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('Db', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 3));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('G#', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 4));
    expect(measureNode, isNull);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight, chordSectionLocation!.marker);
    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.none);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'v: [A B C D, Ab Bb Eb Db, D C G G# ] x3 E F F# G T: A',
      rawLyrics: 'i:\nv: bob, bob, bob berand\nt: last line \n',
    );
    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(0);
    expect(phrase!.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(12, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('A', a.beatsPerBar), measureNode);
    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('Db', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('D', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('Db', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('G#', a.beatsPerBar), measureNode);
    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight, chordSectionLocation!.marker);
    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(2, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.none);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);

    a = SongBase(
      title: 'A',
      artist: 'bob',
      copyright: 'bsteele.com',
      key: Key.getDefault(),
      beatsPerMinute: 100,
      beatsPerBar: beatsPerBar,
      unitsPerMeasure: 4,
      chords: 'v: E F F# Gb [A B C D, Ab Bb Eb Db, D C G G# ] x3 T: A',
      rawLyrics: 'i:\nv: bob, bob, bob berand\nt: last line \n',
    );
    a.debugSongMoments();

    cs = ChordSection.parseString('v:', a.beatsPerBar);
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection!.getPhrase(1);
    expect(phrase!.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(12, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('A', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('Gb', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(1, 3));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('C', a.beatsPerBar), measureNode);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString('Db', a.beatsPerBar);
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(const GridCoordinate(3, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString('G#', a.beatsPerBar), measureNode);

    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(3, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.repeatLowerRight);
    chordSectionLocation = a.getChordSectionLocation(const GridCoordinate(3, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(chordSectionLocation!.marker, ChordSectionLocationMarker.none);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode!.isRepeat(), isTrue);
  });

  test('test repeat chord rows', () {
    int beatsPerBar = 4;
    MeasureRepeat m;

    m = MeasureRepeat.parseString('[A B C D, E F G, D C G G ] x2', 0, beatsPerBar, null);
    expect(m.chordRowMaxLength(), 6);
    expect(m.rowAt(0).length, 5);
    expect(m.rowAt(1).length, 4);
    expect(m.rowAt(2).length, 6);
    expect(m.rowAt(3).length, 5);
    expect(m.rowAt(4).length, 4);
    expect(m.rowAt(5).length, 6);
    expect(m.rowAt(6).length, 0);

    m = MeasureRepeat.parseString('[A B C D, E F G ] x2', 0, beatsPerBar, null);
    expect(m.chordRowMaxLength(), 6);
    expect(m.rowAt(0).length, 5);
    expect(m.rowAt(1).length, 5);
    expect(m.rowAt(2).length, 5);
    expect(m.rowAt(3).length, 5);
    expect(m.rowAt(4).length, 0);

    m = MeasureRepeat.parseString('[A B C D ] x2', 0, beatsPerBar, null);
    expect(m.chordRowMaxLength(), 5);
    expect(m.rowAt(0).length, 5);
    expect(m.rowAt(1).length, 5);
    expect(m.rowAt(2).length, 0);
  });

  test('test repeat grid', () {
    int phraseIndex = 0;
    int beatsPerBar = 4;
    String s;
    MeasureRepeat repeat;
    Grid<MeasureNode> grid;
    int r;

    {
      s = 'A B C D x2';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 2);
      expect(grid.rowLength(0), 5);
      expect(grid.get(0, grid.rowLength(0) - 2), Measure.parseString('D', beatsPerBar));
      expect(grid.get(0, grid.rowLength(0) - 1), MeasureRepeatMarker(2, 4, repetition: 1));
    }
    {
      s = 'A B C D E F G A x3';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 3);
      expect(grid.rowLength(0), 9);
      expect(grid.get(0, grid.rowLength(0) - 2), Measure.parseString('A', beatsPerBar));
      expect(grid.get(0, grid.rowLength(0) - 1), MeasureRepeatMarker(3, 8, repetition: 1));
      expect(grid.get(1, grid.rowLength(0) - 1), MeasureRepeatMarker(3, 8, repetition: 2));
      expect(grid.get(2, grid.rowLength(0) - 1), MeasureRepeatMarker(3, 8, repetition: 3));
    }
    {
      s = '[A B C D, E F G A#] x4';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 8);
      r = 0;
      expect(grid.rowLength(r), 4 + 1 + 1);
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.upperRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), isNull);
      r = 1;
      expect(grid.rowLength(r), 4 + 1 + 1);
      expect(grid.get(r, grid.rowLength(r) - 3), Measure.parseString('A#', beatsPerBar));
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), MeasureRepeatMarker(4, 8, repetition: 1));
    }
    {
      s = '[A B C D, E F G A#, Bb CE C#] x2';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 6);
      r = 0;
      expect(grid.rowLength(r), 4 + 1 + 1);
      expect(grid.get(r, grid.rowLength(0) - 3), Measure.parseString('D,', beatsPerBar));
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.upperRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), isNull);
      r = 1;
      expect(grid.rowLength(r), 4 + 1 + 1);
      expect(grid.get(r, grid.rowLength(1) - 3), Measure.parseString('A#,', beatsPerBar));
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), isNull);
      r = 2;
      expect(grid.rowLength(r), 4 + 1 + 1);
      expect(grid.get(r, grid.rowLength(r) - 4), Measure.parseString('C#', beatsPerBar));
      expect(grid.get(r, grid.rowLength(r) - 3), isNull);
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), MeasureRepeatMarker(2, 11, repetition: r - 1));
    }
    {
      s = '[A, E F, Bb CE C#, A# B C D] x2';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 8);
      expect(grid.rowLength(0), 4 + 1 + 1);
      expect(grid.rowLength(1), 4 + 1 + 1);
      expect(grid.rowLength(2), 4 + 1 + 1);
      expect(grid.get(0, 0), Measure.parseString('A,', beatsPerBar));
      expect(grid.get(0, 1), isNull);
      expect(grid.get(0, 2), isNull);
      expect(grid.get(0, 3), isNull);
      expect(grid.get(0, 4), MeasureRepeatExtension.upperRightMeasureRepeatExtension);
      expect(grid.get(0, 5), isNull);

      expect(grid.get(1, 1), Measure.parseString('F,', beatsPerBar));
      expect(grid.get(1, 2), isNull);
      expect(grid.get(1, 3), isNull);
      expect(grid.get(1, 4), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(1, 5), isNull);

      expect(grid.get(2, 2), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(2, 3), isNull);
      expect(grid.get(2, 4), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(2, 5), isNull);

      expect(grid.get(3, 3), Measure.parseString('D', beatsPerBar));
      expect(grid.get(3, 4), MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      expect(grid.get(3, 5), MeasureRepeatMarker(2, 10, repetition: 1));
    }
    {
      s = '[A# B C D, Bb CE C#, E F, A,  ] x3';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 12);
      expect(grid.rowLength(0), 4 + 1 + 1);
      expect(grid.rowLength(1), 4 + 1 + 1);
      expect(grid.rowLength(2), 4 + 1 + 1);

      expect(grid.get(0, 3), Measure.parseString('D,', beatsPerBar));
      expect(grid.get(0, 4), MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      expect(grid.get(0, 5), isNull);

      expect(grid.get(1, 2), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(1, 3), isNull);
      expect(grid.get(1, 4), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(1, 5), isNull);

      expect(grid.get(2, 1), Measure.parseString('F,', beatsPerBar));
      expect(grid.get(2, 2), isNull);
      expect(grid.get(2, 3), isNull);
      expect(grid.get(2, 4), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(2, 5), isNull);

      expect(grid.get(3, 0), Measure.parseString('A', beatsPerBar));
      expect(grid.get(3, 1), isNull);
      expect(grid.get(3, 2), isNull);
      expect(grid.get(3, 3), isNull);
      expect(grid.get(3, 4), MeasureRepeatExtension.upperRightMeasureRepeatExtension);
      expect(grid.get(3, 5), MeasureRepeatMarker(3, 10, repetition: 1));
    }
  });
  test('test repeat grid expanded', () {
    int phraseIndex = 0;
    int beatsPerBar = 4;
    String s;
    MeasureRepeat repeat;
    Grid<MeasureNode> grid;
    int r;

    {
      s = 'A B C D x2';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 2);
      expect(grid.rowLength(0), 5);
      expect(grid.get(0, grid.rowLength(0) - 2), Measure.parseString('D', beatsPerBar));
      expect(grid.get(0, grid.rowLength(0) - 1), MeasureRepeatMarker(2, 4, repetition: 1));
    }
    {
      s = 'A B C D E F G A x3';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 3);
      expect(grid.rowLength(0), 9);
      expect(grid.get(0, grid.rowLength(0) - 2), Measure.parseString('A', beatsPerBar));
      expect(grid.get(0, grid.rowLength(0) - 1), MeasureRepeatMarker(3, 8, repetition: 1));
    }
    {
      s = '[A B C D, E F G A#] x4';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 8);
      for (var r = 0; r < grid.getRowCount(); r++) {
        expect(grid.rowLength(r), 4 + 1 + 1);
      }
      r = 0;
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.upperRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), isNull);
      r = 1;
      expect(grid.get(r, grid.rowLength(r) - 3), Measure.parseString('A#', beatsPerBar));
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), MeasureRepeatMarker(4, 8, repetition: 1));
    }
    {
      s = '[A B C D, E F G A#, Bb CE C#] x2';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 6);
      for (var r = 0; r < grid.getRowCount(); r++) {
        expect(grid.rowLength(r), 4 + 1 + 1);
      }
      r = 0;
      expect(grid.get(r, grid.rowLength(0) - 3), Measure.parseString('D,', beatsPerBar));
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.upperRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), isNull);
      r = 1;
      expect(grid.get(r, grid.rowLength(1) - 3), Measure.parseString('A#,', beatsPerBar));
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), isNull);
      r = 2;
      expect(grid.get(r, grid.rowLength(r) - 4), Measure.parseString('C#', beatsPerBar));
      expect(grid.get(r, grid.rowLength(r) - 3), isNull);
      expect(grid.get(r, grid.rowLength(r) - 2), MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      expect(grid.get(r, grid.rowLength(r) - 1), MeasureRepeatMarker(2, 11, repetition: 1));
    }
    {
      s = '[A, E F, Bb CE C#, A# B C D] x2';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 8);
      for (var r = 0; r < grid.getRowCount(); r++) {
        expect(grid.rowLength(r), 4 + 1 + 1);
      }
      expect(grid.get(0, 0), Measure.parseString('A,', beatsPerBar));
      expect(grid.get(0, 1), isNull);
      expect(grid.get(0, 2), isNull);
      expect(grid.get(0, 3), isNull);
      expect(grid.get(0, 4), MeasureRepeatExtension.upperRightMeasureRepeatExtension);
      expect(grid.get(0, 5), isNull);

      expect(grid.get(1, 1), Measure.parseString('F,', beatsPerBar));
      expect(grid.get(1, 2), isNull);
      expect(grid.get(1, 3), isNull);
      expect(grid.get(1, 4), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(1, 5), isNull);

      expect(grid.get(2, 2), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(2, 3), isNull);
      expect(grid.get(2, 4), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(2, 5), isNull);

      expect(grid.get(3, 3), Measure.parseString('D', beatsPerBar));
      expect(grid.get(3, 4), MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      expect(grid.get(3, 5), MeasureRepeatMarker(2, 10, repetition: 1));
    }
    {
      s = '[A# B C D, Bb CE C#, E F, A,  ] x3';
      repeat = MeasureRepeat.parseString(s, phraseIndex, beatsPerBar, null);
      grid = repeat.toGrid();
      expect(grid.getRowCount(), 12);
      for (var r = 0; r < grid.getRowCount(); r++) {
        expect(grid.rowLength(r), 4 + 1 + 1);
      }

      expect(grid.get(0, 3), Measure.parseString('D,', beatsPerBar));
      expect(grid.get(0, 4), MeasureRepeatExtension.lowerRightMeasureRepeatExtension);
      expect(grid.get(0, 5), isNull);

      expect(grid.get(1, 2), Measure.parseString('C#,', beatsPerBar));
      expect(grid.get(1, 3), isNull);
      expect(grid.get(1, 4), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(1, 5), isNull);

      expect(grid.get(2, 1), Measure.parseString('F,', beatsPerBar));
      expect(grid.get(2, 2), isNull);
      expect(grid.get(2, 3), isNull);
      expect(grid.get(2, 4), MeasureRepeatExtension.middleRightMeasureRepeatExtension);
      expect(grid.get(2, 5), isNull);

      expect(grid.get(3, 0), Measure.parseString('A', beatsPerBar));
      expect(grid.get(3, 1), isNull);
      expect(grid.get(3, 2), isNull);
      expect(grid.get(3, 3), isNull);
      expect(grid.get(3, 4), MeasureRepeatExtension.upperRightMeasureRepeatExtension);
      expect(grid.get(3, 5), MeasureRepeatMarker(3, 10, repetition: 1));
    }
  });

  test('test repeat firstMeasureInRow()', () {
    Logger.level = Level.info;
    int phraseIndex = 0;
    int beatsPerBar = 4;

    var repeat = MeasureRepeat.parseString('[Dm C B Bb, A, B C D] x3', phraseIndex, beatsPerBar, null);
    logger.i('0: ${repeat.firstMeasureInRow(0)}');

    expect(repeat.firstMeasureInRow(0).toMarkup(), 'Dm');
    expect(repeat.firstMeasureInRow(1).toMarkup(), 'A,');
    expect(repeat.firstMeasureInRow(2).toMarkup(), 'B');
    expect(repeat.firstMeasureInRow(3).toMarkup(), 'Dm');
    expect(repeat.firstMeasureInRow(4).toMarkup(), 'A,');
    expect(repeat.firstMeasureInRow(5).toMarkup(), 'B');
    expect(repeat.firstMeasureInRow(6).toMarkup(), 'Dm');
    expect(repeat.firstMeasureInRow(7).toMarkup(), 'A,');
    expect(repeat.firstMeasureInRow(8).toMarkup(), 'B');
    expect(repeat.firstMeasureInRow(9).toMarkup(), 'Dm');
    expect(repeat.firstMeasureInRow(10).toMarkup(), 'Dm');
    expect(repeat.firstMeasureInRow(11).toMarkup(), 'Dm');
    expect(repeat.firstMeasureInRow(12).toMarkup(), 'Dm');
    expect(repeat.firstMeasureInRow(13).toMarkup(), 'Dm');
  });
}
