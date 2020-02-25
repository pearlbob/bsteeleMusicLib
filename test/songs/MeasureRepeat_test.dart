import 'package:bsteeleMusicLib/GridCoordinate.dart';
import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/ChordSection.dart';
import 'package:bsteeleMusicLib/songs/ChordSectionLocation.dart';
import 'package:bsteeleMusicLib/songs/Measure.dart';
import 'package:bsteeleMusicLib/songs/MeasureNode.dart';
import 'package:bsteeleMusicLib/songs/MeasureRepeat.dart';
import 'package:bsteeleMusicLib/songs/Phrase.dart';
import 'package:bsteeleMusicLib/songs/SongBase.dart';
import 'package:bsteeleMusicLib/songs/Key.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.warning;

  test("parseMarkup", () {
    MeasureRepeat measureRepeat;

    try {
      //  bad input means this is not a repeat
      measureRepeat =
          MeasureRepeat.parseString("[A B C D [ x2 E F", 0, 4, null);
      fail("bad input was parsed");
    } catch (e) {
      //  expected
    }

    String s;

    s = "A B C D |\n E F G Gb x2 ";
    MarkedString markedString = new MarkedString(s);
    MeasureRepeat refRepeat = MeasureRepeat.parse(markedString, 0, 4, null);
    expect(refRepeat, isNotNull);
    expect(refRepeat.toMarkup(), "[A B C D, E F G Gb ] x2 ");
    expect(0, markedString.available());

    s = "[A B C D ] x2 ";
    markedString = new MarkedString(s);
    refRepeat = MeasureRepeat.parse(markedString, 0, 4, null);
    expect(refRepeat, isNotNull);
    expect(s, refRepeat.toMarkup());
    expect(0, markedString.available());

    s = "[A B C D ] x2 E F";
    measureRepeat = MeasureRepeat.parseString(s, 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect(s, startsWith(measureRepeat.toMarkup()));
    expect(refRepeat, measureRepeat);

    s = "   [   A B   C D ]\nx2 Eb Fmaj7";
    measureRepeat = MeasureRepeat.parseString(s, 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect(refRepeat, measureRepeat);

    s = "A B C D x2 Eb Fmaj7";
    measureRepeat = MeasureRepeat.parseString(s, 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect(refRepeat, measureRepeat);

    //  test without brackets
    measureRepeat = MeasureRepeat.parseString("   A B C D  x2 E F", 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect(refRepeat, measureRepeat);

    //  test with comment
    refRepeat = MeasureRepeat.parseString("   A B(yo)C D  x2 E F", 0, 4, null);
    expect(refRepeat, isNotNull);
    expect("[A B (yo) C D ] x2 ", refRepeat.toMarkup());

    measureRepeat =
        MeasureRepeat.parseString("   A B (yo)|\nC D  x2 E F", 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect("[A B (yo) C D ] x2 ", measureRepeat.toMarkup());
    expect(refRepeat, measureRepeat);

    measureRepeat =
        MeasureRepeat.parseString(" [   A B (yo)|\nC D]x2 E F", 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect("[A B (yo) C D ] x2 ", measureRepeat.toMarkup());
    expect(refRepeat, measureRepeat);

    measureRepeat =
        MeasureRepeat.parseString(" [   A B (yo)   C D]x2 E F", 0, 4, null);
    expect(measureRepeat, isNotNull);
    expect("[A B (yo) C D ] x2 ", measureRepeat.toMarkup());
    expect(refRepeat, measureRepeat);
  });

  test("testMultilineInput", () {
    MeasureRepeat measureRepeat;

    ChordSection chordSection;

    chordSection =
        ChordSection.parseString("v3: A B C D | \n E F G G# | x2   \n", 4);

    expect(chordSection, isNotNull);
    Phrase phrase = chordSection.getPhrase(0);
    expect(phrase is MeasureRepeat, isTrue);
    measureRepeat = phrase as MeasureRepeat;
    logger.d(measureRepeat.toMarkup());
    ChordSectionLocation loc =
        new ChordSectionLocation(chordSection.sectionVersion, phraseIndex: 0);
    logger.d(loc.toString());
    expect("V3:0", loc.toString());

    chordSection = ChordSection.parseString("v3:A B C D|\nE F G G#|x2\n", 4);

    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(0);
    expect(phrase is MeasureRepeat, isTrue);
    measureRepeat = phrase as MeasureRepeat;
    logger.d(measureRepeat.toMarkup());
    loc = new ChordSectionLocation(chordSection.sectionVersion, phraseIndex: 0);
    logger.d(loc.toString());
    expect("V3:0", loc.toString());
  });

  test("testGridMapping", () {
    int beatsPerBar = 4;
    SongBase a;
    Measure m;

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "V: [G Bm F♯m G, GBm ] x3",
        "v: bob, bob, bob berand\n");
    a.debugSongMoments();

    ChordSection cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    ChordSection chordSection =
        a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    Phrase phrase = chordSection.getPhrase(0);
    expect(phrase.isRepeat(), isTrue);

    MeasureRepeat measureRepeat = phrase as MeasureRepeat;
    expect(5, measureRepeat.length);

    MeasureNode measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("G", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 2));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("Bm", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 3));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("F♯m", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("G", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("GBm", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 2));
    expect(measureNode, isNull);
    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 3));
    expect(measureNode, isNull);
    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 4));
    expect(measureNode, isNull);

    ChordSectionLocation chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(1, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight,
        chordSectionLocation.marker);
    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(1, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "v: [A B , Ab Bb Eb, D C G G# ] x3 T: A",
        "i:\nv: bob, bob, bob berand\nt: last line \n");
    a.debugSongMoments();

    cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(0);
    expect(phrase.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(9, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 2));
    expect(measureNode, isNotNull);
    m = Measure.parseString("B", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 3));
    expect(measureNode, isNull);
    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 4));
    expect(measureNode, isNull);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 3));
    expect(measureNode, isNotNull);
    m = Measure.parseString("Eb", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 4));
    expect(measureNode, isNull);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 4));
    expect(measureNode, isNull);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("G#", a.getBeatsPerBar()), measureNode);

    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight,
        chordSectionLocation.marker);
    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "v: E F F# G [A B C D Ab Bb Eb Db D C G Gb D C G# A#] x3 T: A",
        //         1 2 3  4  1 2 3 4 5  6  7  8  1 2 3 4  5 6 7  8
        //                                       9 101112 131415 16
        "i:\nv: bob, bob, bob berand\nt: last line \n");
    a.debugSongMoments();

    cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(1);
    expect(phrase.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(16, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("D", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("Gb", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 7));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("G#", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 8));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A#", a.getBeatsPerBar()), measureNode);

    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 8 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight,
        chordSectionLocation.marker);
    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 8 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "v: A B C D x3 T: A",
        "i:\nv: bob, bob, bob berand\nt: last line \n");
    a.debugSongMoments();

    cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(0);
    expect(phrase.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(4, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("D", a.getBeatsPerBar()), measureNode);

    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(0, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "v: [A B C D] x3 T: A",
        "i:\nv: bob, bob, bob berand\nt: last line \n");
    a.debugSongMoments();

    cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(0);
    expect(phrase.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(4, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("D", a.getBeatsPerBar()), measureNode);

    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(0, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "v: [A B C D, Ab Bb Eb Db, D C G G# ] x3 T: A",
        "i:\nv: bob, bob, bob berand\nt: last line \n");
    a.debugSongMoments();

    cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(0);
    expect(phrase.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(12, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("D", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("Db", a.getBeatsPerBar());
    m.endOfRow = true;

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("G#", a.getBeatsPerBar()), measureNode);

    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight,
        chordSectionLocation.marker);
    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "v: [A B C D, Ab Bb Eb Db, D C G# ] x3 T: A",
        "i:\nv: bob, bob, bob berand\nt: last line \n");
    a.debugSongMoments();

    cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(0);
    expect(phrase.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(11, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("D", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("Db", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 3));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("G#", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 4));
    expect(measureNode, isNull);

    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight,
        chordSectionLocation.marker);
    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "v: [A B C D, Ab Bb Eb Db, D C G G# ] x3 E F F# G T: A",
        "i:\nv: bob, bob, bob berand\nt: last line \n");
    a.debugSongMoments();

    cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(0);
    expect(phrase.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(12, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A", a.getBeatsPerBar()), measureNode);
    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("Db", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("D", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("Db", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("G#", a.getBeatsPerBar()), measureNode);
    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight,
        chordSectionLocation.marker);
    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(2, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);

    a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        beatsPerBar,
        4,
        "v: E F F# Gb [A B C D, Ab Bb Eb Db, D C G G# ] x3 T: A",
        "i:\nv: bob, bob, bob berand\nt: last line \n");
    a.debugSongMoments();

    cs = ChordSection.parseString("v:", a.getBeatsPerBar());
    chordSection = a.findChordSectionBySectionVersion(cs.sectionVersion);
    expect(chordSection, isNotNull);
    phrase = chordSection.getPhrase(1);
    expect(phrase.isRepeat(), isTrue);

    measureRepeat = phrase as MeasureRepeat;
    expect(12, measureRepeat.length);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 1));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("A", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(0, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("Gb", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(1, 3));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("C", a.getBeatsPerBar()), measureNode);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(2, 4));
    expect(measureNode, isNotNull);
    m = Measure.parseString("Db", a.getBeatsPerBar());
    m.endOfRow = true;
    expect(measureNode, m);

    measureNode = a.findMeasureNodeByGrid(new GridCoordinate(3, 4));
    expect(measureNode, isNotNull);
    expect(Measure.parseString("G#", a.getBeatsPerBar()), measureNode);

    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(3, 4 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.repeatLowerRight,
        chordSectionLocation.marker);
    chordSectionLocation =
        a.getChordSectionLocation(new GridCoordinate(3, 4 + 1 + 1));
    expect(chordSectionLocation, isNotNull);
    expect(ChordSectionLocationMarker.none, chordSectionLocation.marker);
    measureNode = a.findMeasureNodeByLocation(chordSectionLocation);
    expect(measureNode, isNotNull);
    expect(measureNode.isRepeat(), isTrue);
  });
}
