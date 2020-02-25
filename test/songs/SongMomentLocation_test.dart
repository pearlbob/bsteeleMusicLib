import 'package:bsteeleMusicLib/Grid.dart';
import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/ChordSectionLocation.dart';
import 'package:bsteeleMusicLib/songs/Section.dart';
import 'package:bsteeleMusicLib/songs/SectionVersion.dart';
import 'package:bsteeleMusicLib/songs/SongBase.dart';
import 'package:bsteeleMusicLib/songs/SongMoment.dart';
import 'package:bsteeleMusicLib/songs/SongMomentLocation.dart';
import 'package:bsteeleMusicLib/songs/Key.dart';
import 'package:bsteeleMusicLib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.verbose;

  test("parse ", () {
    SongMomentLocation loc;
    {
      loc = SongMomentLocation.parseString(null);
      expect(loc, isNull);

      loc = SongMomentLocation.parseString("V2:");
      expect(loc, isNull);
      loc = SongMomentLocation.parseString("V2:0");
      expect(loc, isNull);
      loc = SongMomentLocation.parseString("V2:0:1");
      expect(loc, isNull);
      loc = SongMomentLocation.parseString("V2:0:1");
      expect(loc, isNull);
      loc = SongMomentLocation.parseString("V2:0:1#0");
      expect(loc, isNull);
      loc = SongMomentLocation.parseString("V2:2:1#3");
      SongMomentLocation locExpected = SongMomentLocation(
          ChordSectionLocation(
              SectionVersion(Section.get(SectionEnum.verse), 2),
              phraseIndex: 2,
              measureIndex: 1),
          3);
      logger.d(locExpected.toString());
      expect(loc, locExpected);
    }

    for (Section section in Section.values)
      for (int version = 0; version < 10; version++)
        for (int phraseIndex = 0; phraseIndex <= 3; phraseIndex++)
          for (int index = 1; index < 8; index++) {
            for (int instance = 1; instance < 4; instance++) {
              SongMomentLocation locExpected = new SongMomentLocation(
                  new ChordSectionLocation(new SectionVersion(section, version),
                      phraseIndex: phraseIndex, measureIndex: index),
                  instance);
              MarkedString markedString = new MarkedString(section.toString() +
                  (version > 0 ? version.toString() : "") +
                  ":" +
                  phraseIndex.toString() +
                  ":" +
                  index.toString() +
                  "#" +
                  instance.toString());

              logger.d(markedString.toString());
              loc = SongMomentLocation.parse(markedString);

              expect(loc, isNotNull);
              expect(loc, locExpected);
            }
          }
  });

  test("grid ", () {
    SongBase _a = SongBase.createSongBase(
        "A",
        "bob",
        "bsteele.com",
        Key.getDefault(),
        100,
        4,
        4,
        "i: A B C D V: D E F F# [ D C B A ]x2 (comment) c: D C G G A B o: G",
        "i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro");

    Grid<SongMoment> songMomentGrid = _a.songMomentGrid;

    expect(songMomentGrid.getRowCount(), 7);

    {
      SongMoment lastSongMoment;

      int lastRowLength;
      for (int row = 0; row < songMomentGrid.getRowCount(); row++) {
        logger.i('$row:');

        int rowLength =songMomentGrid.rowLength(row);
        if ( lastRowLength!= null )
          expect(rowLength,lastRowLength);
        lastRowLength=rowLength;

        for (int col = 0; col < rowLength; col++) {
          SongMoment songMoment = songMomentGrid.get(row, col);
          String s = (songMoment == null ? 'null' : songMoment.toString());
          logger.d('\t($row,$col): $s');
          if (songMoment != null) {
            //  the beat must go on
            if (lastSongMoment != null)
              expect(lastSongMoment.beatNumber < songMoment.beatNumber, isTrue);
            lastSongMoment = songMoment;
          }
        }
      }
    }
  });
}
