import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/grid.dart';
import 'package:bsteele_music_lib/songs/chord_section_location.dart';
import 'package:bsteele_music_lib/songs/key.dart';
import 'package:bsteele_music_lib/songs/section.dart';
import 'package:bsteele_music_lib/songs/section_version.dart';
import 'package:bsteele_music_lib/songs/song_base.dart';
import 'package:bsteele_music_lib/songs/song_moment.dart';
import 'package:bsteele_music_lib/songs/song_moment_location.dart';
import 'package:bsteele_music_lib/util/util.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  Logger.level = Level.trace;

  test('parse ', () {
    SongMomentLocation? loc;
    {
      loc = SongMomentLocation.parseString(null);
      expect(loc, isNull);

      loc = SongMomentLocation.parseString('V2:');
      expect(loc, isNull);
      loc = SongMomentLocation.parseString('V2:0');
      expect(loc, isNull);
      loc = SongMomentLocation.parseString('V2:0:1');
      expect(loc, isNull);
      loc = SongMomentLocation.parseString('V2:0:1');
      expect(loc, isNull);
      loc = SongMomentLocation.parseString('V2:0:1#0');
      expect(loc, isNull);
      loc = SongMomentLocation.parseString('V2:2:1#3');
      SongMomentLocation locExpected = SongMomentLocation(
          ChordSectionLocation(SectionVersion(Section.get(.verse), 2), phraseIndex: 2, measureIndex: 1), 3);
      logger.d(locExpected.toString());
      expect(loc, locExpected);
    }

    for (Section section in Section.values) {
      for (int version = 0; version < 10; version++) {
        for (int phraseIndex = 0; phraseIndex <= 3; phraseIndex++) {
          for (int index = 1; index < 8; index++) {
            for (int instance = 1; instance < 4; instance++) {
              SongMomentLocation locExpected = SongMomentLocation(
                  ChordSectionLocation(SectionVersion(section, version), phraseIndex: phraseIndex, measureIndex: index),
                  instance);
              MarkedString markedString =
                  MarkedString('$section${version > 0 ? version.toString() : ''}:$phraseIndex:$index#$instance');

              logger.d(markedString.toString());
              loc = SongMomentLocation.parse(markedString);

              expect(loc, isNotNull);
              expect(loc, locExpected);
            }
          }
        }
      }
    }
  });

  test('grid ', () {
    SongBase a = SongBase(
        title: 'A',
        artist: 'bob',
        copyright: 'bsteele.com',
        key: MajorKey.getDefault(),
        beatsPerMinute: 100,
        beatsPerBar: 4,
        unitsPerMeasure: 4,
        chords: 'i: A B C D V: D E F F# [ D C B A ]x2 (comment) c: D C G G A B o: G',
        rawLyrics: 'i:\nv: bob, bob, bob berand\nc: sing chorus here \no: last line of outro');

    Grid<SongMoment> songMomentGrid = a.songMomentGrid;

    logger.t(songMomentGrid.toString());
    expect(songMomentGrid.getRowCount(), 8);

    {
      SongMoment? lastSongMoment;

      int? lastRowLength;
      for (int row = 0; row < songMomentGrid.getRowCount(); row++) {
        logger.i('$row:');

        int? rowLength = songMomentGrid.rowLength(row);
        if (lastRowLength != null) {
          expect(rowLength, lastRowLength);
        }
        lastRowLength = rowLength;

        for (int col = 0; col < rowLength; col++) {
          SongMoment? songMoment = songMomentGrid.get(row, col);
          String s = (songMoment == null ? 'null' : songMoment.toString());
          logger.d('\t($row,$col): $s');
          if (songMoment != null) {
            //  the beat must go on
            if (lastSongMoment != null) {
              expect(lastSongMoment.beatNumber < songMoment.beatNumber, isTrue);
            }
            lastSongMoment = songMoment;
          }
        }
      }
    }
  });
}
