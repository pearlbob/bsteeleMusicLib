import 'dart:math';

import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/grid.dart';
import 'package:bsteeleMusicLib/songs/chordSectionGridData.dart';
import 'package:bsteeleMusicLib/songs/key.dart' as music_key;
import 'package:bsteeleMusicLib/songs/measure.dart';
import 'package:bsteeleMusicLib/songs/section.dart';
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
        var asLyrics = lyricSection.asExpandedLyrics(a.findChordSectionByLyricSection(lyricSection)!, rows);
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

  test('test lyricSection toLyrics()', () {
    {
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

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          var lyrics = lyricSection.toLyrics(chordSection, false);
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 1);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 1);
              expect(lyrics.first.line.split('\n').length, 3);
              break;
            default:
              assert(false);
          }
          logger.i('\n  $lyrics');
        }
      }
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
          'i: D C G G v: A B C D x3',
          'i: (instrumental)\n'
              'v:bob, bob, bob berand\n'
              'You got me\n'
              'rockn and rollin');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          var lyrics = lyricSection.toLyrics(chordSection, false);
          logger.i('\n  $lyrics');
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 1);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 3);
              for (var i = 0; i < lyrics.length; i++) {
                expect(lyrics[i].line.split('\n').length, 1);
              }
              break;
            default:
              assert(false);
          }
        }
      }
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
          'i: D C G G v: A B C D x3',
          'i: (instrumental)\n'
              'v:bob, bob, bob berand\n'
              'second bob, bob, bob berand\n'
              'You got me\n'
              'second You got me\n'
              'rockn and rollin\n'
              'second rockn and rollin');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          var lyrics = lyricSection.toLyrics(chordSection, false);
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 1);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 3);
              for (var i = 0; i < lyrics.length; i++) {
                expect(lyrics[i].line.split('\n').length, 2);
              }
              break;
            default:
              assert(false);
          }
          logger.i('\n  $lyrics');
        }
      }
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
          'i: D C G G, F C F G v: A B C D x3 D C G G, F C F G',
          'i: foo foo\n'
              'bar bar\n'
              'v:bob, bob, bob berand\n'
              'second bob, bob, bob berand\n'
              'You got me\n'
              'second You got me\n'
              'rockn and rollin\n'
              'second rockn and rollin\n'
              'first non-repeat line\n'
              'second non-repeat line\n');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          var lyrics = lyricSection.toLyrics(chordSection, false);
          logger.i('\n  $lyrics');
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 2);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 5);
              expect(lyrics[0].line.split('\n').length, 2);
              expect(lyrics[1].line.split('\n').length, 2);
              expect(lyrics[2].line.split('\n').length, 2);
              expect(lyrics[3].line.split('\n').length, 1);
              expect(lyrics[4].line.split('\n').length, 1);
              break;
            default:
              assert(false);
          }
        }
      }
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
          'i: D C G G v: A B C D',
          'i: (instrumental)\n'
              'v:bob, bob, bob berand\n'
              'You got me\n'
              'rockn and rollin');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          //  expansion should have no effect if there are no repeats
          var lyrics = lyricSection.toLyrics(chordSection, true);
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 1);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 1);
              expect(lyrics.first.line.split('\n').length, 3);
              break;
            default:
              assert(false);
          }
          logger.i('\n  $lyrics');
        }
      }
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
          'i: D C G G, F C F G v: A B C D x3 D C G G, F C F G',
          'i: foo foo\n'
              'bar bar\n'
              'v:bob, bob, bob berand\n'
              'second bob, bob, bob berand\n'
              'You got me\n'
              'second You got me\n'
              'rockn and rollin\n'
              'second rockn and rollin\n'
              'first non-repeat line\n'
              'second non-repeat line\n');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          //  expansion should have no effect if the repeats are single row
          var lyrics = lyricSection.toLyrics(chordSection, true);
          logger.i('\n  $lyrics');
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 2);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 5);
              expect(lyrics[0].line.split('\n').length, 2);
              expect(lyrics[1].line.split('\n').length, 2);
              expect(lyrics[2].line.split('\n').length, 2);
              expect(lyrics[3].line.split('\n').length, 1);
              expect(lyrics[4].line.split('\n').length, 1);
              break;
            default:
              assert(false);
          }
        }
      }
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
          'i: D C G G, F C F G v: [ A B C D, C F G F ] x3 D C G G, F C F G',
          'i: foo foo\n'
              'bar bar\n'
              'v:bob, bob, bob berand\n'
              'second bob, bob, bob berand\n'
              'You got me\n'
              'second You got me\n'
              'rockn and rollin\n'
              'second rockn and rollin\n'
              'first non-repeat line\n'
              'second non-repeat line\n');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          //  expansion should have no effect if the repeats are single row
          var lyrics = lyricSection.toLyrics(chordSection, true);
          logger.i('\n  $lyrics');
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 2);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 8);
              for (var i = 0; i < lyrics.length; i++) {
                expect(lyrics[i].line.split('\n').length, 1);
              }
              break;
            default:
              assert(false);
          }
        }
      }
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
          'i: D C G G, F C F G v: [ A B C D, C F G F ] x3 D C G G, F C F G',
          'i: foo foo\n'
              'bar bar\n'
              'v:bob, bob, bob berand\n'
              'You got me\n');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          //  expansion should have no effect if the repeats are single row
          var lyrics = lyricSection.toLyrics(chordSection, false);
          logger.i('\n  $lyrics');
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 2);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 5);
              expect(lyrics[0].line.split('\n').length, 2);
              expect(lyrics[1].line.split('\n').length, 2);
              expect(lyrics[2].line.split('\n').length, 2);
              expect(lyrics[3].line.split('\n').length, 1);
              expect(lyrics[4].line.split('\n').length, 1);
              break;
            default:
              assert(false);
          }
        }
      }
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
          'v: [ A B C D ] x4',
          'v: foo foo\n'
              'bar bar\n'
              'bob, bob, bob berand\n'
              'You got me');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          //  expansion should have no effect if the repeats are single row
          var lyrics = lyricSection.toLyrics(chordSection, false);
          logger.i('\n  $lyrics');
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.verse:
              expect(lyrics.length, 4);
              expect(lyrics[0].line.split('\n').length, 1);
              expect(lyrics[1].line.split('\n').length, 1);
              expect(lyrics[2].line.split('\n').length, 1);
              expect(lyrics[2].line, 'bob, bob, bob berand');
              expect(lyrics[3].line.split('\n').length, 1);
              break;
            default:
              assert(false);
          }
        }
      }
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
          'i: D C G G, F C F G v: D C G G, A B C D x3 F C F G',
          'i: foo foo\n'
              'bar bar\n'
              'v:\n'
              'first non-repeat line\n'
              '-\n'
              'bob, bob, bob berand\n'
              'second bob, bob, bob berand\n'
              'You got me\n'
              'second You got me\n'
              'rockn and rollin\n'
              'second rockn and rollin\n'
              'second non-repeat line\n');

      for (var lyricSection in a.lyricSections) {
        var chordSection = a.findChordSectionByLyricSection(lyricSection);

        logger.i('\n$lyricSection: $chordSection');

        expect(chordSection, isNotNull);
        if (chordSection != null) {
          //  expansion should have no effect if the repeats are single row
          var lyrics = lyricSection.toLyrics(chordSection, true);
          logger.i('\n  $lyrics');
          switch (lyricSection.sectionVersion.section.sectionEnum) {
            case SectionEnum.intro:
              expect(lyrics.length, 2);
              expect(lyrics.first.line.split('\n').length, 1);
              break;
            case SectionEnum.verse:
              expect(lyrics.length, 5);
              logger.i('first line: "${lyrics[0].line.replaceAll('\n', '\\n')}"');
              logger.i('first line split: ${lyrics[0].line.split('\n')}');
              expect(lyrics[0].line.split('\n').length, 2);
              expect(lyrics[1].line.split('\n').length, 2);
              expect(lyrics[2].line.split('\n').length, 2);
              expect(lyrics[3].line.split('\n').length, 2);
              expect(lyrics[4].line.split('\n').length, 1);
              expect(lyrics[4].line, 'second non-repeat line');
              break;
            default:
              assert(false);
          }
        }
      }
    }
  });
}
