import 'dart:math';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/grid.dart';
import 'package:bsteeleMusicLib/songs/chordSectionGridData.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/songBase.dart';
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

  test('test lyricSection asLyrics()', () {
    SongBase a = SongBase.createSongBase(
        'A',
        'bob',
        'bsteele.com',
        music_key.Key.getDefault(),
        100,
        4,
        4,
        'i: D C G G v: A B C D',
        'i: (instrumental)\n'
            'v:bob, bob, bob berand\n'
            'You got me\n'
            'rockn and rollin');

    for (var rows = 0; rows < 6; rows++) {
      for (var lyricSection in a.lyricSections) {
        logger.i('\n$lyricSection in $rows rows:');
        var i = 1;
        var asLyrics = lyricSection.asLyrics(rows);
        assert(asLyrics.length == max(1, rows));
        for (var lyric in asLyrics) {
          logger.i('${i++}:  "$lyric"');
        }
        for (var i = 0; i < rows; i++) {
          assert(asLyrics[i].toMarkup().isEmpty == (i > lyricSection.lyricsLines.length - 1));
        }
      }
    }
  });
}
